import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';

final deliveryRoutesDatabaseProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

final deliveryRoutesStreamProvider = StreamProvider<List<DeliveryRoute>>(
  (ref) => ref.watch(deliveryRoutesDatabaseProvider).watchAllDeliveryRoutes(),
);

final deliveryRoutesSearchProvider = StateProvider<String>((ref) => '');

final selectedDeliveryRouteProvider = StateProvider<DeliveryRoute?>((ref) => null);

final deliveryRoutesStatusFilterProvider = StateProvider<String?>((ref) => null);

final filteredDeliveryRoutesProvider = Provider<List<DeliveryRoute>>((ref) {
  final search = ref.watch(deliveryRoutesSearchProvider).toLowerCase();
  final statusFilter = ref.watch(deliveryRoutesStatusFilterProvider);
  var list = ref.watch(deliveryRoutesStreamProvider).value ?? [];

  if (search.isNotEmpty) {
    list = list.where((r) =>
        r.routeName.toLowerCase().contains(search) ||
        r.municipality.toLowerCase().contains(search) ||
        (r.assignedRepName ?? '').toLowerCase().contains(search)).toList();
  }
  if (statusFilter != null) {
    list = list.where((r) => r.status == statusFilter).toList();
  }
  return list;
});
