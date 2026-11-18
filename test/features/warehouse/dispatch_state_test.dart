import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/loading_dispatch_screen.dart';
import 'package:villahermosa_inventory_system/features/warehouse/widgets/wh_widgets.dart';

/// The header must say WHY Dispatch is or isn't available, not leave a greyed
/// button next to "10 of 10 lines loaded" on a route that already went out.
void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
  });
  tearDown(() => db.close());

  Future<void> seed({required String warehouseStatus, required bool lineLoaded}) async {
    await db.createDeliveryRoute(DeliveryRoutesCompanion.insert(
        uuid: 'r1', routeName: 'Boac Route', municipality: 'Boac', deliveryDays: 'Mon'));
    await db.createOrder(OrdersCompanion.insert(
        uuid: 'o1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x', routeName: const Value('Boac Route'),
        storeName: const Value('Store A'), warehouseStatus: Value(warehouseStatus), status: const Value('processing'),
        updatedAt: Value(DateTime(2026, 11, 19, 9, 5))));
    await db.createOrderItem(OrderItemsCompanion.insert(
        uuid: 'i1', orderId: 'o1', productId: 'p', productSku: 'S', productName: 'Cola', quantity: 3, unitPrice: 1, subtotal: 3,
        totalAmount: 3, status: Value(lineLoaded ? 'loaded' : 'pending')));
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const WarehouseLoadingDispatchScreen())));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Order o(String wh) => Order(
      id: 1, uuid: 'x', customerId: '', orderNumber: '', status: 'processing', deliveryAddress: '', subtotal: 0, totalAmount: 0,
      warehouseStatus: wh, createdAt: DateTime(2026), updatedAt: DateTime(2026), isDeleted: false, syncStatus: 'pending', itemCount: 0);

  test('routeDispatchState', () {
    final ready = [o('ready')], gone = [o('dispatched')];
    expect(routeDispatchState(loadable: [], dispatched: [], rows: 0, allLoaded: false), DispatchState.empty);
    expect(routeDispatchState(loadable: ready, dispatched: [], rows: 2, allLoaded: false), DispatchState.needsLoading);
    expect(routeDispatchState(loadable: ready, dispatched: [], rows: 2, allLoaded: true), DispatchState.readyToDispatch);
    expect(routeDispatchState(loadable: [], dispatched: gone, rows: 2, allLoaded: false), DispatchState.dispatched);
    expect(routeDispatchState(loadable: ready, dispatched: gone, rows: 4, allLoaded: false), DispatchState.needsLoading,
        reason: 'something still ready: that is what the user must act on');
  });

  testWidgets('already dispatched: "Dispatched" with the time, no greyed Dispatch button, rows say Dispatched', (tester) async {
    await tester.runAsync(() => seed(warehouseStatus: 'dispatched', lineLoaded: true));
    await pump(tester);
    expect(find.byKey(const Key('route-dispatched')), findsOneWidget);
    expect(find.text('Dispatched 2026-11-19 09:05'), findsOneWidget);
    expect(find.text('Dispatch'), findsNothing, reason: 'no disabled button');
    expect(find.textContaining('lines loaded'), findsNothing);
    expect(find.text('Loaded'), findsNothing, reason: 'dispatched lines are not "Loaded"');
    expect(find.descendant(of: find.byType(WhTableRow), matching: find.text('Dispatched')), findsOneWidget, reason: 'the line badge');
    await unmount(tester);
  });

  testWidgets('ready but not all loaded: hint says to load all lines; button still disabled', (tester) async {
    await tester.runAsync(() => seed(warehouseStatus: 'ready', lineLoaded: false));
    await pump(tester);
    expect(find.byKey(const Key('load-all-hint')), findsOneWidget);
    expect(find.text('Load all lines to dispatch'), findsOneWidget);
    expect(find.text('0 of 1 lines loaded'), findsOneWidget);
    expect(find.text('Dispatch'), findsOneWidget);
    expect(find.byKey(const Key('route-dispatched')), findsNothing);
    await unmount(tester);
  });

  testWidgets('ready and all loaded: no hint, Dispatch available', (tester) async {
    await tester.runAsync(() => seed(warehouseStatus: 'ready', lineLoaded: true));
    await pump(tester);
    expect(find.byKey(const Key('load-all-hint')), findsNothing);
    expect(find.text('1 of 1 lines loaded'), findsOneWidget);
    expect(find.text('Dispatch'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('nothing on the route: the existing empty state, no stray "0 of 0"', (tester) async {
    await tester.runAsync(() => db.createDeliveryRoute(DeliveryRoutesCompanion.insert(
        uuid: 'r1', routeName: 'Boac Route', municipality: 'Boac', deliveryDays: 'Mon')));
    await pump(tester);
    expect(find.text('Nothing to load yet'), findsOneWidget);
    expect(find.textContaining('lines loaded'), findsNothing);
    expect(find.byKey(const Key('route-dispatched')), findsNothing);
    await unmount(tester);
  });
}
