import 'package:flutter/material.dart';

class CustomerChannelBadge extends StatelessWidget {
  const CustomerChannelBadge({super.key, required this.channel});
  final String channel;

  static const Map<String, _Style> _styles = {
    'Sari-Sari Store': _Style(bg: Color(0xFFF3F4F6), text: Color(0xFF374151)),
    'Mini Mart': _Style(bg: Color(0xFFEFF6FF), text: Color(0xFF1E40AF)),
    'Grocery Store': _Style(bg: Color(0xFFF0FDF4), text: Color(0xFF166534)),
    'Supermarket': _Style(bg: Color(0xFFFDF4FF), text: Color(0xFF7C3AED)),
    'Wholesaler': _Style(bg: Color(0xFFFFF7ED), text: Color(0xFFC2410C)),
  };

  static const _fallback = _Style(bg: Color(0xFFF3F4F6), text: Color(0xFF374151));

  @override
  Widget build(BuildContext context) {
    final style = _styles[channel] ?? _fallback;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(channel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: style.text)),
    );
  }
}

class _Style {
  const _Style({required this.bg, required this.text});
  final Color bg;
  final Color text;
}
