import 'package:drift/drift.dart' hide isNotNull, isNull, Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/constants/order_status.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';
import 'package:villahermosa_inventory_system/features/admin/widgets/order_status_badge.dart';
import 'package:villahermosa_inventory_system/features/customer/providers/customer_providers.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_order_detail_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/widgets/delivery_qr_card.dart';
import 'package:villahermosa_inventory_system/features/customer/widgets/order_progress_stepper.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_scan_screen.dart';
import 'package:villahermosa_inventory_system/features/sales/services/delivery_confirmation.dart';
import 'package:villahermosa_inventory_system/features/warehouse/providers/warehouse_providers.dart';

const _store = "Nena's Sari-Sari Store";

const _profile = CustomerProfile(
  firstName: 'Nena',
  ownerName: 'Nena Reyes',
  storeName: _store,
  customerUuid: 'c1',
  routeName: 'Boac North',
  deliveryDays: 'Mon,Thu',
  repName: 'Jun Mendoza',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  Future<int> addOrder(
    String number, {
    String status = 'pending',
    String warehouseStatus = 'pending',
    String? notes = 'Payment method: Cash on Delivery',
    double total = 1752,
    DateTime? updatedAt,
  }) =>
      db.createOrder(OrdersCompanion.insert(
        uuid: 'u-$number',
        customerId: 'c1',
        orderNumber: number,
        deliveryAddress: 'Boac',
        status: Value(status),
        warehouseStatus: Value(warehouseStatus),
        totalAmount: Value(total),
        subtotal: Value(total),
        itemCount: const Value(3),
        storeName: const Value(_store),
        routeName: const Value('Boac North'),
        salesRepName: const Value('Jun Mendoza'),
        customerNotes: Value(notes),
        updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
        expectedDeliveryDate: Value(DateTime(2026, 10, 29)),
      ));

  Future<Order> byNumber(String number) async => (await db.getOrderByCode(number))!;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ── Status model ────────────────────────────────────────────────────────────

  group('order statuses', () {
    test('labels and fulfilment helpers', () {
      expect(OrderStatus.all, ['pending', 'processing', 'out_for_delivery', 'delivered', 'completed', 'cancelled']);
      expect(OrderStatus.label('out_for_delivery'), 'Out for Delivery');
      expect(OrderStatus.label('processing'), 'Processing');
      expect(OrderStatus.label('some_new_status'), 'Some New Status');
      expect(OrderStatus.isInFulfilment('out_for_delivery'), isTrue);
      expect(OrderStatus.isInFulfilment('delivered'), isFalse);
      expect(OrderStatus.isFinished('delivered'), isTrue);
      expect(OrderStatus.isFinished('processing'), isFalse);
    });

    testWidgets('the badge handles all six statuses', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Column(children: [for (final s in OrderStatus.all) OrderStatusBadge(status: s)])),
      ));
      for (final label in ['Pending', 'Processing', 'Out for Delivery', 'Delivered', 'Completed', 'Cancelled']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('the stepper reads "Completed ✓" once the customer confirmed', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OrderProgressStepper(currentStep: 3, completed: true)),
      ));
      expect(find.text('Completed ✓'), findsOneWidget);
      expect(find.text('Delivered'), findsNothing);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OrderProgressStepper(currentStep: 0)),
      ));
      expect(find.text('Order Placed'), findsOneWidget);
    });
  });

  // ── Database helpers ────────────────────────────────────────────────────────

  group('database helpers', () {
    test('getOrderByCode matches the order number, ignoring case and spaces', () async {
      await addOrder('ORD-2408');
      expect((await db.getOrderByCode('ORD-2408'))?.orderNumber, 'ORD-2408');
      expect((await db.getOrderByCode('  ord-2408 '))?.orderNumber, 'ORD-2408');
      expect(await db.getOrderByCode('ORD-9999'), isNull);
    });

    test('updateOrderStatusById sets status, flags sync and stamps delivery', () async {
      final id = await addOrder('ORD-1', status: 'out_for_delivery');
      await db.updateOrderStatusById(id, 'delivered');
      var o = await byNumber('ORD-1');
      expect(o.status, 'delivered');
      expect(o.syncStatus, 'pending');
      expect(o.actualDeliveryDate, isNotNull);

      await db.updateOrderStatusById(id, 'completed');
      o = await byNumber('ORD-1');
      expect(o.status, 'completed');
    });
  });

  // ── Scan logic ──────────────────────────────────────────────────────────────

  group('confirmDeliveryByCode', () {
    test('unknown or empty code → not found', () async {
      expect(await confirmDeliveryByCode(db, 'ORD-0000'), isA<ScanNotFound>());
      expect(await confirmDeliveryByCode(db, '   '), isA<ScanNotFound>());
    });

    test('only out-for-delivery orders can be confirmed', () async {
      await addOrder('ORD-P', status: 'pending');
      await addOrder('ORD-X', status: 'processing');
      await addOrder('ORD-D', status: 'delivered');
      await addOrder('ORD-C', status: 'cancelled');
      for (final (code, status) in [('ORD-P', 'pending'), ('ORD-X', 'processing'), ('ORD-D', 'delivered'), ('ORD-C', 'cancelled')]) {
        final r = await confirmDeliveryByCode(db, code);
        expect(r, isA<ScanWrongStatus>(), reason: code);
        expect((r as ScanWrongStatus).status, status);
        expect((await byNumber(code)).status, status, reason: '$code must be untouched');
      }
    });

    test('success marks the order delivered, flags sync, and reports what to collect', () async {
      await addOrder('ORD-2408', status: 'out_for_delivery');
      final r = await confirmDeliveryByCode(db, ' ord-2408 ');
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

      // Scanning again (e.g. a double scan) is refused, not re-applied.
      expect(await confirmDeliveryByCode(db, 'ORD-2408'), isA<ScanWrongStatus>());
    });

    test('payment method comes from the order notes, defaulting to cash on delivery', () async {
      await addOrder('ORD-G', status: 'out_for_delivery', notes: 'Payment method: GCash');
      final g = await confirmDeliveryByCode(db, 'ORD-G') as ScanSuccess;
      expect(g.paymentMethod, 'GCash');
      expect(g.collectOnDelivery, isFalse);

      await addOrder('ORD-N', status: 'out_for_delivery', notes: null);
      final n = await confirmDeliveryByCode(db, 'ORD-N') as ScanSuccess;
      expect(n.paymentMethod, 'Cash on Delivery');
    });
  });

  // ── Auto-confirm ────────────────────────────────────────────────────────────

  group('auto-confirm', () {
    test('delivered orders older than 3 days are completed; nothing else is touched', () async {
      final now = DateTime(2026, 10, 27, 12);
      await addOrder('ORD-OLD', status: 'delivered', updatedAt: now.subtract(const Duration(days: 4)));
      await addOrder('ORD-NEW', status: 'delivered', updatedAt: now.subtract(const Duration(days: 2)));
      await addOrder('ORD-OUT', status: 'out_for_delivery', updatedAt: now.subtract(const Duration(days: 9)));
      await addOrder('ORD-DONE', status: 'completed', updatedAt: now.subtract(const Duration(days: 9)));

      final n = await SyncEngine(db).autoConfirmDeliveries(now: now);
      expect(n, 1);

      final old = await byNumber('ORD-OLD');
      expect(old.status, 'completed');
      expect(old.syncStatus, 'pending');
      expect((await byNumber('ORD-NEW')).status, 'delivered');
      expect((await byNumber('ORD-OUT')).status, 'out_for_delivery');
      expect((await byNumber('ORD-DONE')).status, 'completed');

      // Idempotent.
      expect(await SyncEngine(db).autoConfirmDeliveries(now: now), 0);
    });
  });

  // ── Warehouse ───────────────────────────────────────────────────────────────

  group('warehouse lifecycle', () {
    test('whOrderStatus reads the new statuses', () async {
      await addOrder('ORD-1', status: 'pending');
      await addOrder('ORD-2', status: 'out_for_delivery');
      await addOrder('ORD-3', status: 'delivered');
      await addOrder('ORD-4', status: 'completed');
      expect(whOrderStatus(await byNumber('ORD-1')), 'pending');
      expect(whOrderStatus(await byNumber('ORD-2')), 'dispatched');
      expect(whOrderStatus(await byNumber('ORD-3')), 'completed');
      expect(whOrderStatus(await byNumber('ORD-4')), 'completed');
      expect(needsPreparing(await byNumber('ORD-2')), isFalse);
    });

    test('process → complete picklist → dispatch walks pending → processing → out_for_delivery', () async {
      await addOrder('ORD-W');
      final actions = WarehouseActions(db);

      await actions.processOrder(await byNumber('ORD-W'));
      var o = await byNumber('ORD-W');
      expect(o.status, 'processing');
      expect(o.syncStatus, 'pending');

      await actions.completeOrder(o, const []);
      o = await byNumber('ORD-W');
      expect(o.status, 'processing'); // ready for loading, not yet on the truck
      expect(whOrderStatus(o), 'ready');

      // Mark it synced to prove dispatch re-flags it for sync.
      await (db.update(db.orders)..where((t) => t.id.equals(o.id))).write(const OrdersCompanion(syncStatus: Value('synced')));
      final n = await actions.dispatchOrders([await byNumber('ORD-W')]);
      expect(n, 1);
      o = await byNumber('ORD-W');
      expect(o.status, 'out_for_delivery');
      expect(o.syncStatus, 'pending');
      expect(whOrderStatus(o), 'dispatched');
    });
  });

  // ── Customer order detail ───────────────────────────────────────────────────

  group('customer order detail', () {
    final overrides = [customerProfileProvider.overrideWithValue(_profile)];

    Future<void> open(WidgetTester tester, String number, {Size size = const Size(390, 2000)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: CustomerOrderDetailScreen(orderUuid: 'u-$number')),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('pending / processing: stepper only, no QR', (tester) async {
      await addOrder('ORD-1', status: 'pending');
      await open(tester, 'ORD-1');
      expect(find.byType(OrderProgressStepper), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Confirm Receipt'), findsNothing);
      expect(find.text('Pending'), findsOneWidget);
      await close(tester);
    });

    testWidgets('out for delivery: QR with the order number and the rep instruction', (tester) async {
      await addOrder('ORD-2408', status: 'out_for_delivery');
      await open(tester, 'ORD-2408');
      expect(find.text('Show this to your sales rep'), findsOneWidget);
      expect(find.text('Your rep will scan this to confirm delivery'), findsOneWidget);
      // The card encodes the order number — what the rep's scanner looks up.
      expect(tester.widget<DeliveryQrCard>(find.byType(DeliveryQrCard)).orderNumber, 'ORD-2408');
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Confirm Receipt'), findsNothing);
      expect(find.byKey(const ValueKey('delivered-check')), findsNothing);
      await close(tester);
    });

    testWidgets('delivered: greyed QR with a check, and Confirm Receipt completes the order', (tester) async {
      await addOrder('ORD-2408', status: 'delivered');
      await open(tester, 'ORD-2408');
      expect(find.text('Delivered by Jun Mendoza'), findsOneWidget);
      expect(find.text('Please confirm you received your order'), findsOneWidget);
      expect(find.byKey(const ValueKey('delivered-check')), findsOneWidget);
      expect(find.text('Tap to confirm you received all items'), findsOneWidget);

      await tester.tap(find.text('Confirm Receipt'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Thank you! Order confirmed.'), findsOneWidget);
      final o = await tester.runAsync(() => byNumber('ORD-2408'));
      expect(o!.status, 'completed');
      expect(o.syncStatus, 'pending');

      // The screen rebuilt into the completed state.
      expect(find.text('Order Complete!'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Confirm Receipt'), findsNothing);
      expect(find.text('Completed ✓'), findsOneWidget);
      await close(tester);
    });

    testWidgets('completed: completion card instead of a QR', (tester) async {
      await addOrder('ORD-5', status: 'completed');
      await open(tester, 'ORD-5');
      expect(find.text('Order Complete!'), findsOneWidget);
      expect(find.textContaining('Received on'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      await close(tester);
    });

    testWidgets('cancelled: a Cancelled badge replaces the stepper', (tester) async {
      await addOrder('ORD-6', status: 'cancelled');
      await open(tester, 'ORD-6');
      expect(find.byType(OrderProgressStepper), findsNothing);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      await close(tester);
    });

    for (final size in const [Size(1200, 900), Size(320, 900)]) {
      testWidgets('QR states lay out cleanly at ${size.width.toInt()}px', (tester) async {
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.toString());
        try {
          for (final (i, status) in ['out_for_delivery', 'delivered', 'completed', 'cancelled'].indexed) {
            await addOrder('ORD-L$i', status: status);
            await open(tester, 'ORD-L$i', size: size);
            await close(tester);
          }
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty, reason: errors.join(' ||| '));
      });
    }
  });

  // ── Sales rep scanner screen (desktop: manual entry) ────────────────────────

  group('sales scan screen', () {
    Future<void> open(WidgetTester tester, {Size size = const Size(390, 844)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SalesScanScreen())));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> enterCode(WidgetTester tester, String code) async {
      // The scan line animates forever, so pumpAndSettle can't be used. A route
      // needs one frame to start its transition and a second to finish it.
      await tester.tap(find.text('Enter order number instead'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Enter Order Number'), findsOneWidget);
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Confirm Delivery'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('desktop shows the frame and manual entry, with no camera widget', (tester) async {
      await open(tester);
      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.text('Enter order number instead'), findsOneWidget);
      expect(find.byType(MobileScanner), findsNothing);
      expect(find.byTooltip('Torch'), findsNothing);
      expect(scannerCameraSupported, isFalse);
      await close(tester);
    });

    testWidgets('typing an order number confirms the delivery and shows what to collect', (tester) async {
      await addOrder('ORD-2408', status: 'out_for_delivery');
      await open(tester);
      await enterCode(tester, 'ord-2408');

      expect(find.text('Delivery Confirmed!'), findsOneWidget);
      expect(find.text(_store), findsOneWidget);
      expect(find.text('ORD-2408'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Collect ₱1,752'), findsOneWidget);
      expect(find.text('Saved on this phone · will sync when online'), findsOneWidget);

      final o = await tester.runAsync(() => byNumber('ORD-2408'));
      expect(o!.status, 'delivered');
      await close(tester);
    });

    testWidgets('an unknown code shows Order Not Found, and Try Again clears it', (tester) async {
      await open(tester);
      await enterCode(tester, 'ORD-0000');
      expect(find.text('Order Not Found'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Enter Manually'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Order Not Found'), findsNothing);
      await close(tester);
    });

    testWidgets('an order that is not out for delivery is refused with a reason', (tester) async {
      await addOrder('ORD-3001', status: 'pending');
      await open(tester);
      await enterCode(tester, 'ORD-3001');
      expect(find.text("Can't Confirm This Order"), findsOneWidget);
      expect(find.textContaining('has not been dispatched yet'), findsOneWidget);
      final o = await tester.runAsync(() => byNumber('ORD-3001'));
      expect(o!.status, 'pending');
      await close(tester);
    });

    for (final size in const [Size(1200, 800), Size(320, 640)]) {
      testWidgets('lays out cleanly at ${size.width.toInt()}px, including the result card', (tester) async {
        await addOrder('ORD-OK', status: 'out_for_delivery');
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.toString());
        try {
          await open(tester, size: size);
          await enterCode(tester, 'ORD-OK');
          expect(find.text('Delivery Confirmed!'), findsOneWidget);
          await close(tester);
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty, reason: errors.join(' ||| '));
      });
    }
  });
}
