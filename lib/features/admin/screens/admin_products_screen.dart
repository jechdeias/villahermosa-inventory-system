import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/products_provider.dart';
import '../widgets/add_product_panel.dart';
import '../widgets/adjust_stock_sheet.dart';
import '../widgets/mobile_list_card.dart';
import '../widgets/product_detail_panel.dart';
import '../widgets/product_status_badge.dart';
import '../widgets/orders_stat_card.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchCtrl = TextEditingController();
  bool _showAddPanel = false;
  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(productsSearchProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeDetailPanel() {
    ref.read(selectedProductProvider.notifier).state = null;
  }

  void _openAddPanel({Product? editing}) {
    setState(() {
      _showAddPanel = true;
      _editingProduct = editing;
    });
    ref.read(selectedProductProvider.notifier).state = null;
  }

  void _closeAddPanel() => setState(() {
    _showAddPanel = false;
    _editingProduct = null;
  });

  void _showAddSheet(BuildContext context, {Product? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: AddProductPanel(editing: editing, onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final selectedProduct = ref.watch(selectedProductProvider);

    ref.listen<Product?>(selectedProductProvider, (_, next) {
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
                child: ProductDetailPanel(product: next, onClose: () => Navigator.pop(context)),
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
      selectedRoute: '/admin/products',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProductsListColumn(
                searchCtrl: _searchCtrl,
                onAddProduct: isWide ? () => _openAddPanel() : () => _showAddSheet(context),
                onEditProduct: (p) => isWide ? _openAddPanel(editing: p) : _showAddSheet(context, editing: p),
              ),
            ),
            if (isWide && _showAddPanel)
              SizedBox(
                width: 380,
                child: AddProductPanel(editing: _editingProduct, onClose: _closeAddPanel),
              ),
            if (isWide && !_showAddPanel && selectedProduct != null)
              SizedBox(
                width: 360,
                child: ProductDetailPanel(product: selectedProduct, onClose: _closeDetailPanel),
              ),
          ],
        ),
      ),
    );
  }
}

// ── List Column ───────────────────────────────────────────────────────────────

class _ProductsListColumn extends ConsumerWidget {
  const _ProductsListColumn({
    required this.searchCtrl,
    required this.onAddProduct,
    required this.onEditProduct,
  });
  final TextEditingController searchCtrl;
  final VoidCallback onAddProduct;
  final void Function(Product) onEditProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(productsStreamProvider).value ?? [];

    final totalCount = allProducts.length;
    final lowStockCount = allProducts.where((p) => p.currentStock <= p.minStock).length;
    final totalValue = allProducts.fold<double>(0, (s, p) => s + p.currentStock * p.unitPrice);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(totalCount, lowStockCount, totalValue),
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
        const Text('Inventory Management',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        const Text('Monitor and manage product stock levels',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildStatsRow(int total, int lowStock, double totalValue) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      final cards = [
        OrdersStatCard(title: 'Total Products', value: '$total', subtitle: 'SKUs tracked'),
        OrdersStatCard(title: 'Low Stock Items', value: '$lowStock', subtitle: 'Below threshold', valueColor: const Color(0xFFD97706)),
        OrdersStatCard(title: 'Total Inventory Value', value: _formatAbbrev(totalValue), subtitle: 'Stock on hand'),
      ];
      if (isNarrow) {
        return Column(children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ]),
          const SizedBox(height: 12),
          cards[2],
        ]);
      }
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
      ]);
    });
  }

  Widget _buildContentCard(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(productsTabProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final categories = ref.watch(productCategoriesProvider);
    final allProducts = ref.watch(productsStreamProvider).value ?? [];

    final tabs = [
      _Tab('All', null, allProducts.length),
      ...categories.map((c) => _Tab(c, c, allProducts.where((p) => p.category == c).length)),
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
          if (filteredProducts.isEmpty)
            _buildEmptyState(tab)
          else
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: filteredProducts.map((p) => _ProductMobileCard(product: p)).toList(),
                );
              }
              return Column(children: [
                _buildTableHeader(),
                ...filteredProducts.map((p) => _ProductRow(product: p, onEdit: () => onEditProduct(p))),
              ]);
            }),
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
              onTap: () => ref.read(productsTabProvider.notifier).state = t.value,
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
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : const Color(0xFF6B7280))),
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
    final filters = ref.watch(productsFilterProvider);
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
                  hintText: 'Search products...',
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
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => UncontrolledProviderScope(
                  container: ProviderScope.containerOf(context),
                  child: const _ProductsFilterSheet(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: filterActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                backgroundColor: filterActive ? const Color(0xFFEFF6FF) : null,
                side: BorderSide(color: filterActive ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: filterActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text('Filter', style: TextStyle(fontSize: 12, color: filterActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280))),
                  if (filterActive) ...[
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
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
        _HeaderCell('PRODUCT CODE', flex: 2),
        _HeaderCell('DESCRIPTION', flex: 3),
        _HeaderCell('SUPPLIER', flex: 2),
        _HeaderCell('CATEGORY', flex: 2),
        _HeaderCell('STOCK', flex: 1),
        _HeaderCell('UNIT PRICE', flex: 2),
        _HeaderCell('STATUS', flex: 2),
        _HeaderCell('', flex: 2),
      ]),
    );
  }

  Widget _buildEmptyState(String? tab) {
    final label = tab == null ? 'products' : '$tab products';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No $label found', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ]),
    );
  }

  static String _formatAbbrev(double v) {
    if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(0)}K';
    return '₱${v.toStringAsFixed(0)}';
  }
}

