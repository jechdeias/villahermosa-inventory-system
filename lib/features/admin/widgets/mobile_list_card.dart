import 'package:flutter/material.dart';

/// Shared mobile card shell for table rows across admin screens: a primary
/// identifier + badge row, an optional muted secondary line, an optional
/// value row (amount/count left, date/detail right), and optional actions.
class MobileListCard extends StatelessWidget {
  const MobileListCard({
    super.key,
    required this.primary,
    this.badge,
    this.secondary,
    this.valueLeft,
    this.valueRight,
    this.actions,
    this.onTap,
  });

  final Widget primary;
  final Widget? badge;
  final Widget? secondary;
  final Widget? valueLeft;
  final Widget? valueRight;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: primary),
                  ?badge,
                ],
              ),
              if (secondary != null) ...[
                const SizedBox(height: 4),
                secondary!,
              ],
              if (valueLeft != null || valueRight != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    valueLeft ?? const SizedBox(),
                    valueRight ?? const SizedBox(),
                  ],
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: actions![i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small muted 12px text, used for the secondary line and value-row details.
class MobileCardMuted extends StatelessWidget {
  const MobileCardMuted(this.text, {super.key, this.overflow = TextOverflow.ellipsis});
  final String text;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        overflow: overflow);
  }
}

/// Full-width outlined action button used in mobile card action rows.
class MobileCardAction extends StatelessWidget {
  const MobileCardAction({super.key, required this.label, this.onPressed, this.color});
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? const Color(0xFF374151),
        side: BorderSide(color: color ?? const Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}
