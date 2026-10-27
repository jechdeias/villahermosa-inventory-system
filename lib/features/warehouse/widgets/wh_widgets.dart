import 'package:flutter/material.dart';

/// Design tokens shared by every warehouse screen — same palette as admin.
class WhColors {
  static const sidebar = Color(0xFF1E1E1E);
  static const page = Color(0xFFF4F4F4);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const hover = Color(0xFFFAFAFA);
  static const chip = Color(0xFFF9FAFB);
  static const green = Color(0xFF059669);
  static const amber = Color(0xFFD97706);
  static const red = Color(0xFFDC2626);
  static const blue = Color(0xFF2563EB);
  static const primary = Color(0xFF1E1E1E);
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} hr ago';
  return '${d.inDays} d ago';
}

String formatClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

String formatNumber(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatDate(DateTime t) => '${_months[t.month - 1]} ${t.day}, ${t.year}';
String formatShortDate(DateTime t) => '${_weekdays[t.weekday - 1]}, ${_months[t.month - 1]} ${t.day}';
String weekdayName(DateTime t) => _weekdays[t.weekday - 1];

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

// ── Layout ────────────────────────────────────────────────────────────────────

/// Page scaffold body: scrollable, 24px padding (16px on phones).
class WhPage extends StatelessWidget {
  const WhPage({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 768;
    return ColoredBox(
      color: WhColors.page,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(narrow ? 16 : 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

class WhPageHeader extends StatelessWidget {
  const WhPageHeader({super.key, required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: WhColors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      );
}

/// White surface, 1px border, radius 12.
class WhCard extends StatelessWidget {
  const WhCard({super.key, required this.child, this.padding, this.clip = true});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool clip;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: WhColors.surface,
          border: Border.all(color: WhColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        padding: padding,
        child: child,
      );
}

class WhCardTitle extends StatelessWidget {
  const WhCardTitle(this.title, {super.key, this.trailing, this.padded = true});
  final String title;
  final Widget? trailing;
  final bool padded;

  @override
  Widget build(BuildContext context) => Container(
        padding: padded ? const EdgeInsets.fromLTRB(18, 14, 18, 12) : EdgeInsets.zero,
        decoration: padded ? const BoxDecoration(border: Border(bottom: BorderSide(color: WhColors.border))) : null,
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WhColors.text))),
            ?trailing,
          ],
        ),
      );
}

/// Row of equal-width stat cards that wraps to 2 columns on narrow screens.
class WhStatRow extends StatelessWidget {
  const WhStatRow({super.key, required this.cards, this.bottomGap = 16});
  final List<Widget> cards;
  final double bottomGap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: LayoutBuilder(builder: (context, c) {
          final perRow = c.maxWidth < 560 ? 2 : cards.length;
          final width = (c.maxWidth - 12 * (perRow - 1)) / perRow;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final card in cards) SizedBox(width: width, child: card)],
          );
        }),
      );
}

/// Two columns on wide screens (fixed-width side + flexible main), stacked otherwise.
class WhTwoColumn extends StatelessWidget {
  const WhTwoColumn({super.key, required this.main, required this.side, this.sideWidth = 300, this.sideFirst = false});
  final Widget main;
  final Widget side;
  final double sideWidth;
  final bool sideFirst;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sideFirst ? [side, const SizedBox(height: 16), main] : [main, const SizedBox(height: 16), side],
          );
        }
        final sideBox = SizedBox(width: sideWidth, child: side);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sideFirst
              ? [sideBox, const SizedBox(width: 16), Expanded(child: main)]
              : [Expanded(child: main), const SizedBox(width: 16), sideBox],
        );
      });
}

// ── Stat card (no icon) ───────────────────────────────────────────────────────

class WhStatCard extends StatelessWidget {
  const WhStatCard({super.key, required this.label, required this.value, required this.sub, this.dotColor, this.valueColor});
  final String label;
  final String value;
  final String sub;
  final Color? dotColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: WhColors.surface,
          border: Border.all(color: WhColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: WhColors.muted)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: valueColor ?? WhColors.text)),
            const SizedBox(height: 4),
            Row(
              children: [
                if (dotColor != null) ...[
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                ],
                Expanded(child: Text(sub, style: const TextStyle(fontSize: 10, color: WhColors.muted), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      );
}

// ── Inputs & buttons ──────────────────────────────────────────────────────────

class WhSearchInput extends StatelessWidget {
  const WhSearchInput({super.key, required this.hint, this.controller, this.onChanged});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: WhColors.muted),
            prefixIcon: const Icon(Icons.search, size: 18, color: WhColors.muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WhColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WhColors.primary)),
          ),
        ),
      );
}

class WhFilterButton extends StatelessWidget {
  const WhFilterButton({super.key, required this.onPressed, this.active = false});
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.filter_alt_outlined, size: 16),
        label: const Text('Filter'),
        style: OutlinedButton.styleFrom(
          foregroundColor: WhColors.text,
          backgroundColor: active ? WhColors.chip : Colors.white,
          side: BorderSide(color: active ? WhColors.primary : WhColors.border),
          minimumSize: const Size(0, 36),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}

