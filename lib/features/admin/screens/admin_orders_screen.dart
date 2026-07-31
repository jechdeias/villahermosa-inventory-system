import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/orders_provider.dart';
import '../services/orders_service.dart';
import '../widgets/add_item_form.dart';
import '../widgets/mobile_list_card.dart';
import '../widgets/order_detail_panel.dart';
import '../widgets/order_item_row.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/orders_filter_sheet.dart';
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
  bool _showNewOrderPanel = false;

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

  void _closeDetailPanel() {
    ref.read(selectedOrderProvider.notifier).state = null;
  }

  void _openNewOrderPanel() {
    setState(() => _showNewOrderPanel = true);
    ref.read(selectedOrderProvider.notifier).state = null;
  }

  void _closeNewOrderPanel() => setState(() => _showNewOrderPanel = false);

  void _showNewOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: _NewOrderPanel(onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final selectedOrder = ref.watch(selectedOrderProvider);

    ref.listen<Order?>(selectedOrderProvider, (_, next) {
      if (next != null) {
        if (!isWide) {
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
          ).then((_) => _closeDetailPanel());
        } else if (_showNewOrderPanel) {
          setState(() => _showNewOrderPanel = false);
        }
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
            Expanded(
              child: _OrdersListColumn(
                searchCtrl: _searchCtrl,
                onNewOrder: isWide
                    ? _openNewOrderPanel
                    : () => _showNewOrderSheet(context),
              ),
            ),
            if (isWide && _showNewOrderPanel)
              SizedBox(
                width: 380,
                child: _NewOrderPanel(onClose: _closeNewOrderPanel),
              ),
            if (isWide && !_showNewOrderPanel && selectedOrder != null)
              SizedBox(
                width: 360,
                child: OrderDetailPanel(onClose: _closeDetailPanel),
              ),
          ],
        ),
      ),
    );
  }
}

// ── List Column ───────────────────────────────────────────────────────────────

