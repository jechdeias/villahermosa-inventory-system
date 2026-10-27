import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseLoadingDispatchScreen extends ConsumerStatefulWidget {
  const WarehouseLoadingDispatchScreen({super.key});

  @override
  ConsumerState<WarehouseLoadingDispatchScreen> createState() => _WarehouseLoadingDispatchScreenState();
}

class _WarehouseLoadingDispatchScreenState extends ConsumerState<WarehouseLoadingDispatchScreen> {
  static const _flex = [5, 2, 4, 2];
  String? _selectedUuid;

  Future<void> _dispatch(DeliveryRoute route, List<Order> loadable) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Dispatch route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Dispatch ${route.routeName} with ${loadable.length} ${loadable.length == 1 ? 'order' : 'orders'}?', style: const TextStyle(fontSize: 13, color: WhColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: WhColors.muted))),
          WhPrimaryButton(label: 'Dispatch', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    final count = await ref.read(warehouseActionsProvider).dispatchOrders(loadable);
    SyncManager.syncInBackground();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route dispatched. $count ${count == 1 ? 'order is' : 'orders are'} out for delivery.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstLoad(ref.watch(deliveryRoutesStreamProvider))) return const WhLoadingShell(route: WhRoutes.dispatch);
    final routes = (ref.watch(deliveryRoutesStreamProvider).value ?? []).toList();
    final orders = ref.watch(ordersStreamProvider).value ?? [];
    final byOrder = ref.watch(orderLinesByOrderProvider);

    DeliveryRoute? selected;
    for (final r in routes) {
      if (r.uuid == _selectedUuid) selected = r;
    }
    selected ??= routes.isEmpty ? null : routes.first;

    return WarehouseShell(
      route: WhRoutes.dispatch,
      child: WhPage(children: [
        const WhPageHeader(title: 'Loading & Dispatch', subtitle: 'Manage truck loading and route dispatch'),
        WhTwoColumn(
          sideFirst: true,
          sideWidth: 280,
          side: WhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WhCardTitle('Routes'),
                if (routes.isEmpty)
                  const WhEmpty('Routes added in Admin → Deliveries will appear here', title: 'No delivery routes yet', icon: Icons.local_shipping_outlined)
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      for (final r in routes)
                        Builder(builder: (_) {
                          final state = routeLoadState(r, orders);
                          final active = r.uuid == selected?.uuid;
                          return WhRouteCard(
                            title: r.routeName,
                            mono: false,
                            subtitle: '${r.municipality} · ${r.customerCount} stores',
                            active: active,
                            badge: active
                                ? WhRoutePill(state == 'not started' ? 'Not started' : state[0].toUpperCase() + state.substring(1), active: true)
                                : WhStatusBadge(state),
                            onTap: () => setState(() => _selectedUuid = r.uuid),
                          );
                        }),
                    ]),
                  ),
              ],
            ),
          ),
          main: selected == null
              ? const WhCard(child: WhEmpty('Pick a route on the left to see its loading list', title: 'Select a route', icon: Icons.local_shipping_outlined))
              : _detail(selected, orders, byOrder),
        ),
      ]),
    );
  }

  Widget _detail(DeliveryRoute route, List<Order> allOrders, Map<String, List<OrderItem>> byOrder) {
    final mine = allOrders.where((o) => o.routeName == route.routeName && !OrderStatus.isFinished(o.status)).toList();
    final loadable = mine.where((o) => whOrderStatus(o) == 'ready').toList();
    final dispatched = mine.where((o) => whOrderStatus(o) == 'dispatched').toList();
    final waiting = mine.where(needsPreparing).length;

    // Lines come from orders that are prepared (ready) or already dispatched.
    final shown = [...loadable, ...dispatched];
    final rows = <({OrderItem line, Order order})>[
      for (final o in shown)
        for (final l in byOrder[o.uuid] ?? <OrderItem>[]) (line: l, order: o),
    ];
    final loaded = rows.where((r) => isItemLoaded(r.line) || whOrderStatus(r.order) == 'dispatched').length;
    final allLoaded = loadable.isNotEmpty && rows.where((r) => whOrderStatus(r.order) == 'ready').every((r) => isItemLoaded(r.line));

    final stores = shown.map((o) => o.storeName ?? '').where((s) => s.isNotEmpty).toSet().length;
    final products = rows.map((r) => r.line.productSku).toSet().length;
    final units = rows.fold<int>(0, (s, r) => s + r.line.quantity);

    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WhCardHeader(
            leading: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(route.routeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: WhColors.text)),
              const SizedBox(height: 2),
              Text(
                '${route.municipality} • ${(route.assignedRepName ?? '').isEmpty ? 'No driver assigned' : 'Driver: ${route.assignedRepName}'}',
                style: const TextStyle(fontSize: 12, color: WhColors.muted),
              ),
            ]),
            actions: [
              Text('$loaded of ${rows.length} lines loaded', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
              WhPrimaryButton(label: 'Dispatch', icon: Icons.local_shipping_outlined, onPressed: allLoaded ? () => _dispatch(route, loadable) : null),
            ],
          ),
          if (rows.isEmpty)
            WhEmpty(
                waiting > 0
                    ? '$waiting ${waiting == 1 ? 'order is' : 'orders are'} still being prepared. Complete them in Prepare Orders to load them here.'
                    : 'Prepared orders for this route will appear here',
                title: 'Nothing to load yet',
                icon: Icons.inventory_2_outlined)
          else
            WhTableScroll(
              minWidth: 620,
              child: Column(children: [
                const WhTableHeader(columns: ['Product', 'Quantity', 'Destination', 'Status'], flex: _flex),
                for (final r in rows) _row(r.line, r.order),
              ]),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: WhColors.border))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ROUTE SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: WhColors.muted, letterSpacing: 0.44)),
              const SizedBox(height: 10),
              WhStatRow(bottomGap: 0, cards: [
                WhStatCard(label: 'Stores', value: '$stores', sub: 'On this route'),
                WhStatCard(label: 'Products', value: '$products', sub: 'Distinct items'),
                WhStatCard(label: 'Total Units', value: formatNumber(units), sub: 'To load'),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(OrderItem l, Order o) {
    final dispatched = whOrderStatus(o) == 'dispatched';
    final loaded = dispatched || isItemLoaded(l);
    return WhTableRow(
      flex: _flex,
      onTap: dispatched ? null : () => ref.read(warehouseActionsProvider).setItemLoaded(l, !loaded),
      cells: [
        Text(l.productName, style: const TextStyle(fontSize: 13, color: WhColors.text), overflow: TextOverflow.ellipsis),
        Text('${l.quantity} units', style: const TextStyle(fontSize: 13, color: WhColors.text)),
        Text(o.storeName ?? '—', style: const TextStyle(fontSize: 13, color: WhColors.muted), overflow: TextOverflow.ellipsis),
        Tooltip(message: dispatched ? 'Dispatched' : 'Tap to mark ${loaded ? 'pending' : 'loaded'}', child: WhStatusBadge(loaded ? 'loaded' : 'pending')),
      ],
    );
  }
}
