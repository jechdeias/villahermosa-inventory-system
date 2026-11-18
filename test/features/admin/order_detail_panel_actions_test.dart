import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/admin/providers/orders_provider.dart';
import 'package:villahermosa_inventory_system/features/admin/widgets/order_detail_panel.dart';

/// The footer buttons used to be three equal Expanded cells in a ~330px panel, so
/// "Dispatch for Delivery" / "Mark as Delivered" wrapped mid-phrase inside the
/// pill — silently (nothing overflows or warns). They now stack at full width
/// when side-by-side wouldn't fit, and every label is maxLines: 1.
void main() {
  late AppDatabase db;

  // The default test font (Ahem) is roughly twice as wide as Inter, which would
  // make every narrow-width assertion about the font, not the layout. Load the
  // app's real font from the repo's assets.
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/google_fonts/Inter-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    }
    await loader.load();
  });

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
  });
  tearDown(() => db.close());

  Order order(String status) => Order(
        id: 1,
        uuid: 'o-1',
        customerId: 'c',
        orderNumber: 'ORD-1',
        status: status,
        deliveryAddress: 'x',
        subtotal: 0,
        totalAmount: 0,
        warehouseStatus: 'pending',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isDeleted: false,
        syncStatus: 'synced',
        itemCount: 0,
      );

  const labelFor = {
    'pending': 'Start Processing',
    'processing': 'Dispatch for Delivery',
    'out_for_delivery': 'Mark as Delivered',
    'delivered': 'Mark Completed',
    'cancelled': 'Restore Order',
  };

  Future<void> pump(WidgetTester tester, String status, double width) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [selectedOrderProvider.overrideWith((ref) => order(status))],
      child: MaterialApp(theme: ThemeData(fontFamily: 'Inter'), home: Scaffold(body: SizedBox(width: width, child: OrderDetailPanel(onClose: () {})))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  bool wraps(WidgetTester tester, String label) {
    final p = tester.renderObject<RenderParagraph>(find.text(label));
    final oneLine = p.getMaxIntrinsicHeight(double.infinity);
    return p.size.height > oneLine + 1 || p.didExceedMaxLines;
  }

  // 280 = a narrow window / phone sheet, 360 = the desktop side panel's fixed
  // width, 700 = wide enough for side by side with Inter.
  for (final width in const [280.0, 360.0, 700.0]) {
    for (final e in labelFor.entries) {
      testWidgets('${e.value} (${e.key}) never wraps at ${width.toInt()}px', (tester) async {
        await pump(tester, e.key, width);
        for (final label in [e.value, 'Export PDF', 'Close']) {
          expect(find.text(label), findsOneWidget);
          expect(wraps(tester, label), isFalse, reason: '"$label" wrapped or was cut at ${width.toInt()}px');
        }
        await unmount(tester);
      });
    }
  }

  testWidgets('narrow: buttons stack at full width, primary action first, 8px apart', (tester) async {
    await pump(tester, 'processing', 360);
    final action = tester.getRect(find.widgetWithText(ElevatedButton, 'Dispatch for Delivery'));
    final export = tester.getRect(find.widgetWithText(OutlinedButton, 'Export PDF'));
    final close = tester.getRect(find.widgetWithText(OutlinedButton, 'Close'));

    expect(action.top, lessThan(export.top));
    expect(export.top, lessThan(close.top));
    expect(export.top - action.bottom, 8);
    expect(close.top - export.bottom, 8);
    expect(action.width, export.width);
    expect(export.width, close.width);
    expect(action.width, 360 - 32, reason: 'full width inside the 16px footer padding');
    await unmount(tester);
  });

  testWidgets('wide: buttons sit side by side on one row', (tester) async {
    await pump(tester, 'processing', 700);
    final action = tester.getRect(find.widgetWithText(ElevatedButton, 'Dispatch for Delivery'));
    final export = tester.getRect(find.widgetWithText(OutlinedButton, 'Export PDF'));
    final close = tester.getRect(find.widgetWithText(OutlinedButton, 'Close'));
    // One row: the buttons share a vertical centre (heights can differ by a pixel or two).
    expect(action.center.dy, closeTo(export.center.dy, 2));
    expect(export.center.dy, closeTo(close.center.dy, 2));
    expect(action.left, greaterThan(export.right));
    expect(export.left, greaterThan(close.right));
    await unmount(tester);
  });

  testWidgets('an order with no next status (completed) still shows Close and Export PDF', (tester) async {
    await pump(tester, 'completed', 360);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a failing Dispatch shows a red snackbar and leaves the order and the open panel untouched', (tester) async {
    await tester.runAsync(() async {
      await db.createProduct(ProductsCompanion.insert(
          uuid: 'p1', sku: 'S', name: 'P', category: 'c', unitPrice: 1, costPrice: 1, unit: 'pc', currentStock: 10, minStock: 0));
      await db.createOrder(OrdersCompanion.insert(
          uuid: 'o-1', customerId: 'c', orderNumber: 'ORD-1', deliveryAddress: 'x', status: const Value('processing')));
      await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          uuid: 'l1', orderId: 'o-1', productId: 'p1', productSku: 'S', productName: 'P', quantity: 3, unitPrice: 1, subtotal: 3, totalAmount: 3));
      await db.customStatement("CREATE TRIGGER fail_movement BEFORE INSERT ON stock_movements BEGIN SELECT RAISE(ABORT, 'disk on fire'); END");
    });
    await pump(tester, 'processing', 360);

    final button = find.widgetWithText(ElevatedButton, 'Dispatch for Delivery');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining("Couldn't Dispatch for Delivery: ORD-1 was not changed"), findsOneWidget);
    expect(find.textContaining('disk on fire'), findsOneWidget);
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.backgroundColor, Colors.red);

    // Still open and still selected: the order is in its old state.
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Dispatch for Delivery'), findsOneWidget);
    final row = await tester.runAsync(() => db.getOrderById('o-1'));
    expect(row!.status, 'processing');
    final p = await tester.runAsync(() => db.getProductByUuid('p1'));
    expect(p!.currentStock, 10);
    await unmount(tester);
  });
}
