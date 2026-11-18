import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/services/order_stock_service.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/sync/sync_manager.dart';
import '../../admin/providers/orders_provider.dart' show databaseProvider;
import '../../admin/providers/products_provider.dart' show productsStreamProvider;
import '../../admin/services/products_service.dart';

export '../../admin/providers/orders_provider.dart' show databaseProvider, ordersStreamProvider;
export '../../admin/providers/products_provider.dart' show productsStreamProvider;
export '../../admin/providers/stock_movements_provider.dart' show stockMovementsStreamProvider;
export '../../admin/providers/delivery_routes_provider.dart' show deliveryRoutesStreamProvider;

/// Every live (non-deleted) order line, so screens can group by parent order.
final orderItemsStreamProvider = StreamProvider<List<OrderItem>>(
  (ref) => ref.watch(databaseProvider).watchAllOrderItems(),
);

// ── Pure helpers (no Flutter / provider deps, easy to unit test) ──────────────

/// Warehouse-side state of an order: cancelled | completed | dispatched |
/// ready | processing | pending.
String whOrderStatus(Order o) {
  // Terminal / downstream statuses come from orders.status, which syncs.
  if (o.status == OrderStatus.cancelled) return 'cancelled';
  if (o.status == OrderStatus.completed || o.status == OrderStatus.delivered) return 'completed';
  if (o.status == OrderStatus.outForDelivery) return 'dispatched';
  // Before dispatch, picking progress lives in warehouseStatus (synced both ways: pushed and pulled).
  switch (o.warehouseStatus) {
    case 'dispatched':
      return 'dispatched';
    case 'ready':
    case 'packed':
      return 'ready';
    case 'processing':
      return 'processing';
    default:
      return 'pending';
  }
}

/// Still needs warehouse work (not ready, dispatched, completed or cancelled).
bool needsPreparing(Order o) {
  final s = whOrderStatus(o);
  return s == 'pending' || s == 'processing';
}

/// 'not started' | 'loading' | 'dispatched', derived from the route's open orders.
String routeLoadState(DeliveryRoute r, List<Order> orders) {
  final mine = orders.where((o) => o.routeName == r.routeName && !OrderStatus.isFinished(o.status)).toList();
  if (mine.isEmpty) return 'not started';
  if (mine.every((o) => whOrderStatus(o) == 'dispatched')) return 'dispatched';
  if (mine.any((o) => whOrderStatus(o) == 'ready' || whOrderStatus(o) == 'dispatched')) return 'loading';
  return 'not started';
}

bool isReadyForLoading(Order o) => whOrderStatus(o) == 'ready';

bool isLowStock(Product p) => p.currentStock > 0 && p.currentStock <= p.minStock;
bool isOutOfStock(Product p) => p.currentStock <= 0;

/// 'in_stock' | 'low_stock' | 'out_of_stock'
String stockStatusOf(Product p) {
  if (isOutOfStock(p)) return 'out_of_stock';
  if (isLowStock(p)) return 'low_stock';
  return 'in_stock';
}

/// Order lines reference the product by uuid (or, for seed data, only by SKU).
Product? productForItem(OrderItem item, List<Product> products) {
  for (final p in products) {
    if (p.uuid == item.productId) return p;
  }
  for (final p in products) {
    if (p.sku == item.productSku) return p;
  }
  return null;
}

bool isItemPicked(OrderItem i) => i.status == 'picked' || i.status == 'loaded';
bool isItemLoaded(OrderItem i) => i.status == 'loaded';

/// Movement reasons the Returns screen treats as a return/damage/expiry entry.
const returnReasons = {'Customer return': 'returned', 'Damaged': 'damaged', 'Expired': 'expired'};

String? returnTypeOf(StockMovement m) => returnReasons[m.reason];

String returnId(StockMovement m) => 'RET-${m.id.toString().padLeft(4, '0')}';

DateTime? lastSyncTime() {
  try {
    return AppSettings.instance.lastSyncTimestamp;
  } catch (_) {
    return null;
  }
}

String currentUserName() {
  final u = AuthService.instance.getCurrentUser();
  if (u == null) return 'Warehouse';
  final n = '${u.firstName} ${u.lastName}'.trim();
  return n.isEmpty ? 'Warehouse' : n;
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// Open orders grouped by order uuid → their lines.
final orderLinesByOrderProvider = Provider<Map<String, List<OrderItem>>>((ref) {
  final items = ref.watch(orderItemsStreamProvider).valueOrNull ?? [];
  final map = <String, List<OrderItem>>{};
  for (final i in items) {
    map.putIfAbsent(i.orderId, () => []).add(i);
  }
  return map;
});

final lowStockProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsStreamProvider).valueOrNull ?? [];
  return products.where((p) => isLowStock(p) || isOutOfStock(p)).toList()
    ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
});

// ── Writes ────────────────────────────────────────────────────────────────────
//
// Order status, warehouse_status, packed_at and per-line status/picked_at all
// sync (they are in the push maps in sync_engine.dart), so every write below
// marks its row 'pending'.

class WarehouseActions {
  const WarehouseActions(this._db);
  final AppDatabase _db;

