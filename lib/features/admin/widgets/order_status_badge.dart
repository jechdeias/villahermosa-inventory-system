import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;

  static _Style _styleFor(String s) => switch (s) {
    'pending'   => const _Style(bg: Color(0xFFFFFBEB), text: Color(0xFF92400E), icon: Icons.access_time),
    'completed' => const _Style(bg: Color(0xFFECFDF5), text: Color(0xFF065F46), icon: Icons.check_circle_outline),
    'cancelled' => const _Style(bg: Color(0xFFFEF2F2), text: Color(0xFF991B1B), icon: Icons.cancel_outlined),
    _           => const _Style(bg: Color(0xFFF3F4F6), text: Color(0xFF6B7280), icon: Icons.help_outline),
  };

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(status);
    final label = status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 12, color: s.text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: s.text),
          ),
        ],
      ),
    );
  }
}

class _Style {
  const _Style({required this.bg, required this.text, required this.icon});
  final Color bg;
  final Color text;
  final IconData icon;
}
