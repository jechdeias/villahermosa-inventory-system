import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_service.dart';
import '../constants/order_status.dart';
import '../database/app_database.dart';

/// Moves product stock when an order's status changes. This is the ONE place
/// stock is deducted for orders; every path into `out_for_delivery` or
/// `cancelled` calls [applyStatusChange] (see its callers) instead of doing its
/// own arithmetic.
///
/// * Dispatch (→ out_for_delivery): goods physically leave the warehouse, so
///   each order line's quantity is taken off its product, as one
///   `stock_movements` row per line (reason [fulfillmentReason], referenceId =
///   the order's UUID, so the audit trail and sync come from the existing
///   [AppDatabase.adjustProductStock]).
/// * Cancel (→ cancelled): whatever is still deducted for the order is put back
///   (reason [cancelledReason], same referenceId).
///
/// Not at order creation: reserving at order time is a different model and would
/// double-count against this one.
///
/// **Idempotency is keyed on the stock_movements rows, never on order status.**
/// Sync can move a status backwards and forwards (the pull overwrites; statuses
/// flap), and a status-based check would then deduct twice with no trace. Instead
/// the amount currently deducted for an order is derived from its movements:
/// `Σ 'Order fulfillment' − Σ 'Order cancelled'` per product. Dispatch skips if
/// anything is still deducted; cancel restores exactly what is still deducted.
/// A second dispatch therefore deducts nothing, a second cancel restores
/// nothing, an order that was never deducted is never "restored", and an order
/// that was cancelled (stock restored) and later restored to pending and
/// dispatched again deducts again — the fulfillment row from the first round no
/// longer counts because the cancellation cancelled it out.
///
/// **Negative stock is allowed, deliberately.** On the live data almost every
/// product sits at 0; refusing to dispatch when stock is insufficient would stop
/// dispatch working at all. Stock goes negative instead, which is truthful and
/// makes the data problem visible (negative figures render in red).
class OrderStockService {
  OrderStockService(this._db);
  final AppDatabase _db;

  static const fulfillmentReason = 'Order fulfillment';
  static const cancelledReason = 'Order cancelled';

  /// Applies whatever stock effect [newStatus] has for [orderUuid]; a no-op for
  /// every other status. Call it inside the same transaction as the status write
  /// so both succeed or neither does.
  Future<void> applyStatusChange(String orderUuid, String newStatus) async {
    if (newStatus == OrderStatus.outForDelivery) {
      await deductForDispatch(orderUuid);
    } else if (newStatus == OrderStatus.cancelled) {
      await restoreForCancellation(orderUuid);
    }
  }

  /// Net units currently deducted for [orderUuid], by product uuid.
  Future<Map<String, int>> deductedFor(String orderUuid) async {
    final rows = await (_db.select(_db.stockMovements)
          ..where((m) =>
              m.referenceId.equals(orderUuid) &
              m.reason.isIn([fulfillmentReason, cancelledReason]) &
              m.isDeleted.equals(false)))
        .get();
    final net = <String, int>{};
    for (final m in rows) {
      final signed = m.reason == fulfillmentReason ? m.quantity : -m.quantity;
      net[m.productId] = (net[m.productId] ?? 0) + signed;
    }
    net.removeWhere((_, units) => units <= 0);
    return net;
  }

  /// Deducts every line of the order, once. Returns the number of lines
  /// deducted (0 when already deducted, or nothing to deduct).
  Future<int> deductForDispatch(String orderUuid) async {
    if ((await deductedFor(orderUuid)).isNotEmpty) {
      debugPrint('Stock for order $orderUuid is already deducted — skipping');
      return 0;
    }
    final lines = await _db.getOrderItemsByOrderId(orderUuid);
    final (userUuid, userName) = _actor();
    var deducted = 0;
    // One transaction per order: a failure part-way rolls back every line
    // already done (adjustProductStock opens its own transaction; Drift nests
    // these as savepoints, and the whole thing joins the caller's transaction).
    await _db.transaction(() async {
      for (final line in lines) {
        if (line.quantity <= 0) continue;
        final product = await _db.getProductByUuid(line.productId);
        if (product == null) {
          // A line whose product is gone must not abort the whole dispatch.
          debugPrint('Order $orderUuid line ${line.uuid}: product ${line.productId} not found — no stock deducted for it');
          continue;
        }
        await _db.adjustProductStock(
          productUuid: product.uuid,
          delta: -line.quantity, // may go below zero — deliberate
          reason: fulfillmentReason,
          notes: 'Dispatched: ${line.productName} × ${line.quantity}',
          userUuid: userUuid,
          userName: userName,
          referenceId: orderUuid,
        );
        deducted++;
      }
    });
    return deducted;
  }

  /// Puts back whatever is still deducted for the order. Returns the number of
  /// products restored (0 if the order was never deducted or already restored).
  Future<int> restoreForCancellation(String orderUuid) async {
    final outstanding = await deductedFor(orderUuid);
    if (outstanding.isEmpty) return 0;
    final (userUuid, userName) = _actor();
    var restored = 0;
    await _db.transaction(() async {
      for (final entry in outstanding.entries) {
        final product = await _db.getProductByUuid(entry.key);
        if (product == null) {
          debugPrint('Order $orderUuid: product ${entry.key} not found — cannot restore its stock');
          continue;
        }
        await _db.adjustProductStock(
          productUuid: product.uuid,
          delta: entry.value,
          reason: cancelledReason,
          notes: 'Order cancelled after dispatch',
          userUuid: userUuid,
          userName: userName,
          referenceId: orderUuid,
        );
        restored++;
      }
    });
    return restored;
  }

  (String, String) _actor() {
    try {
      final u = AuthService.instance.getCurrentUser();
      if (u != null) {
        final name = '${u.firstName} ${u.lastName}'.trim();
        return (u.uuid, name.isEmpty ? u.email : name);
      }
    } catch (_) {}
    return ('system', 'System');
  }
}
