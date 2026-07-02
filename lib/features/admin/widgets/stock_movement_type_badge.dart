import 'package:flutter/material.dart';

class StockMovementTypeBadge extends StatelessWidget {
  const StockMovementTypeBadge({super.key, required this.movementType});
  final String movementType;

  @override
  Widget build(BuildContext context) {
    final isIn = movementType == 'in';
    final bg = isIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final text = isIn ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, size: 12, color: text),
          const SizedBox(width: 4),
          Text(isIn ? 'Stock In' : 'Stock Out',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: text)),
        ],
      ),
    );
  }
}
