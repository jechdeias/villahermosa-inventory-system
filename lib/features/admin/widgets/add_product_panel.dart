import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../providers/products_provider.dart';
import '../services/products_service.dart';

class AddProductPanel extends ConsumerStatefulWidget {
  const AddProductPanel({super.key, required this.onClose, this.editing});
  final VoidCallback onClose;
  final Product? editing;

  @override
  ConsumerState<AddProductPanel> createState() => _AddProductPanelState();
}

class _AddProductPanelState extends ConsumerState<AddProductPanel> {
  late final _skuCtrl = TextEditingController(text: widget.editing?.sku ?? '');
  late final _nameCtrl = TextEditingController(text: widget.editing?.name ?? '');
  late final _categoryCtrl = TextEditingController(text: widget.editing?.category ?? '');
  late final _unitCtrl = TextEditingController(text: widget.editing?.unit ?? 'pcs');
  late final _qtyPerCaseCtrl = TextEditingController(text: '${widget.editing?.qtyPerCase ?? 1}');
  late final _unitPriceCtrl = TextEditingController(text: widget.editing != null ? '${widget.editing!.unitPrice}' : '');
  late final _costPriceCtrl = TextEditingController(text: widget.editing != null ? '${widget.editing!.costPrice}' : '');
  late final _minStockCtrl = TextEditingController(text: '${widget.editing?.minStock ?? 0}');
  late final _initialStockCtrl = TextEditingController(text: '0');
  int? _supplierId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _supplierId = widget.editing?.supplierId;
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _unitCtrl.dispose();
    _qtyPerCaseCtrl.dispose();
    _unitPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _minStockCtrl.dispose();
    _initialStockCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.editing != null;

  Future<void> _save() async {
    if (_skuCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      _snackErr('Product code and description are required');
      return;
    }
    final unitPrice = double.tryParse(_unitPriceCtrl.text.trim());
    if (unitPrice == null) {
      _snackErr('Enter a valid unit price');
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(productsServiceProvider);
      final companion = ProductsCompanion(
        sku: Value(_skuCtrl.text.trim()),
        name: Value(_nameCtrl.text.trim()),
        category: Value(_categoryCtrl.text.trim().isEmpty ? 'Others' : _categoryCtrl.text.trim()),
        unitPrice: Value(unitPrice),
        costPrice: Value(double.tryParse(_costPriceCtrl.text.trim()) ?? 0),
        unit: Value(_unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim()),
        minStock: Value(int.tryParse(_minStockCtrl.text.trim()) ?? 0),
        supplierId: Value(_supplierId),
        qtyPerCase: Value(int.tryParse(_qtyPerCaseCtrl.text.trim()) ?? 1),
      );

      if (_isEditing) {
        await service.updateProduct(widget.editing!.uuid, companion);
      } else {
        await service.createProduct(companion.copyWith(
          uuid: Value(const Uuid().v4()),
          currentStock: Value(int.tryParse(_initialStockCtrl.text.trim()) ?? 0),
        ));
      }

      widget.onClose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Product updated' : 'Product added')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snackErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersStreamProvider).value ?? [];

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
                  _sectionLabel('PRODUCT INFO'),
                  const SizedBox(height: 10),
                  TextField(controller: _skuCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Product Code')),
                  const SizedBox(height: 10),
                  TextField(controller: _nameCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Item Description')),
                  const SizedBox(height: 10),
                  TextField(controller: _categoryCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Category (e.g. Beverages, Food)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int?>(
                    decoration: _dec('Supplier'),
                    isExpanded: true,
                    initialValue: _supplierId,
                    items: suppliers.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.tradeName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setState(() => _supplierId = v),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('PRICING & UNITS'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: _unitCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Unit (pcs, cs)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _qtyPerCaseCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 13), decoration: _dec('Qty per Case'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: _unitPriceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13), decoration: _dec('Unit Price').copyWith(prefixText: '₱'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _costPriceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13), decoration: _dec('Cost Price').copyWith(prefixText: '₱'))),
                  ]),
                  const SizedBox(height: 20),
                  _sectionLabel('STOCK'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: _minStockCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 13), decoration: _dec('Min Stock (reorder level)'))),
                    if (!_isEditing) ...[
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _initialStockCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 13), decoration: _dec('Initial Stock'))),
                    ],
                  ]),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Use the +/- actions on the product row to adjust stock.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
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
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(
        child: Text(_isEditing ? 'Edit Product' : 'Add Product',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ),
      GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
    ]),
  );

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _saving ? null : widget.onClose,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            foregroundColor: const Color(0xFF374151),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Product', style: TextStyle(fontSize: 13)),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6B7280))),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  );
}
