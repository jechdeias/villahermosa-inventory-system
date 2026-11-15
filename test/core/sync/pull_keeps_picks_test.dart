import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';

/// Picking state (order_items.status / picked_at) is local bookkeeping:
/// Supabase has no such columns and push never sends them. A pull must not
/// reset it, or every sync un-ticks the warehouse worker's picklist.
void main() {
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
}
