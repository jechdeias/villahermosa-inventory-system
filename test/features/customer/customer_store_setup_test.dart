import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/admin/providers/delivery_routes_provider.dart' show deliveryRoutesStreamProvider;
import 'package:villahermosa_inventory_system/features/admin/providers/orders_provider.dart' show customersProvider;
import 'package:villahermosa_inventory_system/features/customer/providers/customer_providers.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_shop_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_store_screen.dart';

/// The customer profile is the root of the whole routing chain:
///   customers row → town → route (by municipality) → delivery days + rep
///   → the order's rep → the payment's rep.
/// A customer with no customers row (a new Google sign-in) used to be stuck:
/// both edit dialogs were gated on having one. These cover the way out.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> addRoute(String uuid, String name, String town, String? rep, String days, {String status = 'active'}) =>
      db.createDeliveryRoute(DeliveryRoutesCompanion.insert(
        uuid: uuid,
        routeName: name,
        municipality: town,
        assignedRepName: Value(rep),
        deliveryDays: days,
        status: Value(status),
      ));

  Future<User> addCustomerUser({String email = 'cora@gmail.com'}) async {
    await db.createUser(UsersCompanion.insert(
        uuid: 'user-cora', firstName: 'Cora', lastName: 'Cruz', email: email, passwordHash: '', role: 'customer'));
    final user = (await db.getUserByEmail(email))!;
    AuthService.instance.debugSetCurrentUser(user);
    return user;
  }

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
    container = ProviderContainer();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  RouteMatch match(String town, List<DeliveryRoute> routes) => matchRouteForTown(town, routes);

  Future<List<DeliveryRoute>> routes() => db.select(db.deliveryRoutes).get();

  group('which route serves a town (the loop used to have no break, so the LAST route won)', () {
    test('lowest id wins among equals, and the tie is flagged', () async {
      await addRoute('r1', 'Route 1', 'Boac', 'Rita Rep', 'Mon,Thu');
      await addRoute('r2', 'Route 1B', 'Boac', 'Ben Rep', 'Tue');
      final m = match('Boac', await routes());
      expect(m.route!.routeName, 'Route 1', reason: 'first (lowest id), not the last');
      expect(m.ambiguous, isTrue);
    });

    test('an active route beats an on-hold one; a lone route is not ambiguous', () async {
      await addRoute('r1', 'On hold route', 'Gasan', 'A', 'Mon', status: 'on_hold');
      await addRoute('r2', 'Active route', 'Gasan', 'B', 'Tue');
      var m = match('gasan', await routes()); // case-insensitive
      expect(m.route!.routeName, 'Active route');
      expect(m.ambiguous, isFalse);

      await addRoute('r3', 'Only route', 'Mogpog', 'C', 'Wed');
      m = match('Mogpog', await routes());
      expect(m.route!.routeName, 'Only route');
      expect(m.ambiguous, isFalse);
    });

    test('inactive and deleted routes do not serve a town; empty town matches nothing', () async {
      await addRoute('r1', 'Dead', 'Torrijos', 'A', 'Mon', status: 'inactive');
      await addRoute('r2', 'Gone', 'Buenavista', 'A', 'Mon');
      await db.customStatement("UPDATE delivery_routes SET is_deleted = 1 WHERE uuid = 'r2'");
      expect(match('Torrijos', await routes()).route, isNull);
      expect(match('Buenavista', await routes()).route, isNull);
      expect(match('', await routes()).route, isNull);
    });
  });

  group('the town picker', () {
    test('lists what routes serve first; other towns are offered but marked not served', () async {
      await addRoute('r1', 'Route 1', 'Boac', 'Rita', 'Mon');
      await addRoute('r2', 'Route 2', 'Gasan', 'Ben', 'Tue');
      final opts = townOptions(await routes());
      expect(opts.where((o) => o.served).map((o) => o.town), ['Boac', 'Gasan']);
      expect(opts.where((o) => !o.served).map((o) => o.town), containsAll(['Buenavista', 'Mogpog', 'Sta. Cruz', 'Torrijos']));
      expect(opts.indexWhere((o) => !o.served), greaterThan(opts.lastIndexWhere((o) => o.served)), reason: 'served first');
    });

    test('a legacy free-text town stays selectable (flagged) instead of vanishing', () async {
      final opts = townOptions(await routes(), current: 'Boak');
      expect(opts.singleWhere((o) => o.town == 'Boak').served, isFalse);
    });
  });

  group('first-run setup for a customer with no customers row', () {
    Future<void> pumpShop(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CustomerShopScreen())));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('home prompts; completing the form creates the row and fills route, delivery day and rep', (tester) async {
      await tester.runAsync(() async {
        await addCustomerUser();
        await addRoute('r1', 'Route 1', 'Boac', 'Rita Rep', 'Mon,Thu');
        await addRoute('r2', 'Route 2', 'Gasan', 'Ben Rep', 'Tue,Fri');
      });
      await pumpShop(tester);

      // Prompted, and nothing is derived yet.
      expect(find.byKey(const Key('setup-store-banner')), findsOneWidget);
      var profile = container.read(customerProfileProvider);
      expect(profile.hasCustomerRecord, isFalse);
      expect(profile.routeName, isEmpty);
      expect(profile.repName, isEmpty);

      await tester.tap(find.text('Set up now'));
      await settle(tester);
      expect(find.text('Set up your store'), findsWidgets);

      await tester.enterText(find.widgetWithText(TextFormField, 'Store name'), 'Cora Store');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contact number'), '0917 111 2222');
      await tester.tap(find.byKey(const Key('town-picker')));
      await settle(tester);
      await tester.tap(find.text('Boac').last);
      await settle(tester);

      // The consequence of the town is shown read-only, before saving.
      expect(find.byKey(const Key('route-preview')), findsOneWidget);
      expect(find.text('Route 1'), findsOneWidget);
      expect(find.text('Mon & Thu'), findsOneWidget);
      expect(find.text('Rita Rep'), findsOneWidget);

      await tester.ensureVisible(find.text('Save and continue'));
      await tester.tap(find.text('Save and continue'));
      await settle(tester);

      final row = (await tester.runAsync(() => db.getCustomerByEmail('cora@gmail.com')))!;
      expect(row.businessName, 'Cora Store');
      expect(row.name, 'Cora Cruz', reason: 'the owner is the account holder');
      expect(row.town, 'Boac');
      expect(row.municipality, 'Boac');
      expect(row.phone, '0917 111 2222');
      expect(row.syncStatus, 'pending');

      profile = (await tester.runAsync(() async {
        await container.read(customersProvider.future);
        return container.read(customerProfileProvider);
      }))!;
      expect(profile.hasCustomerRecord, isTrue);
      expect(profile.storeName, 'Cora Store');
      expect(profile.routeName, 'Route 1');
      expect(profile.deliveryDays, 'Mon,Thu');
      expect(profile.repName, 'Rita Rep');

      // The prompt is gone.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('setup-store-banner')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('orders placed before setup (local-only, keyed by the USER uuid) are re-pointed at the new customer so they can sync', (tester) async {
      late WidgetRef ref;
      await tester.runAsync(() async {
        await addCustomerUser();
        await db.createOrder(OrdersCompanion.insert(
            uuid: 'o1', customerId: 'user-cora', orderNumber: 'ORD-1', deliveryAddress: 'x', syncStatus: const Value('synced')));
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        })),
      ));

      final uuid = (await tester.runAsync(() => createStoreForCurrentUser(
          ref, const StoreDetails(storeName: 'Cora Store', town: 'Boac', phone: '0917'))))!;

      final order = (await tester.runAsync(() => db.getOrderById('o1')))!;
      expect(order.customerId, uuid);
      expect(order.syncStatus, 'pending');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('the derived route follows the town', () {
    testWidgets('changing town changes the route, delivery days and rep', (tester) async {
      late WidgetRef ref;
      await tester.runAsync(() async {
        await addCustomerUser();
        await addRoute('r1', 'Route 1', 'Boac', 'Rita Rep', 'Mon,Thu');
        await addRoute('r2', 'Route 2', 'Gasan', 'Ben Rep', 'Tue,Fri');
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        })),
      ));

      final uuid = (await tester.runAsync(() => createStoreForCurrentUser(
          ref, const StoreDetails(storeName: 'Cora Store', town: 'Boac', phone: '0917'))))!;
      Future<CustomerProfile> profile() async {
        await container.read(customersProvider.future);
        await container.read(deliveryRoutesStreamProvider.future);
        return container.read(customerProfileProvider);
      }

      var p = (await tester.runAsync(profile))!;
      expect([p.routeName, p.deliveryDays, p.repName], ['Route 1', 'Mon,Thu', 'Rita Rep']);

      await tester.runAsync(() => updateStoreDetails(ref, uuid, const StoreDetails(storeName: 'Cora Store', town: 'Gasan', phone: '0917')));
      p = (await tester.runAsync(profile))!;
      expect([p.routeName, p.deliveryDays, p.repName], ['Route 2', 'Tue,Fri', 'Ben Rep']);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('a town no route serves is reported, not silently empty', () {
    testWidgets('profile flags it, the home screen says so, and the form says "we don\'t deliver to X yet"', (tester) async {
      late WidgetRef ref;
      await tester.runAsync(() async {
        await addCustomerUser();
        await addRoute('r1', 'Route 1', 'Boac', 'Rita Rep', 'Mon,Thu');
      });
      tester.view.physicalSize = const Size(420, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Consumer(builder: (c, r, _) {
          ref = r;
          return const CustomerShopScreen();
        })),
      ));
      await tester.runAsync(() => createStoreForCurrentUser(ref, const StoreDetails(storeName: 'Far Store', town: 'Torrijos', phone: '0917')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 100));

      final p = container.read(customerProfileProvider);
      expect(p.townNotServed, isTrue);
      expect(p.routeName, isEmpty);
      expect(find.byKey(const Key('unserved-town-note')), findsOneWidget);
      expect(find.textContaining("We don't deliver to Torrijos yet"), findsOneWidget);

      // And in the edit form, right under the town.
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CustomerStoreScreen())));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('route-preview-unserved')), findsOneWidget);
      expect(find.textContaining("We don't deliver to Torrijos yet"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('editing the store', () {
    testWidgets('store name and address save and mark the row pending', (tester) async {
      late WidgetRef ref;
      await tester.runAsync(() async {
        await addCustomerUser();
        await addRoute('r1', 'Route 1', 'Boac', 'Rita Rep', 'Mon');
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        })),
      ));
      final uuid = (await tester.runAsync(() => createStoreForCurrentUser(
          ref, const StoreDetails(storeName: 'Old Name', town: 'Boac', phone: '0917', address: 'Old Street'))))!;
      await tester.runAsync(() => db.customStatement("UPDATE customers SET sync_status = 'synced'"));
      expect((await tester.runAsync(() => db.getCustomerById(uuid)))!.syncStatus, 'synced');

      await tester.runAsync(() => updateStoreDetails(
          ref, uuid, const StoreDetails(storeName: 'New Name', town: 'Boac', phone: '0917', address: 'New Street 5', barangay: 'Tanza')));

      final row = (await tester.runAsync(() => db.getCustomerById(uuid)))!;
      expect(row.businessName, 'New Name');
      expect(row.address, 'New Street 5');
      expect(row.barangay, 'Tanza');
      expect(row.syncStatus, 'pending');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('renaming the store does NOT rewrite existing orders (the name is denormalised on purpose)', (tester) async {
      late WidgetRef ref;
      await tester.runAsync(() async {
        await addCustomerUser();
        await db.createCustomer(CustomersCompanion.insert(
            uuid: 'cust-x', name: 'Cora Cruz', municipality: 'Boac', province: 'Marinduque', storeType: 's', contactNumber: '0',
            email: const Value('cora@gmail.com'), businessName: const Value('Old Name')));
        await db.createOrder(OrdersCompanion.insert(
            uuid: 'o1', customerId: 'cust-x', orderNumber: 'ORD-1', deliveryAddress: 'x', storeName: const Value('Old Name')));
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        })),
      ));
      await tester.runAsync(() => updateStoreDetails(ref, 'cust-x', const StoreDetails(storeName: 'New Name', town: 'Boac', phone: '0917')));
      expect((await tester.runAsync(() => db.getOrderById('o1')))!.storeName, 'Old Name');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
