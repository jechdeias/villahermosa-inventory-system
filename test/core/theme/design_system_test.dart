import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:villahermosa_inventory_system/core/theme/app_theme.dart';
import 'package:villahermosa_inventory_system/core/widgets/empty_state.dart';
import 'package:villahermosa_inventory_system/core/widgets/shimmer_loading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    test('tokens match the design spec', () {
      expect(AppTheme.primary, const Color(0xFF1E1E1E));
      expect(AppTheme.background, const Color(0xFFF4F4F4));
      expect(AppTheme.textPrimary, const Color(0xFF111827));
      expect(AppTheme.success, const Color(0xFF059669));
      expect(AppTheme.error, const Color(0xFFDC2626));
      expect(AppTheme.sidebarTextActive, Colors.white);
      expect(AppTheme.radiusLG, 12);
      expect(AppTheme.spacing2XL, 24);
    });

    test('fonts come from the bundled assets, never the network', () async {
      // With fetching off, a missing bundled file would throw — so this proves
      // Inter and JetBrains Mono ship inside the app (offline-first).
      GoogleFonts.config.allowRuntimeFetching = false;
      await GoogleFonts.pendingFonts([
        AppTheme.displayLarge, // Inter 700
        AppTheme.headingMedium, // Inter 600
        AppTheme.bodyLarge, // Inter 400
        AppTheme.labelMedium, // Inter 500
        GoogleFonts.inter(fontWeight: FontWeight.w800), // Inter 800 (customer prices)
        AppTheme.monoSmall, // JetBrains Mono 600
      ]);
    });

    test('lightTheme builds with the expected component themes', () {
      final t = AppTheme.lightTheme;
      expect(t.scaffoldBackgroundColor, AppTheme.background);
      expect(t.colorScheme.primary, AppTheme.primary);
      expect(t.inputDecorationTheme.filled, isTrue);
      expect(t.cardTheme.elevation, 0);
      expect(t.bottomNavigationBarTheme.type, BottomNavigationBarType.fixed);
    });
  });

  group('EmptyState', () {
    testWidgets('shows icon, title and message; no button without an action', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyState(icon: Icons.store_outlined, title: 'No customers found', message: 'Add customers or adjust your search')),
      ));
      expect(find.text('No customers found'), findsOneWidget);
      expect(find.text('Add customers or adjust your search'), findsOneWidget);
      expect(find.byIcon(Icons.store_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('action button uses the label and fires the callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders today', message: 'Tap New Order', action: () => taps++, actionLabel: 'New Order'),
        ),
      ));
      await tester.tap(find.text('New Order'));
      expect(taps, 1);
    });

    testWidgets('an empty message renders no message line', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(icon: Icons.inbox_outlined, title: 'Queue is empty', message: ''))));
      expect(find.text('Queue is empty'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('shimmer', () {
    test('isFirstLoad is only true before the first value', () {
      expect(isFirstLoad(const AsyncLoading<int>()), isTrue);
      expect(isFirstLoad(const AsyncData<int>(1)), isFalse);
      // A refresh that already has data must not flicker back to shimmer.
      expect(isFirstLoad(const AsyncLoading<int>().copyWithPrevious(const AsyncData<int>(1))), isFalse);
      expect(isFirstLoad(AsyncError<int>('x', StackTrace.empty)), isFalse);
    });

    for (final size in const [Size(1200, 800), Size(390, 800)]) {
      testWidgets('placeholders render without layout errors at ${size.width.toInt()}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final page in const <Widget>[
          ShimmerTablePage(statCards: 4),
          ShimmerTablePage(statCards: 0, rows: 3),
          ShimmerCardList(count: 3),
          Column(children: [ShimmerStatCard(), ShimmerTableRow(), ShimmerListCard(), ShimmerBox(width: 40, height: 10)]),
        ]) {
          await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
