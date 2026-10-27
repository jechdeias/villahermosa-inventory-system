import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseDashboardScreen extends ConsumerWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersStreamProvider).value ?? [];
    final routes = ref.watch(deliveryRoutesStreamProvider).value ?? [];
    final lowStock = ref.watch(lowStockProductsProvider);

    final incoming = orders.where((o) => whOrderStatus(o) == 'pending').length;
    final toPrepare = orders.where(needsPreparing).length;
    final activeRoutes = routes.where((r) => r.status == 'active').length;

    final synced = lastSyncTime();

    return WarehouseShell(
      route: WhRoutes.dashboard,
      child: WhPage(children: [
        WhPageHeader(
          title: 'Warehouse Dashboard',
          subtitle: 'Villahermosa Marketing - Warehouse Operations',
          trailing: _SyncChip(lastSync: synced),
        ),
        WhStatRow(cards: [
          WhStatCard(label: 'Incoming Orders', value: '$incoming', sub: 'Orders to receive', dotColor: WhColors.blue),
          WhStatCard(label: 'Orders to Prepare', value: '$toPrepare', sub: 'Pending picklist', dotColor: WhColors.amber),
          WhStatCard(label: 'Low Stock Alerts', value: '${lowStock.length}', sub: 'Items below threshold', dotColor: WhColors.red),
          WhStatCard(label: "Today's Routes", value: '$activeRoutes', sub: 'Active delivery routes', dotColor: WhColors.green),
        ]),
        WhTwoColumn(
          sideWidth: 320,
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RecentActivityCard(),
              const SizedBox(height: 16),
              _TodayRoutesCard(routes: routes, orders: orders),
            ],
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _QuickActionsCard(),
              const SizedBox(height: 16),
              _LowStockCard(items: lowStock),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.lastSync});
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final ok = lastSync != null;
    final color = ok ? WhColors.green : WhColors.amber;
    final label = lastSync == null
        ? 'Not synced yet'
        : isSameDay(lastSync!, DateTime.now())
            ? 'Last sync: Today, ${formatClock(lastSync!)}'
            : 'Last sync: ${formatDate(lastSync!)}, ${formatClock(lastSync!)}';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: ok ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(ok ? 'Synced' : 'Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ]),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: WhColors.muted)),
      ],
    );
  }
}

class _ActivityItem {
  const _ActivityItem(this.time, this.icon, this.color, this.bg, this.title, this.subtitle);
  final DateTime time;
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;
}

class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(stockMovementsStreamProvider).value ?? [];
    final orders = ref.watch(ordersStreamProvider).value ?? [];
    final products = ref.watch(productsStreamProvider).value ?? [];

    String nameOf(String uuid) {
      for (final p in products) {
        if (p.uuid == uuid) return p.name;
      }
      return 'Unknown product';
    }

    final items = <_ActivityItem>[
      for (final m in movements)
        _ActivityItem(
          m.createdAt,
          m.movementType == 'in' ? Icons.south : Icons.north,
          m.movementType == 'in' ? WhColors.blue : WhColors.red,
          m.movementType == 'in' ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
          m.movementType == 'in' ? 'Stock-in: ${m.quantity} × ${nameOf(m.productId)}' : 'Stock-out: ${m.quantity} × ${nameOf(m.productId)}',
          [m.reason, if ((m.referenceId ?? '').isNotEmpty) m.referenceId!, 'by ${m.userName}'].join(' · '),
        ),
      for (final o in orders)
        if (whOrderStatus(o) == 'ready' || whOrderStatus(o) == 'dispatched')
          _ActivityItem(
            o.packedAt ?? o.updatedAt,
            whOrderStatus(o) == 'ready' ? Icons.check : Icons.local_shipping_outlined,
            whOrderStatus(o) == 'ready' ? WhColors.green : WhColors.amber,
            whOrderStatus(o) == 'ready' ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
            'Order ${o.orderNumber} ${whOrderStatus(o) == 'ready' ? 'prepared' : 'dispatched'}',
            [o.storeName ?? '', if ((o.routeName ?? '').isNotEmpty) o.routeName!].where((s) => s.isNotEmpty).join(' · '),
          ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    final recent = items.take(5).toList();
    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WhCardTitle('Recent Activity',
              trailing: InkWell(
                onTap: () => whGo(context, WhRoutes.sync),
                child: const Text('View all', style: TextStyle(fontSize: 12, color: WhColors.text, decoration: TextDecoration.underline)),
              )),
          if (recent.isEmpty)
            const WhEmpty('No activity yet')
          else
            for (final a in recent)
              WhRecentActivityRow(icon: a.icon, iconColor: a.color, iconBg: a.bg, title: a.title, subtitle: a.subtitle, time: timeAgo(a.time)),
        ],
      ),
    );
  }
}

