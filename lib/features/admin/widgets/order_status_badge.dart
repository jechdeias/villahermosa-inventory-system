import 'package:flutter/material.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/theme/app_theme.dart';

/// Status pill for an order; handles all six statuses.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;

  static _Style _styleFor(String s) => switch (s) {
        OrderStatus.pending => const _Style(bg: Color(0xFFFFFBEB), text: Color(0xFF92400E), icon: Icons.access_time_outlined),
        OrderStatus.processing => const _Style(bg: Color(0xFFEFF6FF), text: Color(0xFF1E40AF), icon: Icons.settings_outlined),
        OrderStatus.outForDelivery => const _Style(bg: Color(0xFFF5F3FF), text: Color(0xFF6D28D9), icon: Icons.local_shipping_outlined),
        OrderStatus.delivered => const _Style(bg: Color(0xFFF0FDFA), text: Color(0xFF0F766E), icon: Icons.check_circle_outline),
        OrderStatus.completed => const _Style(bg: Color(0xFFECFDF5), text: Color(0xFF065F46), icon: Icons.verified_outlined),
        OrderStatus.cancelled => const _Style(bg: Color(0xFFFEF2F2), text: Color(0xFF991B1B), icon: Icons.cancel_outlined),
        _ => const _Style(bg: Color(0xFFF3F4F6), text: AppTheme.textMuted, icon: Icons.help_outline),
      };

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(status);
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
            OrderStatus.label(status),
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
