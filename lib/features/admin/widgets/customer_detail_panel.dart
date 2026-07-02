import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/customers_provider.dart';
import 'customer_channel_badge.dart';

class CustomerDetailPanel extends ConsumerWidget {
  const CustomerDetailPanel({super.key, required this.customer, required this.onClose});
  final Customer customer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(customersDatabaseProvider);
    final outstanding = customer.currentCredit ?? 0;
    final limit = customer.creditLimit;
    final progress = limit > 0 ? (outstanding / limit).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection('STORE INFO', [
                    _row('Owner', Text(customer.businessName ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Barangay', Text(customer.barangay ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Town', Text(customer.town ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Contact', Text(customer.contactNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    if (customer.channel != null)
                      _row('Channel', CustomerChannelBadge(channel: customer.channel!)),
                  ]),
                  _buildSection('CREDIT', [
                    _row('Credit Limit', Text('₱${_fmt(limit)}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Outstanding', Text('₱${_fmt(outstanding)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF3F4F6),
                        color: progress >= 0.9 ? const Color(0xFFDC2626) : const Color(0xFF1E1E1E),
                      ),
                    ),
                  ]),
                  _buildOrdersSection(context, db),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(BuildContext context, AppDatabase db) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER HISTORY', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          FutureBuilder<List<Order>>(
            future: db.getOrdersByCustomerId(customer.uuid),
            builder: (context, snap) {
              final orders = (snap.data ?? [])
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final recent = orders.take(3).toList();
              if (recent.isEmpty) {
                return const Text('No orders yet', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)));
              }
              return Column(
                children: recent.map((o) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(
                      child: Text(o.orderNumber, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF111827))),
                    ),
                    Text('₱${_fmt(o.totalAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  ]),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/admin/orders'),
            child: const Text('View All Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(child: Text(customer.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
      GestureDetector(onTap: onClose, child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
    ]),
  );

  Widget _buildSection(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
        const SizedBox(height: 12),
        ...rows,
      ],
    ),
  );

  Widget _row(String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Expanded(child: value),
      ],
    ),
  );

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
    child: OutlinedButton(
      onPressed: onClose,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        foregroundColor: const Color(0xFF374151),
        padding: const EdgeInsets.symmetric(vertical: 10),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: const Text('Close', style: TextStyle(fontSize: 13)),
    ),
  );

  static String _fmt(double v) {
    final n = v.round().toString();
    final buf = StringBuffer();
    final mod = n.length % 3;
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (i - mod) % 3 == 0) buf.write(',');
      buf.write(n[i]);
    }
    return buf.toString();
  }
}
