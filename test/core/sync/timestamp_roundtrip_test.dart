import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';

/// Every timestamp leaving the device must carry an explicit offset ("Z").
/// A LOCAL DateTime's toIso8601String() has none ("2026-11-19T14:00:00.000"),
/// Postgres timestamptz reads that as 14:00 UTC, and in Manila (UTC+8) every
/// round trip then ADDED 8 hours. The pull parsed it back and the next push
/// did it again, forever.
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    engine = SyncEngine(db);
  });
  tearDown(() => db.close());

  final stamp = RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d');
  final hasOffset = RegExp(r'(Z|[+-]\d\d:?\d\d)$');

  /// What Postgres does with a timestamptz literal (session time zone UTC).
  DateTime postgresStores(String s) => hasOffset.hasMatch(s) ? DateTime.parse(s) : DateTime.parse('${s}Z');

  /// What PostgREST sends back for a timestamptz.
  String postgrestReturns(DateTime instant) => instant.toUtc().toIso8601String().replaceFirst('Z', '+00:00');

  // A fixed, unambiguous local wall-clock time.
  final local = DateTime(2026, 11, 19, 14, 0, 0);

  test('every timestamp in every push payload carries an offset', () async {
    await db.createOrder(OrdersCompanion.insert(
        uuid: 'o1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x',
        createdAt: Value(local), updatedAt: Value(local), packedAt: Value(local),
        expectedDeliveryDate: Value(local), actualDeliveryDate: Value(local), orderDate: Value(local)));
    await db.createUser(UsersCompanion.insert(
        uuid: 'u1', firstName: 'A', lastName: 'B', email: 'a@b.c', passwordHash: '', role: 'customer'));
    await db.createCustomer(CustomersCompanion.insert(
        uuid: 'c1', name: 'N', municipality: 'm', province: 'p', storeType: 's', contactNumber: '0'));
    await db.createDeliveryRoute(DeliveryRoutesCompanion.insert(uuid: 'r1', routeName: 'R', municipality: 'm', deliveryDays: 'Mon'));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
        uuid: 'i1', orderId: 'o1', productId: 'p', productSku: 'S', productName: 'P', quantity: 1, unitPrice: 1, subtotal: 1,
        totalAmount: 1, pickedAt: Value(local)));
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
        uuid: 'm1', productId: 'p', movementType: 'in', quantity: 1, reason: 'r', userId: 'u', userName: 'n'));
    final order = (await db.select(db.orders).get()).single;
    await db.createPayment(PaymentsCompanion.insert(
        paymentId: 'PAY-1', orderId: order.id, orderCode: 'ORD-1', storeName: 's', salesRepId: 0, salesRepName: 'r',
        orderAmount: 1, balance: 1, paymentDate: local));

    final records = <dynamic>[
      ...await db.select(db.orders).get(),
      ...await db.select(db.users).get(),
      ...await db.select(db.customers).get(),
      ...await db.select(db.deliveryRoutes).get(),
      ...await db.select(db.orderItems).get(),
      ...await db.select(db.stockMovements).get(),
      ...await db.select(db.payments).get(),
    ];
    var checked = 0;
    for (final r in records) {
      engine.recordToPushMap(r).forEach((k, v) {
        if (v is String && stamp.hasMatch(v)) {
          checked++;
          expect(v, matches(hasOffset), reason: '${r.runtimeType}.$k = $v would be read by Postgres as UTC wall-clock time');
        }
      });
    }
    expect(checked, greaterThan(20), reason: 'the test must actually have looked at timestamps');
  });

  test('serialise -> Postgres -> PostgREST -> pull lands on the SAME instant, however many round trips', () async {
    await db.createOrder(OrdersCompanion.insert(
        uuid: 'o1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x', syncStatus: const Value('synced'),
        createdAt: Value(local), updatedAt: Value(local), packedAt: Value(local),
        expectedDeliveryDate: Value(local), actualDeliveryDate: Value(local), orderDate: Value(local)));

    for (var trip = 1; trip <= 3; trip++) {
      final row = (await db.getOrderById('o1'))!;
      final pushed = engine.recordToPushMap(row);
      final server = <String, dynamic>{
        for (final k in ['created_at', 'updated_at', 'packed_at', 'expected_delivery_date', 'actual_delivery_date', 'order_date'])
          k: postgrestReturns(postgresStores(pushed[k] as String)),
        'id': row.id,
        'uuid': 'o1',
        'order_number': 'ORD-1',
      };
      await engine.applyPulledRecord('orders', server);
      final back = (await db.getOrderById('o1'))!;
      for (final (name, got) in [
        ('createdAt', back.createdAt),
        ('updatedAt', back.updatedAt),
        ('packedAt', back.packedAt),
        ('expectedDeliveryDate', back.expectedDeliveryDate),
        ('actualDeliveryDate', back.actualDeliveryDate),
        ('orderDate', back.orderDate),
      ]) {
        expect(got!.isAtSameMomentAs(local), isTrue, reason: '$name drifted by ${got.difference(local)} after round trip $trip');
      }
    }
  });

  test('the pull parses an offset-bearing string to the correct instant', () async {
    await db.createOrder(OrdersCompanion.insert(
        uuid: 'o1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x', syncStatus: const Value('synced')));
    // 06:00 UTC == 14:00 in Manila, whichever zone this machine is in.
    await engine.applyPulledRecord('orders', {'id': 1, 'uuid': 'o1', 'created_at': '2026-11-19T06:00:00+00:00'});
    expect((await db.getOrderById('o1'))!.createdAt.isAtSameMomentAs(DateTime.utc(2026, 11, 19, 6)), isTrue);
    await engine.applyPulledRecord('orders', {'id': 1, 'uuid': 'o1', 'created_at': '2026-11-19T14:00:00+08:00'});
    expect((await db.getOrderById('o1'))!.createdAt.isAtSameMomentAs(DateTime.utc(2026, 11, 19, 6)), isTrue);
  });
}
