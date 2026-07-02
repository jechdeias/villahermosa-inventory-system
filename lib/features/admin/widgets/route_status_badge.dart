import 'package:flutter/material.dart';

class RouteStatusBadge extends StatelessWidget {
  const RouteStatusBadge({super.key, required this.status});
  final String status;

  static _Style _styleFor(String s) => switch (s) {
    'active'   => const _Style(bg: Color(0xFFECFDF5), text: Color(0xFF065F46), label: 'Active'),
    'on_hold'  => const _Style(bg: Color(0xFFFFFBEB), text: Color(0xFF92400E), label: 'On Hold'),
    'inactive' => const _Style(bg: Color(0xFFF3F4F6), text: Color(0xFF6B7280), label: 'Inactive'),
    _          => const _Style(bg: Color(0xFFF3F4F6), text: Color(0xFF6B7280), label: 'Unknown'),
  };

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(s.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: s.text)),
    );
  }
}

class _Style {
  const _Style({required this.bg, required this.text, required this.label});
  final Color bg;
  final Color text;
  final String label;
}
