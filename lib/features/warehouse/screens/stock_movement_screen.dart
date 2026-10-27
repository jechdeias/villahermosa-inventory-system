import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseStockMovementScreen extends ConsumerStatefulWidget {
  const WarehouseStockMovementScreen({super.key});

  @override
  ConsumerState<WarehouseStockMovementScreen> createState() => _WarehouseStockMovementScreenState();
}

class _WarehouseStockMovementScreenState extends ConsumerState<WarehouseStockMovementScreen> {
  final _qtyCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isIn = true;
  bool _argsRead = false;
  bool _saving = false;
  String? _productUuid;
  String? _reason;

  List<String> get _reasons => _isIn ? stockInReasons : stockOutReasons;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    // Quick Actions on the dashboard open this screen as 'in' or 'out'.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == 'out') _isIn = false;
    _reason = _reasons.first;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _qtyCtrl.clear();
      _refCtrl.clear();
      _notesCtrl.clear();
      _productUuid = null;
      _reason = _reasons.first;
    });
  }

  void _setType(bool isIn) => setState(() {
        _isIn = isIn;
        _reason = _reasons.first;
      });

  Future<void> _confirm(List<Product> products) async {
    final messenger = ScaffoldMessenger.of(context);
    final qty = int.tryParse(_qtyCtrl.text.trim());
    Product? product;
    for (final p in products) {
      if (p.uuid == _productUuid) product = p;
    }
    if (product == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }
    if (qty == null || qty <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    if (!_isIn && qty > product.currentStock) {
      messenger.showSnackBar(SnackBar(content: Text('Only ${product.currentStock} units in stock')));
      return;
    }
    setState(() => _saving = true);
    try {
      await recordStockMovement(
        ref,
        productUuid: product.uuid,
        delta: _isIn ? qty : -qty,
        reason: _reason ?? _reasons.first,
        notes: _notesCtrl.text,
        reference: _refCtrl.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${_isIn ? 'Stock in' : 'Stock out'} recorded: $qty × ${product.name}')));
      _reset();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsStreamProvider).value ?? [];
    final movements = <StockMovement>[...(ref.watch(stockMovementsStreamProvider).value ?? [])]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return WarehouseShell(
      route: WhRoutes.stockMovement,
      child: WhPage(children: [
        const WhPageHeader(title: 'Stock Movement', subtitle: 'Record stock-in and stock-out operations'),
        WhTwoColumn(
          sideWidth: 300,
          main: _formCard(products),
          side: _recentCard(movements, products),
        ),
      ]),
    );
  }

  Widget _typeButton(String label, IconData icon, bool isIn) {
    final selected = _isIn == isIn;
    return Expanded(
      child: InkWell(
        onTap: () => _setType(isIn),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? WhColors.primary : Colors.white,
            border: Border.all(color: selected ? WhColors.primary : WhColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? Colors.white : WhColors.text),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : WhColors.text)),
          ]),
        ),
      ),
    );
  }

  Widget _formCard(List<Product> products) {
    Product? selected;
    for (final p in products) {
      if (p.uuid == _productUuid) selected = p;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final after = selected == null ? null : selected.currentStock + (_isIn ? qty : -qty);

    return WhCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Record Movement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WhColors.text)),
          const SizedBox(height: 14),
          Row(children: [
            _typeButton('Stock In', Icons.download, true),
            const SizedBox(width: 8),
            _typeButton('Stock Out', Icons.upload, false),
          ]),
          const SizedBox(height: 14),
          const WhFieldLabel('Product'),
          DropdownButtonFormField<String>(
            initialValue: _productUuid,
            isExpanded: true,
            hint: const Text('Select a product', style: TextStyle(fontSize: 13, color: WhColors.muted)),
            decoration: whFieldDecoration(),
            items: [
              for (final p in products)
                DropdownMenuItem(value: p.uuid, child: Text('${p.name} — ${p.sku}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _productUuid = v),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'In stock now: ${selected.currentStock} units${qty > 0 ? ' · after this: $after units' : ''}',
                style: const TextStyle(fontSize: 11, color: WhColors.muted),
              ),
            ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const WhFieldLabel('Quantity'),
                TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: whFieldDecoration(hint: 'e.g. 120')),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const WhFieldLabel('Reason'),
                DropdownButtonFormField<String>(
                  key: ValueKey(_isIn),
                  initialValue: _reason,
                  isExpanded: true,
                  decoration: whFieldDecoration(),
                  items: [for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))],
                  onChanged: (v) => setState(() => _reason = v),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          const WhFieldLabel('Reference Number', optional: true),
          TextField(controller: _refCtrl, decoration: whFieldDecoration(hint: 'Supplier DR number, e.g. DR-58821')),
          const SizedBox(height: 12),
          const WhFieldLabel('Notes'),
          TextField(controller: _notesCtrl, maxLines: 3, decoration: whFieldDecoration(hint: 'Anything the next shift should know')),
          const SizedBox(height: 18),
          WhPrimaryButton(label: _isIn ? 'Confirm Stock In' : 'Confirm Stock Out', height: 44, expand: true, onPressed: _saving ? null : () => _confirm(products)),
          const SizedBox(height: 10),
          WhSecondaryButton(label: 'Cancel', height: 44, expand: true, onPressed: _saving ? null : _reset),
        ],
      ),
    );
  }

  Widget _recentCard(List<StockMovement> movements, List<Product> products) {
    String nameOf(String uuid) {
      for (final p in products) {
        if (p.uuid == uuid) return p.name;
      }
      return 'Unknown product';
    }

    final recent = movements.take(5).toList();
    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WhCardTitle('Recent Movements', trailing: Text('Today', style: TextStyle(fontSize: 12, color: WhColors.muted))),
          if (recent.isEmpty)
            const WhEmpty('No movements recorded yet')
          else
            for (final m in recent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WhMovementBadge(isIn: m.movementType == 'in'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nameOf(m.productId), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${m.movementType == 'in' ? '+' : '−'}${m.quantity} units · ${(m.referenceId ?? '').isNotEmpty ? m.referenceId : m.reason}',
                          style: const TextStyle(fontSize: 11, color: WhColors.muted), overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(timeAgo(m.createdAt), style: const TextStyle(fontSize: 11, color: WhColors.muted)),
                ]),
              ),
        ],
      ),
    );
  }
}
