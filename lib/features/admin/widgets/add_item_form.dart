import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/orders_provider.dart';

class AddItemForm extends ConsumerStatefulWidget {
  const AddItemForm({super.key, required this.onAdd});
  final void Function(String productName, int quantity, double unitPrice) onAdd;

  @override
  ConsumerState<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends ConsumerState<AddItemForm> {
  bool _showForm = false;
  Product? _selectedProduct;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _subtotal {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  void _addItem() {
    final product = _selectedProduct;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (product == null || qty <= 0 || price <= 0) return;
    widget.onAdd(product.name, qty, price);
    setState(() {
      _showForm = false;
      _selectedProduct = null;
      _qtyCtrl.text = '1';
      _priceCtrl.clear();
    });
  }

  void _cancelForm() => setState(() {
        _showForm = false;
        _selectedProduct = null;
        _qtyCtrl.text = '1';
        _priceCtrl.clear();
      });

  @override
  Widget build(BuildContext context) {
    if (!_showForm) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _showForm = true),
        icon: const Icon(Icons.add, size: 14),
        label: const Text('Add Item'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF374151),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size(double.infinity, 36),
          textStyle: const TextStyle(fontSize: 13),
        ),
      );
    }

    final products = ref.watch(productsProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Product>(
            value: _selectedProduct, // ignore: deprecated_member_use
            decoration: _dec('Product'),
            isExpanded: true,
            items: products.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (p) => setState(() {
              _selectedProduct = p;
              if (p != null) _priceCtrl.text = p.unitPrice.toStringAsFixed(0);
            }),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: _dec('Qty'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13),
                decoration: _dec('Unit Price'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Text('Subtotal: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            Text(
              '₱${_subtotal.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelForm,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  foregroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Add Item'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF374151))),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        filled: true,
        fillColor: Colors.white,
      );
}
