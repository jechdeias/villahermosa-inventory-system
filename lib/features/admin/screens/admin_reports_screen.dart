import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/reports_provider.dart';
import '../widgets/mobile_list_card.dart';
import '../widgets/orders_stat_card.dart';
import '../../../core/theme/app_theme.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/reports',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              const SizedBox(height: 20),
              _Toolbar(),
              const SizedBox(height: 20),
              _StatsRow(),
              const SizedBox(height: 20),
              _ChartsSection(),
              const SizedBox(height: 20),
              _TopProductsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        SizedBox(height: 4),
        Text('Sales, inventory, and payment insights', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
      ],
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _Toolbar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isNarrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _RangeSelector(),
              const SizedBox(height: 10),
              _ExportButton(),
            ])
          : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _RangeSelector(),
              _ExportButton(),
            ]),
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  static const _labels = {
    ReportsRange.week: 'Week',
    ReportsRange.month: 'Month',
    ReportsRange.quarter: 'Quarter',
    ReportsRange.year: 'Year',
    ReportsRange.all: 'All',
    ReportsRange.custom: 'Custom',
  };

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: ref.read(reportsCustomRangeProvider) ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppTheme.textPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    ref.read(reportsCustomRangeProvider.notifier).state = picked;
    ref.read(reportsRangeProvider.notifier).state = ReportsRange.custom;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportsRangeProvider);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReportsRange.values.map((r) {
          final isActive = r == selected;
          return GestureDetector(
            onTap: () => r == ReportsRange.custom
                ? _pickCustomRange(context, ref)
                : ref.read(reportsRangeProvider.notifier).state = r,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r == ReportsRange.custom) ...[
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: isActive ? Colors.white : AppTheme.textMuted),
                    const SizedBox(width: 4),
                  ],
                  Text(_labels[r]!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.white : AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExportButton extends ConsumerWidget {
  String _csvField(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final orders = ref.read(reportsOrdersProvider);
    final messenger = ScaffoldMessenger.of(context);

    final rows = <List<String>>[
      ['Order Number', 'Date', 'Store', 'Route', 'Sales Rep', 'Status', 'Total Amount'],
      for (final o in orders)
        [
          o.orderNumber,
          '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')}',
          o.storeName ?? '',
          o.routeName ?? '',
          o.salesRepName ?? '',
          o.status,
          o.totalAmount.toStringAsFixed(2),
        ],
    ];
    final csv = rows.map((r) => r.map(_csvField).join(',')).join('\r\n');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'reports_export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsString(csv);
      messenger.showSnackBar(SnackBar(content: Text('Exported ${orders.length} orders to ${file.path}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _export(context, ref),
      icon: const Icon(Icons.file_download_outlined, size: 16),
      label: const Text('Export Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 36),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Stat cards ───────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(reportsStatsProvider);
    final revenue = stats['totalRevenue'] as double;
    final collected = stats['collected'] as double;
    final outstanding = stats['outstanding'] as double;
    final avgOrderValue = stats['avgOrderValue'] as double;
    final growthRate = stats['growthRate'] as double?;

    final growthLabel = growthRate == null
        ? '—'
        : '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';
    final growthColor = growthRate == null
        ? null
        : growthRate >= 0
            ? AppTheme.success
            : AppTheme.error;

    final cards = [
      OrdersStatCard(title: 'Total Revenue', value: _peso(revenue), subtitle: '${stats['orderCount']} orders'),
      OrdersStatCard(title: 'Collected', value: _peso(collected), subtitle: 'Payments received', valueColor: AppTheme.success),
      OrdersStatCard(title: 'Outstanding', value: _peso(outstanding), subtitle: 'Unpaid / partial', valueColor: AppTheme.error),
      OrdersStatCard(title: 'Low Stock Alerts', value: '${stats['lowStockCount']}', subtitle: 'Need restocking', valueColor: AppTheme.warning),
      OrdersStatCard(title: 'Avg Order Value', value: _peso(avgOrderValue), subtitle: 'Per transaction'),
      OrdersStatCard(title: 'Growth Rate', value: growthLabel, subtitle: 'vs. previous period', valueColor: growthColor),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      if (isNarrow) {
        return Column(children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[4]), const SizedBox(width: 12), Expanded(child: cards[5])]),
        ]);
      }
      return Column(children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[4]),
          const SizedBox(width: 12),
          Expanded(child: cards[5]),
        ]),
      ]);
    });
  }

  static String _peso(double v) => v >= 1000 ? '₱${(v / 1000).toStringAsFixed(1)}K' : '₱${v.toStringAsFixed(0)}';
}

