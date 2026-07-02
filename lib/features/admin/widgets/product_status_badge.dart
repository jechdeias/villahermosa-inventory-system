import 'package:flutter/material.dart';

/// Derives an In Stock / Low Stock / Out of Stock pill from live stock counts
/// (not a stored status string).
class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({super.key, required this.currentStock, required this.minStock});
  final int currentStock;
  final int minStock;

  @override
  Widget build(BuildContext context) {
    final _Style style;
    final String label;
    if (currentStock <= 0) {
      style = const _Style(bg: Color(0xFFFEF2F2), text: Color(0xFF991B1B));
      label = 'Out of Stock';
    } else if (currentStock <= minStock) {
      style = const _Style(bg: Color(0xFFFFFBEB), text: Color(0xFF92400E));
      label = 'Low Stock';
    } else {
      style = const _Style(bg: Color(0xFFECFDF5), text: Color(0xFF065F46));
      label = 'In Stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: style.text)),
    );
  }
}

class _Style {
  const _Style({required this.bg, required this.text});
  final Color bg;
  final Color text;
}
