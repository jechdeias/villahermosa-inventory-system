import 'package:drift/drift.dart' hide isNotNull, isNull, Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_home_screen.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_scan_screen.dart';

void main() {
  testWidgets('sales home has a Scan Delivery quick action that opens the scanner', (tester) async {
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SalesHomeScreen())));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Scan Delivery'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Sync Data'), findsOneWidget);

    await tester.tap(find.text('Scan Delivery'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SalesScanScreen), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
  });
}