class WhPrimaryButton extends StatelessWidget {
  const WhPrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.height = 36, this.expand = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: WhColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFD1D5DB),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: Size(expand ? double.infinity : 0, height),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label))
        : ElevatedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 16), label: Text(label));
  }
}

class WhSecondaryButton extends StatelessWidget {
  const WhSecondaryButton({super.key, required this.label, this.icon, this.onPressed, this.height = 36, this.expand = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: WhColors.text,
      backgroundColor: Colors.white,
      side: const BorderSide(color: WhColors.border),
      minimumSize: Size(expand ? double.infinity : 0, height),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 16), label: Text(label));
  }
}

/// Small outlined "+ In" / "− Out" button.
class WhStockButton extends StatelessWidget {
  const WhStockButton({super.key, required this.label, required this.color, required this.onPressed});
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.white,
          side: const BorderSide(color: WhColors.border),
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      );
}

class WhFilterChip extends StatelessWidget {
  const WhFilterChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? WhColors.primary : Colors.white,
            border: Border.all(color: selected ? WhColors.primary : WhColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : WhColors.text)),
        ),
      );
}

class WhActionIconButton extends StatefulWidget {
  const WhActionIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<WhActionIconButton> createState() => _WhActionIconButtonState();
}

class _WhActionIconButtonState extends State<WhActionIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Tooltip(
          message: widget.tooltip,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: _hover ? const Color(0xFFF3F4F6) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
              child: Icon(widget.icon, size: 16, color: WhColors.muted),
            ),
          ),
        ),
      );
}

class WhQuickActionButton extends StatefulWidget {
  const WhQuickActionButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<WhQuickActionButton> createState() => _WhQuickActionButtonState();
}

class _WhQuickActionButtonState extends State<WhQuickActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: _hover ? const Color(0xFFF3F4F6) : WhColors.chip,
              border: Border.all(color: WhColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: WhColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: Icon(widget.icon, size: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: WhColors.text)),
              ],
            ),
          ),
        ),
      );
}

// ── Badges ────────────────────────────────────────────────────────────────────

class WhStatusBadge extends StatelessWidget {
  const WhStatusBadge(this.status, {super.key, this.label});
  final String status;
  final String? label;

  static (Color, Color) _colors(String s) => switch (s.toLowerCase()) {
        'pending' || 'low stock' || 'expired' || 'warning' || 'scheduled' || 'not started' || 'loading' =>
          (const Color(0xFFFFFBEB), const Color(0xFF92400E)),
        'received' || 'ready' || 'completed' || 'in stock' || 'loaded' || 'success' || 'dispatched' =>
          (const Color(0xFFECFDF5), const Color(0xFF065F46)),
        'returned' => (const Color(0xFFF0FDF4), const Color(0xFF166534)),
        'processing' || 'in progress' => (const Color(0xFFEFF6FF), const Color(0xFF1E40AF)),
        'cancelled' || 'out of stock' || 'damaged' || 'error' => (const Color(0xFFFEF2F2), const Color(0xFF991B1B)),
        _ => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    final text = label ?? (status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1));
    // "Scheduled"/"Not started" read as neutral in the mockups.
    final neutral = status == 'scheduled' || status == 'not started';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(color: neutral ? const Color(0xFFF3F4F6) : bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: neutral ? WhColors.muted : fg)),
    );
  }
}

class WhMovementBadge extends StatelessWidget {
  const WhMovementBadge({super.key, required this.isIn});
  final bool isIn;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
        decoration: BoxDecoration(
          color: isIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(isIn ? 'IN' : 'OUT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isIn ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
      );
}

// ── Tables ────────────────────────────────────────────────────────────────────

/// Horizontal-scroll wrapper so wide tables stay readable on narrow windows.
class WhTableScroll extends StatelessWidget {
  const WhTableScroll({super.key, required this.minWidth, required this.child});
  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= minWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: child),
        );
      });
}

class WhTableHeader extends StatelessWidget {
  const WhTableHeader({super.key, required this.columns, required this.flex, this.rightAlignLast = false});
  final List<String> columns;
  final List<int> flex;
  final bool rightAlignLast;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: const BoxDecoration(
          color: WhColors.chip,
          border: Border(top: BorderSide(color: WhColors.border), bottom: BorderSide(color: WhColors.border)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: flex[i],
                child: Text(
                  columns[i].toUpperCase(),
                  textAlign: rightAlignLast && i == columns.length - 1 ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: WhColors.muted, letterSpacing: 0.44),
                ),
              ),
          ],
        ),
      );
}

class WhTableRow extends StatefulWidget {
  const WhTableRow({super.key, required this.cells, required this.flex, this.highlight, this.onTap, this.rightAlignLast = false});
  final List<Widget> cells;
  final List<int> flex;
  final Color? highlight;
  final VoidCallback? onTap;
  final bool rightAlignLast;

  @override
  State<WhTableRow> createState() => _WhTableRowState();
}

