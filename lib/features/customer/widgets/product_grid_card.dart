import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import 'customer_common.dart';
import '../../../core/theme/app_theme.dart';

/// First letter of a product's name, for the photo placeholder. Names that
/// start with a number ("24 Seven Lemon Ice Tea") use their first letter
/// ("S"), not the digit; a name with no letters at all falls back to its
/// first character.
String productInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final letter = RegExp(r'\p{L}', unicode: true).firstMatch(trimmed);
  return (letter?.group(0) ?? trimmed[0]).toUpperCase();
}

/// Big initial letter on a grey tile — stands in for a product photo.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key, required this.name, required this.height, this.fontSize = 56});
  final String name;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        color: CcColors.imageBg,
        alignment: Alignment.center,
        child: Text(
          productInitial(name),
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: CcColors.muted),
        ),
      );
}

class ProductGridCard extends StatelessWidget {
  const ProductGridCard({super.key, required this.product, required this.supplierName, required this.inCart, required this.onTap, required this.onAdd});
  final Product product;
  final String supplierName;
  final int inCart;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final inStock = product.currentStock > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: CcColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImagePlaceholder(name: product.name, height: 120),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CcColors.text, height: 1.25)),
                    const SizedBox(height: 2),
                    Text(supplierName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CcColors.light)),
                    const Spacer(),
                    Row(children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatPeso(product.unitPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CcColors.text)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: CcBadge.status(inStock ? 'In Stock' : 'Out of Stock'))),
                    ]),
                    SizedBox(
                      height: 18,
                      child: inCart > 0
                          ? Align(alignment: Alignment.centerLeft, child: Text('$inCart in cart', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CcColors.green)))
                          : null,
                    ),
                    SizedBox(
                      height: 36,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: inStock ? onAdd : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CcColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.border,
                          disabledForegroundColor: CcColors.light,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(inStock ? '+ Add' : 'Unavailable'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
