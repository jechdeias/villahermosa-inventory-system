import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseReportsScreen extends ConsumerWidget {
  const WarehouseReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(stockMovementsStreamProvider).value ?? [];
    final orders = ref.watch(ordersStreamProvider).value ?? [];
    final routes = (ref.watch(deliveryRoutesStreamProvider).value ?? []).where((r) => r.status == 'active').toList();
    final lines = ref.watch(orderLinesByOrderProvider);
    final products = ref.watch(productsStreamProvider).value ?? [];

    final today = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day).subtract(Duration(days: i))];
    final start = days.first;
    bool inWeek(DateTime t) => !t.isBefore(start);

    final week = movements.where((m) => inWeek(m.createdAt)).toList();
    final stockIn = week.where((m) => m.movementType == 'in').fold<int>(0, (s, m) => s + m.quantity);
    final stockOut = week.where((m) => m.movementType == 'out').fold<int>(0, (s, m) => s + m.quantity);

    DateTime doneAt(Order o) => o.packedAt ?? o.updatedAt;
    final processed = orders.where((o) => (whOrderStatus(o) == 'ready' || whOrderStatus(o) == 'dispatched') && inWeek(doneAt(o))).toList();
    final inPicklist = orders.where(needsPreparing).length;
    final routesDone = routes.where((r) => routeLoadState(r, orders) == 'dispatched').length;
    final returns = week.where((m) => returnTypeOf(m) != null).toList();
    final damaged = returns.where((m) => returnTypeOf(m) == 'damaged').length;

    final perDay = [
      for (final d in days) week.where((m) => isSameDay(m.createdAt, d)).fold<int>(0, (s, m) => s + m.quantity),
    ];

    final perProduct = <String, int>{};
    for (final m in week) {
      perProduct[m.productId] = (perProduct[m.productId] ?? 0) + m.quantity;
    }
    String nameOf(String uuid) {
      for (final p in products) {
        if (p.uuid == uuid) return p.name;
      }
      return 'Unknown product';
    }

    final top = perProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    int itemsOf(Order o) {
      final l = lines[o.uuid];
      return (l == null || l.isEmpty) ? o.itemCount : l.fold<int>(0, (s, i) => s + i.quantity);
    }

    final summary = [
      for (final d in days.reversed)
        (
          date: d,
          orders: processed.where((o) => isSameDay(doneAt(o), d)).toList(),
        ),
    ].where((e) => e.orders.isNotEmpty).take(5).toList();

    return WarehouseShell(
      route: WhRoutes.reports,
      child: WhPage(children: [
        WhPageHeader(
          title: 'Reports',
          subtitle: 'This week · ${formatShortDate(start).split(', ').last} – ${formatShortDate(today).split(', ').last}, ${today.year}',
          trailing: WhPrimaryButton(
            label: 'Export PDF',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF export is not set up yet'))),
          ),
        ),
        WhStatRow(bottomGap: 12, cards: [
          WhStatCard(label: 'Total Stock In (Week)', value: '${formatNumber(stockIn)} units', sub: 'Last 7 days', dotColor: WhColors.green),
          WhStatCard(label: 'Total Stock Out (Week)', value: '${formatNumber(stockOut)} units', sub: 'Last 7 days', dotColor: WhColors.blue),
          WhStatCard(label: 'Orders Processed', value: '${processed.length}', sub: '$inPicklist still in picklist', dotColor: WhColors.amber),
        ]),
        WhStatRow(cards: [
          WhStatCard(label: 'Routes Completed', value: '$routesDone', sub: 'Of ${routes.length} active', dotColor: WhColors.green),
          WhStatCard(label: 'Returns Logged', value: '${returns.length}', sub: '$damaged damaged, written off', dotColor: WhColors.red),
          const WhStatCard(label: 'Avg Pick Time', value: '—', sub: 'Not tracked yet', dotColor: WhColors.green),
        ]),
        WhTwoColumn(
          sideWidth: 420,
          main: _barChart(days, perDay),
          side: _topProducts(top.take(6).toList(), nameOf),
        ),
        const SizedBox(height: 16),
        WhCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const WhCardTitle('Daily Loading Summary'),
            if (summary.isEmpty)
              const WhEmpty('No prepared orders in the last 7 days')
            else
              WhTableScroll(
                minWidth: 460,
                child: Column(children: [
                  const WhTableHeader(columns: ['Date', 'Routes', 'Orders', 'Items'], flex: [4, 2, 2, 2]),
                  for (final e in summary)
                    WhTableRow(flex: const [4, 2, 2, 2], cells: [
                      Text('${formatShortDate(e.date).split(', ').first}, ${formatShortDate(e.date).split(', ').last}${isSameDay(e.date, today) ? ' (today)' : ''}',
                          style: const TextStyle(fontSize: 13, color: WhColors.text)),
                      Text('${e.orders.map((o) => o.routeName ?? '').where((r) => r.isNotEmpty).toSet().length}', style: const TextStyle(fontSize: 13, color: WhColors.text)),
                      Text('${e.orders.length}', style: const TextStyle(fontSize: 13, color: WhColors.text)),
                      Text(formatNumber(e.orders.fold<int>(0, (s, o) => s + itemsOf(o))), style: const TextStyle(fontSize: 13, color: WhColors.text)),
                    ]),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _barChart(List<DateTime> days, List<int> values) {
    final maxV = values.fold<int>(0, (m, v) => v > m ? v : m);
    return WhCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const WhCardTitle('Stock Movement (Last 7 Days)', trailing: Text('Units in + out', style: TextStyle(fontSize: 12, color: WhColors.muted))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: maxV == 0
              ? const SizedBox(height: 160, child: Center(child: Text('No stock movement in the last 7 days', style: TextStyle(fontSize: 13, color: WhColors.muted))))
              : SizedBox(
                  height: 216,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < days.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(formatNumber(values[i]), style: const TextStyle(fontSize: 11, color: WhColors.text)),
                                const SizedBox(height: 4),
                                Container(
                                  height: (values[i] / maxV) * 140 + (values[i] > 0 ? 2 : 0),
                                  decoration: BoxDecoration(
                                    color: i == days.length - 1 ? const Color(0xFF6B7280) : WhColors.primary,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(i == days.length - 1 ? 'Today' : weekdayName(days[i]), style: const TextStyle(fontSize: 11, color: WhColors.muted)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _topProducts(List<MapEntry<String, int>> top, String Function(String) nameOf) {
    final maxV = top.isEmpty ? 1 : top.first.value;
    return WhCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const WhCardTitle('Top Products (Stock Movement)', trailing: Text('Units this week', style: TextStyle(fontSize: 12, color: WhColors.muted))),
        if (top.isEmpty)
          const WhEmpty('No stock movement in the last 7 days')
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(children: [
              for (final e in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(flex: 4, child: Text(nameOf(e.key), style: const TextStyle(fontSize: 12, color: WhColors.text), overflow: TextOverflow.ellipsis)),
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: e.value / maxV, minHeight: 10, backgroundColor: const Color(0xFFF3F4F6), color: WhColors.primary),
                      ),
                    ),
                    SizedBox(width: 52, child: Text(formatNumber(e.value), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WhColors.text))),
                  ]),
                ),
            ]),
          ),
      ]),
    );
  }
}
