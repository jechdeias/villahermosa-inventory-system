import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/providers/orders_provider.dart' show databaseProvider;
import '../../customer/providers/customer_providers.dart' show paymentMethodFromNotes;
import '../../customer/widgets/customer_common.dart' show formatPeso;
import '../services/delivery_confirmation.dart';
import 'delivery_result_card.dart';

/// "Mark as Delivered" for stores with no app: the rep confirms the hand-over
/// themselves. A confirmation dialog is required (never a one-tap delivery),
/// and the confirm button stays disabled until the rep ticks that the items
/// were handed over. On confirm it runs the same code path as a QR scan.
///
/// Works fully offline — only a local database write.
Future<void> showMarkDeliveredFlow(BuildContext context, WidgetRef ref, Order order) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ConfirmDeliveryDialog(order: order),
  );
  if (confirmed != true || !context.mounted) return;

  final result = await confirmDeliveryManually(ref.read(databaseProvider), order.id);
  if (!context.mounted) return;

  switch (result) {
    case ScanSuccess():
      await showDeliverySuccessDialog(context, result);
    case ScanWrongStatus():
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${result.orderCode} is ${OrderStatus.label(result.status).toLowerCase()} — it can no longer be marked as delivered.'),
      ));
    case ScanNotFound():
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order not found on this phone.')));
  }
}

class _ConfirmDeliveryDialog extends StatefulWidget {
  const _ConfirmDeliveryDialog({required this.order});
  final Order order;

  @override
  State<_ConfirmDeliveryDialog> createState() => _ConfirmDeliveryDialogState();
}

class _ConfirmDeliveryDialogState extends State<_ConfirmDeliveryDialog> {
  bool _handedOver = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final method = paymentMethodFromNotes(o.customerNotes) ?? defaultPaymentMethod;
    final cash = method.toLowerCase().startsWith('cash');
    final amount = formatPeso(o.totalAmount);
    final store = (o.storeName ?? '').isEmpty ? 'Unknown store' : o.storeName!;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm delivery?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text('${o.orderNumber} · ${o.itemCount} ${o.itemCount == 1 ? 'item' : 'items'}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cash ? 'Collect $amount ($method)' : '$amount · $method — nothing to collect',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: AppTheme.primary,
              value: _handedOver,
              onChanged: (v) => setState(() => _handedOver = v ?? false),
              title: const Text('Items handed to store owner/staff', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _handedOver ? () => Navigator.pop(context, true) : null,
          child: const Text('Confirm Delivery'),
        ),
      ],
    );
  }
}
