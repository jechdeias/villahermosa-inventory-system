import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseRoutesTodayScreen extends ConsumerStatefulWidget {
  const WarehouseRoutesTodayScreen({super.key});

  @override
  ConsumerState<WarehouseRoutesTodayScreen> createState() => _WarehouseRoutesTodayScreenState();
}

class _WarehouseRoutesTodayScreenState extends ConsumerState<WarehouseRoutesTodayScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final routes = (ref.watch(deliveryRoutesStreamProvider).value ?? []).where((r) => r.status == 'active').toList();
    final orders = ref.watch(ordersStreamProvider).value ?? [];
    final lines = ref.watch(orderLinesByOrderProvider);

    bool open(Order o) => o.status != 'cancelled' && o.status != 'completed';
    Map<String, List<Order>> perRoute = {
      for (final r in routes) r.routeName: orders.where((o) => o.routeName == r.routeName && open(o)).toList(),
    };

    // Dispatched routes first, then loading, then the rest.
    int rank(DeliveryRoute r) => switch (routeLoadState(r, orders)) {
          'dispatched' => 0,
          'loading' => 1,
          _ => 2,
        };
    routes.sort((a, b) => rank(a).compareTo(rank(b)));

    final totalOrders = perRoute.values.fold<int>(0, (s, l) => s + l.length);
    final stores = <String>{for (final l in perRoute.values) for (final o in l) if ((o.storeName ?? '').isNotEmpty) o.storeName!}.length;
    final onRoad = routes.where((r) => routeLoadState(r, orders) == 'dispatched').length;
    final loading = routes.where((r) => routeLoadState(r, orders) == 'loading').length;
    final allExpanded = routes.isNotEmpty && _expanded.length == routes.length;

    final now = DateTime.now();
    const longDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const longMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return WarehouseShell(
      route: WhRoutes.routesToday,
      child: WhPage(children: [
        WhPageHeader(
          title: 'Routes Today',
          subtitle: '${longDays[now.weekday - 1]}, ${longMonths[now.month - 1]} ${now.day}, ${now.year} · stops in delivery order',
          trailing: WhSecondaryButton(
            label: allExpanded ? 'Collapse all' : 'Expand all',
            onPressed: () => setState(() {
              if (allExpanded) {
                _expanded.clear();
              } else {
                _expanded.addAll(routes.map((r) => r.uuid));
              }
            }),
          ),
        ),
        WhStatRow(cards: [
          WhStatCard(label: 'Active Routes', value: '${routes.length}', sub: '$onRoad on the road, $loading loading', dotColor: WhColors.blue),
          WhStatCard(label: 'Total Orders', value: '$totalOrders', sub: 'Across all routes today', dotColor: WhColors.amber),
          WhStatCard(label: 'Stores to Visit', value: '$stores', sub: 'Stops scheduled today', dotColor: WhColors.green),
        ]),
        if (routes.isEmpty)
          const WhCard(child: WhEmpty('No active routes. Add or activate a route in Admin → Deliveries.'))
        else
          for (final r in routes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _routeCard(r, perRoute[r.routeName] ?? [], lines, orders),
            ),
      ]),
    );
  }

  Widget _routeCard(DeliveryRoute r, List<Order> routeOrders, Map<String, List<OrderItem>> lines, List<Order> allOrders) {
    final state = routeLoadState(r, allOrders);
    final badge = switch (state) {
      'dispatched' => 'in progress',
      'loading' => 'loading',
      _ => 'scheduled',
    };
    int itemsOf(Order o) {
      final l = lines[o.uuid];
      return (l == null || l.isEmpty) ? o.itemCount : l.fold<int>(0, (s, i) => s + i.quantity);
    }

    final totalItems = routeOrders.fold<int>(0, (s, o) => s + itemsOf(o));
    final byStore = <String, List<Order>>{};
    for (final o in routeOrders) {
      byStore.putIfAbsent(o.storeName ?? 'Unknown store', () => []).add(o);
    }
    final open = _expanded.contains(r.uuid);

    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => open ? _expanded.remove(r.uuid) : _expanded.add(r.uuid)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 4, children: [
                      Text(r.routeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: WhColors.text)),
                      WhStatusBadge(badge),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${r.municipality} · ${(r.assignedRepName ?? '').isEmpty ? 'No driver assigned' : 'Driver: ${r.assignedRepName}'} · ${byStore.length} stops',
                      style: const TextStyle(fontSize: 12, color: WhColors.muted),
                    ),
                    Text('${routeOrders.length} orders · $totalItems items', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                  ]),
                ),
                const SizedBox(width: 10),
                Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: WhColors.text),
              ]),
            ),
          ),
          if (open)
            if (byStore.isEmpty)
              const Padding(padding: EdgeInsets.only(bottom: 8), child: WhEmpty('No orders on this route today'))
            else
              Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: WhColors.border))),
                child: Column(children: [
                  for (final (i, e) in byStore.entries.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                      child: Row(children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: WhColors.primary, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
                            if (e.value.first.deliveryAddress.isNotEmpty)
                              Text(e.value.first.deliveryAddress, style: const TextStyle(fontSize: 12, color: WhColors.muted), overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        SizedBox(width: 80, child: Text('${e.value.length} ${e.value.length == 1 ? 'order' : 'orders'}', style: const TextStyle(fontSize: 12, color: WhColors.text))),
                        SizedBox(width: 80, child: Text('${e.value.fold<int>(0, (s, o) => s + itemsOf(o))} items', style: const TextStyle(fontSize: 12, color: WhColors.text))),
                      ]),
                    ),
                ]),
              ),
        ],
      ),
    );
  }
}
