import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Palette shared by every customer screen.
class CcColors {
  static const page = Color(0xFFF3F4F6);
  static const surface = Colors.white;
  static const border = AppTheme.border;
  static const text = AppTheme.textPrimary;
  static const body = Color(0xFF374151);
  static const muted = AppTheme.textMuted;
  static const light = AppTheme.textLight;
  static const primary = AppTheme.primary;
  static const green = AppTheme.success;
  static const red = AppTheme.error;
  static const amber = Color(0xFFB45309);
  static const blue = AppTheme.info;
  static const imageBg = Color(0xFFEDEEF0);
}

/// ₱1,752 — whole pesos without decimals, otherwise two decimals.
String formatPeso(num value) {
  final negative = value < 0;
  final v = value.abs();
  final whole = v.truncate();
  final hasCents = (v - whole).abs() > 0.004;
  final digits = whole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final cents = hasCents ? '.${((v - whole) * 100).round().toString().padLeft(2, '0')}' : '';
  return '${negative ? '-' : ''}₱$buf$cents';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _longMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _longWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String ccShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}'; // Oct 26
String ccFullDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}'; // Oct 26, 2026
String ccWeekdayShort(DateTime d) => '${_weekdays[d.weekday - 1]}, ${ccShortDate(d)}'; // Thu, Oct 29
String ccWeekdayLong(DateTime d) => '${_longWeekdays[d.weekday - 1]}, ${ccShortDate(d)}'; // Thursday, Oct 29
String ccLongFullDate(DateTime d) => '${_longWeekdays[d.weekday - 1]}, ${ccFullDate(d)}'; // Saturday, Oct 24, 2026
String ccMonthYear(DateTime d) => '${_longMonths[d.month - 1]} ${d.year}'; // March 2023

/// 10:12 AM
String ccTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

bool ccSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today, Oct 26" when it's today, otherwise "Thu, Oct 29".
String ccDeliveryDay(DateTime d) => ccSameDay(d, DateTime.now()) ? 'Today, ${ccShortDate(d)}' : ccWeekdayShort(d);

class CcCard extends StatelessWidget {
  const CcCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 12});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: CcColors.surface,
          border: Border.all(color: CcColors.border),
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: padding,
        child: child,
      );
}

class CcBadge extends StatelessWidget {
  const CcBadge(this.label, {super.key, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  /// Badge styled from a status word (In Stock, Processing, Collected, ...).
  factory CcBadge.status(String label) {
    final (bg, fg) = switch (label.toLowerCase()) {
      'in stock' || 'delivered' || 'collected' || 'paid' => (AppTheme.successLight, const Color(0xFF065F46)),
      'out of stock' || 'unpaid' => (AppTheme.errorLight, const Color(0xFFB91C1C)),
      'processing' || 'partial' => (AppTheme.infoLight, const Color(0xFF1D4ED8)),
      'out for delivery' || 'pending' => (AppTheme.warningLight, const Color(0xFFB45309)),
      'cancelled' => (const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
      _ => (const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
    };
    return CcBadge(label, bg: bg, fg: fg);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

/// − [ n ] + stepper; [large] gives the 48px touch targets of the product page.
class CcQtyStepper extends StatelessWidget {
  const CcQtyStepper({super.key, required this.value, required this.onChanged, this.large = false});
  final int value;
  final ValueChanged<int> onChanged;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final h = large ? 48.0 : 40.0;
    Widget btn(IconData icon, VoidCallback onTap, String label) => Semantics(
          label: label,
          button: true,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: large ? 48 : 40, height: h, child: Icon(icon, size: large ? 22 : 18, color: CcColors.text)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: CcColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove, () => onChanged(value - 1), 'Decrease quantity'),
        Container(
          width: large ? 64 : 48,
          height: h,
          alignment: Alignment.center,
          color: Colors.white,
          child: Text('$value', style: TextStyle(fontSize: large ? 18 : 15, fontWeight: FontWeight.w600, color: CcColors.text)),
        ),
        btn(Icons.add, () => onChanged(value + 1), 'Increase quantity'),
      ]),
    );
  }
}

class CcPrimaryButton extends StatelessWidget {
  const CcPrimaryButton({super.key, required this.label, required this.onPressed, this.height = 48, this.expand = true, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: CcColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFD1D5DB),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: Size(expand ? double.infinity : 0, height),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label, overflow: TextOverflow.ellipsis))
        : ElevatedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 18), label: Text(label));
  }
}

/// Section label like "DETAILS" / "HOW WILL YOU PAY?".
class CcSectionLabel extends StatelessWidget {
  const CcSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CcColors.muted, letterSpacing: 0.8)),
      );
}

/// Label on the left, value on the right, hairline divider between rows.
class CcInfoRows extends StatelessWidget {
  const CcInfoRows({super.key, required this.rows});
  final List<({String label, Widget value})> rows;

  @override
  Widget build(BuildContext context) => CcCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final (i, r) in rows.indexed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: CcColors.border))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(r.label, style: const TextStyle(fontSize: 14, color: CcColors.muted)),
                const SizedBox(width: 16),
                Expanded(child: Align(alignment: Alignment.centerRight, child: r.value)),
              ]),
            ),
        ]),
      );
}

Widget ccValueText(String v, {Color color = CcColors.text}) =>
    Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color));

/// White page title bar used by the tab screens (no back arrow).
class CcTitleBar extends StatelessWidget {
  const CcTitleBar({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: CcColors.border))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CcColors.text)),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      );
}
