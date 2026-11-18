import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/customer/providers/customer_providers.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_payments_screen.dart';

/// A customer-placed order creates its payment before any rep is assigned, with
/// the "no rep" placeholder. The rep's payments list reads payments BY REP NAME,
/// so that payment was invisible to every rep until — now — assigning a rep to
/// the order carries the rep onto the payment.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
  });
  tearDown(() => db.close());

  Future<void> addOrder(String uuid, String number, {String store = 'Tindahan A', String? rep}) => db.createOrder(OrdersCompanion.insert(
        uuid: uuid,
        customerId: 'c',
        orderNumber: number,
        deliveryAddress: 'x',
        storeName: Value(store),
        salesRepName: Value(rep),
        syncStatus: const Value('synced'),
      ));

  Future<int> addPayment(String number, {String store = 'Tindahan A', String rep = '—', String status = 'unpaid', double balance = 500, int orderId = 1}) async {
    final id = await db.createPayment(PaymentsCompanion.insert(
      paymentId: 'PAY-$number-$store',
      orderId: orderId,
      orderCode: number,
      storeName: store,
      salesRepId: 0,
      salesRepName: rep,
      orderAmount: 500,
      amountPaid: Value(500 - balance),
      balance: balance,
      paymentDate: DateTime(2026, 11, 19),
      status: Value(status),
      syncStatus: const Value('synced'),
    ));
    return id;
  }

  Future<Payment> payment(int id) async => (await db.getPaymentById(id))!;
  Future<List<Payment>> visibleTo(String rep) => db.watchPaymentsBySalesRep(rep).first;

  group('a customer-placed order\'s payment', () {
    testWidgets('is created unpaid with the placeholder, then becomes visible to the rep who delivers it', (tester) async {
      await tester.runAsync(() => db.createProduct(ProductsCompanion.insert(
          uuid: 'p1', sku: 'S', name: 'Milk', category: 'c', unitPrice: 50, costPrice: 30, unit: 'pc', currentStock: 100, minStock: 0)));
      final product = (await tester.runAsync(() => db.getProductByUuid('p1')))!;

      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: Consumer(builder: (context, r, _) {
          ref = r;
          return const SizedBox();
        })),
      ));

      // No route for the customer's town, so no rep on the profile.
      const profile = CustomerProfile(firstName: 'Cora', ownerName: 'Cora Cruz', storeName: 'Cora Store', customerUuid: 'cust-1');
      final orderNumber = (await tester.runAsync(() => placeCustomerOrder(
            ref,
            items: [CartItem(product: product, quantity: 3)],
            paymentMethod: 'Cash on Delivery',
            profile: profile,
          )))!;

      final created = (await tester.runAsync(() => db.select(db.payments).get()))!.single;
      expect(created.orderCode, orderNumber);
      expect(created.status, 'unpaid', reason: "'credit' is the admin's deliberate decision, not a fresh order's");
      expect(created.balance, 150);
      expect(AppDatabase.isUnassignedRepName(created.salesRepName), isTrue);

      // Today's bug: invisible to every rep.
      expect(await tester.runAsync(() => visibleTo('Rita Rep')), isEmpty);

      // Admin assigns Rita in order detail.
      final order = (await tester.runAsync(() => db.getOrderByCode(orderNumber)))!;
      await tester.runAsync(() => db.assignOrderRoute(order.uuid, routeId: 1, routeName: 'Route 1', salesRepId: 7, salesRepName: 'Rita Rep'));

      final visible = (await tester.runAsync(() => visibleTo('Rita Rep')))!;
      expect(visible.map((p) => p.orderCode), [orderNumber], reason: 'the rep who delivers it can now see and collect it');
      expect(visible.single.balance, 150);
      expect(await tester.runAsync(() => visibleTo('Someone Else')), isEmpty);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('assigning a rep to an order updates its payment row', () {
    test('rep name and id carried over, row flagged for sync', () async {
      await addOrder('o1', 'ORD-1');
      final id = await addPayment('ORD-1');

      await db.assignOrderRoute('o1', routeId: 1, routeName: 'R1', salesRepId: 7, salesRepName: 'Rita Rep');

      final p = await payment(id);
      expect(p.salesRepName, 'Rita Rep');
      expect(p.salesRepId, 7);
      expect(p.syncStatus, 'pending');
    });

    test('reassigning moves the outstanding payment to the new rep', () async {
      await addOrder('o1', 'ORD-1');
      final id = await addPayment('ORD-1');
      await db.assignOrderRoute('o1', routeId: 1, routeName: 'R1', salesRepId: 7, salesRepName: 'Rita Rep');
      await db.assignOrderRoute('o1', routeId: 2, routeName: 'R2', salesRepId: 8, salesRepName: 'Ben Rep');

      expect((await payment(id)).salesRepName, 'Ben Rep');
      expect(await visibleTo('Rita Rep'), isEmpty);
      expect(await visibleTo('Ben Rep'), hasLength(1));
    });

    test('a fully paid payment keeps the rep who collected it', () async {
      await addOrder('o1', 'ORD-1');
      final id = await addPayment('ORD-1', rep: 'Rita Rep', status: 'paid', balance: 0);
      await db.assignOrderRoute('o1', routeId: 2, routeName: 'R2', salesRepId: 8, salesRepName: 'Ben Rep');
      expect((await payment(id)).salesRepName, 'Rita Rep');
    });

    test('only that order\'s payment moves (same order code under another store is left alone)', () async {
      await addOrder('o1', 'ORD-1', store: 'Tindahan A');
      final mine = await addPayment('ORD-1', store: 'Tindahan A');
      final other = await addPayment('ORD-1', store: 'Tindahan B'); // a different device's ORD-1
      final different = await addPayment('ORD-2', store: 'Tindahan A');

      await db.assignOrderRoute('o1', routeId: 1, routeName: 'R1', salesRepId: 7, salesRepName: 'Rita Rep');

      expect((await payment(mine)).salesRepName, 'Rita Rep');
      expect(AppDatabase.isUnassignedRepName((await payment(other)).salesRepName), isTrue);
      expect(AppDatabase.isUnassignedRepName((await payment(different)).salesRepName), isTrue);
    });
  });

  group('backfill for payments already stuck on the placeholder', () {
    test('repairs the ones whose order has a rep, leaves the rest, and is idempotent', () async {
      await addOrder('o1', 'ORD-1', rep: 'Rita Rep');
      await addOrder('o2', 'ORD-2'); // no rep assigned yet
      final fixable = await addPayment('ORD-1');
      final stillUnassigned = await addPayment('ORD-2');
      final noOrder = await addPayment('ORD-9');

      expect(await db.repairUnassignedPaymentReps(), 1);
      expect((await payment(fixable)).salesRepName, 'Rita Rep');
      expect((await payment(fixable)).syncStatus, 'pending', reason: 'the repair pushes itself');
      expect(AppDatabase.isUnassignedRepName((await payment(stillUnassigned)).salesRepName), isTrue);
      expect(AppDatabase.isUnassignedRepName((await payment(noOrder)).salesRepName), isTrue);

      expect(await db.repairUnassignedPaymentReps(), 0, reason: 'nothing left to repair');
    });

    test('empty and em-dash both count as unassigned', () {
      expect(AppDatabase.isUnassignedRepName(''), isTrue);
      expect(AppDatabase.isUnassignedRepName('  '), isTrue);
      expect(AppDatabase.isUnassignedRepName('—'), isTrue);
      expect(AppDatabase.isUnassignedRepName('Rita Rep'), isFalse);
    });
  });

  group('admin payments really do show everything', () {
    test('watchAllPayments has no rep or status filter: unassigned and credit rows are included', () async {
      await addPayment('ORD-1'); // unassigned, unpaid
      await addPayment('ORD-2', store: 'B', rep: 'Rita Rep', status: 'credit');
      final all = await db.watchAllPayments().first;
      expect(all, hasLength(2));
    });
  });

  group('the rep\'s payment chips cover every status', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SalesPaymentsScreen())));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets("a 'credit' payment shows under the Credit chip, and under All", (tester) async {
      final rep = await tester.runAsync(() async {
        await db.createUser(UsersCompanion.insert(
            uuid: 'rep1', firstName: 'Rita', lastName: 'Rep', email: 'rita@vm.com', passwordHash: 'x', role: 'sales_rep'));
        await addPayment('ORD-1', store: 'Unpaid Store', rep: 'Rita Rep', status: 'unpaid');
        await addPayment('ORD-2', store: 'Credit Store', rep: 'Rita Rep', status: 'credit');
        return (await db.getUserByEmail('rita@vm.com'))!;
      });
      AuthService.instance.debugSetCurrentUser(rep);
      await pumpScreen(tester);

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Unpaid (1)'), findsOneWidget);
      expect(find.text('Credit (1)'), findsOneWidget, reason: "'credit' has a chip of its own");
      expect(find.text('Unpaid Store'), findsOneWidget);
      expect(find.text('Credit Store'), findsOneWidget);

      await tester.ensureVisible(find.text('Credit (1)'));
      await tester.tap(find.text('Credit (1)'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Credit Store'), findsOneWidget);
      expect(find.text('Unpaid Store'), findsNothing);

      await tester.ensureVisible(find.text('Unpaid (1)'));
      await tester.tap(find.text('Unpaid (1)'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Unpaid Store'), findsOneWidget);
      expect(find.text('Credit Store'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
