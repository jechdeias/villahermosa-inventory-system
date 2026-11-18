import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/theme/app_theme.dart';
import 'package:villahermosa_inventory_system/core/widgets/responsive_shell.dart';
import 'package:villahermosa_inventory_system/core/widgets/sync_status_indicator.dart';
import 'package:villahermosa_inventory_system/features/customer/widgets/customer_shell.dart';
import 'package:villahermosa_inventory_system/features/sales/widgets/sales_shell.dart';
import 'package:villahermosa_inventory_system/features/warehouse/widgets/warehouse_shell.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
  });
  tearDown(() => db.close());

  Future<void> addCustomer(String uuid, {String status = 'pending'}) => db.createCustomer(CustomersCompanion.insert(
        uuid: uuid, name: 'N', municipality: 'm', province: 'p', storeType: 's', contactNumber: '0', syncStatus: Value(status)));

  Future<void> addOrder(String uuid, {String status = 'pending'}) => db.createOrder(OrdersCompanion.insert(
        uuid: uuid, customerId: 'c', orderNumber: 'ORD-$uuid', deliveryAddress: 'x', syncStatus: Value(status)));

  // A Drift-visible "mark synced" (notifies streams).
  Future<void> markEverythingSynced() async {
    await db.update(db.customers).write(const CustomersCompanion(syncStatus: Value('synced')));
    await db.update(db.orders).write(const OrdersCompanion(syncStatus: Value('synced')));
  }

  // What SyncEngine._markRecordAsSynced really does: a raw customUpdate with no
  // `updates:` set, which Drift streams cannot see.
  Future<void> markSyncedSilently() => db.customUpdate("UPDATE orders SET sync_status = 'synced'");

  group('pending count', () {
    test('reflects pending rows per table and drops to zero after a successful sync', () async {
      final seen = <Map<String, int>>[];
      final sub = db.watchPendingCounts().listen(seen.add);
      Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

      await settle();
      expect(seen.last, isEmpty, reason: 'nothing pending on a fresh database');

      await addOrder('o1');
      await addOrder('o2');
      await addCustomer('c1');
      await addOrder('o3', status: 'synced'); // already synced: not counted
      await settle();
      expect(seen.last, {'customers': 1, 'orders': 2});
      expect(await db.watchPendingCount().first, 3);

      await markEverythingSynced();
      await settle();
      expect(seen.last, isEmpty, reason: 'the count clears once the push marks rows synced');
      expect(await db.watchPendingCount().first, 0);
      await sub.cancel();
    });

    test('soft-deleted rows still count (they have to push)', () async {
      await addCustomer('c1', status: 'synced');
      await db.softDeleteCustomer('c1'); // forces pending
      expect(await db.watchPendingCount().first, 1);
    });
  });

  group('four states', () {
    test('state, text and colour', () {
      expect(syncStateFor(online: true, pending: 0), SyncIndicatorState.allSynced);
      expect(syncStateFor(online: true, pending: 4), SyncIndicatorState.syncing);
      expect(syncStateFor(online: false, pending: 4), SyncIndicatorState.waitingOffline);
      expect(syncStateFor(online: false, pending: 0), SyncIndicatorState.offline);

      expect(syncLabelFor(SyncIndicatorState.allSynced, 0), 'All synced');
      expect(syncLabelFor(SyncIndicatorState.syncing, 4), 'Syncing 4 items...');
      expect(syncLabelFor(SyncIndicatorState.syncing, 1), 'Syncing 1 item...');
      expect(syncLabelFor(SyncIndicatorState.waitingOffline, 4), '4 items waiting - offline');
      expect(syncLabelFor(SyncIndicatorState.offline, 0), 'Offline');

      expect(syncColorFor(SyncIndicatorState.allSynced), AppTheme.success);
      expect(syncColorFor(SyncIndicatorState.syncing), AppTheme.warning);
      expect(syncColorFor(SyncIndicatorState.waitingOffline), AppTheme.warning);
      expect(syncColorFor(SyncIndicatorState.offline), AppTheme.textMuted);
    });

    Future<void> pumpIndicator(WidgetTester tester, {required bool online, bool dotOnly = false}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SyncStatusIndicator(database: db, initialOnline: online, dotOnly: dotOnly))),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    Color dotColor(WidgetTester tester) =>
        ((tester.widget<Container>(find.byKey(const Key('sync-dot'))).decoration) as BoxDecoration).color!;

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('online + 0 pending: green "All synced"', (tester) async {
      await pumpIndicator(tester, online: true);
      expect(find.text('All synced'), findsOneWidget);
      expect(dotColor(tester), AppTheme.success);
      await unmount(tester);
    });

    testWidgets('online + N pending: amber "Syncing N items..."', (tester) async {
      await tester.runAsync(() async {
        await addOrder('o1');
        await addCustomer('c1');
      });
      await pumpIndicator(tester, online: true);
      expect(find.text('Syncing 2 items...'), findsOneWidget);
      expect(dotColor(tester), AppTheme.warning);
      await unmount(tester);
    });

    testWidgets('offline + N pending: amber "N items waiting - offline"', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await pumpIndicator(tester, online: false);
      expect(find.text('1 item waiting - offline'), findsOneWidget);
      expect(dotColor(tester), AppTheme.warning);
      await unmount(tester);
    });

    testWidgets('offline + 0 pending: grey "Offline"', (tester) async {
      await pumpIndicator(tester, online: false);
      expect(find.text('Offline'), findsOneWidget);
      expect(dotColor(tester), AppTheme.textMuted);
      await unmount(tester);
    });

    testWidgets('it re-reads on the sync-completed signal — no timer — because sync marks rows synced silently', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      final cycleEnded = ValueNotifier<int>(0);
      addTearDown(cycleEnded.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: SyncStatusIndicator(database: db, initialOnline: true, syncCompleted: cycleEnded)),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Syncing 1 item...'), findsOneWidget);

      // What _markRecordAsSynced does: a raw customUpdate Drift streams can't see.
      await tester.runAsync(markSyncedSilently);

      // Time passing alone changes nothing: there is no polling timer.
      await tester.pump(const Duration(seconds: 30));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Syncing 1 item...'), findsOneWidget, reason: 'stale until a cycle ends');

      // The cycle ends: the indicator re-reads, once.
      cycleEnded.value++;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('All synced'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('it follows connectivity changes live', (tester) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SyncStatusIndicator(database: db, initialOnline: true, onlineStream: online.stream))),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('All synced'), findsOneWidget);

      online.add(false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Offline'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('dot-only (narrow) keeps the colour, hides the label, shows the number', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await pumpIndicator(tester, online: true, dotOnly: true);
      expect(find.text('Syncing 1 item...'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(dotColor(tester), AppTheme.warning);
      await unmount(tester);
    });
  });

  group('every role gets it from its shell', () {
    Future<void> pumpAt(WidgetTester tester, double width, Widget app) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: app)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('admin (ResponsiveShell, desktop sidebar)', (tester) async {
      await pumpAt(tester, 1400, ResponsiveShell(database: db, selectedRoute: '/admin/dashboard', child: const SizedBox()));
      expect(find.byType(SyncStatusIndicator), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('admin (ResponsiveShell, mobile app bar)', (tester) async {
      await pumpAt(tester, 400, ResponsiveShell(database: db, selectedRoute: '/admin/dashboard', child: const SizedBox()));
      expect(find.byType(SyncStatusIndicator), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('warehouse (WarehouseShell wraps ResponsiveShell)', (tester) async {
      await pumpAt(tester, 1400, const WarehouseShell(route: '/warehouse/dashboard', child: SizedBox()));
      expect(find.byType(SyncStatusIndicator), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('customer (CustomerShell)', (tester) async {
      await pumpAt(tester, 400, const CustomerShell(currentRoute: CustomerRoutes.shop, child: SizedBox()));
      // Idle: the strip is its hairline; it opens to the indicator when there is something to say.
      expect(find.byType(SyncStatusStrip), findsOneWidget);
      expect(find.byKey(const Key('sync-strip-collapsed')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('sales rep and delivery (SalesShell — both roles land on /sales/home)', (tester) async {
      await pumpAt(tester, 400, const SalesShell(currentRoute: '/sales/home', child: SizedBox()));
      expect(find.byType(SyncStatusStrip), findsOneWidget);
      expect(find.byKey(const Key('sync-strip-collapsed')), findsOneWidget);
      await unmount(tester);
    });
  });

  group('tapping opens the sheet', () {
    testWidgets('per-table breakdown, last sync, and a Sync now button that runs a sync', (tester) async {
      await tester.runAsync(() async {
        await addOrder('o1');
        await addOrder('o2');
        await addCustomer('c1');
      });
      var syncs = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SyncStatusIndicator(
              database: db,
              initialOnline: true,
              lastSync: () => DateTime(2026, 11, 19, 9, 5),
              onSyncNow: () async => syncs++,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Syncing 3 items...'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('2 orders'), findsOneWidget);
      expect(find.text('1 customer'), findsOneWidget);
      expect(find.text('WAITING TO UPLOAD'), findsOneWidget);
      expect(find.text('Last sync: 2026-11-19 09:05'), findsOneWidget);

      await tester.tap(find.text('Sync now'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(syncs, 1);

      // Closing the sheet and unmounting leaves no timers behind.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a failed sync is reported inside the sheet', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SyncStatusIndicator(database: db, initialOnline: true, onSyncNow: () async => throw Exception('no route to host')),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Syncing 1 item...'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Sync now'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining("Couldn't sync"), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('SyncStatusStrip collapses to a hairline when there is nothing to say', () {
    Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
          builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion), child: c!),
          home: Scaffold(body: child),
        );

    Widget strip({bool online = true, Future<void> Function()? onSyncNow}) => SizedBox(
          height: 100,
          child: SyncStatusScope(
            database: db,
            initialOnline: online,
            child: SyncStatusStrip(onSyncNow: onSyncNow, lastSync: () => DateTime(2026, 11, 19, 9, 5), child: const SizedBox()),
          ),
        );

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('online and idle: a 3px hairline in the green token, not zero', (tester) async {
      await tester.pumpWidget(app(strip()));
      await settle(tester);
      expect(find.byKey(const Key('sync-strip')), findsNothing);
      expect(tester.getSize(find.byKey(const Key('sync-strip-collapsed'))).height, 3);
      final hairline = tester.widget<Container>(find.byKey(const Key('sync-strip-collapsed')));
      expect(hairline.color, AppTheme.success);
      // The tap target is bigger than the line but adds no layout height.
      expect(tester.getSize(find.byKey(const Key('sync-hairline-target'))).height, 20);
      expect(tester.getSize(find.byType(SyncStatusStrip)).height, 100, reason: 'the strip fills its parent; only 3px of it is the hairline');
      await unmount(tester);
    });

    testWidgets('pending rows: opens to full height', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await tester.pumpWidget(app(strip()));
      await settle(tester);
      expect(tester.getSize(find.byKey(const Key('sync-strip'))).height, kSyncStripHeight);
      expect(find.text('Syncing 1 item...'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('offline (nothing pending): opens to full height', (tester) async {
      await tester.pumpWidget(app(strip(online: false)));
      await settle(tester);
      expect(tester.getSize(find.byKey(const Key('sync-strip'))).height, kSyncStripHeight);
      expect(find.text('Offline'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('it closes again once everything has synced', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await tester.pumpWidget(app(strip()));
      await settle(tester);
      expect(find.byKey(const Key('sync-strip')), findsOneWidget);

      await tester.runAsync(markEverythingSynced);
      await settle(tester);
      expect(find.byKey(const Key('sync-strip')), findsNothing);
      expect(tester.getSize(find.byKey(const Key('sync-strip-collapsed'))).height, 3, reason: 'closes back to the hairline');
      await unmount(tester);
    });

    testWidgets('tapping the hairline (anywhere in its ~20px target) opens the sync sheet', (tester) async {
      var syncs = 0;
      await tester.pumpWidget(app(strip(onSyncNow: () async => syncs++)));
      await settle(tester);

      // Not on the 3px line itself: 15px below the top, inside the invisible target.
      await tester.tapAt(tester.getTopLeft(find.byKey(const Key('sync-hairline-target'))) + const Offset(100, 15));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('All synced'), findsOneWidget);
      expect(find.text('Nothing is waiting to upload.'), findsOneWidget);
      expect(find.text('Last sync: 2026-11-19 09:05'), findsOneWidget);
      await tester.tap(find.text('Sync now'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(syncs, 1);

      await tester.tapAt(const Offset(5, 5)); // dismiss the sheet
      await tester.pump(const Duration(milliseconds: 400));
      await unmount(tester);
    });

    testWidgets('while open (pending), there is no hairline target to steal taps from the content', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await tester.pumpWidget(app(strip()));
      await settle(tester);
      expect(find.byKey(const Key('sync-hairline-target')), findsNothing);
      await unmount(tester);
    });

    testWidgets('it animates open (mid-way height) and snaps open with reduced motion', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await tester.pumpWidget(app(strip()));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(); // the count arrives, the strip starts opening
      await tester.pump(const Duration(milliseconds: 60));
      final midway = tester.getSize(find.byType(AnimatedSize)).height;
      expect(midway, greaterThan(3));
      expect(midway, lessThan(kSyncStripHeight), reason: 'still sliding open');
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getSize(find.byType(AnimatedSize)).height, kSyncStripHeight);
      await unmount(tester);

      await tester.pumpWidget(app(strip(), reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(AnimatedSize), findsNothing, reason: 'no animation widget with reduced motion');
      expect(tester.getSize(find.byKey(const Key('sync-strip'))).height, kSyncStripHeight, reason: 'open at once');
      await unmount(tester);
    });
  });

  group('one indicator per mobile shell: no dot over the nav bar', () {
    testWidgets('CustomerShell and SalesShell show the hairline strip and no SyncStatusDot', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final shell in <Widget>[
        const CustomerShell(currentRoute: CustomerRoutes.shop, child: SizedBox()),
        const SalesShell(currentRoute: '/sales/home', child: SizedBox()),
      ]) {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(ProviderScope(child: MaterialApp(home: shell)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const Key('sync-dot')), findsNothing, reason: 'idle: no floating dot');
        expect(find.byKey(const Key('sync-strip-collapsed')), findsOneWidget, reason: 'the hairline is the always-visible signal');
        expect(find.byType(SyncStatusIndicator), findsNothing, reason: 'nothing overlays the bottom nav');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
  });

  group('fourth state: RED for rows that will not sync (sync_status error)', () {
    test('state, text and colour — errors outrank everything, online or not', () {
      expect(syncStateFor(online: true, pending: 0, errors: 2), SyncIndicatorState.error);
      expect(syncStateFor(online: false, pending: 5, errors: 1), SyncIndicatorState.error);
      expect(syncStateFor(online: true, pending: 3), SyncIndicatorState.syncing, reason: 'no errors: unchanged');
      expect(syncLabelFor(SyncIndicatorState.error, 0, errors: 1), '1 item could not sync - contact your administrator');
      expect(syncLabelFor(SyncIndicatorState.error, 0, errors: 3), '3 items could not sync - contact your administrator');
      expect(syncColorFor(SyncIndicatorState.error), AppTheme.error);
    });

    testWidgets('the pill turns red, and the sheet lists what is stuck per table', (tester) async {
      await tester.runAsync(() async {
        await addCustomer('c1', status: 'error');
        await addOrder('o1', status: 'error');
        await addOrder('o2', status: 'error');
        await addOrder('o3'); // an ordinary pending row alongside
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SyncStatusIndicator(database: db, initialOnline: true, dotOnly: false))),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('3 items could not sync - contact your administrator'), findsOneWidget);
      final dot = tester.widget<Container>(find.byKey(const Key('sync-dot'))).decoration as BoxDecoration;
      expect(dot.color, AppTheme.error);

      await tester.tap(find.text('3 items could not sync - contact your administrator'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('sync-stuck-section')), findsOneWidget);
      expect(find.text('COULD NOT UPLOAD'), findsOneWidget);
      expect(find.text('2 orders'), findsOneWidget, reason: 'stuck orders');
      expect(find.text('1 customer'), findsOneWidget, reason: 'stuck customer');
      expect(find.text('1 order'), findsOneWidget, reason: 'the ordinary pending order is still listed under waiting');
      expect(find.textContaining('Contact your administrator'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('no error rows: no red anywhere', (tester) async {
      await tester.runAsync(() => addOrder('o1'));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SyncStatusIndicator(database: db, initialOnline: true, dotOnly: false))),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Syncing 1 item...'), findsOneWidget);
      expect(find.textContaining('administrator'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