// ── Product Row ──────────────────────────────────────────────────────────────

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product, required this.onEdit});
  final Product product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProductProvider);
    final isSelected = selected?.uuid == product.uuid;
    final supplierName = ref.watch(supplierNameProvider(product.supplierId));
    final isLowStock = product.currentStock <= product.minStock;

    return InkWell(
      onTap: () => ref.read(selectedProductProvider.notifier).state = product,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF9FAFB)
              : (isLowStock ? const Color(0xFFFFFBEB) : Colors.white),
          border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(product.sku,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: Color(0xFF111827))),
            ),
            Expanded(
              flex: 3,
              child: Text(product.name, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(supplierName, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(product.category, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLowStock) ...[
                    const Icon(Icons.warning_amber_outlined, size: 12, color: Color(0xFFD97706)),
                    const SizedBox(width: 2),
                  ],
                  Text('${product.currentStock}',
                      style: TextStyle(
                          fontSize: 12,
                          color: product.currentStock <= 0
                              ? const Color(0xFFDC2626)
                              : (isLowStock ? const Color(0xFFD97706) : const Color(0xFF111827)))),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('₱${product.unitPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            ),
            Expanded(
              flex: 2,
              child: ProductStatusBadge(currentStock: product.currentStock, minStock: product.minStock),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIconButton(
                    icon: Icons.add,
                    tooltip: 'Add stock',
                    hoverColor: const Color(0xFF059669),
                    onTap: () => showAdjustStockSheet(context, product),
                  ),
                  _ActionIconButton(
                    icon: Icons.remove,
                    tooltip: 'Remove stock',
                    hoverColor: const Color(0xFFDC2626),
                    onTap: () => showAdjustStockSheet(context, product),
                  ),
                  _ActionIconButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View',
                    onTap: () => ref.read(selectedProductProvider.notifier).state = product,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Mobile Card ───────────────────────────────────────────────────────

class _ProductMobileCard extends ConsumerWidget {
  const _ProductMobileCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierName = ref.watch(supplierNameProvider(product.supplierId));
    final isLowStock = product.currentStock <= product.minStock;
    final stockColor = product.currentStock <= 0
        ? const Color(0xFFDC2626)
        : (isLowStock ? const Color(0xFFD97706) : const Color(0xFF111827));

    return MobileListCard(
      onTap: () => ref.read(selectedProductProvider.notifier).state = product,
      primary: Text(product.sku,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: Color(0xFF111827))),
      badge: ProductStatusBadge(currentStock: product.currentStock, minStock: product.minStock),
      secondary: MobileCardMuted('${product.name} · $supplierName'),
      valueLeft: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isLowStock) ...[
          const Icon(Icons.warning_amber_outlined, size: 13, color: Color(0xFFD97706)),
          const SizedBox(width: 4),
        ],
        Text('${product.currentStock} in stock',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stockColor)),
      ]),
      valueRight: Text('₱${product.unitPrice.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      actions: [
        MobileCardAction(
          label: '+ Stock',
          color: const Color(0xFF059669),
          onPressed: () => showAdjustStockSheet(context, product),
        ),
        MobileCardAction(
          label: '- Stock',
          color: const Color(0xFFDC2626),
          onPressed: () => showAdjustStockSheet(context, product),
        ),
        MobileCardAction(
          label: 'View',
          onPressed: () => ref.read(selectedProductProvider.notifier).state = product,
        ),
      ],
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _ProductsFilterSheet extends ConsumerStatefulWidget {
  const _ProductsFilterSheet();

  @override
  ConsumerState<_ProductsFilterSheet> createState() => _ProductsFilterSheetState();
}

class _ProductsFilterSheetState extends ConsumerState<_ProductsFilterSheet> {
  late int? _supplierId = ref.read(productsFilterProvider).supplierId;
  late bool _lowStockOnly = ref.read(productsFilterProvider).lowStockOnly;

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersStreamProvider).value ?? [];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          ),
          const Text('Filter Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _supplierId,
            decoration: InputDecoration(
              hintText: 'Supplier',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All suppliers', style: TextStyle(fontSize: 13))),
              ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.tradeName, style: const TextStyle(fontSize: 13)))),
            ],
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Low stock only', style: TextStyle(fontSize: 13)),
            value: _lowStockOnly,
            onChanged: (v) => setState(() => _lowStockOnly = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(productsFilterProvider.notifier).state = const ProductFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(productsFilterProvider.notifier).state =
                      ProductFilters(supplierId: _supplierId, lowStockOnly: _lowStockOnly);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
                child: const Text('Apply', style: TextStyle(fontSize: 13)),
              ),
            ),
          ]),
        ],
      ),
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
      child: Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({required this.icon, required this.onTap, this.tooltip = '', this.hoverColor = const Color(0xFF6B7280)});
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
