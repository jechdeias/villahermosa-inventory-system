import 'package:drift/drift.dart' hide isNotNull, isNull, Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_manager.dart';
import 'package:villahermosa_inventory_system/features/sales/providers/sales_providers.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_order_detail_screen.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_orders_screen.dart';
import 'package:villahermosa_inventory_system/features/sales/services/delivery_confirmation.dart';

const _store = "Nena's Sari-Sari Store";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  Future<int> addOrder(
    String number, {
    String status = 'out_for_delivery',
    String? notes = 'Payment method: Cash on Delivery',
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) =>
      db.createOrder(OrdersCompanion.insert(
        uuid: 'u-$number',
        customerId: 'c1',
        orderNumber: number,
        deliveryAddress: 'Boac',
        status: Value(status),
        totalAmount: const Value(1752),
        subtotal: const Value(1752),
        itemCount: const Value(3),
        storeName: const Value(_store),
        salesRepName: const Value('Jun Mendoza'),
        customerNotes: Value(notes),
        updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
        actualDeliveryDate: Value(deliveredAt),
      ));

  Future<Order> byNumber(String number) async => (await db.getOrderByCode(number))!;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ── The recorded confirmation method ────────────────────────────────────────

  group('delivery method in the order notes', () {
    test('append replaces an earlier line and keeps everything else', () {
      expect(appendDeliveryMethod(null, 'manual'), 'Delivery confirmed: manual');
      expect(appendDeliveryMethod('Payment method: GCash', 'qr'), 'Payment method: GCash\nDelivery confirmed: qr');
      final twice = appendDeliveryMethod(appendDeliveryMethod('Payment method: GCash', 'qr'), 'manual');
      expect(twice, 'Payment method: GCash\nDelivery confirmed: manual');
    });

    test('deliveryMethodFromNotes reads it back', () {
      expect(deliveryMethodFromNotes('Payment method: GCash\nDelivery confirmed: manual'), 'manual');
      expect(deliveryMethodFromNotes('Delivery confirmed: qr'), 'qr');
      expect(deliveryMethodFromNotes('Payment method: GCash'), isNull);
      expect(deliveryMethodFromNotes(null), isNull);
    });
  });

  // ── Manual "Mark as Delivered" ──────────────────────────────────────────────

  group('confirmDeliveryManually', () {
    test('sets status, delivered time, method=manual and syncStatus=pending — offline, local write only', () async {
      final id = await addOrder('ORD-2408');
      final before = DateTime.now();

      final r = await confirmDeliveryManually(db, id);

      expect(r, isA<ScanSuccess>());
      final ok = r as ScanSuccess;
      expect(ok.storeName, _store);
      expect(ok.orderCode, 'ORD-2408');
      expect(ok.amount, 1752);
      expect(ok.paymentMethod, 'Cash on Delivery');
      expect(ok.collectOnDelivery, isTrue);

      final o = await byNumber('ORD-2408');
      expect(o.status, 'delivered');
      expect(o.syncStatus, 'pending');
      expect(o.actualDeliveryDate, isNotNull);
      expect(o.actualDeliveryDate!.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
      expect(deliveryMethodFromNotes(o.customerNotes), 'manual');
      // The checkout's payment line survives.
      expect(o.customerNotes, contains('Payment method: Cash on Delivery'));
    });

    test('the QR scan goes through the same code path and records method=qr', () async {
      await addOrder('ORD-QR');
      final r = await confirmDeliveryByCode(db, 'ord-qr');
      expect(r, isA<ScanSuccess>());
      final o = await byNumber('ORD-QR');
      expect(o.status, 'delivered');
      expect(o.syncStatus, 'pending');
      expect(o.actualDeliveryDate, isNotNull);
      expect(deliveryMethodFromNotes(o.customerNotes), 'qr');
    });

    test('only out-for-delivery orders can be marked, and a refused order is left untouched', () async {
      for (final status in ['pending', 'processing', 'delivered', 'completed', 'cancelled']) {
        final id = await addOrder('ORD-$status', status: status);
        final r = await confirmDeliveryManually(db, id);
        expect(r, isA<ScanWrongStatus>(), reason: status);
        expect((r as ScanWrongStatus).status, status);
        final o = await byNumber('ORD-$status');
        expect(o.status, status);
        expect(deliveryMethodFromNotes(o.customerNotes), isNull, reason: '$status must not record a method');
        expect(o.actualDeliveryDate, isNull);
      }
    });

    test('an unknown order id is not found', () async {
      expect(await confirmDeliveryManually(db, 9999), isA<ScanNotFound>());
    });

    test('a second tap (stale screen) cannot deliver twice', () async {
      final id = await addOrder('ORD-DOUBLE');
      expect(await confirmDeliveryManually(db, id), isA<ScanSuccess>());
      expect(await confirmDeliveryManually(db, id), isA<ScanWrongStatus>());
    });

    test('non-cash orders show no amount to collect', () async {
      final id = await addOrder('ORD-GCASH', notes: 'Payment method: GCash');
      final r = await confirmDeliveryManually(db, id) as ScanSuccess;
      expect(r.paymentMethod, 'GCash');
      expect(r.collectOnDelivery, isFalse);
    });
  });

  // ── Auto-complete after 72h ─────────────────────────────────────────────────

  group('auto-complete (72h)', () {
    final now = DateTime(2026, 11, 3, 12);
    DateTime ago(int hours) => now.subtract(Duration(hours: hours));

    test('completes a 73h-old delivered order and leaves a 71h-old one alone', () async {
      await addOrder('ORD-73', status: 'delivered', deliveredAt: ago(73), updatedAt: ago(73));
      await addOrder('ORD-71', status: 'delivered', deliveredAt: ago(71), updatedAt: ago(71));

      final n = await SyncEngine(db).autoConfirmDeliveries(now: now);
      expect(n, 1);

      final done = await byNumber('ORD-73');
      expect(done.status, 'completed');
      expect(done.syncStatus, 'pending');
      expect((await byNumber('ORD-71')).status, 'delivered');
    });

    test('measures from the delivery time, falling back to updatedAt only when it is missing', () async {
      // updatedAt is ancient but it was delivered an hour ago -> still waiting for the customer.
      await addOrder('ORD-FRESH', status: 'delivered', deliveredAt: ago(1), updatedAt: ago(200));
      // updatedAt looks recent (a later sync touched it) but it was delivered 80h ago -> complete.
      await addOrder('ORD-STALE', status: 'delivered', deliveredAt: ago(80), updatedAt: ago(2));
      // No delivery time recorded (e.g. delivered on another phone): use updatedAt.
      await addOrder('ORD-NOTIME-OLD', status: 'delivered', updatedAt: ago(100));
      await addOrder('ORD-NOTIME-NEW', status: 'delivered', updatedAt: ago(10));

      expect(await SyncEngine(db).autoConfirmDeliveries(now: now), 2);
      expect((await byNumber('ORD-FRESH')).status, 'delivered');
      expect((await byNumber('ORD-STALE')).status, 'completed');
      expect((await byNumber('ORD-NOTIME-OLD')).status, 'completed');
      expect((await byNumber('ORD-NOTIME-NEW')).status, 'delivered');
    });

    test('only touches delivered orders, and is idempotent', () async {
      await addOrder('ORD-OUT', status: 'out_for_delivery', updatedAt: ago(500));
      await addOrder('ORD-PEND', status: 'pending', updatedAt: ago(500));
      await addOrder('ORD-DONE', status: 'completed', updatedAt: ago(500));
      await addOrder('ORD-CANC', status: 'cancelled', updatedAt: ago(500));
      await addOrder('ORD-OLD', status: 'delivered', deliveredAt: ago(90));

      final engine = SyncEngine(db);
      expect(await engine.autoConfirmDeliveries(now: now), 1);
      expect(await engine.autoConfirmDeliveries(now: now), 0);

      expect((await byNumber('ORD-OUT')).status, 'out_for_delivery');
      expect((await byNumber('ORD-PEND')).status, 'pending');
      expect((await byNumber('ORD-DONE')).status, 'completed');
      expect((await byNumber('ORD-CANC')).status, 'cancelled');
    });

    test('SyncManager runs it with no network or Supabase session (app start while offline)', () async {
      await addOrder('ORD-OLD', status: 'delivered', deliveredAt: DateTime.now().subtract(const Duration(hours: 80)));
      final manager = SyncManager(db, SyncEngine(db));
      expect(await manager.autoConfirmDeliveries(), 1);
      expect((await byNumber('ORD-OLD')).status, 'completed');
    });
  });

  // ── Sales rep UI ────────────────────────────────────────────────────────────

  group('sales rep UI', () {
    Future<List<Override>> overridesFor(WidgetTester tester, List<String> numbers) async {
      final orders = (await tester.runAsync(() async => [for (final n in numbers) await byNumber(n)]))!;
      return [salesRepOrdersProvider.overrideWith((ref) => Stream.value(orders))];
    }

    Future<void> mount(WidgetTester tester, Widget home, List<Override> overrides, {Size size = const Size(390, 900)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(home: home)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('order detail offers Scan Delivery QR and Mark as Delivered only while out for delivery', (tester) async {
      await addOrder('ORD-OUT');
      await addOrder('ORD-PEND', status: 'pending');
      await addOrder('ORD-DONE', status: 'delivered');
      final overrides = await overridesFor(tester, ['ORD-OUT', 'ORD-PEND', 'ORD-DONE']);

      await mount(tester, const SalesOrderDetailScreen(orderUuid: 'u-ORD-OUT'), overrides);
      expect(find.text('Scan Delivery QR'), findsOneWidget);
      expect(find.text('Mark as Delivered'), findsOneWidget);
      // The secondary action sits under the primary one.
      expect(tester.getTopLeft(find.text('Mark as Delivered')).dy, greaterThan(tester.getTopLeft(find.text('Scan Delivery QR')).dy));

      for (final uuid in ['u-ORD-PEND', 'u-ORD-DONE']) {
        await mount(tester, SalesOrderDetailScreen(orderUuid: uuid), overrides);
        expect(find.text('Scan Delivery QR'), findsNothing, reason: uuid);
        expect(find.text('Mark as Delivered'), findsNothing, reason: uuid);
      }
      await unmount(tester);
    });

    testWidgets('confirmation is required: disabled until the hand-over box is ticked, Cancel changes nothing', (tester) async {
      await addOrder('ORD-OUT');
      final overrides = await overridesFor(tester, ['ORD-OUT']);
      await mount(tester, const SalesOrderDetailScreen(orderUuid: 'u-ORD-OUT'), overrides);

      await tester.tap(find.text('Mark as Delivered'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirm delivery?'), findsOneWidget);
      expect(find.text(_store), findsWidgets);
      expect(find.textContaining('ORD-OUT'), findsWidgets);
      expect(find.textContaining('3 items'), findsOneWidget);
      expect(find.text('Collect ₱1,752 (Cash on Delivery)'), findsOneWidget);
      expect(find.text('Items handed to store owner/staff'), findsOneWidget);

      ElevatedButton confirmButton() => tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirm Delivery'));
      expect(confirmButton().onPressed, isNull, reason: 'no one-tap delivery');

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(confirmButton().onPressed, isNotNull);

      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Confirm delivery?'), findsNothing);
      expect((await tester.runAsync(() => byNumber('ORD-OUT')))!.status, 'out_for_delivery');
      await unmount(tester);
    });

    testWidgets('confirming shows the same success dialog as a QR scan and records a manual delivery', (tester) async {
      await addOrder('ORD-OUT');
      final overrides = await overridesFor(tester, ['ORD-OUT']);
      await mount(tester, const SalesOrderDetailScreen(orderUuid: 'u-ORD-OUT'), overrides);

      await tester.tap(find.text('Mark as Delivered'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Confirm Delivery'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Delivery Confirmed!'), findsOneWidget);
      expect(find.text('Collect ₱1,752'), findsOneWidget);
      expect(find.text('Saved on this phone · will sync when online'), findsOneWidget);

      final o = (await tester.runAsync(() => byNumber('ORD-OUT')))!;
      expect(o.status, 'delivered');
      expect(o.syncStatus, 'pending');
      expect(o.actualDeliveryDate, isNotNull);
      expect(deliveryMethodFromNotes(o.customerNotes), 'manual');

      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Delivery Confirmed!'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the Orders list gives out-for-delivery rows an actions menu, and other rows none', (tester) async {
      await addOrder('ORD-OUT');
      await addOrder('ORD-PEND', status: 'pending');
      final overrides = await overridesFor(tester, ['ORD-OUT', 'ORD-PEND']);
      await mount(tester, const SalesOrdersScreen(), overrides);

      expect(find.byIcon(Icons.more_vert), findsOneWidget, reason: 'only the out-for-delivery row');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mark as Delivered'), findsOneWidget);
      expect(find.text('Scan Delivery QR'), findsOneWidget);

      await tester.tap(find.text('Mark as Delivered'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Confirm delivery?'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('tapping an order row opens its detail', (tester) async {
      await addOrder('ORD-OUT');
      final overrides = await overridesFor(tester, ['ORD-OUT']);
      await mount(tester, const SalesOrdersScreen(), overrides);

      await tester.tap(find.textContaining('ORD-OUT · 3 items'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SalesOrderDetailScreen), findsOneWidget);
      expect(find.text('Mark as Delivered'), findsOneWidget);
      await unmount(tester);
    });

    for (final size in const [Size(1200, 800), Size(320, 640)]) {
      testWidgets('detail and confirmation dialog lay out cleanly at ${size.width.toInt()}px', (tester) async {
        await addOrder('ORD-OUT');
        final overrides = await overridesFor(tester, ['ORD-OUT']);
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.toString());
        try {
          await mount(tester, const SalesOrderDetailScreen(orderUuid: 'u-ORD-OUT'), overrides, size: size);
          await tester.tap(find.text('Mark as Delivered'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Confirm delivery?'), findsOneWidget);
          await unmount(tester);
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty, reason: errors.join(' ||| '));
      });
    }
  });
}
