import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/delivery_routes_provider.dart';

class DeliveryRoutesService {
  const DeliveryRoutesService(this._ref);
  final Ref _ref;

  Future<void> createRoute(DeliveryRoutesCompanion route) async {
    await _ref.read(deliveryRoutesDatabaseProvider).createDeliveryRoute(route);
    await _sync();
  }

  Future<void> updateRoute(String uuid, DeliveryRoutesCompanion route) async {
    await _ref.read(deliveryRoutesDatabaseProvider).updateDeliveryRoute(uuid, route);
    await _sync();
  }

  Future<void> _sync() async {
    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }
}

final deliveryRoutesServiceProvider = Provider<DeliveryRoutesService>(
  (ref) => DeliveryRoutesService(ref),
);
