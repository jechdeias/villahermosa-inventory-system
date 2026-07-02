import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/products_provider.dart';

class ProductsService {
  const ProductsService(this._ref);
  final Ref _ref;

  Future<void> createProduct(ProductsCompanion product) async {
    await _ref.read(productsDatabaseProvider).createProduct(product);
    await _sync();
  }

  Future<void> updateProduct(String uuid, ProductsCompanion product) async {
    await _ref.read(productsDatabaseProvider).updateProduct(uuid, product);
    await _sync();
  }

  Future<void> adjustStock({
    required String productUuid,
    required int delta,
    required String reason,
    String? notes,
    required String userUuid,
    required String userName,
    String? referenceId,
  }) async {
    await _ref.read(productsDatabaseProvider).adjustProductStock(
      productUuid: productUuid,
      delta: delta,
      reason: reason,
      notes: notes,
      userUuid: userUuid,
      userName: userName,
      referenceId: referenceId,
    );
    await _sync();
  }

  Future<void> _sync() async {
    try {
      await SyncManager.instance.syncPendingData();
    } catch (_) {}
  }
}

final productsServiceProvider = Provider<ProductsService>(
  (ref) => ProductsService(ref),
);
