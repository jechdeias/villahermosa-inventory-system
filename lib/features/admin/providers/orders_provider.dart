import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

final ordersStreamProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(databaseProvider).watchAllOrders(),
);

final customersProvider = FutureProvider<List<Customer>>(
  (ref) => ref.watch(databaseProvider).getAllCustomers(),
);

final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(databaseProvider).getAllProducts(),
);

final usersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(databaseProvider).getAllUsers(),
);

/// Active tab: null = All Orders, else 'pending' | 'completed' | 'cancelled'
final ordersTabProvider = StateProvider<String?>((ref) => 'pending');

final ordersSearchProvider = StateProvider<String>((ref) => '');

final selectedOrderProvider = StateProvider<Order?>((ref) => null);

@immutable
class OrderFilters {
  const OrderFilters({
    this.route,
    this.salesRepName,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
  });
  final String? route;
  final String? salesRepName;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minAmount;
  final double? maxAmount;

  bool get isActive =>
      route != null ||
      salesRepName != null ||
      dateFrom != null ||
      dateTo != null ||
      minAmount != null ||
      maxAmount != null;
}

final ordersFilterProvider =
    StateProvider<OrderFilters>((ref) => const OrderFilters());

final filteredOrdersProvider = Provider<List<Order>>((ref) {
  final tab = ref.watch(ordersTabProvider);
  final search = ref.watch(ordersSearchProvider).toLowerCase();
  final filters = ref.watch(ordersFilterProvider);
  var list = ref.watch(ordersStreamProvider).value ?? [];

  if (tab != null) {
    list = list.where((o) => o.status == tab).toList();
  }
  if (search.isNotEmpty) {
    list = list.where((o) =>
        o.orderNumber.toLowerCase().contains(search) ||
        (o.storeName ?? '').toLowerCase().contains(search) ||
        (o.routeName ?? '').toLowerCase().contains(search) ||
        (o.salesRepName ?? '').toLowerCase().contains(search)).toList();
  }
  if (filters.route != null) {
    list = list.where((o) => o.routeName == filters.route).toList();
  }
  if (filters.salesRepName != null) {
    list = list.where((o) => o.salesRepName == filters.salesRepName).toList();
  }
  if (filters.dateFrom != null) {
    list = list.where((o) => o.createdAt.isAfter(filters.dateFrom!)).toList();
  }
  if (filters.dateTo != null) {
    list = list
        .where((o) => o.createdAt
            .isBefore(filters.dateTo!.add(const Duration(days: 1))))
        .toList();
  }
  if (filters.minAmount != null) {
    list = list.where((o) => o.totalAmount >= filters.minAmount!).toList();
  }
  if (filters.maxAmount != null) {
    list = list.where((o) => o.totalAmount <= filters.maxAmount!).toList();
  }
  return list;
});

final orderItemsProvider =
    FutureProvider.family<List<OrderItem>, String>((ref, orderUuid) {
  return ref.watch(databaseProvider).getOrderItemsByOrderId(orderUuid);
});
