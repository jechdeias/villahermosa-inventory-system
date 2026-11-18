import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/customer/providers/customer_providers.dart';
import 'package:villahermosa_inventory_system/features/sales/providers/sales_providers.dart';

/// A store NAME is a label the customer can edit; the customer UUID is the
/// identity. Renaming a store must not drop it from its rep's list or detach
/// the customer from their own payments.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory())));
  tearDown(() => db.close());

  Future<void> cust(String uuid, String business) => db.createCustomer(CustomersCompanion.insert(
      uuid: uuid, name: 'Owner $uuid', municipality: 'Boac', province: 'Marinduque', storeType: 's', contactNumber: '0',
      businessName: Value(business)));

  Future<void> order(String uuid, String code, String customerId, String store) => db.createOrder(OrdersCompanion.insert(
      uuid: uuid, customerId: customerId, orderNumber: code, deliveryAddress: 'x', storeName: Value(store), salesRepName: const Value('Rita')));

  Future<void> pay(String code, String store) async {
    final o = (await db.getOrderByCode(code))!;
    await db.createPayment(PaymentsCompanion.insert(
        paymentId: 'PAY-$code', orderId: o.id, orderCode: code, storeName: store, salesRepId: 0, salesRepName: 'Rita',
        orderAmount: 100, balance: 100, paymentDate: DateTime.now()));
  }

  Future<List<Customer>> mine() async => customersForRep(
      customers: await db.select(db.customers).get(),
      orders: await db.select(db.orders).get(),
      payments: await db.select(db.payments).get());

  test('a customer who renames their store stays in their rep\'s list', () async {
    await cust('c1', 'Old Name');
    await order('o1', 'ORD-1', 'c1', 'Old Name'); // placed before the rename
    await pay('ORD-1', 'Old Name');
    expect((await mine()).map((c) => c.uuid), ['c1']);

    await (db.update(db.customers)..where((c) => c.uuid.equals('c1'))).write(const CustomersCompanion(businessName: Value('New Name')));
    final after = await mine();
    expect(after.map((c) => c.uuid), ['c1'], reason: 'orders/payments still say "Old Name"; the uuid still matches');
    expect(after.single.businessName, 'New Name');
  });

  test('a payment resolves to its customer through its order, not its stale store name', () async {
    await cust('c1', 'Old Name');
    await order('o1', 'ORD-1', 'c1', 'Old Name');
    await pay('ORD-1', 'Old Name');
    await (db.update(db.customers)..where((c) => c.uuid.equals('c1'))).write(const CustomersCompanion(businessName: Value('New Name')));
    final payments = await db.select(db.payments).get();
    final got = customersForRep(customers: await db.select(db.customers).get(), orders: await db.select(db.orders).get(), payments: payments);
    expect(got.map((c) => c.uuid), ['c1']);
  });

  test('a row with no resolvable customer uuid still matches by store name', () async {
    await cust('c2', 'Mabini Store');
    await order('o2', 'ORD-2', '', 'Mabini Store'); // legacy / unlinked order: no customer uuid
    await cust('c3', 'Someone Else');
    expect((await mine()).map((c) => c.uuid), ['c2']);
  });

  test('two customers with the same store name are told apart by uuid', () async {
    await cust('c1', 'Same Name');
    await cust('c2', 'Same Name');
    await order('o1', 'ORD-1', 'c1', 'Same Name');
    expect((await mine()).map((c) => c.uuid), ['c1']);
  });

  test('the customer\'s own payments survive a rename too', () async {
    await order('o1', 'ORD-1', 'c1', 'Old Name');
    await pay('ORD-1', 'Old Name');
    await order('o9', 'ORD-9', 'other', 'Another Store');
    await pay('ORD-9', 'Another Store');
    final orders = (await db.select(db.orders).get()).where((o) => o.customerId == 'c1').toList();
    final got = paymentsForCustomer(await db.select(db.payments).get(), orders, 'New Name');
    expect(got.map((p) => p.orderCode), ['ORD-1']);
  });

  test('ambiguousMunicipalities lists towns with two in-service routes (admin banner)', () async {
    Future<void> r(String u, String town, String status) => db.createDeliveryRoute(DeliveryRoutesCompanion.insert(
        uuid: u, routeName: u, municipality: town, deliveryDays: 'Mon', status: Value(status)));
    await r('a', 'Sta. Cruz', 'active');
    await r('b', 'Sta. Cruz', 'active');
    await r('c', 'Boac', 'active');
    await r('d', 'Boac', 'inactive'); // inactive doesn't compete
    await r('e', 'Gasan', 'active');
    await r('f', 'Gasan', 'on_hold'); // active outranks on_hold: not a tie
    expect(ambiguousMunicipalities(await db.select(db.deliveryRoutes).get()), ['Sta. Cruz']);
  });
}
