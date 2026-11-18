import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_manager.dart';
import 'package:villahermosa_inventory_system/features/warehouse/providers/warehouse_providers.dart' show WarehouseActions;

// NOTE: rows seeded here are 'synced' on purpose. These tests are about the
// per-column keep-local guards (legacy NULLs on SYNCED rows); a 'pending' row is
// skipped by the pull entirely (see 'a pending row is never touched by a pull').
/// Picking state (order_items.status / picked_at) is local bookkeeping:
/// Supabase has no such columns and push never sends them. A pull must not
/// reset it, or every sync un-ticks the warehouse worker's picklist.
void main() {
  group('round trip', roundTripTests);
  group('sync invariants', syncInvariantTests);

  late AppDatabase db;
  late SyncEngine engine;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          uuid: 'oi-1',
          orderId: 'o-1',
          productId: 'p-1',
          productSku: 'S',
          productName: 'P',
          quantity: 1,
          unitPrice: 1,
          subtotal: 1,
          totalAmount: 1,
          status: const Value('picked'),
          pickedAt: Value(DateTime(2026, 11, 15)),
          syncStatus: const Value('synced'),
        ));
  });
  tearDown(() => db.close());

  test('pulling an order_item the server has no status for keeps the local pick', () async {
    await engine.applyPulledRecord('order_items', {'id': 1, 'uuid': 'oi-1', 'quantity': 2, 'unit_price': 1, 'total_price': 2});
    expect(engine.pullFailureCount, 0);

    final row = await db.getOrderItemById('oi-1');
    expect(row!.quantity, 2, reason: 'server fields still apply');
    expect(row.status, 'picked');
    expect(row.pickedAt, isNotNull);
  });

  test('a status the server does send still wins', () async {
    await engine.applyPulledRecord('order_items', {'id': 1, 'uuid': 'oi-1', 'status': 'loaded'});
    expect((await db.getOrderItemById('oi-1'))!.status, 'loaded');
  });
  group('orders.packed_at', () {
    Future<void> seedOrder() => db.createOrder(OrdersCompanion.insert(
          uuid: 'o-9',
          customerId: 'c',
          orderNumber: 'ORD-9',
          deliveryAddress: 'x',
          packedAt: Value(DateTime(2026, 11, 15, 9)),
          syncStatus: const Value('synced'),
        ));

    test('a pull the server sends no packed_at for keeps the local value', () async {
      await seedOrder();
      await engine.applyPulledRecord('orders', {'id': 9, 'uuid': 'o-9', 'order_number': 'ORD-9', 'status': 'processing'});
      expect(engine.pullFailureCount, 0);
      final o = await db.getOrderById('o-9');
      expect(o!.status, 'processing', reason: 'server fields still apply');
      expect(o.packedAt, DateTime(2026, 11, 15, 9));
    });

    test('a packed_at the server does send wins', () async {
      await seedOrder();
      await engine.applyPulledRecord('orders', {'id': 9, 'uuid': 'o-9', 'packed_at': '2026-11-16T10:00:00Z'});
      expect((await db.getOrderById('o-9'))!.packedAt!.toUtc(), DateTime.utc(2026, 11, 16, 10));
    });
  });
}

