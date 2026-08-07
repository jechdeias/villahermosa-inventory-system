import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/sales_providers.dart';
import 'new_order_flow.dart';
import 'record_payment_sheet.dart';

void showCustomerDetailSheet(BuildContext context, Customer customer) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: CustomerDetailSheet(customer: customer),
    ),
  );
}

class CustomerDetailSheet extends ConsumerWidget {
  const CustomerDetailSheet({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeName = salesDisplayStoreName(customer);
    final orders = (ref.watch(salesRepOrdersProvider).value ?? [])
        .where((o) => o.storeName == storeName)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final payments = (ref.watch(salesRepPaymentsProvider).value ?? [])
        .where((p) => p.storeName == storeName);
    final outstanding = payments.fold(0.0, (s, p) => s + p.balance);
    final lastOrder = orders.isEmpty ? null : orders.first;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(storeName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ]),
            Text(customer.barangay ?? customer.town ?? customer.municipality,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _InfoTile(
                  label: 'Outstanding Balance',
                  value: '₱${outstanding.toStringAsFixed(0)}',
                  color: outstanding > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'Last Order',
                  value: lastOrder == null ? 'None' : _relativeDate(lastOrder.createdAt),
                  color: const Color(0xFF111827),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (customer.contactNumber.isNotEmpty || (customer.phone ?? '').isNotEmpty) ...[
              _DetailRow(label: 'Phone', value: customer.phone ?? customer.contactNumber),
              const SizedBox(height: 4),
            ],
            if ((customer.address ?? '').isNotEmpty) _DetailRow(label: 'Address', value: customer.address!),
            const SizedBox(height: 4),
            _DetailRow(label: 'Credit Limit', value: '₱${customer.creditLimit.toStringAsFixed(0)}'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showNewOrderFlow(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('New Order', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: outstanding <= 0
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          final due = payments.where((p) => p.balance > 0);
                          showRecordPaymentSheet(context, payment: due.isEmpty ? null : due.first);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  static String _relativeDate(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
      ]),
    );
  }
}
