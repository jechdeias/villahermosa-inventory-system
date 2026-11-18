import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_manager.dart';

/// A row whose push can NEVER succeed used to stay 'pending' forever: never
/// pushed, never refreshed by a pull (the pull skips pending rows), and invisible
/// (push() reported success). After [SyncEngine.maxPushAttempts] consecutive
/// failures it is flagged 'error'.
///
/// Supabase is not initialised in tests, so every push attempt fails per record
/// ("Supabase.instance" throws) — exactly the failure mode being handled.
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late SyncManager manager;
  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
    manager = SyncManager(db, engine);
  });
  tearDown(() => db.close());

  Future<void> addCustomer(String uuid, {String status = 'pending'}) => db.createCustomer(CustomersCompanion.insert(
      uuid: uuid, name: 'N', municipality: 'm', province: 'p', storeType: 's', contactNumber: '0', syncStatus: Value(status)));

  Future<String> status(String uuid) async =>
      (await (db.select(db.customers)..where((c) => c.uuid.equals(uuid))).getSingle()).syncStatus;

  test('a row that fails to push 3 times is marked error (not before)', () async {
    await addCustomer('c1');
    await engine.performPush();
    expect(await status('c1'), 'pending', reason: '1 failure');
    await engine.performPush();
    expect(await status('c1'), 'pending', reason: '2 failures');
    await engine.performPush();
    expect(await status('c1'), 'error', reason: '3 consecutive failures');
    expect(engine.pushFailures['customers'], 1);
  });

  test('a flagged row is no longer pushed (push selects only pending)', () async {
    await addCustomer('c1');
    for (var i = 0; i < 3; i++) {
      await engine.performPush();
    }
    await engine.performPush();
    expect(engine.pushFailureCount, 0, reason: 'nothing left to attempt');
  });

  test('a successful push clears the failure count', () async {
    await addCustomer('c1');
    await engine.performPush();
    await engine.performPush(); // 2 failures recorded
    final row = await (db.select(db.customers)..where((c) => c.uuid.equals('c1'))).getSingle();
    await engine.markRecordSyncedForTest(row); // a push of that row succeeded
    expect(await status('c1'), 'synced');

    // Edited again later (helpers force pending): it gets a fresh 3 attempts,
    // not 1, because the earlier streak was cleared.
    await db.updateCustomer(row.uuid, const CustomersCompanion(name: Value('edited')));
    await engine.performPush();
    await engine.performPush();
    expect(await status('c1'), 'pending', reason: 'only 2 failures since the success');
    await engine.performPush();
    expect(await status('c1'), 'error');
  });

  test("an 'error' row IS refreshed by a pull (a 'pending' row is not)", () async {
    await addCustomer('stuck', status: 'error');
    await addCustomer('waiting', status: 'pending');
    await engine.applyPulledRecord('customers', {
      'id': 1, 'uuid': 'stuck', 'name': 'From Server', 'municipality': 'm', 'province': 'p', 'store_type': 's', 'phone': '0',
    });
    await engine.applyPulledRecord('customers', {
      'id': 2, 'uuid': 'waiting', 'name': 'From Server', 'municipality': 'm', 'province': 'p', 'store_type': 's', 'phone': '0',
    });
    final stuck = await (db.select(db.customers)..where((c) => c.uuid.equals('stuck'))).getSingle();
    final waiting = await (db.select(db.customers)..where((c) => c.uuid.equals('waiting'))).getSingle();
    expect(stuck.name, 'From Server');
    expect(stuck.syncStatus, 'synced');
    expect(waiting.name, 'N', reason: 'pending rows are still protected');
    expect(waiting.syncStatus, 'pending');
  });

  test('the push result reports the failed count, and performFullSync carries it', () async {
    await addCustomer('c1');
    await addCustomer('c2');
    final push = await manager.push();
    expect(push['failedCount'], 2);
    expect(push['success'], isFalse, reason: 'a push that dropped rows is not a success');
    expect((push['failedTables'] as Map)['customers'], 2);
    expect(push['error'], contains('2 records could not be uploaded'));

    final full = await manager.performFullSync();
    expect(full['failedCount'], 2);
    expect(full['pushFailedCount'], 2);
    expect(full['success'], isFalse);
  });

  test('a clean push reports zero failures', () async {
    final push = await manager.push();
    expect(push['failedCount'], 0);
    expect(push['success'], isTrue);
  });
}