/// Push-key / pull-key agreement and the push maps for newly synced columns.
/// A mismatch between the two maps is invisible from Dart — see CLAUDE.md.
void roundTripTests() {
  late AppDatabase db;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
  });
  tearDown(() => db.close());

  Future<StockMovement> movement() => (db.select(db.stockMovements)..where((t) => t.uuid.equals('m-1'))).getSingle();

  Future<void> seedMovement() => db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
        uuid: 'm-1',
        productId: 'p',
        movementType: 'in',
        quantity: 1,
        reason: 'r',
        userId: 'u-local',
        userName: 'Anne Warehouse',
        referenceId: const Value('PO-7'),
        syncStatus: const Value('synced'),
      ));

  group('stock_movements pull keys', () {
    test("reads 'reference' and 'performed_by_name' (the names Supabase and push use)", () async {
      await engine.applyPulledRecord('stock_movements', {
        'id': 1, 'uuid': 'm-1', 'movement_type': 'in', 'quantity': 1,
        'reference': 'PO-9', 'performed_by_name': 'Server Name', 'user_id': 'u-server',
      });
      final m = await movement();
      expect(engine.pullFailureCount, 0);
      expect(m.referenceId, 'PO-9');
      expect(m.userName, 'Server Name');
      expect(m.userId, 'u-server');
    });

    test('NULL server values leave local reference, user name and user id intact', () async {
      await seedMovement();
      await engine.applyPulledRecord('stock_movements', {'id': 1, 'uuid': 'm-1', 'movement_type': 'in', 'quantity': 2});
      final m = await movement();
      expect(m.quantity, 2, reason: 'server fields still apply');
      expect(m.referenceId, 'PO-7');
      expect(m.userName, 'Anne Warehouse');
      expect(m.userId, 'u-local');
    });
  });

  group('customers push', () {
    test('the push payload carries the uuid (the upsert conflict key)', () async {
      await db.createCustomer(CustomersCompanion.insert(
        uuid: 'c-unique-1',
        name: 'Nena',
        municipality: 'Boac',
        province: 'Marinduque',
        storeType: 'Sari-Sari Store',
        contactNumber: '0',
      ));
      final customer = await (db.select(db.customers)..where((t) => t.uuid.equals('c-unique-1'))).getSingle();
      final map = engine.recordToPushMap(customer);
      expect(map['uuid'], 'c-unique-1');
      expect(map['name'], 'Nena');
    });
  });

  group('stock_movements uuid', () {
    Future<List<StockMovement>> all() => db.select(db.stockMovements).get();

    test('a pulled row with a real uuid keeps it', () async {
      await engine.applyPulledRecord('stock_movements', {'id': 5, 'uuid': 'real-uuid', 'movement_type': 'in', 'quantity': 1});
      final rows = await all();
      expect(rows, hasLength(1));
      expect(rows.single.uuid, 'real-uuid');
    });

    test('a pulled row with NULL uuid gets the synthetic fallback and is not duplicated', () async {
      final row = {'id': 5, 'uuid': null, 'movement_type': 'in', 'quantity': 1};
      await engine.applyPulledRecord('stock_movements', row);
      await engine.applyPulledRecord('stock_movements', {...row, 'quantity': 3});
      final rows = await all();
      expect(rows, hasLength(1));
      expect(rows.single.uuid, 'sb-stockmovement-5');
      expect(rows.single.quantity, 3);
    });
  });

  group('orders delivery dates', () {
    test('NULL server dates keep local; server dates win', () async {
      await db.createOrder(OrdersCompanion.insert(
        uuid: 'o-1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x',
        expectedDeliveryDate: Value(DateTime(2026, 11, 20)),
        actualDeliveryDate: Value(DateTime(2026, 11, 21)),
        syncStatus: const Value('synced'),
      ));
      await engine.applyPulledRecord('orders', {'id': 1, 'uuid': 'o-1', 'order_number': 'ORD-1'});
      var o = (await db.getOrderById('o-1'))!;
      expect(o.expectedDeliveryDate, DateTime(2026, 11, 20));
      expect(o.actualDeliveryDate, DateTime(2026, 11, 21));

      await engine.applyPulledRecord('orders', {'id': 1, 'uuid': 'o-1', 'expected_delivery_date': '2026-12-01T00:00:00Z'});
      o = (await db.getOrderById('o-1'))!;
      expect(o.expectedDeliveryDate!.toUtc(), DateTime.utc(2026, 12, 1));
    });
  });
}

/// A SyncManager whose push/pull are counted (and can be held open) instead of
/// touching Supabase.
class _CountingSyncManager extends SyncManager {
  _CountingSyncManager(AppDatabase db) : super(db, SyncEngine(db));
  int pushes = 0;
  int pulls = 0;
  Completer<void>? holdPush;

