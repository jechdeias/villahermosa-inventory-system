import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';

/// orders.warehouse_status syncs both ways, but a legacy Supabase row has it
/// NULL. A pull of such a row must not reset a local 'ready'/'dispatched'.
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
  });
  tearDown(() => db.close());

  Future<void> seed(String wh) => db.createOrder(OrdersCompanion.insert(
      uuid: 'o-1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x',
      warehouseStatus: Value(wh), syncStatus: const Value('synced')));

  for (final local in ['ready', 'dispatched']) {
    test("a pull with warehouse_status NULL leaves a local '$local' as '$local'", () async {
      await seed(local);
      await engine.applyPulledRecord('orders', {'id': 1, 'uuid': 'o-1', 'order_number': 'ORD-1', 'status': 'processing'});
      expect(engine.pullFailureCount, 0);
      final o = (await db.getOrderById('o-1'))!;
      expect(o.status, 'processing', reason: 'server fields still apply');
      expect(o.warehouseStatus, local);
    });
  }

  test('a warehouse_status the server does send still wins', () async {
    await seed('ready');
    await engine.applyPulledRecord('orders', {'id': 1, 'uuid': 'o-1', 'warehouse_status': 'dispatched'});
    expect((await db.getOrderById('o-1'))!.warehouseStatus, 'dispatched');
  });

  test("a brand-new order with no warehouse_status starts 'pending'", () async {
    await engine.applyPulledRecord('orders', {'id': 5, 'uuid': 'o-new', 'order_number': 'ORD-5'});
    expect((await db.getOrderById('o-new'))!.warehouseStatus, 'pending');
  });
}
