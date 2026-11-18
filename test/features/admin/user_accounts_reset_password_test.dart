import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_manager.dart';
import 'package:villahermosa_inventory_system/features/admin/screens/user_accounts_screen.dart';

/// Regression: _ResetPasswordDialog existed and was wired to
/// AuthService.adminResetPassword, but nothing ever showed it — the admin had no
/// way to reset a password.
void main() {
  late AppDatabase db;
  late AuthService auth;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
    auth = AuthService.instance;
    await db.createUser(UsersCompanion.insert(
      uuid: 'u-wh',
      firstName: 'Wanda',
      lastName: 'Warehouse',
      email: 'wanda@vm.com',
      passwordHash: BCrypt.hashpw('old-pass', BCrypt.gensalt()),
      role: 'warehouse',
      syncStatus: const Value('synced'),
    ));
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester) async {
    // The flutter_test font (Ahem) is far wider than the real one, so the reset
    // dialog's Cancel / Reset Password button row (352px wide) reports a
    // RenderFlex overflow here that doesn't happen on a device. Ignore ONLY
    // that, so it doesn't mask the behaviour under test.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: UserAccountsScreen(database: db, syncManager: SyncManager(db, SyncEngine(db))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> settleDialog(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('the row has a Reset password action that opens the dialog', (tester) async {
    await open(tester);
    expect(find.text('Wanda Warehouse'), findsWidgets);

    final action = find.byTooltip('Reset password');
    expect(action, findsOneWidget, reason: 'next to Edit on the user row');
    await tester.tap(action);
    await settleDialog(tester);

    expect(find.text('Reset Password for Wanda Warehouse'), findsOneWidget);
    await close(tester);
  });

  testWidgets('a successful reset calls adminResetPassword with the uuid, email and new password', (tester) async {
    final upserted = <(String, String)>[];
    auth.authUpserter = (email, pw) async {
      upserted.add((email, pw));
      return true;
    };

    await open(tester);
    await tester.tap(find.byTooltip('Reset password'));
    await settleDialog(tester);

    await tester.enterText(find.byType(TextFormField), 'temp-pass-1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(upserted, [('wanda@vm.com', 'temp-pass-1')], reason: 'the email and new password reached Supabase Auth');
    final after = (await tester.runAsync(() => db.getUserByEmail('wanda@vm.com')))!;
    expect(after.uuid, 'u-wh');
    expect(BCrypt.checkpw('temp-pass-1', after.passwordHash), isTrue, reason: 'the uuid\'s row got the new bcrypt hash');
    expect(after.forcePasswordChange, isTrue);
    expect(after.syncStatus, 'pending');
    expect(find.textContaining('Password reset successfully'), findsOneWidget);
    await close(tester);
  });

  testWidgets('a Supabase Auth failure is shown and the password is NOT changed', (tester) async {
    auth.authUpserter = (_, _) async => false;
    final before = (await db.getUserByEmail('wanda@vm.com'))!.passwordHash;

    await open(tester);
    await tester.tap(find.byTooltip('Reset password'));
    await settleDialog(tester);
    await tester.enterText(find.byType(TextFormField), 'temp-pass-1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Password NOT reset'), findsOneWidget);
    expect((await tester.runAsync(() => db.getUserByEmail('wanda@vm.com')))!.passwordHash, before);
    await close(tester);
  });
}