  @override
  Future<Map<String, dynamic>> push() async {
    pushes++;
    await holdPush?.future;
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> pull() async {
    pulls++;
    return {'success': true};
  }
}

/// The three-layer "local change reverts or never syncs" invariants.
void syncInvariantTests() {
  late AppDatabase db;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
  });
  tearDown(() => db.close());

  Future<void> markAllSynced() async {
    for (final t in ['users', 'products', 'customers', 'orders', 'order_items']) {
      await db.customStatement("UPDATE $t SET sync_status = 'synced'");
    }
  }

  Future<Customer> customer(String uuid) => (db.select(db.customers)..where((t) => t.uuid.equals(uuid))).getSingle();

  Future<void> addCustomer(String uuid) => db.createCustomer(CustomersCompanion.insert(
      uuid: uuid, name: 'N', municipality: 'm', province: 'p', storeType: 's', contactNumber: '0'));

  // ── Layer 2: the pull never clobbers unpushed work ──────────────────────────
  group('a pending row is never touched by a pull', () {
    test('order_items (matched by uuid)', () async {
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
            uuid: 'oi-p', orderId: 'o', productId: 'p', productSku: 'S', productName: 'P',
            quantity: 1, unitPrice: 1, subtotal: 1, totalAmount: 1,
            status: const Value('picked'), // syncStatus defaults to 'pending'
          ));
      await engine.applyPulledRecord('order_items', {'id': 1, 'uuid': 'oi-p', 'quantity': 99, 'status': 'pending'});

      final row = (await db.getOrderItemById('oi-p'))!;
      expect(row.status, 'picked');
      expect(row.quantity, 1);
      expect(row.syncStatus, 'pending', reason: 'left pending so the next push sends it');
      expect(engine.pullFailureCount, 0);
    });

    test('orders (a stale server status does not revert a local Process)', () async {
      await db.createOrder(OrdersCompanion.insert(
        uuid: 'o-p', customerId: 'c', orderNumber: 'ORD-P', deliveryAddress: 'x',
        status: const Value('processing'),
      ));
      await engine.applyPulledRecord('orders', {'id': 7, 'uuid': 'o-p', 'order_number': 'ORD-P', 'status': 'pending'});
      final o = (await db.getOrderById('o-p'))!;
      expect(o.status, 'processing');
      expect(o.syncStatus, 'pending');
    });

    test('products (matched by id, the way the pull writes them)', () async {
      await db.createProduct(ProductsCompanion.insert(
        uuid: 'pr-p', sku: 'S', name: 'Local name', category: 'c', unitPrice: 1, costPrice: 1, unit: 'pc', currentStock: 5, minStock: 0,
      ));
      final id = (await (db.select(db.products)..where((t) => t.uuid.equals('pr-p'))).getSingle()).id;
      await engine.applyPulledRecord('products', {'id': id, 'uuid': 'pr-p', 'name': 'Server name', 'sku': 'S', 'current_stock': 0});
      final p = await (db.select(db.products)..where((t) => t.uuid.equals('pr-p'))).getSingle();
      expect(p.name, 'Local name');
      expect(p.currentStock, 5);
      expect(p.syncStatus, 'pending');
    });

    test('control: the same pull DOES apply once the row is synced', () async {
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
            uuid: 'oi-s', orderId: 'o', productId: 'p', productSku: 'S', productName: 'P',
            quantity: 1, unitPrice: 1, subtotal: 1, totalAmount: 1,
            syncStatus: const Value('synced'),
          ));
      await engine.applyPulledRecord('order_items', {'id': 2, 'uuid': 'oi-s', 'quantity': 99});
      expect((await db.getOrderItemById('oi-s'))!.quantity, 99);
    });
  });

  // ── Layer 3: no write path can forget syncStatus ────────────────────────────
  group('local writes mark the row pending', () {
    test('soft-deleting a user, a product and a customer', () async {
      await db.createUser(UsersCompanion.insert(
          uuid: 'u1', firstName: 'A', lastName: 'B', email: 'a@b.c', passwordHash: 'x', role: 'customer'));
      await db.createProduct(ProductsCompanion.insert(
          uuid: 'p1', sku: 'S', name: 'N', category: 'c', unitPrice: 1, costPrice: 1, unit: 'pc', currentStock: 1, minStock: 0));
      await addCustomer('c1');
      await markAllSynced();

      await db.softDeleteUser('u1');
      await db.softDeleteProduct('p1');
      await db.softDeleteCustomer('c1');

      final u = await (db.select(db.users)..where((t) => t.uuid.equals('u1'))).getSingle();
      final p = await (db.select(db.products)..where((t) => t.uuid.equals('p1'))).getSingle();
      final c = await customer('c1');
      expect([u.isDeleted, p.isDeleted, c.isDeleted], everyElement(isTrue));
      expect([u.syncStatus, p.syncStatus, c.syncStatus], everyElement('pending'));
    });

    test('updateX helpers force pending even if the caller passes nothing (or "synced")', () async {
      await addCustomer('c2');
      await markAllSynced();
      await db.updateCustomer('c2', const CustomersCompanion(name: Value('New')));
      expect((await customer('c2')).syncStatus, 'pending');

      await markAllSynced();
      await db.updateCustomer('c2', const CustomersCompanion(name: Value('Newer'), syncStatus: Value('synced')));
      expect((await customer('c2')).syncStatus, 'pending');
    });

    test('setItemPicked and setItemLoaded mark the order item pending', () async {
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
            uuid: 'oi-w', orderId: 'o', productId: 'p', productSku: 'S', productName: 'P',
            quantity: 1, unitPrice: 1, subtotal: 1, totalAmount: 1,
            syncStatus: const Value('synced'),
          ));
      var item = (await db.getOrderItemById('oi-w'))!;
      final actions = WarehouseActions(db);

      await actions.setItemPicked(item, true);
      item = (await db.getOrderItemById('oi-w'))!;
      expect(item.status, 'picked');
      expect(item.syncStatus, 'pending');

      await markAllSynced();
      await actions.setItemLoaded(item, true);
      item = (await db.getOrderItemById('oi-w'))!;
      expect(item.status, 'loaded');
      expect(item.syncStatus, 'pending');
    });

    test('completing an order marks it pending (warehouse_status and packed_at sync now)', () async {
      await db.createOrder(OrdersCompanion.insert(
        uuid: 'o-w', customerId: 'c', orderNumber: 'ORD-W', deliveryAddress: 'x',
        status: const Value('processing'), syncStatus: const Value('synced'),
      ));
      var o = (await db.getOrderById('o-w'))!;
      await WarehouseActions(db).completeOrder(o, const []);
      o = (await db.getOrderById('o-w'))!;
      expect(o.warehouseStatus, 'ready');
      expect(o.packedAt, isNotNull);
      expect(o.syncStatus, 'pending', reason: 'status was already processing; this used to leave the row synced');
    });
  });

  // ── Layer 1: sync is serialised ─────────────────────────────────────────────
  group('syncPendingData is single-flight', () {
    test('two overlapping calls share one push/pull cycle', () async {
      final m = _CountingSyncManager(db)..holdPush = Completer<void>();
      final a = m.syncPendingData();
      final b = m.syncPendingData(); // arrives while the first is still pushing
      expect(identical(a, b), isTrue, reason: 'the second caller gets the in-flight Future');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      m.holdPush!.complete();
      await Future.wait([a, b]);

      expect(m.pushes, 1);
      expect(m.pulls, 1);
    });

    test('a caller that joined mid-cycle gets one more cycle only if rows are still pending', () async {
      await addCustomer('c-pend'); // pending
      final m = _CountingSyncManager(db)..holdPush = Completer<void>();
      final a = m.syncPendingData();
      final b = m.syncPendingData();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      m.holdPush!.complete();
      await Future.wait([a, b]);
      expect(m.pushes, 2, reason: 'something was still pending, so one trailing cycle ran');
      expect(m.pulls, 2);
    });

    test('sequential calls each run their own cycle', () async {
      final m = _CountingSyncManager(db);
      await m.syncPendingData();
      await m.syncPendingData();
      expect(m.pushes, 2);
    });

    test('a full sync waits for the running cycle instead of overlapping it', () async {
      final m = _CountingSyncManager(db)..holdPush = Completer<void>();
      final cycle = m.syncPendingData();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      var fullDone = false;
      final full = m.performFullSync().then((_) => fullDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(m.pushes, 1, reason: 'full sync has not started its own push yet');
      expect(fullDone, isFalse);
      m.holdPush!.complete();
      await Future.wait([cycle, full]);
      expect(m.pushes, 2);
    });
  });
}