// ── Charts ───────────────────────────────────────────────────────────────────

class _ChartsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final charts = [
      _chartCard('Sales Trend (6 months)', _SalesTrendChart()),
      _chartCard('Orders by Status', _OrderStatusChart()),
      _chartCard('Stock by Category', _StockByCategoryChart()),
    ];
    return isNarrow
        ? Column(children: [
            charts[0],
            const SizedBox(height: 14),
            charts[1],
            const SizedBox(height: 14),
            charts[2],
          ])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: charts[0]),
            const SizedBox(width: 14),
            Expanded(child: charts[1]),
            const SizedBox(width: 14),
            Expanded(child: charts[2]),
          ]);
  }

  Widget _chartCard(String title, Widget chart) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            chart,
          ],
        ),
      );
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 160,
        child: Center(
          child: Text('No data for this period', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
        ),
      );
}

class _SalesTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(salesTrendProvider);
    if (points.every((p) => p.total == 0)) return const _EmptyChartState();

    final maxY = points.map((p) => p.total).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].total)],
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 1.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) =>
                    FlDotCirclePainter(radius: 3, color: AppTheme.primary, strokeWidth: 0),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox();
                  return Text(points[idx].label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _OrderStatusChart extends ConsumerWidget {
  static const _palette = [AppTheme.primary, AppTheme.textMuted, Color(0xFFD1D5DB), AppTheme.border, AppTheme.textLight];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(orderStatusBreakdownProvider);
    if (data.isEmpty) return const _EmptyChartState();

    final total = data.fold(0, (s, d) => s + d.count);
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].count.toDouble(),
                    color: _palette[i % _palette.length],
                    radius: 20,
                    showTitle: false,
                  ),
              ],
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(data.length, (i) {
          final d = data[i];
          final pct = total > 0 ? (d.count / total * 100).toStringAsFixed(0) : '0';
          final label = d.status.isEmpty ? d.status : d.status[0].toUpperCase() + d.status.substring(1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text('$label (${d.count})', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted))),
              Text('$pct%', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ]),
          );
        }),
      ],
    );
  }
}

class _StockByCategoryChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(stockByCategoryProvider);
    if (data.isEmpty) return const _EmptyChartState();

    final maxY = data.map((d) => d.stock).reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data[i].stock.toDouble(),
                  color: AppTheme.primary.withValues(alpha: 1 - (i * 0.12).clamp(0, 0.6)),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data[idx].category,
                        style: const TextStyle(fontSize: 9, color: AppTheme.textMuted), textAlign: TextAlign.center),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// ── Top Products ─────────────────────────────────────────────────────────────

class _TopProductsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(topProductsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: const Text('Top Products', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No sales in this period', style: TextStyle(fontSize: 12, color: AppTheme.textLight))),
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(children: products.map((p) => MobileListCard(
                  primary: Text(p.sku,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: AppTheme.monoFamily, color: AppTheme.textPrimary)),
                  secondary: MobileCardMuted(p.name),
                  valueLeft: Text('${p.quantity} sold',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  valueRight: MobileCardMuted('₱${p.revenue.toStringAsFixed(0)}'),
                )).toList());
              }
              return Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(top: BorderSide(color: AppTheme.border), bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 1, child: Text('SKU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 0.5))),
                    Expanded(flex: 3, child: Text('PRODUCT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 0.5))),
                    Expanded(flex: 1, child: Text('QTY SOLD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 0.5))),
                    Expanded(flex: 1, child: Text('REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 0.5))),
                  ]),
                ),
                for (final p in products)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
                    child: Row(children: [
                      Expanded(flex: 1, child: Text(p.sku, style: const TextStyle(fontSize: 12, fontFamily: AppTheme.monoFamily, color: AppTheme.textPrimary))),
                      Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 1, child: Text('${p.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                      Expanded(flex: 1, child: Text('₱${p.revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
                    ]),
                  ),
              ]);
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
