import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // AuthService.instance throws until it owns the shared database (main.dart
    // does this at startup), so the test must do the same.
    final database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(database);
    addTearDown(database.close);

    await tester.pumpWidget(VillahermosaInventoryApp(database: database));

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
