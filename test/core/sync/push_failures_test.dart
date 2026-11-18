import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_manager.dart';

/// A row whose push can NEVER succeed used to stay 'pending' forever (never
/// pushed, never refreshed by a pull, invisible). After
/// [SyncEngine.maxPushAttempts] consecutive PERMANENT failures it is flagged
/// 'error'. Transient failures (network, 5xx, 408/429, anything unrecognised) are
/// NOT counted: on live data 4 of the first 8 flagged rows were false positives
/// from a network blip and pushed fine on retry.
///
/// Supabase is not initialised in tests, so a real push attempt fails with a
/// non-Postgrest error, which must be classed transient.
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
  Future<int> idOf(String uuid) async => (await (db.select(db.customers)..where((c) => c.uuid.equals(uuid))).getSingle()).id;

  Future<void> fail(int id, Object error) => engine.recordPushFailureForTest('customers', id, error: error);

  const dupKey = PostgrestException(message: 'duplicate key value violates unique constraint', code: '23505');
  final networkShaped = <Object>[
    const SocketException('Failed host lookup'),
    TimeoutException('timed out'),
    // Non-JSON body (a gateway page): the client puts the HTTP status in `code`.
    const PostgrestException(message: '<html>Bad Gateway</html>', code: '502'),
    const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
    const FunctionException(status: 503),
    const FunctionException(status: 429),
    const FunctionException(status: 408),
    const FunctionException(status: 401), // expired session: succeeds after a refresh
    StateError('something nobody classified'),
  ];

  group('classification', () {
    test('constraint-violation SQLSTATEs are permanent', () {
      for (final code in ['23505', '23503', '23502', '22P02']) {
        expect(SyncEngine.isPermanentPushError(PostgrestException(message: 'm', code: code)), isTrue, reason: code);
      }
    });

    test('a 4xx from privileged-sync is permanent except 408, 429 (and 401, an expired token)', () {
      for (final s in [400, 403, 404, 409, 422]) {
        expect(SyncEngine.isPermanentPushError(FunctionException(status: s)), isTrue, reason: '$s');
      }
      for (final s in [401, 408, 429, 500, 502, 503, 504]) {
        expect(SyncEngine.isPermanentPushError(FunctionException(status: s)), isFalse, reason: '$s');
      }
    });

    test('everything else (network errors, 5xx, other codes, anything unrecognised) is transient', () {
      for (final e in networkShaped) {
        expect(SyncEngine.isPermanentPushError(e), isFalse, reason: '$e');
      }
      expect(SyncEngine.isPermanentPushError(null), isFalse);
      expect(SyncEngine.isPermanentPushError(const PostgrestException(message: 'x', code: '23514')), isFalse,
          reason: 'not on the agreed list: unsure means transient');
    });
  });

  group('the 3-strike rule counts only permanent failures', () {
    test('three network-shaped failures do NOT flag the row; it stays pending', () async {
      await addCustomer('c1');
      final id = await idOf('c1');
      for (final e in networkShaped) {
        await fail(id, e);
      }
      expect(await status('c1'), 'pending', reason: '${networkShaped.length} transient failures');
    });

    test('real push attempts that fail for a non-Postgrest reason leave the row pending', () async {
      await addCustomer('c1');
      for (var i = 0; i < 4; i++) {
        await engine.performPush(); // Supabase is not initialised: not a constraint error
      }
      expect(await status('c1'), 'pending');
    });

    test('three constraint violations DO flag it', () async {
      await addCustomer('c1');
      final id = await idOf('c1');
      await fail(id, dupKey);
      await fail(id, dupKey);
      expect(await status('c1'), 'pending', reason: '2 so far');
      await fail(id, dupKey);
      expect(await status('c1'), 'error');
    });

    test('a mix (network, constraint, network) does not reach the threshold', () async {
      await addCustomer('c1');
      final id = await idOf('c1');
      await fail(id, const SocketException('x'));
      await fail(id, dupKey);
      await fail(id, const SocketException('x'));
      expect(await status('c1'), 'pending');
    });

    test('a transient failure neither counts nor clears the permanent streak', () async {
      await addCustomer('c1');
      final id = await idOf('c1');
      await fail(id, dupKey);
      await fail(id, const SocketException('x'));
      await fail(id, dupKey);
      await fail(id, TimeoutException('t'));
      expect(await status('c1'), 'pending', reason: 'only 2 permanent so far');
      await fail(id, dupKey);
      expect(await status('c1'), 'error', reason: 'the 3rd permanent one, transients in between ignored');
    });

    test('the local "no matching product/order" skips count as permanent', () async {
      await addCustomer('c1');
      final id = await idOf('c1');
      for (var i = 0; i < 3; i++) {
        await engine.recordPushFailureForTest('customers', id, permanent: true);
      }
      expect(await status('c1'), 'error');
    });

    test('streaks are per row', () async {
      await addCustomer('c1');
      await addCustomer('c2');
      final a = await idOf('c1'), b = await idOf('c2');
      await fail(a, dupKey);
      await fail(b, dupKey);
      await fail(a, dupKey);
      await fail(b, dupKey);
      expect(await status('c1'), 'pending');
      await fail(a, dupKey);
      expect(await status('c1'), 'error');
      expect(await status('c2'), 'pending');
    });
  });

  test('a flagged row is no longer pushed (push selects only pending)', () async {
    await addCustomer('c1');
    final id = await idOf('c1');
    for (var i = 0; i < 3; i++) {
      await fail(id, dupKey);
    }
    await engine.performPush();
    expect(engine.pushFailureCount, 0, reason: 'nothing left to attempt');
  });

  test('a successful push clears the permanent-failure count', () async {
    await addCustomer('c1');
    final id = await idOf('c1');
    await fail(id, dupKey);
    await fail(id, dupKey); // 2 permanent failures recorded
    final row = await (db.select(db.customers)..where((c) => c.uuid.equals('c1'))).getSingle();
    await engine.markRecordSyncedForTest(row); // a push of that row succeeded
    expect(await status('c1'), 'synced');

    await db.updateCustomer(row.uuid, const CustomersCompanion(name: Value('edited'))); // helpers force pending
    await fail(id, dupKey);
    await fail(id, dupKey);
    expect(await status('c1'), 'pending', reason: 'only 2 since the success');
    await fail(id, dupKey);
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

  test('the push result reports failed rows (transient too), and performFullSync carries the count', () async {
    await addCustomer('c1');
    await addCustomer('c2');
    final push = await manager.push();
    expect(push['failedCount'], 2, reason: 'a transient failure still means the row did not upload this time');
    expect(push['success'], isFalse);
    expect((push['failedTables'] as Map)['customers'], 2);
    expect(push['error'], contains('2 records could not be uploaded'));
    expect(await status('c1'), 'pending', reason: 'but it is not flagged');

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
