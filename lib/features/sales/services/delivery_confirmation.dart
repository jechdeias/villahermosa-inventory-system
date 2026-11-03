import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../customer/providers/customer_providers.dart' show paymentMethodFromNotes;

/// Outcome of confirming a delivery (by QR scan, typed order number, or the
/// rep's own "Mark as Delivered").
sealed class ScanResult {
  const ScanResult();
}

/// No order with that number on this phone.
class ScanNotFound extends ScanResult {
  const ScanNotFound();
}

/// The order exists but isn't out for delivery (not dispatched yet, already
/// delivered, or cancelled), so there is nothing to confirm.
class ScanWrongStatus extends ScanResult {
  const ScanWrongStatus({required this.orderCode, required this.status});
  final String orderCode;
  final String status;
}

/// Delivery confirmed; carries what the rep needs to collect.
class ScanSuccess extends ScanResult {
  const ScanSuccess({required this.storeName, required this.orderCode, required this.amount, required this.paymentMethod});
  final String storeName;
  final String orderCode;
  final double amount;
  final String paymentMethod;

  /// Only cash-on-delivery orders are paid on the spot (GCash and credit are not).
  bool get collectOnDelivery => paymentMethod.toLowerCase().startsWith('cash');
}

const defaultPaymentMethod = 'Cash on Delivery';

// ── How a delivery was confirmed ─────────────────────────────────────────────
//
// Orders have no column for this and the schema must not change, so it is
// recorded as a line in the order's existing notes, next to the
// "Payment method: …" line the customer's checkout writes.

/// The customer's QR code was scanned by the rep.
const deliveryMethodQr = 'qr';

/// The rep confirmed it themselves (store has no app / no smartphone).
const deliveryMethodManual = 'manual';

const _deliveryMethodPrefix = 'Delivery confirmed: ';

/// [notes] with a "Delivery confirmed: METHOD" line added (replacing any
/// earlier one, so confirming twice can't leave two conflicting lines).
String appendDeliveryMethod(String? notes, String method) {
  final kept = (notes ?? '').split('\n').where((l) => !l.startsWith(_deliveryMethodPrefix) && l.trim().isNotEmpty).toList();
  return [...kept, '$_deliveryMethodPrefix$method'].join('\n');
}

/// 'qr' | 'manual' | null (not recorded — e.g. delivered before this existed).
String? deliveryMethodFromNotes(String? notes) {
  if (notes == null) return null;
  for (final line in notes.split('\n')) {
    if (line.startsWith(_deliveryMethodPrefix)) return line.substring(_deliveryMethodPrefix.length).trim();
  }
  return null;
}

/// THE delivery-confirmation code path: marks [order] delivered, stamps the
/// delivery time, records how it was confirmed, flags the order for sync and
/// kicks off a background push. Local Drift write only, so it works offline.
/// Both the QR scan and the manual "Mark as Delivered" go through here.
Future<ScanSuccess> markOrderDelivered(AppDatabase db, Order order, {required String method}) async {
  await db.updateOrderStatusById(
    order.id,
    OrderStatus.delivered,
    customerNotes: appendDeliveryMethod(order.customerNotes, method),
  );
  SyncManager.syncInBackground();

  return ScanSuccess(
    storeName: (order.storeName ?? '').isEmpty ? '—' : order.storeName!,
    orderCode: order.orderNumber,
    amount: order.totalAmount,
    paymentMethod: paymentMethodFromNotes(order.customerNotes) ?? defaultPaymentMethod,
  );
}

/// Looks up the order by the code in the customer's QR (its order number) and,
/// if it is out for delivery, marks it delivered.
Future<ScanResult> confirmDeliveryByCode(AppDatabase db, String rawCode) async {
  final code = rawCode.trim();
  if (code.isEmpty) return const ScanNotFound();

  final order = await db.getOrderByCode(code);
  if (order == null) return const ScanNotFound();
  return _confirmIfOutForDelivery(db, order, deliveryMethodQr);
}

/// "Mark as Delivered" for a store with no app: same rules and same code path
/// as a QR scan, only the recorded method differs. The order is re-read first
/// so a stale screen can't deliver something that has since changed.
Future<ScanResult> confirmDeliveryManually(AppDatabase db, int orderId) async {
  final order = await db.getOrderByIntId(orderId);
  if (order == null) return const ScanNotFound();
  return _confirmIfOutForDelivery(db, order, deliveryMethodManual);
}

Future<ScanResult> _confirmIfOutForDelivery(AppDatabase db, Order order, String method) async {
  if (order.status != OrderStatus.outForDelivery) {
    return ScanWrongStatus(orderCode: order.orderNumber, status: order.status);
  }
  return markOrderDelivered(db, order, method: method);
}
