import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = customerStatusOf(order);
    final lines = ref.watch(orderLinesProvider(order.uuid)).value ?? [];
    final payments = (ref.watch(customerPaymentsProvider).value ?? []).where((p) => p.orderCode == order.orderNumber).toList();

    final paid = payments.fold<double>(0, (s, p) => s + p.amountPaid);
    final balance = payments.isEmpty ? order.totalAmount : payments.fold<double>(0, (s, p) => s + p.balance);
    final payStatus = payments.isEmpty
        ? 'Unpaid'
        : (balance <= 0 ? 'Paid' : (paid > 0 ? 'Partial' : 'Unpaid'));
    final method = payments.map((p) => p.paymentMethod).whereType<String>().firstOrNull ?? paymentMethodFromNotes(order.customerNotes) ?? '—';

    final delivery = order.expectedDeliveryDate;
    final deliveryLabel = status == CustomerOrderStatus.delivered
        ? (order.actualDeliveryDate != null ? ccDeliveryDay(order.actualDeliveryDate!) : 'Delivered')
        : status == CustomerOrderStatus.cancelled
            ? 'Cancelled'
            : (delivery == null ? 'To be scheduled' : ccDeliveryDay(delivery));
    final rep = (order.salesRepName ?? '').isEmpty ? '—' : order.salesRepName!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: Text(order.orderNumber, style: ccMono.copyWith(fontSize: 26, fontWeight: FontWeight.w700))),
          CcBadge.status(customerStatusLabel(status)),
        ]),
        const SizedBox(height: 4),
        Text('Ordered ${ccLongFullDate(order.createdAt)}', style: const TextStyle(fontSize: 15, color: CcColors.muted)),
        const SizedBox(height: 16),
        if (status != CustomerOrderStatus.cancelled) ...[
          CcCard(child: OrderProgressStepper(currentStep: customerStepOf(status))),
          const SizedBox(height: 14),
        ],
        CcInfoRows(rows: [
          (label: 'Delivery date', value: ccValueText(deliveryLabel)),
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
              const Text('Payment status', style: TextStyle(fontSize: 15, color: CcColors.muted)),
              const Spacer(),
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
