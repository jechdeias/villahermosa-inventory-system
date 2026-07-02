import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/orders_provider.dart';

class OrdersService {
  const OrdersService(this._ref);
  final Ref _ref;

  Future<void> markCompleted(String uuid) => _setStatus(uuid, 'completed');
  Future<void> cancelOrder(String uuid) => _setStatus(uuid, 'cancelled');
  Future<void> restoreOrder(String uuid) => _setStatus(uuid, 'pending');

  Future<void> _setStatus(String uuid, String status) async {
    await _ref.read(databaseProvider).updateOrderStatus(uuid, status);
    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }
}

final ordersServiceProvider = Provider<OrdersService>(
  (ref) => OrdersService(ref),
);
