import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/customer/providers/customer_providers.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_cart_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_order_detail_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_orders_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_payments_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_product_detail_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_profile_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/screens/customer_shop_screen.dart';
import 'package:villahermosa_inventory_system/features/customer/widgets/customer_common.dart';
import 'package:villahermosa_inventory_system/features/customer/widgets/order_progress_stepper.dart';
import 'package:villahermosa_inventory_system/features/customer/widgets/product_grid_card.dart';

const _store = "Nena's Sari-Sari Store";

const _profile = CustomerProfile(
  firstName: 'Nena',
  ownerName: 'Nena Reyes',
  storeName: _store,
  customerUuid: 'c1',
  routeName: 'Boac North',
  deliveryDays: 'Mon,Thu',
  repName: 'Jun Mendoza',
  barangay: 'Tanza',
  town: 'Boac',
  channel: 'Sari-Sari Store',
  phone: '0917 555 0142',
  email: 'nena@example.com',
);

Order _order({String status = 'pending', String warehouseStatus = 'pending'}) => Order(
      id: 1,
      uuid: 'o',
      customerId: 'c1',
      orderNumber: 'ORD-1',
      status: status,
      deliveryAddress: '',
      subtotal: 0,
      taxAmount: 0,
      totalAmount: 0,
      paymentStatus: '',
      warehouseStatus: warehouseStatus,
      priority: '',
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isDeleted: false,
      syncStatus: 'pending',
      itemCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pure helpers', () {
    test('customerStatusOf collapses warehouse states for the customer', () {
      expect(customerStatusOf(_order()), CustomerOrderStatus.processing);
      expect(customerStatusOf(_order(warehouseStatus: 'processing')), CustomerOrderStatus.processing);
      expect(customerStatusOf(_order(warehouseStatus: 'ready')), CustomerOrderStatus.processing);
      expect(customerStatusOf(_order(warehouseStatus: 'dispatched')), CustomerOrderStatus.outForDelivery);
      expect(customerStatusOf(_order(status: 'completed')), CustomerOrderStatus.delivered);
      expect(customerStatusOf(_order(status: 'cancelled', warehouseStatus: 'dispatched')), CustomerOrderStatus.cancelled);
      expect(customerStepOf(CustomerOrderStatus.processing), 1);
      expect(customerStepOf(CustomerOrderStatus.outForDelivery), 2);
      expect(customerStepOf(CustomerOrderStatus.delivered), 3);
      expect(isActiveCustomerOrder(CustomerOrderStatus.delivered), isFalse);
    });

    test('nextDeliveryDate picks the next route day', () {
      // Oct 26 2026 is a Monday.
      expect(nextDeliveryDate('Mon,Thu', DateTime(2026, 10, 26)), DateTime(2026, 10, 29));
      expect(nextDeliveryDate('Mon,Thu', DateTime(2026, 10, 29)), DateTime(2026, 11, 2));
      expect(nextDeliveryDate('', DateTime(2026, 10, 26)), DateTime(2026, 10, 27));
    });

    test('formatPeso', () {
      expect(formatPeso(1752), '₱1,752');
      expect(formatPeso(78), '₱78');
      expect(formatPeso(24410.5), '₱24,410.50');
    });

    test('paymentMethodFromNotes', () {
      expect(paymentMethodFromNotes('Payment method: GCash'), 'GCash');
      expect(paymentMethodFromNotes(null), isNull);
      expect(paymentMethodFromNotes('hello'), isNull);
    });
  });

  group('product placeholder + stepper', () {
    test('productInitial uses the first letter, not a leading digit', () {
      expect(productInitial('Coca-Cola 1.5L'), 'C');
      expect(productInitial('24 Seven Lemon Ice Tea Powdered Drink Mix 40g 12x10'), 'S');
      expect(productInitial('  nescafé 3-in-1'), 'N');
      expect(productInitial('7-Up'), 'U');
      expect(productInitial('555'), '5'); // no letters at all -> first character
      expect(productInitial(''), '?');
      expect(productInitial('   '), '?');
    });

    for (final width in const [320.0, 240.0]) {
      testWidgets('stepper labels never overflow or split mid-word at ${width.toInt()}px', (tester) async {
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.toString());
        try {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(body: Center(child: SizedBox(width: width, child: const OrderProgressStepper(currentStep: 1)))),
          ));
          await tester.pump();
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty, reason: errors.join(' ||| '));
        // Each word renders whole (one Text per line), so no label can wrap inside a word.
        for (final line in ['Order Placed', 'Processing', 'Out for', 'Delivery', 'Delivered']) {
          expect(find.text(line), findsOneWidget);
        }
      });
    }
  });

  group('cart', () {
    late Product coke;
    late Product milk;

    setUp(() {
      Product p(String uuid, String name, double price) => Product(
            id: 0,
            sku: uuid,
            name: name,
            category: 'c',
            unitPrice: price,
            costPrice: 1,
            unit: 'bottle',
            currentStock: 10,
            minStock: 1,
            status: 'active',
            isActive: true,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            isDeleted: false,
            syncStatus: 'pending',
            uuid: uuid,
            qtyPerCase: 12,
          );
      coke = p('coke', 'Coca-Cola 1.5L', 78);
      milk = p('milk', 'Bear Brand', 72);
    });

    test('add, merge, update, remove, totals', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);

      cart.addItem(coke, 12);
      cart.addItem(milk, 6);
      cart.addItem(coke, 2); // merges into the existing line
      expect(c.read(cartProvider).length, 2);
      expect(c.read(cartCountProvider), 20);
      expect(c.read(cartTotalProvider), 14 * 78 + 6 * 72);
      expect(c.read(cartQtyProvider('coke')), 14);

      cart.updateQty('milk', 3);
      expect(c.read(cartQtyProvider('milk')), 3);
      cart.updateQty('milk', 0); // zero removes
      expect(c.read(cartProvider).map((i) => i.product.uuid), ['coke']);

      cart.removeItem('coke');
      expect(c.read(cartProvider), isEmpty);
      cart.addItem(coke, 0); // ignored
      expect(c.read(cartProvider), isEmpty);
    });
  });

  group('screens against a seeded database', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      AuthService.initializeWithDatabase(db);

      Future<void> product(String uuid, String sku, String name, double price, int stock) => db.createProduct(ProductsCompanion.insert(
            uuid: uuid,
            sku: sku,
            name: name,
            category: 'Beverages',
            unitPrice: price,
            costPrice: price * 0.8,
            unit: 'Per bottle',
            currentStock: stock,
            minStock: 5,
            qtyPerCase: const Value(12),
          ));
      await product('p-coke', 'BEV-0012', 'Coca-Cola 1.5L', 78, 150);
      await product('p-nescafe', 'BEV-0031', 'Nescafé 3-in-1 Original (30s)', 310, 64);
      await product('p-water', 'WAT-0005', 'Wilkins Distilled Water 500ml', 20, 0);

      Future<int> order(String uuid, String number, {String status = 'pending', String wh = 'pending', double total = 1000, int items = 3}) =>
          db.createOrder(OrdersCompanion.insert(
            uuid: uuid,
            customerId: 'c1',
            orderNumber: number,
            deliveryAddress: 'Boac',
            status: Value(status),
            warehouseStatus: Value(wh),
            totalAmount: Value(total),
            subtotal: Value(total),
            itemCount: Value(items),
            storeName: const Value(_store),
            routeName: const Value('Boac North'),
            salesRepName: const Value('Jun Mendoza'),
            expectedDeliveryDate: Value(DateTime(2026, 10, 29)),
          ));
      final processing = await order('o-proc', 'ORD-1052', total: 1232);
      await order('o-out', 'ORD-1049', wh: 'dispatched', total: 1000, items: 4);
      await order('o-done', 'ORD-1042', status: 'completed', total: 8450, items: 8);
      await order('o-cancel', 'ORD-1031', status: 'cancelled', total: 630, items: 2);

      await db.createOrderItem(OrderItemsCompanion.insert(
        uuid: 'i1',
        orderId: 'o-proc',
        productId: 'p-coke',
        productSku: 'BEV-0012',
        productName: 'Coca-Cola 1.5L',
        quantity: 12,
        unitPrice: 78,
        subtotal: 936,
        totalAmount: 936,
        availableStock: 150,
      ));

      await db.into(db.payments).insert(PaymentsCompanion.insert(
            paymentId: 'pay-1',
            orderId: processing,
            orderCode: 'ORD-1052',
            storeName: _store,
            salesRepId: 1,
            salesRepName: 'Jun Mendoza',
            orderAmount: 1232,
            amountPaid: const Value(2000),
            balance: 5000,
            paymentMethod: const Value('GCash'),
            paymentDate: DateTime(2026, 10, 25),
            status: const Value('partial'),
          ));
    });

    tearDown(() async {
      await db.close();
    });

    final overrides = [customerProfileProvider.overrideWithValue(_profile)];

    Future<void> render(WidgetTester tester, Widget home, Size size, {List<Override> extra = const [], Map<String, WidgetBuilder>? routes}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        overrides: [...overrides, ...extra],
        child: MaterialApp(home: home, routes: routes ?? const {}),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    CartNotifier filledCart() {
      final c = CartNotifier();
      Product p(String uuid, String sku, String name, double price) => Product(
            id: 0,
            sku: sku,
            name: name,
            category: 'Beverages',
            unitPrice: price,
            costPrice: 1,
            unit: 'Per bottle',
            currentStock: 100,
            minStock: 1,
            status: 'active',
            isActive: true,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            isDeleted: false,
            syncStatus: 'pending',
            uuid: uuid,
            qtyPerCase: 12,
          );
      c.addItem(p('p-coke', 'BEV-0012', 'Coca-Cola 1.5L', 78), 12);
      c.addItem(p('p-nescafe', 'BEV-0031', 'Nescafé 3-in-1 Original (30s)', 310), 1);
      return c;
    }

    final screens = <String, Widget Function()>{
      'shop': () => const CustomerShopScreen(),
      'product detail': () => const CustomerProductDetailScreen(productUuid: 'p-coke'),
      'cart': () => const CustomerCartScreen(),
      'orders': () => const CustomerOrdersScreen(),
      'order detail': () => const CustomerOrderDetailScreen(orderUuid: 'o-out'),
      'payments': () => const CustomerPaymentsScreen(),
      'profile': () => const CustomerProfileScreen(),
    };

    for (final size in const [Size(1440, 900), Size(390, 844)]) {
      for (final e in screens.entries) {
        testWidgets('${e.key} at ${size.width.toInt()}px has no layout errors', (tester) async {
          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) => errors.add(d.toString());
          try {
            await render(tester, e.value(), size, extra: [cartProvider.overrideWith((ref) => filledCart())]);
            await unmount(tester);
          } finally {
            FlutterError.onError = previous;
          }
          expect(errors, isEmpty, reason: errors.join(' ||| '));
        });
      }
    }

    testWidgets('empty cart shows the empty state', (tester) async {
      await render(tester, const CustomerCartScreen(), const Size(390, 844));
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('shop shows greeting, outstanding balance and live products', (tester) async {
      await render(tester, const CustomerShopScreen(), const Size(390, 844));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Hello, Nena'), findsOneWidget);
      expect(find.textContaining("Nena's Sari-Sari Store"), findsOneWidget);
      expect(find.textContaining('₱5,000'), findsWidgets); // outstanding balance alert
      expect(find.text('Coca-Cola 1.5L'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('orders list shows status badges and only active orders get a stepper', (tester) async {
      await render(tester, const CustomerOrdersScreen(), const Size(390, 2400));
      expect(find.text('ORD-1052'), findsNothing); // number is part of a rich text
      expect(find.textContaining('ORD-1052'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsWidgets);
      expect(find.text('Delivered'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('Order Placed'), findsNWidgets(2)); // processing + out for delivery only
      expect(find.text('On the way today with Jun Mendoza'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('placing an order writes a pending order + lines and clears the cart', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cart = filledCart();

      await tester.pumpWidget(ProviderScope(
        overrides: [...overrides, cartProvider.overrideWith((ref) => cart)],
        child: MaterialApp(
          home: const CustomerCartScreen(),
          routes: {'/customer/orders': (_) => const Scaffold(body: Text('ORDERS PAGE'))},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Choose GCash, then Place Order → confirmation dialog.
      await tester.tap(find.text('GCash'));
      await tester.pump();
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirm order of ₱1,246?'), findsOneWidget); // 12×78 + 310
      expect(find.textContaining('Jun Mendoza'), findsOneWidget);
      expect(find.textContaining('Thursday, Oct'), findsOneWidget);
      expect(find.text('GCash'), findsWidgets);

      await tester.tap(find.text('Confirm'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();

      expect(find.text('ORDERS PAGE'), findsOneWidget);
      expect(find.text('Order placed!'), findsOneWidget);

      final placed = await tester.runAsync(() => (db.select(db.orders)..where((o) => o.customerId.equals('c1') & o.itemCount.equals(13))).get());
      expect(placed, hasLength(1));
      final o = placed!.single;
      expect(o.status, 'pending');
      expect(o.syncStatus, 'pending');
      expect(o.storeName, _store);
      expect(o.salesRepName, 'Jun Mendoza');
      expect(o.totalAmount, 1246);
      expect(o.orderNumber, startsWith('ORD-'));
      expect(paymentMethodFromNotes(o.customerNotes), 'GCash');

      final lines = await tester.runAsync(() => (db.select(db.orderItems)..where((i) => i.orderId.equals(o.uuid))).get());
      expect(lines!.map((l) => (l.productId, l.quantity)).toSet(), {('p-coke', 12), ('p-nescafe', 1)});
      expect(cart.state, isEmpty);

      await unmount(tester);
    });
  });
}