class _OrdersListColumn extends ConsumerWidget {
  const _OrdersListColumn({
    required this.searchCtrl,
    required this.onNewOrder,
  });
  final TextEditingController searchCtrl;
  final VoidCallback onNewOrder;

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
          _buildToolbar(context, ref),
          if (filteredOrders.isEmpty)
            _buildEmptyState(tab)
          else
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: filteredOrders.map((o) => _OrderMobileCard(order: o)).toList(),
                );
              }
              return Column(children: [
                _buildTableHeader(),
                ...filteredOrders.map((o) => _OrderRow(order: o)),
              ]);
            }),
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

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(ordersFilterProvider);
    final filterActive = filters.isActive;
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
            OutlinedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => UncontrolledProviderScope(
                  container: ProviderScope.containerOf(context),
                  child: const OrdersFilterSheet(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: filterActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
                backgroundColor: filterActive
                    ? const Color(0xFFEFF6FF)
                    : null,
                side: BorderSide(
                  color: filterActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE5E7EB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16,
                      color: filterActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text('Filter',
                      style: TextStyle(
                          fontSize: 12,
                          color: filterActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF6B7280))),
                  if (filterActive) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onNewOrder,
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

// ── Order Mobile Card ─────────────────────────────────────────────────────────

class _OrderMobileCard extends ConsumerWidget {
  const _OrderMobileCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MobileListCard(
      onTap: () => ref.read(selectedOrderProvider.notifier).state = order,
      primary: Text(order.orderNumber,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: Color(0xFF111827))),
      badge: OrderStatusBadge(status: order.status),
      secondary: MobileCardMuted(
          '${order.storeName ?? order.customerId} · ${order.routeName ?? '—'} · ${order.salesRepName ?? '—'}'),
      valueLeft: Text(_OrderRow._formatFull(order.totalAmount),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      valueRight: MobileCardMuted(_OrderRow._formatDate(order.createdAt)),
      actions: [
        MobileCardAction(
          label: 'View',
          onPressed: () => ref.read(selectedOrderProvider.notifier).state = order,
        ),
      ],
    );
  }
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

// ── New Order Panel ───────────────────────────────────────────────────────────

class _OrderItemEntry {
  const _OrderItemEntry({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
  final String productName;
  final int quantity;
  final double unitPrice;
  double get subtotal => quantity * unitPrice;
}

class _NewOrderPanel extends ConsumerStatefulWidget {
  const _NewOrderPanel({required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<_NewOrderPanel> createState() => _NewOrderPanelState();
}

class _NewOrderPanelState extends ConsumerState<_NewOrderPanel> {
  static const _routes = [
    'Route 1 - Centro',
    'Route 2 - North',
    'Route 3 - South',
  ];

  Customer? _selectedCustomer;
  String? _selectedRoute;
  User? _selectedRep;
  DateTime _selectedDate = DateTime.now();
  final List<_OrderItemEntry> _orderItems = [];
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total => _orderItems.fold(0, (s, i) => s + i.subtotal);

  Future<void> _saveOrder() async {
    if (_selectedCustomer == null) {
      _snackErr('Please select a store');
      return;
    }
    if (_selectedRoute == null) {
      _snackErr('Please select a route');
      return;
    }
    if (_selectedRep == null) {
      _snackErr('Please select a sales rep');
      return;
    }
    if (_orderItems.isEmpty) {
      _snackErr('Please add at least one item');
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final orderNumber = await db.generateOrderNumber();
      final orderUuid =
          'ord-${DateTime.now().microsecondsSinceEpoch}';
      final repName =
          '${_selectedRep!.firstName} ${_selectedRep!.lastName}'.trim();
      final storeName = _selectedCustomer!.businessName?.isNotEmpty == true
          ? _selectedCustomer!.businessName!
          : _selectedCustomer!.name;
      final custId = _selectedCustomer!.uuid;

      await db.createOrder(OrdersCompanion(
        uuid: Value(orderUuid),
        orderNumber: Value(orderNumber),
        customerId: Value(custId),
        storeName: Value(storeName),
        routeName: Value(_selectedRoute!),
        salesRepName: Value(repName),
        itemCount: Value(_orderItems.length),
        totalAmount: Value(_total),
        status: const Value('pending'),
        syncStatus: const Value('pending'),
        deliveryAddress: Value(storeName),
        customerNotes: Value(_notesCtrl.text.trim()),
        createdAt: Value(_selectedDate),
        updatedAt: Value(_selectedDate),
      ));

      for (var i = 0; i < _orderItems.length; i++) {
        final item = _orderItems[i];
        await db.createOrderItem(OrderItemsCompanion(
          uuid: Value('item-${DateTime.now().microsecondsSinceEpoch}-$i'),
          orderId: Value(orderUuid),
          productId: const Value(''),
          productSku: Value(item.productName.toLowerCase().replaceAll(' ', '-')),
          productName: Value(item.productName),
          quantity: Value(item.quantity),
          unitPrice: Value(item.unitPrice),
          subtotal: Value(item.subtotal),
          totalAmount: Value(item.subtotal),
          availableStock: const Value(0),
          syncStatus: const Value('pending'),
        ));
      }

      try {
        await SyncManager.instance.syncPendingData();
      } catch (_) {}

      widget.onClose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order $orderNumber created')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snackErr(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final usersAsync = ref.watch(usersProvider);
    final customers = customersAsync.value ?? [];
    final reps = (usersAsync.value ?? [])
        .where((u) => u.role == 'sales_rep' || u.role == 'admin')
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('STORE & ROUTE'),
                  const SizedBox(height: 10),
                  _storeDropdown(customers),
                  const SizedBox(height: 10),
                  _routeDropdown(),
                  const SizedBox(height: 10),
                  _repDropdown(reps),
                  const SizedBox(height: 10),
                  _dateField(context),
                  const SizedBox(height: 20),
                  _sectionLabel('ORDER ITEMS'),
                  const SizedBox(height: 10),
                  ..._orderItems.asMap().entries.map((e) => OrderItemRow(
                        productName: e.value.productName,
                        quantity: e.value.quantity,
                        unitPrice: e.value.unitPrice,
                        onRemove: () =>
                            setState(() => _orderItems.removeAt(e.key)),
                      )),
                  if (_orderItems.isNotEmpty)
                    const Divider(height: 16),
                  AddItemForm(
                    onAdd: (name, qty, price) => setState(() =>
                        _orderItems.add(_OrderItemEntry(
                          productName: name,
                          quantity: qty,
                          unitPrice: price,
                        ))),
                  ),
                  if (_orderItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Expanded(
                        child: Text('Order Total',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827))),
                      ),
                      Text(
                        '₱${_fmtNum(_total)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 20),
                  _sectionLabel('NOTES (OPTIONAL)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: _dec('Add delivery or order notes...'),
                  ),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(children: [
          const Expanded(
            child: Text('New Order',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close,
                size: 18, color: Color(0xFF6B7280)),
          ),
        ]),
      );

  Widget _buildFooter() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : widget.onClose,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                foregroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveOrder,
              icon: _saving
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 14),
              label: const Text('Save Order',
                  style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      );

  Widget _storeDropdown(List<Customer> customers) =>
      DropdownButtonFormField<Customer>(
        decoration: _dec('Store'),
        isExpanded: true,
        items: customers.map((c) {
          final label = c.businessName?.isNotEmpty == true
              ? c.businessName!
              : c.name;
          return DropdownMenuItem(
            value: c,
            child: Text(label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (c) => setState(() => _selectedCustomer = c),
      );

  Widget _routeDropdown() => DropdownButtonFormField<String>(
        decoration: _dec('Route'),
        isExpanded: true,
        items: _routes.map((r) => DropdownMenuItem(
              value: r,
              child: Text(r, style: const TextStyle(fontSize: 13)),
            )).toList(),
        onChanged: (v) => setState(() => _selectedRoute = v),
      );

  Widget _repDropdown(List<User> reps) =>
      DropdownButtonFormField<User>(
        decoration: _dec('Sales Rep'),
        isExpanded: true,
        items: reps.map((u) {
          final name = '${u.firstName} ${u.lastName}'.trim();
          return DropdownMenuItem(
            value: u,
            child: Text(name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (u) => setState(() => _selectedRep = u),
      );

  Widget _dateField(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                '${_selectedDate.day.toString().padLeft(2, '0')}/'
                '${_selectedDate.month.toString().padLeft(2, '0')}/'
                '${_selectedDate.year}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF111827)),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF9CA3AF)),
          ]),
        ),
      );

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: Color(0xFF374151))),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 12),
        filled: true,
        fillColor: Colors.white,
      );

  static String _fmtNum(double v) {
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
