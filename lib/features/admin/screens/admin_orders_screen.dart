import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/orders_provider.dart';
import '../services/orders_service.dart';
import '../widgets/order_detail_panel.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/orders_stat_card.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({
    super.key,
    required this.database,
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(ordersSearchProvider.notifier).state = _searchCtrl.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.database.seedOrdersForDemo();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closePanel() {
    ref.read(selectedOrderProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    ref.listen<Order?>(selectedOrderProvider, (_, next) {
      if (next != null && !isWide) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => UncontrolledProviderScope(
            container: ProviderScope.containerOf(context),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: OrderDetailPanel(onClose: () => Navigator.pop(context)),
            ),
          ),
        ).then((_) => _closePanel());
      }
    });

    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/orders',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _OrdersListColumn(searchCtrl: _searchCtrl)),
            if (isWide)
              Consumer(builder: (ctx, ref, w) {
                final selected = ref.watch(selectedOrderProvider);
                if (selected == null) return const SizedBox.shrink();
                return SizedBox(
                  width: 360,
                  child: OrderDetailPanel(onClose: _closePanel),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── List Column ───────────────────────────────────────────────────────────────

class _OrdersListColumn extends ConsumerWidget {
  const _OrdersListColumn({required this.searchCtrl});
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final allOrders = ordersAsync.value ?? [];

    final totalCount = allOrders.length;
    final pendingCount = allOrders.where((o) => o.status == 'pending').length;
    final completedCount = allOrders.where((o) => o.status == 'completed').length;
    final totalValue = allOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final pendingValue = allOrders
        .where((o) => o.status == 'pending')
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(totalCount, pendingCount, completedCount, totalValue, pendingValue),
          const SizedBox(height: 20),
          _buildContentCard(context, ref),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Orders Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        Text(
          'Track and manage customer orders',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int total, int pending, int completed, double totalValue, double pendingValue) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      final pendingSubtitle = '${_formatAbbrev(pendingValue)} pending';
      if (isNarrow) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: OrdersStatCard(
                title: 'Total Orders', value: '$total',
                subtitle: 'This period', valueColor: const Color(0xFF111827),
              )),
              const SizedBox(width: 12),
              Expanded(child: OrdersStatCard(
                title: 'Pending', value: '$pending',
                subtitle: 'Awaiting dispatch', valueColor: const Color(0xFFD97706),
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OrdersStatCard(
                title: 'Completed', value: '$completed',
                subtitle: 'Delivered', valueColor: const Color(0xFF059669),
              )),
              const SizedBox(width: 12),
              Expanded(child: OrdersStatCard(
                title: 'Total Value', value: _formatAbbrev(totalValue),
                subtitle: pendingSubtitle,
              )),
            ]),
          ],
        );
      }
      return Row(children: [
        Expanded(child: OrdersStatCard(
          title: 'Total Orders', value: '$total',
          subtitle: 'This period', valueColor: const Color(0xFF111827),
        )),
        const SizedBox(width: 12),
        Expanded(child: OrdersStatCard(
          title: 'Pending', value: '$pending',
          subtitle: 'Awaiting dispatch', valueColor: const Color(0xFFD97706),
        )),
        const SizedBox(width: 12),
        Expanded(child: OrdersStatCard(
          title: 'Completed', value: '$completed',
          subtitle: 'Delivered', valueColor: const Color(0xFF059669),
        )),
        const SizedBox(width: 12),
        Expanded(child: OrdersStatCard(
          title: 'Total Value', value: _formatAbbrev(totalValue),
          subtitle: pendingSubtitle,
        )),
      ]);
    });
  }

  Widget _buildContentCard(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(ordersTabProvider);
    final filteredOrders = ref.watch(filteredOrdersProvider);
    final allOrders = ref.watch(ordersStreamProvider).value ?? [];

    final tabs = [
      _Tab('Pending', 'pending', allOrders.where((o) => o.status == 'pending').length),
      _Tab('Completed', 'completed', allOrders.where((o) => o.status == 'completed').length),
      _Tab('Cancelled', 'cancelled', allOrders.where((o) => o.status == 'cancelled').length),
      _Tab('All Orders', null, allOrders.length),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabBar(ref, tab, tabs),
          _buildToolbar(ref),
          _buildTableHeader(),
          if (filteredOrders.isEmpty)
            _buildEmptyState(tab)
          else
            ...filteredOrders.map((o) => _OrderRow(order: o)),
        ],
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, String? tab, List<_Tab> tabs) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = tab == t.value;
            return GestureDetector(
              onTap: () => ref.read(ordersTabProvider.notifier).state = t.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? const Color(0xFF111827) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${t.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.white : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildToolbar(WidgetRef ref) {
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
                  hintText: 'Search orders, stores, routes...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF6B7280)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: open filter sheet
              },
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: open new order form
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
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
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: const Row(children: [
        _HeaderCell('ORDER', flex: 2),
        _HeaderCell('STORE', flex: 2),
        _HeaderCell('ROUTE', flex: 2),
        _HeaderCell('REP', flex: 2),
        _HeaderCell('ITEMS', flex: 1),
        _HeaderCell('AMOUNT', flex: 2),
        _HeaderCell('DATE', flex: 2),
        _HeaderCell('STATUS', flex: 2),
        _HeaderCell('', flex: 2),
      ]),
    );
  }

  Widget _buildEmptyState(String? tab) {
    final label = tab == null ? 'orders' : '$tab orders';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No $label found',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ]),
    );
  }

  static String _formatAbbrev(double v) {
    if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(0)}K';
    return '₱${v.toStringAsFixed(0)}';
  }
}

// ── Order Row ─────────────────────────────────────────────────────────────────

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedOrderProvider);
    final isSelected = selected?.uuid == order.uuid;
    final service = ref.read(ordersServiceProvider);

    return InkWell(
      onTap: () => ref.read(selectedOrderProvider.notifier).state = order,
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
              child: Text(
                order.orderNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.storeName ?? order.customerId,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.routeName ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.salesRepName ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${order.itemCount}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatFull(order.totalAmount),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(order.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
            Expanded(
              flex: 2,
              child: OrderStatusBadge(status: order.status),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIconButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View',
                    onTap: () => ref.read(selectedOrderProvider.notifier).state = order,
                  ),
                  _ActionIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onTap: () {
                      // TODO: open edit order form
                    },
                  ),
                  _ActionIconButton(
                    icon: Icons.delete_outline,
                    tooltip: order.status == 'cancelled' ? 'Restore' : 'Cancel',
                    hoverColor: order.status == 'cancelled'
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFDC2626),
                    onTap: () async {
                      if (order.status == 'cancelled') {
                        await service.restoreOrder(order.uuid);
                      } else {
                        await service.cancelOrder(order.uuid);
                      }
                      ref.read(selectedOrderProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFull(double v) {
    final n = v.round().toString();
    final buf = StringBuffer('₱');
    final mod = n.length % 3;
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (i - mod) % 3 == 0) buf.write(',');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _Tab {
  const _Tab(this.label, this.value, this.count);
  final String label;
  final String? value;
  final int count;
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
    this.hoverColor = const Color(0xFF6B7280),
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color hoverColor;

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
            child: Icon(widget.icon, size: 15, color: _hovered ? widget.hoverColor : const Color(0xFF9CA3AF)),
          ),
        ),
      ),
    );
  }
}
