import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../providers/products_provider.dart';
import '../services/products_service.dart';

const _reasons = ['Delivery', 'Sale', 'Damage', 'Adjustment', 'Return'];

class RecordMovementPanel extends ConsumerStatefulWidget {
  const RecordMovementPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<RecordMovementPanel> createState() => _RecordMovementPanelState();
}

class _RecordMovementPanelState extends ConsumerState<RecordMovementPanel> {
  Product? _selectedProduct;
  bool _isStockIn = true;
  String _reason = _reasons.first;
  final _qtyCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedProduct == null) {
      _snackErr('Please select a product');
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _snackErr('Enter a valid quantity');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = AuthService.instance.getCurrentUser();
      await ref.read(productsServiceProvider).adjustStock(
        productUuid: _selectedProduct!.uuid,
        delta: _isStockIn ? qty : -qty,
        reason: _reason,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        referenceId: _referenceCtrl.text.trim().isEmpty ? null : _referenceCtrl.text.trim(),
        userUuid: user?.uuid ?? '',
        userName: user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Admin',
      );
      widget.onClose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movement recorded')),
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
    final products = ref.watch(productsStreamProvider).value ?? [];

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
                  _sectionLabel('MOVEMENT DETAILS'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Product>(
                    decoration: _dec('Product'),
                    isExpanded: true,
                    initialValue: _selectedProduct,
                    items: products.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.sku} — ${p.name}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (p) => setState(() => _selectedProduct = p),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _typeButton('Stock In', true)),
                    const SizedBox(width: 8),
                    Expanded(child: _typeButton('Stock Out', false)),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: _dec('Quantity'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _reason,
                    decoration: _dec('Reason'),
                    items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _reason = v ?? _reason),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _referenceCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _dec('Reference (e.g. ORD-2401, DEL-001)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: _dec('Notes (optional)'),
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

  Widget _typeButton(String label, bool isIn) {
    final active = _isStockIn == isIn;
    return GestureDetector(
      onTap: () => setState(() => _isStockIn = isIn),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(color: active ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF374151))),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      const Expanded(
        child: Text('Record Movement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
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
              : const Text('Save', style: TextStyle(fontSize: 13)),
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
