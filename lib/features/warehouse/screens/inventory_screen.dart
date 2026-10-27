import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';
import '../../../core/theme/app_theme.dart';

class WarehouseInventoryScreen extends ConsumerStatefulWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  ConsumerState<WarehouseInventoryScreen> createState() => _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends ConsumerState<WarehouseInventoryScreen> {
  static const _flex = [5, 2, 3, 2, 2, 3];

  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _category;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _quickMove(Product p, bool isIn) async {
    final qtyCtrl = TextEditingController();
    String reason = (isIn ? stockInReasons : stockOutReasons).first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('${isIn ? 'Stock in' : 'Stock out'}: ${p.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('In stock now: ${p.currentStock} units', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
              const SizedBox(height: 12),
              const WhFieldLabel('Quantity'),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, autofocus: true, decoration: whFieldDecoration(hint: 'e.g. 24')),
              const SizedBox(height: 12),
              const WhFieldLabel('Reason'),
              DropdownButtonFormField<String>(
                initialValue: reason,
                isExpanded: true,
                decoration: whFieldDecoration(),
                items: [for (final r in (isIn ? stockInReasons : stockOutReasons)) DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))],
                onChanged: (v) => setLocal(() => reason = v ?? reason),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: WhColors.muted))),
            WhPrimaryButton(
              label: isIn ? 'Confirm Stock In' : 'Confirm Stock Out',
              onPressed: () {
                final q = int.tryParse(qtyCtrl.text.trim());
                if (q == null || q <= 0) return;
                Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    final qty = int.tryParse(qtyCtrl.text.trim());
    qtyCtrl.dispose();
    if (confirmed != true || qty == null) return;
    await recordStockMovement(ref, productUuid: p.uuid, delta: isIn ? qty : -qty, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${isIn ? 'Added' : 'Removed'} $qty × ${p.name}')));
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstLoad(ref.watch(productsStreamProvider))) return const WhLoadingShell(route: WhRoutes.inventory, statCards: 3);
    final products = ref.watch(productsStreamProvider).value ?? [];
    final categories = (products.map((p) => p.category).toSet().toList()..sort());
    final q = _search.toLowerCase();
    final filtered = products.where((p) {
      if (_category != null && p.category != _category) return false;
      return q.isEmpty || p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
    }).toList();

    final low = products.where(isLowStock).length;
    final out = products.where(isOutOfStock).length;

    return WarehouseShell(
      route: WhRoutes.inventory,
      child: WhPage(children: [
        WhPageHeader(
          title: 'Inventory Stock',
          subtitle: 'Current stock levels across the warehouse',
          trailing: WhSecondaryButton(
            label: 'Export CSV',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV export is not set up yet'))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: WhSearchInput(hint: 'Search products by name or SKU...', controller: _searchCtrl, onChanged: (v) => setState(() => _search = v)),
        ),
        WhStatRow(cards: [
          WhStatCard(label: 'Total Products', value: '${products.length}', sub: 'Active SKUs in warehouse', dotColor: WhColors.blue),
          WhStatCard(label: 'Low Stock', value: '$low', sub: 'Below minimum level', dotColor: WhColors.amber),
          WhStatCard(label: 'Out of Stock', value: '$out', sub: 'Needs reorder now', dotColor: WhColors.red),
        ]),
        WhCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  WhFilterChip(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null)),
                  for (final c in categories) WhFilterChip(label: c, selected: _category == c, onTap: () => setState(() => _category = c)),
                ]),
              ),
              if (filtered.isEmpty)
                const WhEmpty('Try a different search or category', title: 'No products found', icon: Icons.inventory_2_outlined)
              else
                WhTableScroll(
                  minWidth: 760,
                  child: Column(children: [
                    const WhTableHeader(columns: ['Product', 'SKU', 'Current Stock', 'Min Stock', 'Status', 'Actions'], flex: _flex, rightAlignLast: true),
                    for (final p in filtered) _row(p),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _row(Product p) {
    final status = stockStatusOf(p);
    final low = status == 'low_stock';
    final out = status == 'out_of_stock';
    final stockColor = out ? WhColors.red : (low ? WhColors.amber : WhColors.text);
    return WhTableRow(
      flex: _flex,
      rightAlignLast: true,
      highlight: low ? AppTheme.warningLight : null,
      cells: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
          Text(p.category, style: const TextStyle(fontSize: 11, color: WhColors.muted)),
        ]),
        Text(p.sku, style: whMono.copyWith(color: WhColors.muted), overflow: TextOverflow.ellipsis),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${p.currentStock} units', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stockColor)),
          if (low) ...[const SizedBox(width: 4), const Icon(Icons.warning_amber_rounded, size: 14, color: WhColors.amber)],
        ]),
        Text('${p.minStock} units', style: const TextStyle(fontSize: 13, color: WhColors.muted)),
        WhStatusBadge(out ? 'out of stock' : (low ? 'low stock' : 'in stock')),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.end, children: [
          WhStockButton(label: '+ In', color: WhColors.green, onPressed: () => _quickMove(p, true)),
          WhStockButton(label: '− Out', color: WhColors.red, onPressed: () => _quickMove(p, false)),
        ]),
      ],
    );
  }
}
