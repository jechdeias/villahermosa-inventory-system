import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseReturnsScreen extends ConsumerStatefulWidget {
  const WarehouseReturnsScreen({super.key});

  @override
  ConsumerState<WarehouseReturnsScreen> createState() => _WarehouseReturnsScreenState();
}

class _WarehouseReturnsScreenState extends ConsumerState<WarehouseReturnsScreen> {
  static const _flex = [2, 5, 2, 4, 2, 3, 2];
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logReturn() async {
    final products = ref.read(productsStreamProvider).value ?? [];
    final qtyCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'returned';
    String? productUuid;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Log New Return', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const WhFieldLabel('Type'),
                Wrap(spacing: 8, children: [
                  for (final t in const ['returned', 'damaged', 'expired'])
                    WhFilterChip(label: t[0].toUpperCase() + t.substring(1), selected: type == t, onTap: () => setLocal(() => type = t)),
                ]),
                const SizedBox(height: 12),
                const WhFieldLabel('Product'),
                DropdownButtonFormField<String>(
                  initialValue: productUuid,
                  isExpanded: true,
                  decoration: whFieldDecoration(),
                  hint: const Text('Select a product', style: TextStyle(fontSize: 13, color: WhColors.muted)),
                  items: [for (final p in products) DropdownMenuItem(value: p.uuid, child: Text('${p.name} — ${p.sku}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setLocal(() => productUuid = v),
                ),
                const SizedBox(height: 12),
                const WhFieldLabel('Quantity'),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: whFieldDecoration(hint: 'e.g. 12')),
                const SizedBox(height: 12),
                const WhFieldLabel('Source', optional: true),
                TextField(controller: sourceCtrl, decoration: whFieldDecoration(hint: 'e.g. Route 1 · Store name, or DR number')),
                const SizedBox(height: 12),
                const WhFieldLabel('What happened', optional: true),
                TextField(controller: notesCtrl, maxLines: 2, decoration: whFieldDecoration(hint: 'e.g. Crushed case during unloading')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: WhColors.muted))),
            WhPrimaryButton(
              label: 'Log Return',
              onPressed: () {
                final q = int.tryParse(qtyCtrl.text.trim());
                if (productUuid == null || q == null || q <= 0) return;
                Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    final qty = int.tryParse(qtyCtrl.text.trim());
    final source = sourceCtrl.text;
    final notes = notesCtrl.text;
    qtyCtrl.dispose();
    sourceCtrl.dispose();
    notesCtrl.dispose();
    if (ok != true || qty == null || productUuid == null) return;

    // Returns add stock back; damaged/expired stock is written off.
    final reason = returnReasons.entries.firstWhere((e) => e.value == type).key;
    await recordStockMovement(
      ref,
      productUuid: productUuid!,
      delta: type == 'returned' ? qty : -qty,
      reason: reason,
      notes: notes,
      reference: source,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return logged')));
  }

  Future<void> _view(StockMovement m, String productName) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(returnId(m), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kv('Product', productName),
            _kv('Quantity', '${m.quantity} units'),
            _kv('Type', returnTypeOf(m) ?? m.reason),
            _kv('Source', (m.referenceId ?? '').isEmpty ? '—' : m.referenceId!),
            _kv('Notes', (m.notes ?? '').isEmpty ? '—' : m.notes!),
            _kv('Logged by', m.userName),
            _kv('Date', formatDate(m.createdAt)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: WhColors.muted)))],
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(fontSize: 12, color: WhColors.muted))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, color: WhColors.text))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (isFirstLoad(ref.watch(stockMovementsStreamProvider))) return const WhLoadingShell(route: WhRoutes.returns, statCards: 3);
    final products = ref.watch(productsStreamProvider).value ?? [];
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final all = (ref.watch(stockMovementsStreamProvider).value ?? []).where((m) => returnTypeOf(m) != null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    String nameOf(String uuid) {
      for (final p in products) {
        if (p.uuid == uuid) return p.name;
      }
      return 'Unknown product';
    }

    final week = all.where((m) => m.createdAt.isAfter(weekAgo)).toList();
    final damaged = week.where((m) => returnTypeOf(m) == 'damaged').length;
    final units = week.fold<int>(0, (s, m) => s + m.quantity);

    final q = _search.toLowerCase();
    final shown = all.where((m) {
      if (q.isEmpty) return true;
      return returnId(m).toLowerCase().contains(q) ||
          nameOf(m.productId).toLowerCase().contains(q) ||
          (m.referenceId ?? '').toLowerCase().contains(q) ||
          (m.notes ?? '').toLowerCase().contains(q);
    }).toList();

    return WarehouseShell(
      route: WhRoutes.returns,
      child: WhPage(children: [
        const WhPageHeader(title: 'Returns & Damaged', subtitle: 'Log customer returns, damaged and expired stock · this week'),
        WhStatRow(cards: [
          WhStatCard(label: 'Total Returns', value: '${week.length}', sub: 'Logged this week', dotColor: WhColors.blue),
          WhStatCard(label: 'Damaged Items', value: '$damaged', sub: 'Written off, not resellable', dotColor: WhColors.red),
          WhStatCard(label: 'Total Units', value: '$units', sub: 'Units across all returns', dotColor: WhColors.amber),
        ]),
        WhCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: WhSearchInput(hint: 'Search returns, products, stores...', controller: _searchCtrl, onChanged: (v) => setState(() => _search = v))),
                  const SizedBox(width: 10),
                  WhPrimaryButton(label: '+ Log New Return', onPressed: _logReturn),
                ]),
              ),
              if (shown.isEmpty)
                const WhEmpty('Use Log New Return when stock comes back, is damaged or expires', title: 'No returns logged yet', icon: Icons.history)
              else
                WhTableScroll(
                  minWidth: 820,
                  child: Column(children: [
                    const WhTableHeader(columns: ['Return ID', 'Product', 'Quantity', 'Source', 'Type', 'Date', 'Actions'], flex: _flex, rightAlignLast: true),
                    for (final m in shown.take(50))
                      WhTableRow(
                        flex: _flex,
                        rightAlignLast: true,
                        cells: [
                          Text(returnId(m), style: whMono),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(nameOf(m.productId), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
                            if ((m.notes ?? '').isNotEmpty) Text(m.notes!, style: const TextStyle(fontSize: 11, color: WhColors.muted), overflow: TextOverflow.ellipsis),
                          ]),
                          Text('${m.quantity} units', style: const TextStyle(fontSize: 13, color: WhColors.text)),
                          Text((m.referenceId ?? '').isEmpty ? '—' : m.referenceId!, style: const TextStyle(fontSize: 13, color: WhColors.muted), overflow: TextOverflow.ellipsis),
                          WhStatusBadge(returnTypeOf(m)!),
                          Text(formatDate(m.createdAt), style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                          WhActionIconButton(icon: Icons.visibility_outlined, tooltip: 'View', onPressed: () => _view(m, nameOf(m.productId))),
                        ],
                      ),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Showing ${shown.length > 50 ? 50 : shown.length} of ${shown.length} returns', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
