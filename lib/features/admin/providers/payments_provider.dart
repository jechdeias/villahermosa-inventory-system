import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';

final _dbProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

final paymentsStreamProvider = StreamProvider<List<Payment>>(
  (ref) => ref.watch(_dbProvider).watchAllPayments(),
);

final paymentsTabProvider = StateProvider<String>((ref) => 'all');

final paymentsSearchProvider = StateProvider<String>((ref) => '');

final selectedPaymentProvider = StateProvider<Payment?>((ref) => null);

final filteredPaymentsProvider = Provider<List<Payment>>((ref) {
  final tab = ref.watch(paymentsTabProvider);
  final search = ref.watch(paymentsSearchProvider).toLowerCase();
  final all = ref.watch(paymentsStreamProvider).value ?? [];
  return all.where((p) {
    final matchTab = tab == 'all' || p.status == tab;
    final matchSearch = search.isEmpty ||
        p.orderCode.toLowerCase().contains(search) ||
        p.storeName.toLowerCase().contains(search) ||
        p.salesRepName.toLowerCase().contains(search);
    return matchTab && matchSearch;
  }).toList();
});

final paymentStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final all = ref.watch(paymentsStreamProvider).value ?? [];
  return {
    'collected': all.fold(0.0, (s, p) => s + p.amountPaid),
    'outstanding': all
        .where((p) => p.status == 'unpaid' || p.status == 'partial')
        .fold(0.0, (s, p) => s + p.balance),
    'paidCount': all.where((p) => p.status == 'paid').length,
    'creditCount': all.where((p) => p.status == 'credit').length,
  };
});
