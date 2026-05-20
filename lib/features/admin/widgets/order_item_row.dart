import 'package:flutter/material.dart';

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.onRemove,
  });
  final String productName;
  final int quantity;
  final double unitPrice;
  final VoidCallback onRemove;

  double get subtotal => quantity * unitPrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '$quantity × ₱${unitPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Text(
            '₱${_fmt(subtotal)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final n = v.round().toString();
    final buf = StringBuffer();
    final mod = n.length % 3;
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (i - mod) % 3 == 0) buf.write(',');
      buf.write(n[i]);
    }
    return buf.toString();
  }
}
