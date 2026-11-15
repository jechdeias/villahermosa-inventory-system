import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';

void main() {
  late AppDatabase db;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
  });
  tearDown(() => db.close());

  Future<void> seedProduct(String uuid, String syncStatus) =>
      db.into(db.products).insert(ProductsCompanion.insert(
            uuid: uuid,
            sku: 'S-$uuid',
            name: 'P',
            category: 'General',
            unitPrice: 1,
            costPrice: 1,
            unit: 'pc',
            currentStock: 1,
            minStock: 0,
            syncStatus: Value(syncStatus),
          ));

  Map<String, dynamic> badRow(String uuid) =>
      {'id': 1, 'uuid': uuid, 'current_stock': 'not-a-number'};

  Future<String> statusOf(String uuid) async =>
      (await (db.select(db.products)..where((t) => t.uuid.equals(uuid))).getSingle()).syncStatus;

  test('a row that fails to apply is counted and its local copy flagged error', () async {
    await seedProduct('p1', 'synced');
    await engine.applyPulledRecord('products', badRow('p1'));

    expect(engine.pullFailureCount, 1);
    expect(engine.pullFailures, {'products': 1});
    expect(await statusOf('p1'), 'error');
  });

  test('a row with local edits still waiting to push is not flagged', () async {
    await seedProduct('p2', 'pending');
    await engine.applyPulledRecord('products', badRow('p2'));

    expect(engine.pullFailureCount, 1);
    expect(await statusOf('p2'), 'pending');
  });

  test('a failure for a row that does not exist locally is counted, not thrown', () async {
    await engine.applyPulledRecord('products', badRow('missing'));
    expect(engine.pullFailureCount, 1);
  });

  test('a good row records no failure', () async {
    await engine.applyPulledRecord('products', {'id': 7, 'uuid': 'ok', 'current_stock': 3});
    expect(engine.pullFailureCount, 0);
  });
}
