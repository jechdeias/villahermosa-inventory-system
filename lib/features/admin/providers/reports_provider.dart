import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import 'orders_provider.dart';
import 'payments_provider.dart';
import 'products_provider.dart';

final _dbProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

enum ReportsRange { week, month, quarter, year, all, custom }

final reportsRangeProvider = StateProvider<ReportsRange>((ref) => ReportsRange.month);

/// Only meaningful when [reportsRangeProvider] is [ReportsRange.custom].
final reportsCustomRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final reportsRangeStartProvider = Provider<DateTime?>((ref) {
  final range = ref.watch(reportsRangeProvider);
  if (range == ReportsRange.custom) return ref.watch(reportsCustomRangeProvider)?.start;

  final now = DateTime.now();
  return switch (range) {
    ReportsRange.week => now.subtract(const Duration(days: 7)),
    ReportsRange.month => DateTime(now.year, now.month - 1, now.day),
    ReportsRange.quarter => DateTime(now.year, now.month - 3, now.day),
    ReportsRange.year => DateTime(now.year - 1, now.month, now.day),
    ReportsRange.all => null,
    ReportsRange.custom => null,
  };
});

/// Exclusive upper bound for the selected range — "now" for every preset,
/// the picked end date (+1 day, so that day is included) for a custom range.
final reportsRangeEndProvider = Provider<DateTime>((ref) {
  final range = ref.watch(reportsRangeProvider);
  if (range == ReportsRange.custom) {
    final custom = ref.watch(reportsCustomRangeProvider);
    if (custom != null) return custom.end.add(const Duration(days: 1));
  }
  return DateTime.now();
});

final orderItemsStreamProvider = StreamProvider<List<OrderItem>>(
  (ref) => ref.watch(_dbProvider).watchAllOrderItems(),
);

final reportsOrdersProvider = Provider<List<Order>>((ref) {
  final start = ref.watch(reportsRangeStartProvider);
  final end = ref.watch(reportsRangeEndProvider);
  final all = ref.watch(ordersStreamProvider).value ?? [];
  return all.where((o) => (start == null || o.createdAt.isAfter(start)) && o.createdAt.isBefore(end)).toList();
});

final reportsPaymentsProvider = Provider<List<Payment>>((ref) {
  final start = ref.watch(reportsRangeStartProvider);
  final end = ref.watch(reportsRangeEndProvider);
  final all = ref.watch(paymentsStreamProvider).value ?? [];
  return all.where((p) => (start == null || p.paymentDate.isAfter(start)) && p.paymentDate.isBefore(end)).toList();
});

/// Revenue growth vs. the immediately preceding period of equal length.
/// Null when the range is unbounded (`All`) or has no prior period to compare.
final reportsGrowthRateProvider = Provider<double?>((ref) {
  final start = ref.watch(reportsRangeStartProvider);
  final end = ref.watch(reportsRangeEndProvider);
  if (start == null) return null;

  final prevEnd = start;
  final prevStart = start.subtract(end.difference(start));
  final all = ref.watch(ordersStreamProvider).value ?? [];

  final current = ref.watch(reportsOrdersProvider).fold(0.0, (s, o) => s + o.totalAmount);
  final previous = all
      .where((o) => o.createdAt.isAfter(prevStart) && o.createdAt.isBefore(prevEnd))
      .fold(0.0, (s, o) => s + o.totalAmount);

  if (previous == 0) return null;
  return (current - previous) / previous * 100;
});

/// Stat-card numbers for the selected range. Low-stock count is a current
/// snapshot (stock isn't historical), so it ignores the range filter.
final reportsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final orders = ref.watch(reportsOrdersProvider);
  final payments = ref.watch(reportsPaymentsProvider);
  final products = ref.watch(productsStreamProvider).value ?? [];
  final totalRevenue = orders.fold(0.0, (s, o) => s + o.totalAmount);

  return {
    'totalRevenue': totalRevenue,
    'orderCount': orders.length,
    'avgOrderValue': orders.isEmpty ? 0.0 : totalRevenue / orders.length,
    'growthRate': ref.watch(reportsGrowthRateProvider),
    'collected': payments.fold(0.0, (s, p) => s + p.amountPaid),
    'outstanding': payments
        .where((p) => p.status == 'unpaid' || p.status == 'partial')
        .fold(0.0, (s, p) => s + p.balance),
    'lowStockCount': products.where((p) => p.currentStock <= p.minStock).length,
  };
});

class MonthPoint {
  const MonthPoint(this.label, this.total);
  final String label;
  final double total;
}

const _monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Last 6 calendar months of order revenue, independent of the range filter
/// (a "Week" range would otherwise collapse this to a single point).
final salesTrendProvider = Provider<List<MonthPoint>>((ref) {
  final orders = ref.watch(ordersStreamProvider).value ?? [];
  final now = DateTime.now();
  final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));

  return months.map((m) {
    final total = orders
        .where((o) => o.createdAt.year == m.year && o.createdAt.month == m.month)
        .fold(0.0, (s, o) => s + o.totalAmount);
    return MonthPoint(_monthLabels[m.month - 1], total);
  }).toList();
});

class StatusCount {
  const StatusCount(this.status, this.count);
  final String status;
  final int count;
}

/// Order counts grouped by whatever status values actually occur in the
/// range-filtered data, sorted most common first.
final orderStatusBreakdownProvider = Provider<List<StatusCount>>((ref) {
  final orders = ref.watch(reportsOrdersProvider);
  final counts = <String, int>{};
  for (final o in orders) {
    counts[o.status] = (counts[o.status] ?? 0) + 1;
  }
  final entries = counts.entries.map((e) => StatusCount(e.key, e.value)).toList();
  entries.sort((a, b) => b.count.compareTo(a.count));
  return entries;
});

class CategoryStock {
  const CategoryStock(this.category, this.stock);
  final String category;
  final int stock;
}

/// Current stock summed by category — a snapshot, not range-filtered.
final stockByCategoryProvider = Provider<List<CategoryStock>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  final totals = <String, int>{};
  for (final p in products) {
    totals[p.category] = (totals[p.category] ?? 0) + p.currentStock;
  }
  final entries = totals.entries.map((e) => CategoryStock(e.key, e.value)).toList();
  entries.sort((a, b) => b.stock.compareTo(a.stock));
  return entries;
});

class ProductSales {
  const ProductSales(this.sku, this.name, this.quantity, this.revenue);
  final String sku;
  final String name;
  final int quantity;
  final double revenue;
}

/// Top 5 products by quantity sold within the selected range.
final topProductsProvider = Provider<List<ProductSales>>((ref) {
  final start = ref.watch(reportsRangeStartProvider);
  final end = ref.watch(reportsRangeEndProvider);
  final allItems = ref.watch(orderItemsStreamProvider).value ?? [];
  final items = allItems
      .where((i) => (start == null || i.createdAt.isAfter(start)) && i.createdAt.isBefore(end))
      .toList();

  final bySku = <String, ProductSales>{};
  for (final i in items) {
    final existing = bySku[i.productSku];
    bySku[i.productSku] = ProductSales(
      i.productSku,
      i.productName,
      (existing?.quantity ?? 0) + i.quantity,
      (existing?.revenue ?? 0) + i.totalAmount,
    );
  }
  final list = bySku.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));
  return list.take(5).toList();
});
