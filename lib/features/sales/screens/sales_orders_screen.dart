import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../admin/widgets/order_status_badge.dart';
import '../providers/sales_providers.dart';
import '../widgets/new_order_flow.dart';
import '../widgets/sales_shell.dart';

class SalesOrdersScreen extends ConsumerStatefulWidget {
  const SalesOrdersScreen({super.key});

  @override
  ConsumerState<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends ConsumerState<SalesOrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(salesRepOrdersProvider).value ?? [];
    final filtered = _filter == 'all' ? orders : orders.where((o) => o.status == _filter).toList();

    final tabs = [
      ('all', 'All', orders.length),
      ('pending', 'Pending', orders.where((o) => o.status == 'pending').length),
      ('completed', 'Completed', orders.where((o) => o.status == 'completed').length),
      ('cancelled', 'Cancelled', orders.where((o) => o.status == 'cancelled').length),
    ];

    return SalesShell(
      currentRoute: '/sales/orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              const Expanded(
                child: Text('Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ),
              IconButton(
                onPressed: () => showNewOrderFlow(context),
                icon: const Icon(Icons.add_circle, color: Color(0xFF1E1E1E), size: 28),
              ),
            ]),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                ? const Center(child: Text('No orders yet', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, i) => _OrderRow(order: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.storeName ?? 'Unknown store',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text('${order.orderNumber} · ${order.itemCount} items',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₱${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 4),
            OrderStatusBadge(status: order.status),
          ],
        ),
      ]),
    );
  }
}
