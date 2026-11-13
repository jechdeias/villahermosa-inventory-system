import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/orders_provider.dart';

class OrdersService {
  const OrdersService(this._ref);
  final Ref _ref;

  Future<void> markProcessing(String uuid) => _setStatus(uuid, 'processing');
  Future<void> markOutForDelivery(String uuid) => _setStatus(uuid, 'out_for_delivery');
  Future<void> markDelivered(String uuid) => _setStatus(uuid, 'delivered');
  Future<void> markCompleted(String uuid) => _setStatus(uuid, 'completed');
  Future<void> cancelOrder(String uuid) => _setStatus(uuid, 'cancelled');
  Future<void> restoreOrder(String uuid) => _setStatus(uuid, 'pending');

  Future<void> assignRoute(
    String uuid, {
    required String routeId,
    required String routeName,
    required String salesRepId,
    required String salesRepName,
  }) async {
    await _ref.read(databaseProvider).assignOrderRoute(
          uuid,
          routeId: routeId,
          routeName: routeName,
          salesRepId: salesRepId,
          salesRepName: salesRepName,
        );
    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }

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
