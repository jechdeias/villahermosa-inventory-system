import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      'paid'    => (AppTheme.successLight, const Color(0xFF065F46), Icons.check_circle_outline,      'Paid'),
      'partial' => (AppTheme.warningLight, const Color(0xFF92400E), Icons.access_time,               'Partial'),
      'unpaid'  => (AppTheme.errorLight, const Color(0xFF991B1B), Icons.error_outline,             'Unpaid'),
      'credit'  => (AppTheme.infoLight, const Color(0xFF1E40AF), Icons.calendar_today_outlined,   'On Credit'),
      _         => (const Color(0xFFF3F4F6), AppTheme.textMuted, Icons.help_outline,              status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}
