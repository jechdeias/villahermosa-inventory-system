import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/pdf_export.dart';
import '../../admin/utils/order_pdf_printer.dart';
import '../../admin/widgets/order_status_badge.dart';
import '../../customer/providers/customer_providers.dart' show orderLinesProvider, paymentMethodFromNotes;
import '../../customer/widgets/customer_common.dart' show formatPeso, ccLongFullDate;
import '../providers/sales_providers.dart';
import '../services/delivery_confirmation.dart';
import '../widgets/mark_delivered_flow.dart';
import 'sales_scan_screen.dart';

/// One order as the sales rep sees it. While the order is out for delivery it
/// offers both ways to confirm the hand-over: scan the customer's QR code, or
/// "Mark as Delivered" for stores with no app.
class SalesOrderDetailScreen extends ConsumerWidget {
  const SalesOrderDetailScreen({super.key, required this.orderUuid});
  final String orderUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Order? order;
    for (final o in ref.watch(salesRepOrdersProvider).value ?? const <Order>[]) {
      if (o.uuid == orderUuid) order = o;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(order?.orderNumber ?? 'Order', style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 16, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          if (order != null)
            Consumer(builder: (ctx, r, _) {
              final lines = r.watch(orderLinesProvider(order!.uuid)).value ?? const <OrderItem>[];
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF',
                onPressed: () async {
                  final doc = await buildOrderPdf(order!, lines);
                  if (ctx.mounted) await exportPdf(doc, 'Order_${order!.orderNumber}.pdf');
                },
              );
            }),
        ],
      ),
      body: order == null
          ? const Center(child: Text('Order not found', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)))
          : _Body(order: order),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(orderLinesProvider(order.uuid)).value ?? const <OrderItem>[];
    final outForDelivery = order.status == OrderStatus.outForDelivery;
    final method = paymentMethodFromNotes(order.customerNotes) ?? defaultPaymentMethod;
    final confirmedBy = deliveryMethodFromNotes(order.customerNotes);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(width: 16),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
          ]),
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Card(children: [
                  Row(children: [
                    Expanded(child: Text(order.storeName ?? 'Unknown store', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                    const SizedBox(width: 8),
                    OrderStatusBadge(status: order.status),
                  ]),
                  const SizedBox(height: 8),
                  row('Ordered', ccLongFullDate(order.createdAt)),
                  row('Items', '${order.itemCount}'),
                  row('Payment', method),
                  if (order.status == OrderStatus.delivered || order.status == OrderStatus.completed)
                    row('Delivery confirmed', switch (confirmedBy) {
                      deliveryMethodQr => 'Customer QR scanned',
                      deliveryMethodManual => 'Marked by you',
                      _ => 'Yes',
                    }),
                ]),
                const SizedBox(height: 12),
                _Card(children: [
                  if (lines.isEmpty)
                    const Text('No item details recorded on this phone.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(child: Text('${l.productName} × ${l.quantity}', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
                        Text(formatPeso(l.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      ]),
                    ),
                  const Divider(height: 20),
                  Row(children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const Spacer(),
                    Text(formatPeso(order.totalAmount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ]),
                ]),
              ],
            ),
          ),
          if (outForDelivery)
            Container(
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(AppTheme.route((_) => const SalesScanScreen())),
                    icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                    label: const Text('Scan Delivery QR'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => showMarkDeliveredFlow(context, ref, order),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    child: const Text('Mark as Delivered'),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}
