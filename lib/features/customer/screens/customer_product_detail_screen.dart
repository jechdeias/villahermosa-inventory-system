import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';
import '../widgets/product_grid_card.dart';

class CustomerProductDetailScreen extends ConsumerStatefulWidget {
  const CustomerProductDetailScreen({super.key, required this.productUuid});
  final String productUuid;

  @override
  ConsumerState<CustomerProductDetailScreen> createState() => _CustomerProductDetailScreenState();
}

class _CustomerProductDetailScreenState extends ConsumerState<CustomerProductDetailScreen> {
  int _qty = 1;

  /// "bottle" from "Per bottle" / "bottle"; falls back to the raw unit.
  String _unitWord(Product p) => p.unit.toLowerCase().replaceFirst('per ', '').trim();

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsStreamProvider).value ?? [];
    Product? product;
    for (final p in products) {
      if (p.uuid == widget.productUuid) product = p;
    }
    final suppliers = ref.watch(supplierNamesProvider);

    return Scaffold(
      backgroundColor: CcColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 28, color: CcColors.text),
                    label: const Text('Shop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CcColors.text)),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, CustomerRoutes.cart, (_) => false),
                    icon: const CartBadgeIcon(size: 28),
                  ),
                ]),
              ),
              const Divider(height: 1, color: CcColors.border),
              if (product == null)
                const Expanded(child: Center(child: Text('This product is no longer available', style: TextStyle(fontSize: 14, color: CcColors.muted))))
              else
                Expanded(child: _body(product, suppliers[product.supplierId] ?? '')),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _body(Product p, String supplier) {
    final inStock = p.currentStock > 0;
    final unit = _unitWord(p);
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ProductImagePlaceholder(name: p.name, height: 200, fontSize: 96),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.sku, style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 12, color: CcColors.light)),
                const SizedBox(height: 4),
                Text(p.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: CcColors.text)),
                if (supplier.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(supplier, style: const TextStyle(fontSize: 16, color: CcColors.muted)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 10, children: [
                      Text(formatPeso(p.unitPrice), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: CcColors.text)),
                      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('per $unit', style: const TextStyle(fontSize: 16, color: CcColors.muted))),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  CcBadge.status(inStock ? 'In Stock' : 'Out of Stock'),
                ]),
              ]),
            ),
            const Divider(height: 1, color: CcColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const CcSectionLabel('Details'),
                CcInfoRows(rows: [
                  (label: 'Unit', value: ccValueText('Per $unit')),
                  (label: 'Qty per case', value: ccValueText('${p.qtyPerCase} ${p.qtyPerCase == 1 ? unit : '${unit}s'}')),
                  (label: 'Category', value: ccValueText(p.category)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
      Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CcColors.border))),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CcColors.text)),
            const Spacer(),
            CcQtyStepper(large: true, value: _qty, onChanged: (v) => setState(() => _qty = v < 1 ? 1 : v)),
          ]),
          const SizedBox(height: 14),
          CcPrimaryButton(
            height: 56,
            label: 'Add to Cart · ${formatPeso(p.unitPrice * _qty)}',
            onPressed: inStock
                ? () {
                    ref.read(cartProvider.notifier).addItem(p, _qty);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $_qty × ${p.name} to your cart')));
                  }
                : null,
          ),
        ]),
      ),
    ]);
  }
}
