import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../customer/providers/customer_providers.dart' show paymentMethodFromNotes;

/// Outcome of scanning (or typing) an order code on the sales rep's phone.
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

/// Looks up the order by the code in the customer's QR (its order number) and,
/// if it is out for delivery, marks it delivered. The change is saved locally
/// and flagged for sync straight away, so it works offline.
Future<ScanResult> confirmDeliveryByCode(AppDatabase db, String rawCode) async {
  final code = rawCode.trim();
  if (code.isEmpty) return const ScanNotFound();

  final order = await db.getOrderByCode(code);
  if (order == null) return const ScanNotFound();

  if (order.status != OrderStatus.outForDelivery) {
    return ScanWrongStatus(orderCode: order.orderNumber, status: order.status);
  }

  await db.updateOrderStatusById(order.id, OrderStatus.delivered);
  SyncManager.syncInBackground();

  return ScanSuccess(
    storeName: (order.storeName ?? '').isEmpty ? '—' : order.storeName!,
    orderCode: order.orderNumber,
    amount: order.totalAmount,
    paymentMethod: paymentMethodFromNotes(order.customerNotes) ?? defaultPaymentMethod,
  );
}
