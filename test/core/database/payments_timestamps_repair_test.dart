import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';

/// Devices that upgraded from before schema v10 have a payments table WITHOUT
/// created_at/updated_at (the v10 ADD COLUMN used a non-constant default, which
/// SQLite refuses, and the failure was swallowed). Drift's reader does
/// read(created_at)!, so every typed read of payments threw. beforeOpen now
/// rebuilds the table. These tests open a real file twice: once to damage it,
/// once to let beforeOpen repair it (the device is already at v15, so no
/// migration step runs; only beforeOpen can fix it).
void main() {
  late Directory dir;
  late File file;

  AppDatabase open() => AppDatabase.forTesting(DatabaseConnection(NativeDatabase(file)));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('payments_repair_');
    file = File('${dir.path}/test.db');
  });
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Builds a database at the current version, with payments rows, then strips
  /// created_at/updated_at the way a pre-v10 upgrade left them. Returns the db
  /// (still open) so the caller can observe the broken state.
  Future<AppDatabase> damaged() async {
    final db = open();
    await db.customStatement(
        "INSERT INTO orders (uuid, customer_id, order_number, delivery_address) VALUES ('o1','c','ORD-1','x')");
    // Non-contiguous ids on purpose: a repair that re-numbers would be caught.
    for (final (id, code, date) in [(3, 'ORD-3', 1700000300), (7, 'ORD-7', 1700000700), (12, 'ORD-12', 1700001200)]) {
      await db.customStatement(
          "INSERT INTO payments (id, payment_id, order_id, order_code, store_name, sales_rep_id, sales_rep_name, order_amount, "
          "amount_paid, balance, payment_date, status, sync_status, is_deleted) "
          "VALUES ($id, 'PAY-$id', 1, '$code', 'Store $id', 5, 'Rita', 100.5, 20, 80.5, $date, 'partial', 'pending', 0)");
    }
    await db.customStatement('ALTER TABLE payments DROP COLUMN created_at');
    await db.customStatement('ALTER TABLE payments DROP COLUMN updated_at');
    return db;
  }

  test('before the repair every typed read of payments throws; after it, it works', () async {
    final broken = await damaged();
    await expectLater(broken.getPendingSyncPayments(), throwsA(isA<TypeError>()),
        reason: 'Null check operator used on a null value');
    await broken.close();

    final fixed = open(); // beforeOpen runs the repair
    final rows = await fixed.getPendingSyncPayments();
    expect(rows.length, 3);
    await fixed.close();
  });

  test('the detector reports the gap without changing anything', () async {
    final broken = await damaged();
    final gaps = await broken.findSchemaGaps();
    expect(gaps, contains('payments: missing created_at, updated_at'));
    // Read-only: the table is still broken after detecting.
    final cols = (await broken.customSelect('PRAGMA table_info(payments)').get()).map((r) => r.read<String>('name'));
    expect(cols, isNot(contains('created_at')));
    await broken.close();

    final fixed = open();
    expect(await fixed.findSchemaGaps(), isEmpty, reason: 'repaired: no gaps in any of the ten tables');
    await fixed.close();
  });

  test('row count and ids are preserved, and so is every other column', () async {
    await (await damaged()).close();
    final db = open();
    final rows = await (db.select(db.payments)..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
    expect(rows.map((r) => r.id), [3, 7, 12], reason: 'ids preserved: order_id and the rep repair key on them');
    expect(rows.map((r) => r.orderCode), ['ORD-3', 'ORD-7', 'ORD-12']);
    expect(rows.first.storeName, 'Store 3');
    expect(rows.first.salesRepId, 5);
    expect(rows.first.orderAmount, 100.5);
    expect(rows.first.balance, 80.5);
    expect(rows.first.status, 'partial');
    expect(rows.first.syncStatus, 'pending');
    await db.close();
  });

  test('backfilled created_at and updated_at equal each row\'s payment_date (not now, not epoch)', () async {
    await (await damaged()).close();
    final db = open();
    for (final p in await db.select(db.payments).get()) {
      expect(p.createdAt, p.paymentDate, reason: 'payment ${p.id}');
      expect(p.updatedAt, p.paymentDate, reason: 'payment ${p.id}');
    }
    expect((await (db.select(db.payments)..where((p) => p.id.equals(7))).getSingle()).createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000700 * 1000));
    await db.close();
  });

  test('sqlite_sequence reflects max(id) so a new payment does not reuse an id', () async {
    await (await damaged()).close();
    final db = open();
    final seq = await db.customSelect("SELECT seq FROM sqlite_sequence WHERE name = 'payments'").getSingle();
    expect(seq.read<int>('seq'), 12);
    final newId = await db.createPayment(PaymentsCompanion.insert(
        paymentId: 'PAY-NEW', orderId: 1, orderCode: 'ORD-9', storeName: 's', salesRepId: 5, salesRepName: 'r',
        orderAmount: 1, balance: 1, paymentDate: DateTime(2026, 11, 20)));
    expect(newId, 13);
    await db.close();
  });

  test('a payment inserted after the repair gets a sensible created_at (a DEFAULT 0 regression would be 1970)', () async {
    await (await damaged()).close();
    final db = open();
    // Raw insert with no timestamps: the column DEFAULT is what fills them.
    await db.customStatement(
        "INSERT INTO payments (payment_id, order_id, order_code, store_name, sales_rep_id, sales_rep_name, order_amount, balance, payment_date) "
        "VALUES ('PAY-X', 1, 'ORD-X', 's', 5, 'r', 1, 1, 1700000000)");
    final p = await (db.select(db.payments)..where((r) => r.paymentId.equals('PAY-X'))).getSingle();
    final age = DateTime.now().difference(p.createdAt).abs();
    expect(p.createdAt.year, greaterThanOrEqualTo(2026), reason: 'not epoch');
    expect(age, lessThan(const Duration(minutes: 5)), reason: 'DEFAULT (unixepoch()) = now');
    expect(p.updatedAt.year, greaterThanOrEqualTo(2026));
    await db.close();
  });

  test('idempotent: a healthy database is left completely alone, and a second open repairs nothing', () async {
    final db = open();
    await db.customStatement(
        "INSERT INTO orders (uuid, customer_id, order_number, delivery_address) VALUES ('o1','c','ORD-1','x')");
    await db.createPayment(PaymentsCompanion.insert(
        paymentId: 'PAY-1', orderId: 1, orderCode: 'ORD-1', storeName: 's', salesRepId: 5, salesRepName: 'r',
        orderAmount: 1, balance: 1, paymentDate: DateTime(2026, 11, 1),
        createdAt: Value(DateTime(2026, 11, 2)), updatedAt: Value(DateTime(2026, 11, 3))));
    await db.close();

    final again = open();
    final p = (await again.select(again.payments).get()).single;
    expect(p.createdAt, DateTime(2026, 11, 2), reason: 'a healthy row is untouched');
    expect(p.updatedAt, DateTime(2026, 11, 3));
    expect(await again.customSelect("SELECT name FROM sqlite_master WHERE name = 'payments_old'").get(), isEmpty);
    await again.close();
  });
}
