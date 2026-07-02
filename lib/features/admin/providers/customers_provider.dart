import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';

final customersDatabaseProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

final customersStreamProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(customersDatabaseProvider).watchAllCustomers(),
);

/// Marinduque municipalities covered by this deployment.
const kCustomerTowns = [
  'Boac',
  'Buenavista',
  'Gasan',
  'Mogpog',
  'Sta. Cruz',
  'Torrijos',
];

/// Known store channel taxonomy (falls back to the raw value for anything else).
const kCustomerChannels = [
  'Sari-Sari Store',
  'Mini Mart',
  'Grocery Store',
  'Market Stall',
  'Wholesaler',
  'Coffee Shop',
  'Bakery',
  'Eatery',
  'Supermarket',
];

/// Active town tab: null = All.
final customersTabProvider = StateProvider<String?>((ref) => null);

final customersSearchProvider = StateProvider<String>((ref) => '');

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

@immutable
class CustomerFilters {
  const CustomerFilters({this.channel, this.status});
  final String? channel;
  final String? status;

  bool get isActive => channel != null || status != null;
}

final customersFilterProvider = StateProvider<CustomerFilters>((ref) => const CustomerFilters());

final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final tab = ref.watch(customersTabProvider);
  final search = ref.watch(customersSearchProvider).toLowerCase();
  final filters = ref.watch(customersFilterProvider);
  var list = ref.watch(customersStreamProvider).value ?? [];

  if (tab != null) {
    list = list.where((c) => c.town == tab).toList();
  }
  if (filters.channel != null) {
    list = list.where((c) => c.channel == filters.channel).toList();
  }
  if (filters.status != null) {
    list = list.where((c) => c.status == filters.status).toList();
  }
  if (search.isNotEmpty) {
    list = list.where((c) =>
        c.name.toLowerCase().contains(search) ||
        (c.businessName ?? '').toLowerCase().contains(search) ||
        c.contactNumber.toLowerCase().contains(search)).toList();
  }
  return list;
});
