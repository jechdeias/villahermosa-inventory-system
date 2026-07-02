import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/products_provider.dart';
import 'product_status_badge.dart';

class ProductDetailPanel extends ConsumerWidget {
  const ProductDetailPanel({super.key, required this.product, required this.onClose});
  final Product product;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierName = ref.watch(supplierNameProvider(product.supplierId));

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection('PRODUCT INFO', [
                    _row('SKU', Text(product.sku,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
                    _row('Name', Text(product.name, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Category', Text(product.category, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Supplier', Text(supplierName, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Status', ProductStatusBadge(currentStock: product.currentStock, minStock: product.minStock)),
                  ]),
                  _buildSection('STOCK & PRICING', [
                    _row('Current Stock', Text('${product.currentStock} ${product.unit}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Min Stock', Text('${product.minStock} ${product.unit}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Qty per Case', Text('${product.qtyPerCase}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _row('Unit Price', Text('₱${product.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
                    _row('Cost Price', Text('₱${product.costPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                  ]),
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
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(child: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
      GestureDetector(onTap: onClose, child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
    ]),
  );

  Widget _buildSection(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
        const SizedBox(height: 12),
        ...rows,
      ],
    ),
  );

  Widget _row(String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Expanded(child: value),
      ],
    ),
  );

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
    child: OutlinedButton(
      onPressed: onClose,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        foregroundColor: const Color(0xFF374151),
        padding: const EdgeInsets.symmetric(vertical: 10),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: const Text('Close', style: TextStyle(fontSize: 13)),
    ),
  );
}
