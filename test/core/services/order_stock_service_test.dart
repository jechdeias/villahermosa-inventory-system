import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/constants/order_status.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/services/order_stock_service.dart';
import 'package:villahermosa_inventory_system/features/admin/services/orders_service.dart';
import 'package:villahermosa_inventory_system/features/warehouse/providers/warehouse_providers.dart' show WarehouseActions;

/// Stock leaves the warehouse when an order is dispatched (→ out_for_delivery),
/// and comes back if a dispatched order is cancelled. Idempotency comes from the
/// stock_movements rows, never from order status.
void main() {
  late AppDatabase db;
  late OrderStockService stock;
  late ProviderContainer container;

  Future<void> addProduct(String uuid, int stock) => db.createProduct(ProductsCompanion.insert(
        uuid: uuid,
        sku: 'SKU-$uuid',
        name: 'Product $uuid',
        category: 'c',
        unitPrice: 10,
        costPrice: 5,
        unit: 'pc',
        currentStock: stock,
        minStock: 0,
        syncStatus: const Value('synced'),
      ));

  Future<void> addOrder(String uuid, List<(String productUuid, int qty)> lines, {String status = 'processing'}) async {
    await db.createOrder(OrdersCompanion.insert(
      uuid: uuid,
      customerId: 'c',
      orderNumber: 'ORD-$uuid',
      deliveryAddress: 'x',
      status: Value(status),
      syncStatus: const Value('synced'),
    ));
    var n = 0;
    for (final (p, q) in lines) {
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
            uuid: '$uuid-line-${n++}',
            orderId: uuid,
            productId: p,
            productSku: 'SKU-$p',
            productName: 'Product $p',
            quantity: q,
            unitPrice: 10,
            subtotal: 10.0 * q,
            totalAmount: 10.0 * q,
          ));
    }
  }

  Future<int> stockOf(String productUuid) async => (await db.getProductByUuid(productUuid))!.currentStock;

  Future<List<StockMovement>> movementsFor(String orderUuid) => (db.select(db.stockMovements)
        ..where((m) => m.referenceId.equals(orderUuid))
        ..orderBy([(m) => OrderingTerm(expression: m.id)]))
      .get();

  Future<Order> orderRow(String uuid) async => (await db.getOrderById(uuid))!;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
    stock = OrderStockService(db);
    container = ProviderContainer();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('dispatch deducts stock', () {
    test('each line\'s quantity comes off its product, one audit row per line', () async {
      await addProduct('p1', 10);
      await addProduct('p2', 20);
      await addOrder('o1', [('p1', 3), ('p2', 5)]);

      final n = await stock.deductForDispatch('o1');

      expect(n, 2);
      expect(await stockOf('p1'), 7);
      expect(await stockOf('p2'), 15);

      final rows = await movementsFor('o1');
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.referenceId), everyElement('o1'), reason: 'the order UUID, not the order number');
      expect(rows.map((r) => r.reason), everyElement('Order fulfillment'));
      expect(rows.map((r) => r.movementType), everyElement('out'));
      expect({for (final r in rows) r.productId: r.quantity}, {'p1': 3, 'p2': 5});
      expect((await db.getProductByUuid('p1'))!.syncStatus, 'pending', reason: 'the product syncs');
    });

    test('dispatching the same order twice deducts once', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 3)]);

      await stock.deductForDispatch('o1');
      final second = await stock.deductForDispatch('o1');

      expect(second, 0);
      expect(await stockOf('p1'), 7);
      expect(await movementsFor('o1'), hasLength(1));
    });

    test('status flapping does not re-deduct: only the stock_movements rows decide', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 3)], status: 'processing');
      final actions = WarehouseActions(db);

      await actions.dispatchOrders([await orderRow('o1')]);
      // A pull resurrects an older status, then the order is dispatched again.
      await db.customStatement("UPDATE orders SET status = 'processing' WHERE uuid = 'o1'");
      await actions.dispatchOrders([await orderRow('o1')]);

      expect(await stockOf('p1'), 7);
      expect(await movementsFor('o1'), hasLength(1));
    });

    test('stock is allowed to go negative', () async {
      await addProduct('p1', 2);
      await addProduct('p0', 0);
      await addOrder('o1', [('p1', 5), ('p0', 4)]);

      await stock.deductForDispatch('o1');

      expect(await stockOf('p1'), -3);
      expect(await stockOf('p0'), -4);
    });

    test('a line whose product no longer exists does not stop the other lines', () async {
      await addProduct('p1', 10);
      await addProduct('p3', 10);
      await addOrder('o1', [('p1', 2), ('ghost', 9), ('p3', 4)]);

      final n = await stock.deductForDispatch('o1');

      expect(n, 2);
      expect(await stockOf('p1'), 8);
      expect(await stockOf('p3'), 6);
      expect(await movementsFor('o1'), hasLength(2));
    });

    test('a failure part-way leaves nothing half-deducted (nested transactions roll back together)', () async {
      await addProduct('p1', 10);
      await addProduct('p2', 10);
      await addOrder('o1', [('p1', 2), ('p2', 3)]);

      // adjustProductStock opens its own transaction inside ours; if Drift did not
      // nest them as savepoints under the outer one, this rollback would leave the
      // first line deducted.
      await expectLater(
        db.transaction(() async {
          await stock.deductForDispatch('o1');
          throw StateError('boom after both lines');
        }),
        throwsStateError,
      );

      expect(await stockOf('p1'), 10);
      expect(await stockOf('p2'), 10);
      expect(await movementsFor('o1'), isEmpty);
    });
  });

  group('entry points', () {
    test('WarehouseActions.dispatchOrders sets the status AND deducts', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 4)]);

      await WarehouseActions(db).dispatchOrders([await orderRow('o1')]);

      expect((await orderRow('o1')).status, OrderStatus.outForDelivery);
      expect(await stockOf('p1'), 6);
    });

    test('OrdersService.markOutForDelivery (the admin panel) sets the status AND deducts', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 4)]);

      await container.read(ordersServiceProvider).markOutForDelivery('o1');

      expect((await orderRow('o1')).status, OrderStatus.outForDelivery);
      expect(await stockOf('p1'), 6);
    });

    test('the same order dispatched from the warehouse and then the admin panel deducts once', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 4)]);

      await WarehouseActions(db).dispatchOrders([await orderRow('o1')]);
      await container.read(ordersServiceProvider).markOutForDelivery('o1');

      expect(await stockOf('p1'), 6);
    });

    test('other status changes move no stock', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 4)], status: 'pending');
      final service = container.read(ordersServiceProvider);

      await service.markProcessing('o1');
      await service.markDelivered('o1');
      await service.markCompleted('o1');

      expect(await stockOf('p1'), 10);
      expect(await movementsFor('o1'), isEmpty);
    });
  });

  group('cancelling', () {
    test('a dispatched order gets its stock back, exactly once', () async {
      await addProduct('p1', 10);
      await addProduct('p2', 20);
      await addOrder('o1', [('p1', 3), ('p2', 5)]);
      final service = container.read(ordersServiceProvider);
      await service.markOutForDelivery('o1');
      expect(await stockOf('p1'), 7);

      await service.cancelOrder('o1');
      await service.cancelOrder('o1'); // cancelled twice

      expect(await stockOf('p1'), 10);
      expect(await stockOf('p2'), 20);
      final rows = await movementsFor('o1');
      final restores = rows.where((r) => r.reason == 'Order cancelled').toList();
      expect(restores, hasLength(2), reason: 'one per product, not four');
      expect(restores.map((r) => r.movementType), everyElement('in'));
      expect(restores.map((r) => r.referenceId), everyElement('o1'));
    });

    test('an order that was never dispatched changes no stock', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 3)], status: 'processing');

      await container.read(ordersServiceProvider).cancelOrder('o1');

      expect(await stockOf('p1'), 10);
      expect(await movementsFor('o1'), isEmpty);
      expect((await orderRow('o1')).status, OrderStatus.cancelled);
    });

    test('cancel → restore → dispatch again deducts again (the cancellation cancelled the first deduction out)', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 3)]);
      final service = container.read(ordersServiceProvider);

      await service.markOutForDelivery('o1');
      await service.cancelOrder('o1');
      expect(await stockOf('p1'), 10);

      await service.restoreOrder('o1'); // → pending: no stock change
      expect(await stockOf('p1'), 10);

      await service.markOutForDelivery('o1');
      expect(await stockOf('p1'), 7, reason: 'goods left again');

      await service.cancelOrder('o1');
      expect(await stockOf('p1'), 10);
    });

    test('a stock-out the warehouse recorded by hand with another reference is not touched', () async {
      await addProduct('p1', 10);
      await addOrder('o1', [('p1', 3)]);
      await db.adjustProductStock(
          productUuid: 'p1', delta: -1, reason: 'Damaged', userUuid: 'u', userName: 'U', referenceId: 'o1');

      await stock.deductForDispatch('o1');
      await stock.restoreForCancellation('o1');

      expect(await stockOf('p1'), 9, reason: '10 − 1 (damaged); dispatch and cancel net to zero');
    });
  });
}
