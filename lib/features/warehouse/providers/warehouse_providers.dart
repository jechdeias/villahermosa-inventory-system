import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../admin/providers/orders_provider.dart' show databaseProvider;
import '../../admin/providers/products_provider.dart' show productsStreamProvider;
import '../../admin/services/products_service.dart';

export '../../admin/providers/orders_provider.dart' show databaseProvider, ordersStreamProvider;
export '../../admin/providers/products_provider.dart' show productsStreamProvider;
export '../../admin/providers/stock_movements_provider.dart' show stockMovementsStreamProvider;
export '../../admin/providers/delivery_routes_provider.dart' show deliveryRoutesStreamProvider;

/// Every live (non-deleted) order line, so screens can group by parent order.
final orderItemsStreamProvider = StreamProvider<List<OrderItem>>(
  (ref) => ref.watch(databaseProvider).watchAllOrderItems(),
);

// ── Pure helpers (no Flutter / provider deps, easy to unit test) ──────────────

/// Warehouse-side state of an order: cancelled | completed | dispatched |
/// ready | processing | pending.
String whOrderStatus(Order o) {
  if (o.status == 'cancelled') return 'cancelled';
  if (o.status == 'completed') return 'completed';
  switch (o.warehouseStatus) {
    case 'dispatched':
      return 'dispatched';
    case 'ready':
    case 'packed':
      return 'ready';
    case 'processing':
      return 'processing';
    default:
      return 'pending';
  }
}

/// Still needs warehouse work (not ready, dispatched, completed or cancelled).
bool needsPreparing(Order o) {
  final s = whOrderStatus(o);
  return s == 'pending' || s == 'processing';
}

/// 'not started' | 'loading' | 'dispatched', derived from the route's open orders.
String routeLoadState(DeliveryRoute r, List<Order> orders) {
  final mine = orders.where((o) => o.routeName == r.routeName && o.status != 'cancelled' && o.status != 'completed').toList();
  if (mine.isEmpty) return 'not started';
  if (mine.every((o) => whOrderStatus(o) == 'dispatched')) return 'dispatched';
  if (mine.any((o) => whOrderStatus(o) == 'ready' || whOrderStatus(o) == 'dispatched')) return 'loading';
  return 'not started';
}

bool isReadyForLoading(Order o) => whOrderStatus(o) == 'ready';

bool isLowStock(Product p) => p.currentStock > 0 && p.currentStock <= p.minStock;
bool isOutOfStock(Product p) => p.currentStock <= 0;

/// 'in_stock' | 'low_stock' | 'out_of_stock'
String stockStatusOf(Product p) {
  if (isOutOfStock(p)) return 'out_of_stock';
  if (isLowStock(p)) return 'low_stock';
  return 'in_stock';
}

/// Order lines reference the product by uuid (or, for seed data, only by SKU).
Product? productForItem(OrderItem item, List<Product> products) {
  for (final p in products) {
    if (p.uuid == item.productId) return p;
  }
  for (final p in products) {
    if (p.sku == item.productSku) return p;
  }
  return null;
}

bool isItemPicked(OrderItem i) => i.status == 'picked' || i.status == 'loaded';
bool isItemLoaded(OrderItem i) => i.status == 'loaded';

/// Movement reasons the Returns screen treats as a return/damage/expiry entry.
const returnReasons = {'Customer return': 'returned', 'Damaged': 'damaged', 'Expired': 'expired'};

String? returnTypeOf(StockMovement m) => returnReasons[m.reason];

String returnId(StockMovement m) => 'RET-${m.id.toString().padLeft(4, '0')}';

DateTime? lastSyncTime() {
  try {
    return AppSettings.instance.lastSyncTimestamp;
  } catch (_) {
    return null;
  }
}

String currentUserName() {
  final u = AuthService.instance.getCurrentUser();
  if (u == null) return 'Warehouse';
  final n = '${u.firstName} ${u.lastName}'.trim();
  return n.isEmpty ? 'Warehouse' : n;
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// Open orders grouped by order uuid → their lines.
final orderLinesByOrderProvider = Provider<Map<String, List<OrderItem>>>((ref) {
  final items = ref.watch(orderItemsStreamProvider).value ?? [];
  final map = <String, List<OrderItem>>{};
  for (final i in items) {
    map.putIfAbsent(i.orderId, () => []).add(i);
  }
  return map;
});

final lowStockProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  return products.where((p) => isLowStock(p) || isOutOfStock(p)).toList()
    ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
});

// ── Writes ────────────────────────────────────────────────────────────────────
//
// Orders / order lines: warehouse_status, packed_at and line status are local
// warehouse bookkeeping that the Supabase orders / order_items tables don't
// have (see the push maps in sync_engine.dart), so these writes deliberately
// leave sync_status alone — marking the row 'pending' would only make the
// next sync re-insert an already-synced order.

class WarehouseActions {
  const WarehouseActions(this._db);
  final AppDatabase _db;

  Future<void> processOrder(Order o) => (_db.update(_db.orders)..where((t) => t.id.equals(o.id))).write(
        OrdersCompanion(warehouseStatus: const Value('processing'), updatedAt: Value(DateTime.now())),
      );

  Future<void> setItemPicked(OrderItem i, bool picked) => (_db.update(_db.orderItems)..where((t) => t.id.equals(i.id))).write(
        OrderItemsCompanion(
          status: Value(picked ? 'picked' : 'pending'),
          pickedAt: Value(picked ? DateTime.now() : null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> resetPicks(List<OrderItem> items) async {
    for (final i in items) {
      await setItemPicked(i, false);
    }
  }

  Future<void> completeOrder(Order o, List<OrderItem> items) async {
    final now = DateTime.now();
    final user = AuthService.instance.getCurrentUser();
    await (_db.update(_db.orders)..where((t) => t.id.equals(o.id))).write(
      OrdersCompanion(
        warehouseStatus: const Value('ready'),
        pickedAt: Value(now),
        packedAt: Value(now),
        packerId: Value(user?.uuid),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> setItemLoaded(OrderItem i, bool loaded) => (_db.update(_db.orderItems)..where((t) => t.id.equals(i.id))).write(
        OrderItemsCompanion(status: Value(loaded ? 'loaded' : 'picked'), updatedAt: Value(DateTime.now())),
      );

  Future<void> dispatchOrders(List<Order> orders) async {
    for (final o in orders) {
      await (_db.update(_db.orders)..where((t) => t.id.equals(o.id))).write(
        OrdersCompanion(warehouseStatus: const Value('dispatched'), updatedAt: Value(DateTime.now())),
      );
    }
  }
}

final warehouseActionsProvider = Provider<WarehouseActions>((ref) => WarehouseActions(ref.watch(databaseProvider)));

/// Records a stock movement (and adjusts the product's stock) as the current user.
Future<void> recordStockMovement(
  WidgetRef ref, {
  required String productUuid,
  required int delta,
  required String reason,
  String? notes,
  String? reference,
}) {
  final user = AuthService.instance.getCurrentUser();
  return ref.read(productsServiceProvider).adjustStock(
        productUuid: productUuid,
        delta: delta,
        reason: reason,
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        referenceId: (reference == null || reference.trim().isEmpty) ? null : reference.trim(),
        userUuid: user?.uuid ?? '',
        userName: currentUserName(),
      );
}

const stockInReasons = ['Supplier delivery', 'Customer return', 'Stock adjustment'];
const stockOutReasons = ['Order fulfillment', 'Damaged', 'Expired', 'Stock adjustment'];
