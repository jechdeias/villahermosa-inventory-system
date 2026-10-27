import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Generic shimmer placeholder block.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppTheme.border,
        highlightColor: const Color(0xFFF9FAFB),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(borderRadius)),
        ),
      );
}

/// Placeholder shaped like a stat card (label / value / sub).
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerBox(width: 80, height: 10, borderRadius: 4),
            SizedBox(height: 10),
            ShimmerBox(width: 56, height: 22, borderRadius: 4),
            SizedBox(height: 10),
            ShimmerBox(width: 110, height: 9, borderRadius: 4),
          ],
        ),
      );
}

/// Placeholder shaped like a table row.
class ShimmerTableRow extends StatelessWidget {
  const ShimmerTableRow({super.key, this.columns = 5});
  final int columns;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
        child: Row(
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(
                flex: i == 1 ? 3 : 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerBox(width: i == columns - 1 ? 56 : double.infinity, height: 12, borderRadius: 4),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Placeholder shaped like a mobile list card.
class ShimmerListCard extends StatelessWidget {
  const ShimmerListCard({super.key, this.height = 92});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: const Row(
          children: [
            ShimmerBox(width: 44, height: 44, borderRadius: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 13, borderRadius: 4),
                  SizedBox(height: 10),
                  ShimmerBox(width: 100, height: 10, borderRadius: 4),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerBox(width: 54, height: 18, borderRadius: 4),
          ],
        ),
      );
}

/// A whole loading page: optional stat cards, then a card of table rows.
/// Screens show this in place of their content while a stream's first value
/// is still loading.
class ShimmerTablePage extends StatelessWidget {
  const ShimmerTablePage({super.key, this.statCards = 4, this.rows = 6, this.columns = 5, this.padding = const EdgeInsets.all(AppTheme.spacing2XL)});
  final int statCards;
  final int rows;
  final int columns;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (statCards > 0) ...[
              LayoutBuilder(builder: (context, c) {
                final perRow = c.maxWidth < 560 ? 2 : statCards;
                final width = (c.maxWidth - 12 * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [for (var i = 0; i < statCards; i++) SizedBox(width: width, child: const ShimmerStatCard())],
                );
              }),
              const SizedBox(height: AppTheme.spacingXL),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [for (var i = 0; i < rows; i++) ShimmerTableRow(columns: columns)]),
            ),
          ],
        ),
      );
}

/// A whole loading page of mobile list cards.
class ShimmerCardList extends StatelessWidget {
  const ShimmerCardList({super.key, this.count = 5, this.cardHeight = 92, this.padding = const EdgeInsets.all(AppTheme.spacingLG)});
  final int count;
  final double cardHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: AppTheme.spacingMD),
              ShimmerListCard(height: cardHeight),
            ],
          ],
        ),
      );
}

/// True until an async provider has produced its first value — the moment to
/// show shimmer placeholders. Refreshes that already have data are not
/// "first load", so content never flickers back to shimmer.
bool isFirstLoad(AsyncValue<Object?> value) => value.isLoading && !value.hasValue;
