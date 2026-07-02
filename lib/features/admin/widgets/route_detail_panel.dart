import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/delivery_routes_provider.dart';
import '../services/delivery_routes_service.dart';
import 'route_status_badge.dart';

const _statusCycle = ['active', 'on_hold', 'inactive'];

class RouteDetailPanel extends ConsumerWidget {
  const RouteDetailPanel({super.key, required this.route, required this.onClose, required this.onEdit});
  final DeliveryRoute route;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(deliveryRoutesDatabaseProvider);
    final service = ref.read(deliveryRoutesServiceProvider);

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
                  _buildSection('ROUTE INFO', [
                    _row('Municipality', Text(route.municipality, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Assigned Rep', Text(route.assignedRepName ?? 'Unassigned', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Delivery Days', Text(route.deliveryDays.replaceAll(',', ', '), style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Customers', Text('${route.customerCount}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Status', RouteStatusBadge(status: route.status)),
                  ]),
                  _buildOrdersSection(db),
                ],
              ),
            ),
          ),
          _buildFooter(context, ref, service),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(AppDatabase db) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT ORDERS ON THIS ROUTE',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          FutureBuilder<List<Order>>(
            future: db.getOrdersByRouteName(route.routeName),
            builder: (context, snap) {
              final orders = snap.data ?? [];
              if (orders.isEmpty) {
                return const Text('No orders on this route yet', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)));
              }
              return Column(
                children: orders.take(5).map((o) => Padding(
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
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(child: Text(route.routeName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
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
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Expanded(child: value),
      ],
    ),
  );

  Widget _buildFooter(BuildContext context, WidgetRef ref, DeliveryRoutesService service) {
    final nextStatus = _statusCycle[(_statusCycle.indexOf(route.status) + 1) % _statusCycle.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              foregroundColor: const Color(0xFF374151),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Edit Route', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await service.updateRoute(route.uuid, DeliveryRoutesCompanion(status: Value(nextStatus)));
              ref.read(selectedDeliveryRouteProvider.notifier).state = null;
              onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('Mark as ${_label(nextStatus)}', style: const TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  static String _label(String status) => switch (status) {
    'active' => 'Active',
    'on_hold' => 'On Hold',
    'inactive' => 'Inactive',
    _ => status,
  };

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
