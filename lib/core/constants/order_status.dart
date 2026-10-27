/// Values of `orders.status` (a plain text column, so no schema change).
///
/// Lifecycle: pending → processing → out_for_delivery → delivered → completed,
/// with cancelled possible before delivery.
///  - pending: placed, waiting for the warehouse
///  - processing: being picked and packed
///  - out_for_delivery: dispatched, the customer shows a QR code
///  - delivered: the sales rep scanned the QR
///  - completed: the customer confirmed receipt (or it auto-confirmed)
class OrderStatus {
  const OrderStatus._();

  static const pending = 'pending';
  static const processing = 'processing';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const all = [pending, processing, outForDelivery, delivered, completed, cancelled];

  /// "out_for_delivery" → "Out for Delivery".
  static String label(String status) => switch (status) {
        pending => 'Pending',
        processing => 'Processing',
        outForDelivery => 'Out for Delivery',
        delivered => 'Delivered',
        completed => 'Completed',
        cancelled => 'Cancelled',
        '' => '',
        _ => status
            .split('_')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' '),
      };

  /// Still moving through fulfilment (not delivered, completed or cancelled).
  static bool isInFulfilment(String status) => status == pending || status == processing || status == outForDelivery;

  /// Nothing more for the warehouse or a route to do with this order.
  static bool isFinished(String status) => status == delivered || status == completed || status == cancelled;
}
