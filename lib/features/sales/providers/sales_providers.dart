import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../admin/providers/delivery_routes_provider.dart';

/// Live online/offline status — one-shot check first, then live updates,
/// same isOnline logic main.dart's startup sync check already uses.
final salesConnectivityProvider = StreamProvider<bool>((ref) async* {
  final initial = await Connectivity().checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);
  yield* Connectivity()
      .onConnectivityChanged
      .map((r) => !r.contains(ConnectivityResult.none));
});

final salesDatabaseProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

/// The logged-in sales rep. AuthService.instance.getCurrentUser() is a
/// method, not a `currentUser` getter.
final currentSalesRepProvider = Provider<User?>(
  (ref) => AuthService.instance.getCurrentUser(),
);

/// User has no `fullName` field — just firstName/lastName. This is the
/// value Orders.salesRepName/Payments.salesRepName are populated with
/// elsewhere in the app (see admin_orders_screen.dart's _saveOrder), so
/// it's what every rep-name match in this file needs to use.
final salesRepFullNameProvider = Provider<String>((ref) {
  final rep = ref.watch(currentSalesRepProvider);
  if (rep == null) return '';
  return '${rep.firstName} ${rep.lastName}'.trim();
});

final salesRepOrdersProvider = StreamProvider<List<Order>>((ref) {
  final repName = ref.watch(salesRepFullNameProvider);
  if (repName.isEmpty) return Stream.value(const <Order>[]);
  return ref.watch(salesDatabaseProvider).watchOrdersBySalesRep(repName);
});

final salesRepPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final repName = ref.watch(salesRepFullNameProvider);
  if (repName.isEmpty) return Stream.value(const <Payment>[]);
  return ref.watch(salesDatabaseProvider).watchPaymentsBySalesRep(repName);
});

/// This rep's assigned route, if any — DeliveryRoutes.assignedRepName is a
/// real field; reuses the stream already defined for the admin Deliveries
/// screen rather than duplicating a query.
final salesRepRouteProvider = Provider<DeliveryRoute?>((ref) {
  final repName = ref.watch(salesRepFullNameProvider);
  if (repName.isEmpty) return null;
  final routes = ref.watch(deliveryRoutesStreamProvider).value ?? [];
  for (final r in routes) {
    if (r.assignedRepName == repName) return r;
  }
  return null;
});

/// All customers, for the New Order store picker — deliberately NOT
/// filtered to "my customers", so a rep can start selling to a store
/// they've never transacted with before.
final allCustomersProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(salesDatabaseProvider).watchAllCustomers(),
);

String salesDisplayStoreName(Customer c) =>
    (c.businessName?.isNotEmpty ?? false) ? c.businessName! : c.name;

/// "My Customers" — there is no real customer<->route relationship in this
/// schema (Customers has no routeName/routeId column, and DeliveryRoutes.
/// customerCount is just a cached integer, not an actual membership list),
/// so this is derived from transaction history instead: the distinct set
/// of customers this rep has an Order or Payment for. Payments has no
/// customerId FK at all — storeName is the only field common to both
/// Orders and Payments that identifies which customer a transaction
/// belongs to, so matching is by store display name (businessName, or
/// name if there's no business name — the same rule admin_orders_screen.dart
/// uses when it writes storeName in the first place).
final myCustomersProvider = Provider<List<Customer>>((ref) {
  final orders = ref.watch(salesRepOrdersProvider).value ?? [];
  final paymentsList = ref.watch(salesRepPaymentsProvider).value ?? [];
  final allCustomers = ref.watch(allCustomersProvider).value ?? [];

  final storeNames = <String>{
    for (final o in orders)
      if (o.storeName != null) o.storeName!,
    for (final p in paymentsList) p.storeName,
  };
  if (storeNames.isEmpty) return const [];

  return allCustomers
      .where((c) => storeNames.contains(salesDisplayStoreName(c)))
      .toList();
});

/// Distinct stores with an order created today.
final visitedTodayProvider = Provider<Set<String>>((ref) {
  final orders = ref.watch(salesRepOrdersProvider).value ?? [];
  final now = DateTime.now();
  return {
    for (final o in orders)
      if (o.storeName != null &&
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day)
        o.storeName!,
  };
});

final todayProgressProvider = Provider<Map<String, int>>((ref) {
  final total = ref.watch(myCustomersProvider).length;
  final visited = ref.watch(visitedTodayProvider).length;
  return {
    'total': total,
    'visited': visited,
    'remaining': (total - visited) < 0 ? 0 : (total - visited),
  };
});

class SalesActivityEntry {
  const SalesActivityEntry({
    required this.storeName,
    required this.action,
    required this.time,
    required this.color,
  });
  final String storeName;
  final String action;
  final DateTime time;
  final Color color;
}

/// Last 5 entries across this rep's orders + payments, most recent first.
final salesRecentActivityProvider = Provider<List<SalesActivityEntry>>((ref) {
  final orders = ref.watch(salesRepOrdersProvider).value ?? [];
  final paymentsList = ref.watch(salesRepPaymentsProvider).value ?? [];

  final entries = <SalesActivityEntry>[
    for (final o in orders)
      SalesActivityEntry(
        storeName: o.storeName ?? 'Unknown store',
        action: 'Order created',
        time: o.createdAt,
        color: const Color(0xFF2563EB),
      ),
    for (final p in paymentsList)
      SalesActivityEntry(
        storeName: p.storeName,
        action: 'Payment collected',
        time: p.paymentDate,
        color: const Color(0xFF059669),
      ),
  ];
  entries.sort((a, b) => b.time.compareTo(a.time));
  return entries.take(5).toList();
});

/// Not-yet-synced records this rep created, for the Profile sync summary.
final salesPendingUploadsProvider = Provider<int>((ref) {
  final orders = ref.watch(salesRepOrdersProvider).value ?? [];
  final paymentsList = ref.watch(salesRepPaymentsProvider).value ?? [];
  return orders.where((o) => o.syncStatus == 'pending').length +
      paymentsList.where((p) => p.syncStatus == 'pending').length;
});
