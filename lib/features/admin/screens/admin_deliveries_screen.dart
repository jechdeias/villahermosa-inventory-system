import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/delivery_routes_provider.dart';
import '../providers/orders_provider.dart' show ordersStreamProvider;
import '../widgets/add_route_panel.dart';
import '../widgets/mobile_list_card.dart';
import '../widgets/orders_stat_card.dart';
import '../widgets/route_detail_panel.dart';
import '../widgets/route_status_badge.dart';

class AdminDeliveriesScreen extends ConsumerStatefulWidget {
  const AdminDeliveriesScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  ConsumerState<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends ConsumerState<AdminDeliveriesScreen> {
  final _searchCtrl = TextEditingController();
  bool _showAddPanel = false;
  DeliveryRoute? _editingRoute;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(deliveryRoutesSearchProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeDetailPanel() {
    ref.read(selectedDeliveryRouteProvider.notifier).state = null;
  }

  void _openAddPanel({DeliveryRoute? editing}) {
    setState(() {
      _showAddPanel = true;
      _editingRoute = editing;
    });
    ref.read(selectedDeliveryRouteProvider.notifier).state = null;
  }

  void _closeAddPanel() => setState(() {
    _showAddPanel = false;
    _editingRoute = null;
  });

  void _showAddSheet(BuildContext context, {DeliveryRoute? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: AddRoutePanel(editing: editing, onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final selectedRoute = ref.watch(selectedDeliveryRouteProvider);

    ref.listen<DeliveryRoute?>(selectedDeliveryRouteProvider, (_, next) {
      if (next != null) {
        if (!isWide) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (_) => UncontrolledProviderScope(
              container: ProviderScope.containerOf(context),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: RouteDetailPanel(
                  route: next,
                  onClose: () => Navigator.pop(context),
                  onEdit: () {
                    Navigator.pop(context);
                    _showAddSheet(context, editing: next);
                  },
                ),
              ),
            ),
          ).then((_) => _closeDetailPanel());
        } else if (_showAddPanel) {
          setState(() => _showAddPanel = false);
        }
      }
    });

    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/deliveries',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RoutesListColumn(
                searchCtrl: _searchCtrl,
                onAddRoute: isWide ? () => _openAddPanel() : () => _showAddSheet(context),
                onEditRoute: (r) => isWide ? _openAddPanel(editing: r) : _showAddSheet(context, editing: r),
              ),
            ),
            if (isWide && _showAddPanel)
              SizedBox(
                width: 380,
                child: AddRoutePanel(editing: _editingRoute, onClose: _closeAddPanel),
              ),
            if (isWide && !_showAddPanel && selectedRoute != null)
              SizedBox(
                width: 360,
                child: RouteDetailPanel(
                  route: selectedRoute,
                  onClose: _closeDetailPanel,
                  onEdit: () => _openAddPanel(editing: selectedRoute),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── List Column ───────────────────────────────────────────────────────────────

class _RoutesListColumn extends ConsumerWidget {
  const _RoutesListColumn({required this.searchCtrl, required this.onAddRoute, required this.onEditRoute});
  final TextEditingController searchCtrl;
  final VoidCallback onAddRoute;
  final void Function(DeliveryRoute) onEditRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRoutes = ref.watch(deliveryRoutesStreamProvider).value ?? [];
    final allOrders = ref.watch(ordersStreamProvider).value ?? [];
    final now = DateTime.now();

    final totalRoutes = allRoutes.length;
    final activeRoutes = allRoutes.where((r) => r.status == 'active').length;
    final totalCustomers = allRoutes.fold<int>(0, (s, r) => s + r.customerCount);
    final deliveriesToday = allOrders.where((o) =>
        (o.routeName ?? '').isNotEmpty &&
        o.status == 'pending' &&
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month &&
        o.createdAt.day == now.day).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(totalRoutes, activeRoutes, totalCustomers, deliveriesToday),
          const SizedBox(height: 20),
          _buildContentCard(context, ref),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Routes & Delivery Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              SizedBox(height: 4),
              Text('Organize delivery routes and schedules', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAddRoute,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Route'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int total, int active, int customers, int today) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      final cards = [
        OrdersStatCard(title: 'Total Routes', value: '$total', subtitle: 'Coverage areas'),
        OrdersStatCard(title: 'Active Routes', value: '$active', subtitle: 'Running smoothly', valueColor: const Color(0xFF059669)),
        OrdersStatCard(title: 'Total Customers', value: '$customers', subtitle: 'Across all routes'),
        OrdersStatCard(title: 'Deliveries Today', value: '$today', subtitle: 'Scheduled for today'),
      ];
      if (isNarrow) {
        return Column(children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
        ]);
      }
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ]);
    });
  }

  Widget _buildContentCard(BuildContext context, WidgetRef ref) {
    final filteredRoutes = ref.watch(filteredDeliveryRoutesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context),
          if (filteredRoutes.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: filteredRoutes.map((r) => _RouteMobileCard(route: r, onEdit: () => onEditRoute(r))).toList(),
                );
              }
              return Column(children: [
                _buildTableHeader(),
                ...filteredRoutes.map((r) => _RouteRow(route: r, onEdit: () => onEditRoute(r))),
              ]);
            }),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search routes...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6B7280))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: Color(0xFF6B7280)),
                  SizedBox(width: 6),
                  Text('Filter', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB)), bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(children: [
        _HeaderCell('ROUTE NAME', flex: 2),
        _HeaderCell('MUNICIPALITY', flex: 2),
        _HeaderCell('ASSIGNED REP', flex: 2),
        _HeaderCell('DELIVERY DAYS', flex: 2),
        _HeaderCell('CUSTOMERS', flex: 1),
        _HeaderCell('STATUS', flex: 2),
        _HeaderCell('', flex: 2),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.location_on_outlined, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No routes found', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        const Text('Use "Add Route" to create your first delivery route', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}

// ── Route Row ─────────────────────────────────────────────────────────────────

class _RouteRow extends ConsumerWidget {
  const _RouteRow({required this.route, required this.onEdit});
  final DeliveryRoute route;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDeliveryRouteProvider);
    final isSelected = selected?.uuid == route.uuid;

    return InkWell(
      onTap: () => ref.read(selectedDeliveryRouteProvider.notifier).state = route,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9FAFB) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(route.routeName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(route.municipality, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(route.assignedRepName ?? 'Unassigned',
                  style: TextStyle(fontSize: 12, color: route.assignedRepName == null ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontStyle: route.assignedRepName == null ? FontStyle.italic : FontStyle.normal),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(route.deliveryDays.replaceAll(',', ', '), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: Text('${route.customerCount}', style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ),
            Expanded(flex: 2, child: RouteStatusBadge(status: route.status)),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIconButton(icon: Icons.visibility_outlined, tooltip: 'View', onTap: () => ref.read(selectedDeliveryRouteProvider.notifier).state = route),
                  _ActionIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: onEdit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route Mobile Card ─────────────────────────────────────────────────────────

class _RouteMobileCard extends ConsumerWidget {
  const _RouteMobileCard({required this.route, required this.onEdit});
  final DeliveryRoute route;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MobileListCard(
      onTap: () => ref.read(selectedDeliveryRouteProvider.notifier).state = route,
      primary: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(route.routeName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      badge: RouteStatusBadge(status: route.status),
      secondary: MobileCardMuted('${route.municipality} · ${route.assignedRepName ?? 'Unassigned'}'),
      valueLeft: Text('${route.customerCount} customers',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      valueRight: MobileCardMuted(route.deliveryDays.replaceAll(',', ', ')),
      actions: [
        MobileCardAction(
          label: 'View',
          onPressed: () => ref.read(selectedDeliveryRouteProvider.notifier).state = route,
        ),
        MobileCardAction(label: 'Edit', onPressed: onEdit),
      ],
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({required this.icon, required this.onTap, this.tooltip = ''});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFF3F4F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(widget.icon, size: 15, color: _hovered ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
          ),
        ),
      ),
    );
  }
}
