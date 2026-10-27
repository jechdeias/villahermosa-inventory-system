import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/constants/order_status.dart';
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
  // Terminal / downstream statuses come from orders.status, which syncs.
  if (o.status == OrderStatus.cancelled) return 'cancelled';
  if (o.status == OrderStatus.completed || o.status == OrderStatus.delivered) return 'completed';
  if (o.status == OrderStatus.outForDelivery) return 'dispatched';
  // Before dispatch, picking progress lives in warehouseStatus (local only).
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
  final mine = orders.where((o) => o.routeName == r.routeName && !OrderStatus.isFinished(o.status)).toList();
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
// Order *status* changes (pending → processing → out_for_delivery) are real
// lifecycle changes the other roles need to see, so those writes mark the
// order 'pending' for sync. warehouse_status, packed_at and per-line status
// are local bookkeeping that Supabase doesn't have (see the push maps in
// sync_engine.dart); writes that touch only those leave sync_status alone.

class WarehouseActions {
  const WarehouseActions(this._db);
  final AppDatabase _db;

  /// Warehouse picks the order up: pending → processing.
  Future<void> processOrder(Order o) => (_db.update(_db.orders)..where((t) => t.id.equals(o.id))).write(
        OrdersCompanion(
          status: const Value(OrderStatus.processing),
          warehouseStatus: const Value('processing'),
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
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
        // An order completed straight from pending skipped Process; its status
        // should still read "processing" from here on.
        status: o.status == OrderStatus.pending ? const Value(OrderStatus.processing) : const Value.absent(),
        syncStatus: o.status == OrderStatus.pending ? const Value('pending') : const Value.absent(),
      ),
    );
  }

  Future<void> setItemLoaded(OrderItem i, bool loaded) => (_db.update(_db.orderItems)..where((t) => t.id.equals(i.id))).write(
        OrderItemsCompanion(status: Value(loaded ? 'loaded' : 'picked'), updatedAt: Value(DateTime.now())),
      );

  /// Truck leaves: every prepared order on the route becomes out_for_delivery
  /// (the customer's phone then shows its QR code). Returns how many.
  Future<int> dispatchOrders(List<Order> orders) async {
    for (final o in orders) {
      await (_db.update(_db.orders)..where((t) => t.id.equals(o.id))).write(
        OrdersCompanion(
          status: const Value(OrderStatus.outForDelivery),
          warehouseStatus: const Value('dispatched'),
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    return orders.length;
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
