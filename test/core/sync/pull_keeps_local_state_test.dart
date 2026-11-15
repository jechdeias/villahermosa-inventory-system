import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';

/// Picking state (order_items.status / picked_at) is local bookkeeping:
/// Supabase has no such columns and push never sends them. A pull must not
/// reset it, or every sync un-ticks the warehouse worker's picklist.
void main() {
  group('round trip', roundTripTests);

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