class _WhTableRowState extends State<WhTableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _hover ? WhColors.hover : (widget.highlight ?? Colors.transparent),
              border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.cells.length; i++)
                  Expanded(
                    flex: widget.flex[i],
                    child: widget.rightAlignLast && i == widget.cells.length - 1
                        ? Align(alignment: Alignment.centerRight, child: widget.cells[i])
                        : Align(alignment: Alignment.centerLeft, child: widget.cells[i]),
                  ),
              ],
            ),
          ),
        ),
      );
}

/// Card header: title block on the left, actions on the right. Stacks the
/// actions under the title when the card is narrow.
class WhCardHeader extends StatelessWidget {
  const WhCardHeader({super.key, required this.leading, required this.actions});
  final Widget leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
              ],
            );
          }
          return Row(children: [
            Expanded(child: leading),
            for (final a in actions) ...[const SizedBox(width: 10), a],
          ]);
        }),
      );
}

class WhEmpty extends StatelessWidget {
  const WhEmpty(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
        child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: WhColors.muted))),
      );
}

const whMono = TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['Courier New', 'monospace'], fontSize: 12, color: WhColors.text);

// ── Domain-specific rows ──────────────────────────────────────────────────────

class WhPicklistItemRow extends StatelessWidget {
  const WhPicklistItemRow({
    super.key,
    required this.name,
    required this.sku,
    required this.location,
    required this.required,
    required this.available,
    required this.picked,
    required this.onChanged,
  });
  final String name;
  final String sku;
  final String location;
  final int required;
  final int? available;
  final bool picked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final low = available != null && available! < required;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: picked ? WhColors.hover : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Checkbox(
            value: picked,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: WhColors.primary,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: picked ? WhColors.muted : WhColors.text,
                      decoration: picked ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 2),
                Text(sku, style: whMono.copyWith(fontSize: 11, color: WhColors.muted)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(location, style: const TextStyle(fontSize: 12, color: WhColors.muted))),
          Expanded(flex: 2, child: Text('$required units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WhColors.text))),
          Expanded(
            flex: 3,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(available == null ? '—' : '$available units', style: const TextStyle(fontSize: 13, color: WhColors.text)),
                if (low)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Low', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF991B1B))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Queue / route list item: dark when active, white with border otherwise.
class WhRouteCard extends StatelessWidget {
  const WhRouteCard({super.key, required this.title, required this.subtitle, required this.active, required this.onTap, this.badge, this.trailing, this.mono = true});
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final Widget? badge;
  final String? trailing;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? WhColors.primary : Colors.white,
              border: Border.all(color: active ? WhColors.primary : WhColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: (mono ? whMono : const TextStyle()).copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : WhColors.text,
                          )),
                    ),
                    ?badge,
                    if (trailing != null)
                      Text(trailing!, style: TextStyle(fontSize: 11, color: active ? const Color(0xFFD1D5DB) : WhColors.muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: active ? const Color(0xFFD1D5DB) : WhColors.muted)),
              ],
            ),
          ),
        ),
      );
}

/// Dark-on-dark status pill used inside an active [WhRouteCard].
class WhRoutePill extends StatelessWidget {
  const WhRoutePill(this.label, {super.key, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: WhColors.text)),
      );
}

enum WhActivityKind { success, warning, error, info }

class WhActivityLogEntry extends StatelessWidget {
  const WhActivityLogEntry({super.key, required this.kind, required this.title, required this.description, required this.by, this.badge = true});
  final WhActivityKind kind;
  final String title;
  final String description;
  final String by;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label, status) = switch (kind) {
      WhActivityKind.success => (const Color(0xFFECFDF5), WhColors.green, Icons.check, 'Success', 'success'),
      WhActivityKind.warning => (const Color(0xFFFFFBEB), WhColors.amber, Icons.warning_amber_rounded, 'Warning', 'warning'),
      WhActivityKind.error => (const Color(0xFFFEF2F2), WhColors.red, Icons.close, 'Error', 'error'),
      WhActivityKind.info => (const Color(0xFFEFF6FF), WhColors.blue, Icons.info_outline, 'Info', 'processing'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WhColors.text)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                const SizedBox(height: 2),
                Text(by, style: const TextStyle(fontSize: 11, color: WhColors.muted)),
              ],
            ),
          ),
          if (badge) WhStatusBadge(status, label: label),
        ],
      ),
    );
  }
}

/// Compact activity row for the dashboard's Recent Activity card.
class WhRecentActivityRow extends StatelessWidget {
  const WhRecentActivityRow({super.key, required this.icon, required this.iconColor, required this.iconBg, required this.title, required this.subtitle, required this.time});
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: WhColors.muted), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(fontSize: 12, color: WhColors.muted)),
          ],
        ),
      );
}

/// Labelled form field decoration matching the admin panels (h34-ish, radius 8).
InputDecoration whFieldDecoration({String? hint}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: WhColors.muted),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WhColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WhColors.primary)),
    );

class WhFieldLabel extends StatelessWidget {
  const WhFieldLabel(this.label, {super.key, this.optional = false});
  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: WhColors.text)),
          if (optional) const TextSpan(text: ' (optional)', style: TextStyle(fontSize: 12, color: WhColors.muted)),
        ])),
      );
}
