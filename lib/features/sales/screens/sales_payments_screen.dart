import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sales_providers.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/sales_shell.dart';

class SalesPaymentsScreen extends ConsumerStatefulWidget {
  const SalesPaymentsScreen({super.key});

  @override
  ConsumerState<SalesPaymentsScreen> createState() => _SalesPaymentsScreenState();
}

class _SalesPaymentsScreenState extends ConsumerState<SalesPaymentsScreen> {
  String _filter = 'all';

  static const _statusColors = {
    'paid': Color(0xFF059669),
    'partial': Color(0xFFD97706),
    'unpaid': Color(0xFFDC2626),
    'credit': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(salesRepPaymentsProvider).value ?? [];
    final filtered = _filter == 'all' ? payments : payments.where((p) => p.status == _filter).toList();

    final tabs = [
      ('all', 'All', payments.length),
      ('unpaid', 'Unpaid', payments.where((p) => p.status == 'unpaid').length),
      ('partial', 'Partial', payments.where((p) => p.status == 'partial').length),
      ('paid', 'Paid', payments.where((p) => p.status == 'paid').length),
    ];

    final totalCollected = payments.fold(0.0, (s, p) => s + p.amountPaid);
    final totalOutstanding = payments.fold(0.0, (s, p) => s + p.balance);

    return SalesShell(
      currentRoute: '/sales/payments',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: const Text('Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              Expanded(
                child: _SummaryCard(label: 'Collected', value: totalCollected, color: const Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(label: 'Outstanding', value: totalOutstanding, color: const Color(0xFFD97706)),
              ),
            ]),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (value, label, count) = tabs[i];
                final active = _filter == value;
                return InkWell(
                  onTap: () => setState(() => _filter = value),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text('$label ($count)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: active ? Colors.white : const Color(0xFF6B7280))),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No payments yet', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final color = _statusColors[p.status] ?? const Color(0xFF6B7280);
                      return InkWell(
                        onTap: p.balance <= 0 ? null : () => showRecordPaymentSheet(context, payment: p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.storeName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                                  const SizedBox(height: 2),
                                  Text('${p.orderCode} · ₱${p.orderAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  p.balance > 0 ? 'Bal ₱${p.balance.toStringAsFixed(0)}' : 'Paid',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                                ),
                                const SizedBox(height: 2),
                                Text(p.status[0].toUpperCase() + p.status.substring(1),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text('₱${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
