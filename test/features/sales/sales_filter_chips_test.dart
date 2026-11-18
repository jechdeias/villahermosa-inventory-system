import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_orders_screen.dart';
import 'package:villahermosa_inventory_system/features/sales/screens/sales_payments_screen.dart';

/// The filter pills were clipped to about half their height: a fixed
/// `SizedBox(height: 40)` minus the ListView's 16px vertical padding minus each
/// pill's own 16px left 8px for a 12px label (≈15px of line). The row now sizes
/// to its content, so a larger system font can't reintroduce it.
void main() {
  late AppDatabase db;

  // Ahem (the default test font) isn't the app's font; use Inter from the repo.
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

  Future<List<String>> pumpAndCollectErrors(WidgetTester tester, Widget screen, double textScale) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.toString());
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
    return errors;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Every pill must be tall enough for its label: pill height >= label height +
  /// its own 16px of vertical padding. With the old fixed-height row the pill was
  /// squeezed to 8px, so this failed by half.
  void expectNoPillIsClipped(WidgetTester tester, String labelPrefix) {
    final labels = find.textContaining(RegExp('^$labelPrefix|^All \\(|^Pending \\(|^Paid \\(|^Out for Delivery \\('));
    expect(labels, findsWidgets);
    for (final label in labels.evaluate()) {
      final text = label.widget as Text;
      if (!text.data!.contains('(')) continue; // only the pills
      final paragraph = label.renderObject as RenderParagraph;
      // Walk up to the pill's own rounded decoration (the nearest one).
      RenderObject? node = paragraph;
      while (node != null && !(node is RenderDecoratedBox && (node.decoration as BoxDecoration).borderRadius != null)) {
        node = node.parent;
      }
      expect(node, isNotNull, reason: 'no pill found around "${text.data}"');
      final pillHeight = (node! as RenderBox).size.height;
      expect(pillHeight, greaterThanOrEqualTo(paragraph.size.height + 16 - 0.5),
          reason: '"${text.data}": pill is ${pillHeight.toStringAsFixed(1)}px tall but needs ${(paragraph.size.height + 16).toStringAsFixed(1)}');
      expect(paragraph.didExceedMaxLines, isFalse);
      // The label got all the height it naturally needs (the old fixed-height row
      // squeezed a 15px line into 8px).
      final natural = paragraph.getMaxIntrinsicHeight(double.infinity);
      expect(paragraph.size.height, greaterThanOrEqualTo(natural - 0.5),
          reason: '"${text.data}" was laid out in ${paragraph.size.height.toStringAsFixed(1)}px but needs ${natural.toStringAsFixed(1)}px');
    }
  }

  for (final scale in const [1.0, 1.3]) {
    testWidgets('sales orders filter pills are not clipped at text scale $scale', (tester) async {
      final errors = await pumpAndCollectErrors(tester, const SalesOrdersScreen(), scale);
      expect(errors, isEmpty, reason: errors.join(' ||| '));
      expectNoPillIsClipped(tester, 'All');
      await unmount(tester);
    });

    testWidgets('sales payments filter pills are not clipped at text scale $scale', (tester) async {
      final errors = await pumpAndCollectErrors(tester, const SalesPaymentsScreen(), scale);
      expect(errors, isEmpty, reason: errors.join(' ||| '));
      expectNoPillIsClipped(tester, 'All');
      await unmount(tester);
    });
  }

  testWidgets('the pill row grows with the text scale (nothing is fixed-height)', (tester) async {
    await pumpAndCollectErrors(tester, const SalesOrdersScreen(), 1.0);
    final small = tester.getSize(find.byType(SingleChildScrollView).first).height;
    await unmount(tester);

    await pumpAndCollectErrors(tester, const SalesOrdersScreen(), 1.3);
    final large = tester.getSize(find.byType(SingleChildScrollView).first).height;
    expect(large, greaterThan(small), reason: 'a fixed-height row would not grow');
    await unmount(tester);
  });
}
