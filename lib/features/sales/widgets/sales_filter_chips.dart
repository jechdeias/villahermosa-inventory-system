import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Horizontally scrolling filter pills ("All (3)", "Pending (1)", ...).
///
/// The row is as tall as its pills need — it is NOT a fixed-height box. The
/// previous version put a horizontal ListView with its own vertical padding
/// inside `SizedBox(height: 40)`, and each pill added 16px of padding on top:
/// 40 − 16 − 16 left 8px for a 12px label (about 15px of line), so every label
/// was clipped by roughly half — and with a larger system font any fixed height
/// clips again. A horizontal SingleChildScrollView sizes to its content, so the
/// row grows with the text scale.
class SalesFilterChips extends StatelessWidget {
  const SalesFilterChips({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.verticalPadding = 8,
  });

  /// (value, label, count)
  final List<(String, String, int)> tabs;
  final String selected;
  final ValueChanged<String> onSelected;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
        child: Row(children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Chip(
              label: '${tabs[i].$2} (${tabs[i].$3})',
              active: selected == tabs[i].$1,
              onTap: () => onSelected(tabs[i].$1),
            ),
          ],
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // The pill's own padding is what gives it its shape; the row sizes to it.
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      );
}
