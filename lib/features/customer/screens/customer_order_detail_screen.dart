import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/providers/orders_provider.dart' show databaseProvider;
import '../../admin/widgets/order_status_badge.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/delivery_qr_card.dart';
import '../widgets/order_progress_stepper.dart';
import 'customer_orders_screen.dart' show ccMono;

class CustomerOrderDetailScreen extends ConsumerWidget {
  const CustomerOrderDetailScreen({super.key, required this.orderUuid});
  final String orderUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider).value ?? [];
    Order? order;
    for (final o in orders) {
      if (o.uuid == orderUuid) order = o;
    }

    return Scaffold(
      backgroundColor: CcColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 28, color: CcColors.text),
                    label: const Text('My Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CcColors.text)),
                  ),
                ]),
              ),
              const Divider(height: 1, color: CcColors.border),
              Expanded(
                child: order == null
                    ? const Center(child: Text('Order not found', style: TextStyle(fontSize: 14, color: CcColors.muted)))
                    : _Body(order: order),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});
  final Order order;

  Future<void> _confirmReceipt(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(databaseProvider).updateOrderStatusById(order.id, OrderStatus.completed);
    SyncManager.syncInBackground();
    messenger.showSnackBar(const SnackBar(content: Text('Thank you! Order confirmed.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = customerStatusOf(order);
    final cancelled = status == CustomerOrderStatus.cancelled;
    final lines = ref.watch(orderLinesProvider(order.uuid)).value ?? [];
    final payments = (ref.watch(customerPaymentsProvider).value ?? []).where((p) => p.orderCode == order.orderNumber).toList();

    final paid = payments.fold<double>(0, (s, p) => s + p.amountPaid);
    final balance = payments.isEmpty ? order.totalAmount : payments.fold<double>(0, (s, p) => s + p.balance);
    final payStatus = payments.isEmpty ? 'Unpaid' : (balance <= 0 ? 'Paid' : (paid > 0 ? 'Partial' : 'Unpaid'));
    final method = payments.map((p) => p.paymentMethod).whereType<String>().firstOrNull ?? paymentMethodFromNotes(order.customerNotes) ?? '—';

    final wasDelivered = status == CustomerOrderStatus.delivered || status == CustomerOrderStatus.completed;
    final delivery = order.expectedDeliveryDate;
    final deliveredAt = order.actualDeliveryDate ?? order.updatedAt;
    final dateRow = wasDelivered
        ? (label: 'Delivered on', value: '${ccDeliveryDay(deliveredAt)} · ${ccTime(deliveredAt)}')
        : cancelled
            ? (label: 'Delivery date', value: 'Not delivered')
            : (label: 'Delivery date', value: delivery == null ? 'To be scheduled' : ccDeliveryDay(delivery));
    final rep = (order.salesRepName ?? '').isEmpty ? '—' : order.salesRepName!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CcCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(order.orderNumber, style: ccMono.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
                ),
              ),
              if (!cancelled) ...[const SizedBox(width: 8), OrderStatusBadge(status: customerStatusKey(status))],
            ]),
            const SizedBox(height: 4),
            Text('Ordered ${ccLongFullDate(order.createdAt)}', style: const TextStyle(fontSize: 15, color: CcColors.muted)),
            const SizedBox(height: 16),
            if (cancelled)
              Center(child: OrderStatusBadge(status: OrderStatus.cancelled))
            else
              OrderProgressStepper(currentStep: customerStepOf(status), completed: status == CustomerOrderStatus.completed),
          ]),
        ),
        const SizedBox(height: 14),
        if (status == CustomerOrderStatus.outForDelivery || status == CustomerOrderStatus.delivered) ...[
          DeliveryQrCard(
            orderNumber: order.orderNumber,
            delivered: status == CustomerOrderStatus.delivered,
            repName: order.salesRepName ?? '',
          ),
          const SizedBox(height: 14),
        ],
        if (status == CustomerOrderStatus.delivered) ...[
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _confirmReceipt(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Confirm Receipt'))),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Tap to confirm you received all items', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: CcColors.muted)),
          const SizedBox(height: 14),
        ],
        if (status == CustomerOrderStatus.completed) ...[
          OrderCompleteCard(receivedOn: order.updatedAt),
          const SizedBox(height: 14),
        ],
        CcInfoRows(rows: [
          (label: dateRow.label, value: ccValueText(dateRow.value)),
          (label: 'Sales rep', value: ccValueText(rep)),
          (label: 'Payment method', value: ccValueText(method)),
        ]),
        const SizedBox(height: 14),
        CcCard(
          child: Column(children: [
            if (lines.isEmpty)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text('No item details recorded for this order.', style: TextStyle(fontSize: 14, color: CcColors.muted)))),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: l.productName, style: const TextStyle(fontSize: 16, color: CcColors.text)),
                      TextSpan(text: ' × ${l.quantity}', style: const TextStyle(fontSize: 16, color: CcColors.muted)),
                    ])),
                  ),
                  Text(formatPeso(l.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CcColors.text)),
                ]),
              ),
            const Divider(height: 24, color: CcColors.border),
            Row(children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CcColors.text)),
              const Spacer(),
              Text(formatPeso(order.totalAmount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: CcColors.text)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        CcCard(
          child: Column(children: [
            Row(children: [
              const Expanded(child: Text('Payment status', style: TextStyle(fontSize: 15, color: CcColors.muted))),
              const SizedBox(width: 8),
              CcBadge.status(payStatus),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Amount paid', style: TextStyle(fontSize: 17, color: CcColors.text)),
              const Spacer(),
              Text(formatPeso(paid), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CcColors.green)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Balance', style: TextStyle(fontSize: 17, color: CcColors.text)),
              const Spacer(),
              Text(formatPeso(balance), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: balance > 0 ? CcColors.red : CcColors.green)),
            ]),
          ]),
        ),
      ],
    );
  }
}
