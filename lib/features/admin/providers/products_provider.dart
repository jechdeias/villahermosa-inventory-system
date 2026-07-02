import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';

final productsDatabaseProvider = Provider<AppDatabase>(
  (ref) => AuthService.instance.database,
);

final productsStreamProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productsDatabaseProvider).watchAllProducts(),
);

final suppliersStreamProvider = StreamProvider<List<Supplier>>(
  (ref) => ref.watch(productsDatabaseProvider).watchAllSuppliers(),
);

/// Active category tab: null = All.
final productsTabProvider = StateProvider<String?>((ref) => null);

final productsSearchProvider = StateProvider<String>((ref) => '');

final selectedProductProvider = StateProvider<Product?>((ref) => null);

@immutable
class ProductFilters {
  const ProductFilters({this.supplierId, this.lowStockOnly = false});
  final int? supplierId;
  final bool lowStockOnly;

  bool get isActive => supplierId != null || lowStockOnly;
}

final productsFilterProvider = StateProvider<ProductFilters>((ref) => const ProductFilters());

/// Distinct product categories present in the live data, sorted alphabetically.
final productCategoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  final categories = products.map((p) => p.category).toSet().toList();
  categories.sort();
  return categories;
});

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final tab = ref.watch(productsTabProvider);
  final search = ref.watch(productsSearchProvider).toLowerCase();
  final filters = ref.watch(productsFilterProvider);
  var list = ref.watch(productsStreamProvider).value ?? [];

  if (tab != null) {
    list = list.where((p) => p.category == tab).toList();
  }
  if (filters.supplierId != null) {
    list = list.where((p) => p.supplierId == filters.supplierId).toList();
  }
  if (filters.lowStockOnly) {
    list = list.where((p) => p.currentStock <= p.minStock).toList();
  }
  if (search.isNotEmpty) {
    list = list.where((p) =>
        p.sku.toLowerCase().contains(search) ||
        p.name.toLowerCase().contains(search)).toList();
  }
  return list;
});

/// Looks up a supplier's display name by id from the live suppliers list.
final supplierNameProvider = Provider.family<String, int?>((ref, supplierId) {
  if (supplierId == null) return '—';
  final suppliers = ref.watch(suppliersStreamProvider).value ?? [];
  for (final s in suppliers) {
    if (s.id == supplierId) return s.tradeName;
  }
  return '—';
});
