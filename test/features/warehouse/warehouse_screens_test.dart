import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/warehouse/providers/warehouse_providers.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/dashboard_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/incoming_orders_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/inventory_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/loading_dispatch_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/prepare_orders_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/reports_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/returns_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/routes_today_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/stock_movement_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/sync_activity_screen.dart';

Order _order({required String warehouseStatus, int id = 0}) => Order(
      id: id,
      uuid: '',
      customerId: '',
      orderNumber: '',
      status: '',
      deliveryAddress: '',
      subtotal: 0,
      taxAmount: 0,
      totalAmount: 0,
      paymentStatus: '',
      warehouseStatus: warehouseStatus,
      priority: '',
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isDeleted: false,
      syncStatus: 'pending',
      itemCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('order / stock helpers', () {
    test('whOrderStatus maps warehouse state', () {
      expect(whOrderStatus(_order(warehouseStatus: 'pending')), 'pending');
      expect(whOrderStatus(_order(warehouseStatus: 'processing')), 'processing');
      expect(whOrderStatus(_order(warehouseStatus: 'ready')), 'ready');
      expect(whOrderStatus(_order(warehouseStatus: 'packed')), 'ready');
      expect(whOrderStatus(_order(warehouseStatus: 'dispatched')), 'dispatched');
      expect(needsPreparing(_order(warehouseStatus: 'processing')), isTrue);
      expect(needsPreparing(_order(warehouseStatus: 'ready')), isFalse);
    });
  });

  group('warehouse screens render against a seeded database', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      AuthService.initializeWithDatabase(db);

      for (final p in [
        ('BEV-1', 'Coca-Cola 1.5L', 'Beverages', 150, 50),
        ('DAI-1', 'Bear Brand Milk', 'Dairy', 45, 50),
        ('WAT-1', 'Distilled Water', 'Water', 0, 48),
      ]) {
        await db.createProduct(ProductsCompanion.insert(
          uuid: 'p-${p.$1}',
          sku: p.$1,
          name: p.$2,
          category: p.$3,
          unitPrice: 10,
          costPrice: 8,
          unit: 'pcs',
          currentStock: p.$4,
          minStock: p.$5,
        ));
      }

      await db.createDeliveryRoute(DeliveryRoutesCompanion.insert(
        uuid: 'r1',
        routeName: 'Route 1 · Boac North',
        municipality: 'Boac',
        deliveryDays: 'Mon',
      ));

      await db.createOrder(OrdersCompanion.insert(
        uuid: 'o1',
        customerId: 'c1',
        orderNumber: 'ORD-1',
        deliveryAddress: 'Boac',
        storeName: const Value("Nena's Store"),
        routeName: const Value('Route 1 · Boac North'),
        itemCount: const Value(2),
      ));
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
            uuid: 'i1',
            orderId: 'o1',
            productId: 'p-BEV-1',
            productSku: 'BEV-1',
            productName: 'Coca-Cola 1.5L',
            quantity: 24,
            unitPrice: 10,
            subtotal: 240,
            totalAmount: 240,
            availableStock: 150,
          ));
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
            uuid: 'i2',
            orderId: 'o1',
            productId: 'p-WAT-1',
            productSku: 'WAT-1',
            productName: 'Distilled Water',
            quantity: 24,
            unitPrice: 10,
            subtotal: 240,
            totalAmount: 240,
            availableStock: 0,
          ));
      await db.createStockMovement(StockMovementsCompanion.insert(
        uuid: 'm1',
        productId: 'p-BEV-1',
        movementType: 'in',
        quantity: 120,
        reason: 'Supplier delivery',
        userId: 'u',
        userName: 'Lea',
      ));
      await db.createStockMovement(StockMovementsCompanion.insert(
        uuid: 'm2',
        productId: 'p-DAI-1',
        movementType: 'out',
        quantity: 6,
        reason: 'Damaged',
        userId: 'u',
        userName: 'Ramil',
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('WarehouseActions walk an order from pending to dispatched', () async {
      final actions = WarehouseActions(db);
      Future<Order> order() => (db.select(db.orders)..where((o) => o.uuid.equals('o1'))).getSingle();
      Future<List<OrderItem>> lines() => (db.select(db.orderItems)..where((i) => i.orderId.equals('o1'))).get();

      expect(whOrderStatus(await order()), 'pending');

      await actions.processOrder(await order());
      expect(whOrderStatus(await order()), 'processing');

      for (final l in await lines()) {
        await actions.setItemPicked(l, true);
      }
      expect((await lines()).every(isItemPicked), isTrue);

      await actions.resetPicks(await lines());
      expect((await lines()).any(isItemPicked), isFalse);

      for (final l in await lines()) {
        await actions.setItemPicked(l, true);
      }
      await actions.completeOrder(await order(), await lines());
      final ready = await order();
      expect(whOrderStatus(ready), 'ready');
      expect(ready.packedAt, isNotNull);
      // Warehouse bookkeeping must not flag the order for re-push to Supabase.
      expect(ready.syncStatus, 'pending'); // unchanged from how it was created

      for (final l in await lines()) {
        await actions.setItemLoaded(l, true);
      }
      expect((await lines()).every(isItemLoaded), isTrue);

      await actions.dispatchOrders([await order()]);
      expect(whOrderStatus(await order()), 'dispatched');
    });

    test('stockStatusOf classifies by minimum level', () async {
      final products = await db.select(db.products).get();
      final byName = {for (final p in products) p.sku: stockStatusOf(p)};
      expect(byName['BEV-1'], 'in_stock');
      expect(byName['DAI-1'], 'low_stock');
      expect(byName['WAT-1'], 'out_of_stock');
    });

    final screens = <String, Widget>{
      'dashboard': const WarehouseDashboardScreen(),
      'incoming orders': const WarehouseIncomingOrdersScreen(),
      'prepare orders': const WarehousePrepareOrdersScreen(),
      'inventory': const WarehouseInventoryScreen(),
      'stock movement': const WarehouseStockMovementScreen(),
      'loading & dispatch': const WarehouseLoadingDispatchScreen(),
      'routes today': const WarehouseRoutesTodayScreen(),
      'returns': const WarehouseReturnsScreen(),
      'reports': const WarehouseReportsScreen(),
      'sync & activity': const WarehouseSyncActivityScreen(),
    };

    for (final size in const [Size(1440, 900), Size(420, 900)]) {
      for (final e in screens.entries) {
        testWidgets('${e.key} at ${size.width.toInt()}px has no layout errors', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          // Collect every framework error with its full widget-creator chain
          // so a failure points at the exact overflowing widget.
          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) => errors.add(d.toString());
          try {
            await tester.pumpWidget(ProviderScope(child: MaterialApp(home: e.value)));
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 100));

            // Unmount before the in-memory DB closes so drift stream timers settle.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 50));
          } finally {
            FlutterError.onError = previous;
          }

          expect(errors, isEmpty, reason: errors.join(' ||| '));
        });
      }
    }
  });
}
