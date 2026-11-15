import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/warehouse/screens/prepare_orders_screen.dart';

void main() {
  testWidgets('ticking an item updates the counter and enables Complete Order', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
    await db.createOrder(OrdersCompanion.insert(uuid: 'o1', customerId: 'c1', orderNumber: 'ORD-1', deliveryAddress: 'Boac', itemCount: const Value(1), warehouseStatus: const Value('processing'), status: const Value('processing')));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
        uuid: 'i1', orderId: 'o1', productId: 'p', productSku: 'S', productName: 'Thing', quantity: 1, unitPrice: 1, subtotal: 1, totalAmount: 1));

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: WarehousePrepareOrdersScreen())));
    Future<void> settle() async {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await settle();
    await tester.tap(find.text('ORD-1').first);
    await settle();
    expect(find.text('0 of 1 items picked'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await settle();
    expect(find.text('1 of 1 items picked'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    // Complete Order is now enabled: tapping it opens the confirm dialog.
    await tester.tap(find.text('Complete Order'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Complete order'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));

    // Unmount before the in-memory DB closes so drift's stream timers settle.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(db.close);
  });
}
