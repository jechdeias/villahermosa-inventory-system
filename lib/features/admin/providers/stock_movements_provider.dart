import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import 'products_provider.dart';

final stockMovementsDatabaseProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

final stockMovementsStreamProvider = StreamProvider<List<StockMovement>>(
  (ref) => ref.watch(stockMovementsDatabaseProvider).watchAllStockMovements(),
);

/// Active tab: null = All, 'in' | 'out' | 'low_stock'.
final stockMovementsTabProvider = StateProvider<String?>((ref) => null);

final stockMovementsSearchProvider = StateProvider<String>((ref) => '');

/// Looks up a product by its uuid from the live products list.
final productByUuidProvider = Provider.family<Product?, String>((ref, uuid) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  for (final p in products) {
    if (p.uuid == uuid) return p;
  }
  return null;
});

final filteredStockMovementsProvider = Provider<List<StockMovement>>((ref) {
  final tab = ref.watch(stockMovementsTabProvider);
  final search = ref.watch(stockMovementsSearchProvider).toLowerCase();
  final products = ref.watch(productsStreamProvider).value ?? [];
  var list = ref.watch(stockMovementsStreamProvider).value ?? [];

  if (tab == 'in' || tab == 'out') {
    list = list.where((m) => m.movementType == tab).toList();
  } else if (tab == 'low_stock') {
    final lowStockProductIds = products
        .where((p) => p.currentStock <= p.minStock)
        .map((p) => p.uuid)
        .toSet();
    list = list.where((m) => lowStockProductIds.contains(m.productId)).toList();
  }

  if (search.isNotEmpty) {
    Product? productFor(String id) {
      for (final p in products) {
        if (p.uuid == id) return p;
      }
      return null;
    }

    list = list.where((m) {
      final p = productFor(m.productId);
      return (p?.sku.toLowerCase().contains(search) ?? false) ||
          (p?.name.toLowerCase().contains(search) ?? false) ||
          (m.referenceId ?? '').toLowerCase().contains(search);
    }).toList();
  }
  return list;
});