  void _pushAsync() => SyncManager.syncInBackground();

  // Every write here goes through updateOrderById / updateOrderItemById, which
  // force syncStatus = 'pending'. That matters for ALL of them now: status,
  // warehouse_status, packed_at, and per-line status/picked_at are all in the
  // push maps, so a write that left the row 'synced' would never upload and the
  // next pull would revert it.

  /// Warehouse picks the order up: pending → processing.
  Future<void> processOrder(Order o) async {
    await _db.updateOrderById(
      o.id,
      const OrdersCompanion(
        status: Value(OrderStatus.processing),
        warehouseStatus: Value('processing'),
      ),
    );
    _pushAsync();
  }

  Future<void> setItemPicked(OrderItem i, bool picked) => _db.updateOrderItemById(
        i.id,
        OrderItemsCompanion(
          status: Value(picked ? 'picked' : 'pending'),
          pickedAt: Value(picked ? DateTime.now() : null),
        ),
      );

  Future<void> resetPicks(List<OrderItem> items) async {
    for (final i in items) {
      await setItemPicked(i, false);
    }
  }

  Future<void> completeOrder(Order o, List<OrderItem> items) async {
    final now = DateTime.now();
    await _db.updateOrderById(
      o.id,
      OrdersCompanion(
        warehouseStatus: const Value('ready'),
        packedAt: Value(now),
        // An order completed straight from pending skipped Process; its status
        // should still read "processing" from here on.
        status: o.status == OrderStatus.pending ? const Value(OrderStatus.processing) : const Value.absent(),
      ),
    );
    _pushAsync();
  }

  Future<void> setItemLoaded(OrderItem i, bool loaded) =>
      _db.updateOrderItemById(i.id, OrderItemsCompanion(status: Value(loaded ? 'loaded' : 'picked')));

  /// Truck leaves: every prepared order on the route becomes out_for_delivery
  /// (the customer's phone then shows its QR code).
  ///
  /// Each order is its own transaction (status write + stock deduction commit
  /// together, see OrderStockService), so one order failing rolls back only
  /// itself: the rest still go, and the result says exactly which did and which
  /// didn't — callers must show that, not just a count.
  Future<DispatchResult> dispatchOrders(List<Order> orders) async {
    final dispatched = <Order>[];
    final failed = <FailedDispatch>[];
    for (final o in orders) {
      try {
        await _db.transaction(() async {
          await _db.updateOrderById(
            o.id,
            const OrdersCompanion(
              status: Value(OrderStatus.outForDelivery),
              warehouseStatus: Value('dispatched'),
            ),
          );
          await OrderStockService(_db).applyStatusChange(o.uuid, OrderStatus.outForDelivery);
        });
        dispatched.add(o);
      } catch (e) {
        debugPrint('Dispatch of ${o.orderNumber} failed: $e');
        failed.add(FailedDispatch(o, e));
      }
    }
    if (dispatched.isNotEmpty) _pushAsync();
    return DispatchResult(dispatched: dispatched, failed: failed);
  }
}

class FailedDispatch {
  const FailedDispatch(this.order, this.error);
  final Order order;
  final Object error;
}

/// Outcome of a (possibly partial) route dispatch.
class DispatchResult {
  const DispatchResult({required this.dispatched, required this.failed});
  final List<Order> dispatched;
  final List<FailedDispatch> failed;

  int get count => dispatched.length;
  bool get hasFailures => failed.isNotEmpty;

  /// What to tell the user: the real count, and — if anything failed — which
  /// orders went and which did not, with the reason.
  String get summary {
    final total = dispatched.length + failed.length;
    if (failed.isEmpty) {
      return 'Route dispatched. $count ${count == 1 ? 'order is' : 'orders are'} out for delivery.';
    }
    final notSent = failed.map((f) => '${f.order.orderNumber} (${f.error})').join('; ');
    if (dispatched.isEmpty) {
      return 'Nothing was dispatched — $total ${total == 1 ? 'order' : 'orders'} failed and stay as they were. $notSent';
    }
    final sent = dispatched.map((o) => o.orderNumber).join(', ');
    return 'Dispatched $count of $total. Out for delivery: $sent. NOT dispatched: $notSent';
  }
}

final warehouseActionsProvider = Provider<WarehouseActions>((ref) => WarehouseActions(ref.watch(databaseProvider)));

/// Records a stock movement (and adjusts the product's stock) as the current user.
Future<void> recordStockMovement(
  WidgetRef ref, {
  required String productUuid,
  required int delta,
  required String reason,
  String? notes,
  String? reference,
}) {
  final user = AuthService.instance.getCurrentUser();
  return ref.read(productsServiceProvider).adjustStock(
        productUuid: productUuid,
        delta: delta,
        reason: reason,
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        referenceId: (reference == null || reference.trim().isEmpty) ? null : reference.trim(),
        userUuid: user?.uuid ?? '',
        userName: currentUserName(),
      );
}

const stockInReasons = ['Supplier delivery', 'Customer return', 'Stock adjustment'];
const stockOutReasons = ['Order fulfillment', 'Damaged', 'Expired', 'Stock adjustment'];
