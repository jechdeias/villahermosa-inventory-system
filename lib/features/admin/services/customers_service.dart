import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/customers_provider.dart';

class CustomersService {
  const CustomersService(this._ref);
  final Ref _ref;

  Future<void> createCustomer(CustomersCompanion customer) async {
    await _ref.read(customersDatabaseProvider).createCustomer(customer);
    await _sync();
  }

  Future<void> updateCustomer(String uuid, CustomersCompanion customer) async {
    await _ref.read(customersDatabaseProvider).updateCustomer(uuid, customer);
    await _sync();
  }

  Future<void> _sync() async {
    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }
}

final customersServiceProvider = Provider<CustomersService>(
  (ref) => CustomersService(ref),
);
