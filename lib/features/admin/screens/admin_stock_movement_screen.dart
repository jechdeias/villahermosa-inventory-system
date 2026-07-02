import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/products_provider.dart';
import '../providers/stock_movements_provider.dart';
import '../widgets/orders_stat_card.dart';
import '../widgets/record_movement_panel.dart';
import '../widgets/stock_movement_type_badge.dart';

class AdminStockMovementScreen extends ConsumerStatefulWidget {
  const AdminStockMovementScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  ConsumerState<AdminStockMovementScreen> createState() => _AdminStockMovementScreenState();
}

class _AdminStockMovementScreenState extends ConsumerState<AdminStockMovementScreen> {
  final _searchCtrl = TextEditingController();
  bool _showPanel = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(stockMovementsSearchProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openPanel() => setState(() => _showPanel = true);
  void _closePanel() => setState(() => _showPanel = false);

  void _showPanelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: RecordMovementPanel(onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/stock',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StockMovementListColumn(
                searchCtrl: _searchCtrl,
                onRecordMovement: isWide ? _openPanel : () => _showPanelSheet(context),
              ),
            ),
            if (isWide && _showPanel)
              SizedBox(
                width: 380,
                child: RecordMovementPanel(onClose: _closePanel),
              ),
          ],
        ),
      ),
    );
  }
}

// ── List Column ───────────────────────────────────────────────────────────────

class _StockMovementListColumn extends ConsumerWidget {
  const _StockMovementListColumn({required this.searchCtrl, required this.onRecordMovement});
  final TextEditingController searchCtrl;
  final VoidCallback onRecordMovement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMovements = ref.watch(stockMovementsStreamProvider).value ?? [];
    final allProducts = ref.watch(productsStreamProvider).value ?? [];

    final totalCount = allMovements.length;
    final inCount = allMovements.where((m) => m.movementType == 'in').length;
    final outCount = allMovements.where((m) => m.movementType == 'out').length;
    final lowStockCount = allProducts.where((p) => p.currentStock <= p.minStock).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(totalCount, inCount, outCount, lowStockCount),
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
        const Text('Stock Movement', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        const Text('Track inventory changes across all products', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildStatsRow(int total, int inCount, int outCount, int lowStock) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      final cards = [
        OrdersStatCard(title: 'Total Movements', value: '$total', subtitle: 'This period'),
        OrdersStatCard(title: 'Stock In', value: '$inCount', subtitle: 'Deliveries received', valueColor: const Color(0xFF059669)),
        OrdersStatCard(title: 'Stock Out', value: '$outCount', subtitle: 'Sales and usage', valueColor: const Color(0xFFDC2626)),
        OrdersStatCard(title: 'Low Stock Alerts', value: '$lowStock', subtitle: 'Need restocking', valueColor: const Color(0xFFD97706)),
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
    final tab = ref.watch(stockMovementsTabProvider);
    final filtered = ref.watch(filteredStockMovementsProvider);
    final allMovements = ref.watch(stockMovementsStreamProvider).value ?? [];
    final allProducts = ref.watch(productsStreamProvider).value ?? [];
    final lowStockProductIds = allProducts.where((p) => p.currentStock <= p.minStock).map((p) => p.uuid).toSet();

    final tabs = [
      _Tab('All', null, allMovements.length),
      _Tab('Stock In', 'in', allMovements.where((m) => m.movementType == 'in').length),
      _Tab('Stock Out', 'out', allMovements.where((m) => m.movementType == 'out').length),
      _Tab('Low Stock Alert', 'low_stock', allMovements.where((m) => lowStockProductIds.contains(m.productId)).length),
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
          _buildTableHeader(),
          if (filtered.isEmpty)
            _buildEmptyState(tab)
          else
            ...filtered.map((m) => _MovementRow(movement: m)),
        ],
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, String? tab, List<_Tab> tabs) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = tab == t.value;
            return GestureDetector(
              onTap: () => ref.read(stockMovementsTabProvider.notifier).state = t.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF111827) : Colors.transparent, width: 2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${t.count}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF6B7280))),
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
                  hintText: 'Search by product or reference...',
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
            ElevatedButton.icon(
              onPressed: onRecordMovement,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Record Movement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
        _HeaderCell('DATE', flex: 2),
        _HeaderCell('PRODUCT CODE', flex: 2),
        _HeaderCell('PRODUCT NAME', flex: 3),
        _HeaderCell('TYPE', flex: 2),
        _HeaderCell('QTY', flex: 1),
        _HeaderCell('REASON', flex: 2),
        _HeaderCell('REFERENCE', flex: 2),
        _HeaderCell('PERFORMED BY', flex: 2),
      ]),
    );
  }

  Widget _buildEmptyState(String? tab) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.trending_up, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No stock movements found', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ]),
    );
  }
}

// ── Movement Row ─────────────────────────────────────────────────────────────

class _MovementRow extends ConsumerWidget {
  const _MovementRow({required this.movement});
  final StockMovement movement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByUuidProvider(movement.productId));
    final isIn = movement.movementType == 'in';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(_formatDate(movement.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(product?.sku ?? '—',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: Color(0xFF111827))),
          ),
          Expanded(
            flex: 3,
            child: Text(product?.name ?? 'Unknown product', style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis),
          ),
          Expanded(flex: 2, child: StockMovementTypeBadge(movementType: movement.movementType)),
          Expanded(
            flex: 1,
            child: Text('${isIn ? '+' : '-'}${movement.quantity}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isIn ? const Color(0xFF059669) : const Color(0xFFDC2626))),
          ),
          Expanded(
            flex: 2,
            child: Text(movement.reason, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(movement.referenceId ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(movement.userName, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
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
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
    );
  }
}