class _TodayRoutesCard extends StatelessWidget {
  const _TodayRoutesCard({required this.routes, required this.orders});
  final List<DeliveryRoute> routes;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final active = routes.where((r) => r.status == 'active').toList();
    const flex = [5, 3, 2, 2];
    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WhCardTitle("Today's Routes",
              trailing: InkWell(
                onTap: () => whGo(context, WhRoutes.routesToday),
                child: const Text('Open Routes Today', style: TextStyle(fontSize: 12, color: WhColors.text, decoration: TextDecoration.underline)),
              )),
          if (active.isEmpty)
            const WhEmpty('No active routes')
          else
            WhTableScroll(
              minWidth: 460,
              child: Column(children: [
                const WhTableHeader(columns: ['Route', 'Municipality', 'Stores', 'Status'], flex: flex),
                for (final r in active.take(5))
                  WhTableRow(
                    flex: flex,
                    cells: [
                      Text(r.routeName, style: const TextStyle(fontSize: 13, color: WhColors.text)),
                      Text(r.municipality, style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                      Text('${r.customerCount}', style: const TextStyle(fontSize: 13, color: WhColors.text)),
                      WhStatusBadge(routeLoadState(r, orders)),
                    ],
                  ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends ConsumerStatefulWidget {
  const _QuickActionsCard();

  @override
  ConsumerState<_QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<_QuickActionsCard> {
  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Syncing…')));
    try {
      await SyncManager.instance.syncPendingData();
      messenger.showSnackBar(const SnackBar(content: Text('Sync finished')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label, VoidCallback onTap) => WhQuickActionButton(icon: icon, label: label, onTap: onTap);
    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WhCardTitle('Quick Actions'),
          Padding(
            padding: const EdgeInsets.all(14),
            child: GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 88,
              ),
              children: [
                tile(Icons.download, 'Stock In', () => whGo(context, WhRoutes.stockMovement, args: 'in')),
                tile(Icons.upload, 'Stock Out', () => whGo(context, WhRoutes.stockMovement, args: 'out')),
                tile(Icons.add, 'New Order', () => whGo(context, WhRoutes.incoming)),
                tile(Icons.print_outlined, 'Print Labels', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Label printing is not set up yet')));
                }),
                tile(Icons.map_outlined, 'View Routes', () => whGo(context, WhRoutes.routesToday)),
                tile(Icons.sync, 'Sync Data', _sync),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.items});
  final List<Product> items;

  @override
  Widget build(BuildContext context) => WhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WhCardTitle('Low Stock',
                trailing: InkWell(
                  onTap: () => whGo(context, WhRoutes.inventory),
                  child: Text('See all ${items.length}', style: const TextStyle(fontSize: 12, color: WhColors.text, decoration: TextDecoration.underline)),
                )),
            if (items.isEmpty)
              const WhEmpty('Nothing is running low')
            else
              for (final p in items.take(4))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Min ${p.minStock} ${p.unit}', style: const TextStyle(fontSize: 11, color: WhColors.muted)),
                      ]),
                    ),
                    Text('${p.currentStock} left',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOutOfStock(p) ? WhColors.red : WhColors.amber)),
                  ]),
                ),
          ],
        ),
      );
}
