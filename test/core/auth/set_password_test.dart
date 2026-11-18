import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/auth/change_password_screen.dart';
import 'package:villahermosa_inventory_system/features/auth/oauth_platform.dart';
import 'package:villahermosa_inventory_system/features/auth/set_password_dialog.dart';

/// A Google-created account has `passwordHash: ''` (see loginWithOAuthSession).
/// setPassword gives it a password on Supabase Auth AND a local bcrypt hash.
void main() {
  group('password sync to Supabase Auth', passwordSyncTests);

  group('Windows Google button', () {
    test('registryCommandPointsAt matches only the exe the scheme launches', () {
      const out = r'    (Default)    REG_SZ    "C:\Users\u\AppData\Local\Programs\VMDistribution\villahermosa_inventory_system.exe" "%1"';
      expect(registryCommandPointsAt(out, r'C:\Users\u\AppData\Local\Programs\VMDistribution\villahermosa_inventory_system.exe'), isTrue);
      expect(registryCommandPointsAt(out, r'c:\users\u\appdata\local\programs\vmdistribution\VILLAHERMOSA_INVENTORY_SYSTEM.EXE'), isTrue, reason: 'case-insensitive');
      expect(registryCommandPointsAt(out, r'C:\dev\build\windows\x64\runner\Release\villahermosa_inventory_system.exe'), isFalse,
          reason: 'a flutter run / build-folder exe is not the registered one');
    });
  });

  late AppDatabase db;
  late AuthService auth;

  Future<User> addUser(String uuid, {String hash = ''}) async {
    await db.createUser(UsersCompanion.insert(
      uuid: uuid,
      firstName: 'Gina',
      lastName: 'Google',
      email: '$uuid@gmail.com',
      passwordHash: hash,
      role: 'customer',
      syncStatus: const Value('synced'),
    ));
    return (await db.getUserByEmail('$uuid@gmail.com'))!;
  }

  Future<User> reload(User u) async => (await db.getUserByEmail(u.email))!;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    auth = AuthService(db);
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => db.close());

  group('AuthService.setPassword', () {
    test('writes a bcrypt hash (not SHA-256), marks the row pending, and sets the Supabase password', () async {
      final user = await addUser('g1');
      auth.debugSetCurrentUser(user);
      String? sentToSupabase;

      await auth.setPassword('hunter22', updateRemote: (p) async => sentToSupabase = p);

      expect(sentToSupabase, 'hunter22');
      final after = await reload(user);
      expect(after.passwordHash, isNot(''));
      expect(after.passwordHash, startsWith(r'$2'), reason: 'bcrypt, not a 64-char SHA-256 hex digest');
      expect(after.passwordHash.length, isNot(64));
      expect(BCrypt.checkpw('hunter22', after.passwordHash), isTrue);
      expect(BCrypt.checkpw('wrong-one', after.passwordHash), isFalse);
      expect(after.syncStatus, 'pending');
      expect(auth.getCurrentUser()!.passwordHash, after.passwordHash, reason: 'in-memory session is refreshed');
      expect(auth.currentUserNeedsPassword, isFalse);
    });

    test('if Supabase refuses, nothing is written locally', () async {
      final user = await addUser('g2');
      auth.debugSetCurrentUser(user);

      await expectLater(
        auth.setPassword('hunter22', updateRemote: (_) async => throw const AuthException('Password is too weak', code: 'weak_password')),
        throwsA(isA<PasswordSetException>().having((e) => e.message, 'message', 'Password is too weak')),
      );

      final after = await reload(user);
      expect(after.passwordHash, '');
      expect(after.syncStatus, 'synced');
      expect(auth.currentUserNeedsPassword, isTrue);
    });

    test('a network failure is reported, and nothing is written locally', () async {
      final user = await addUser('g3');
      auth.debugSetCurrentUser(user);
      await expectLater(auth.setPassword('hunter22', updateRemote: (_) async => throw Exception('SocketException')), throwsA(isA<PasswordSetException>()));
      expect((await reload(user)).passwordHash, '');
    });

    test('re-setting the same password is not an error: the local half still gets written', () async {
      final user = await addUser('g4');
      auth.debugSetCurrentUser(user);
      await auth.setPassword('hunter22', updateRemote: (_) async => throw const AuthException('same', code: 'same_password'));
      expect(BCrypt.checkpw('hunter22', (await reload(user)).passwordHash), isTrue);
    });

    test('a too-short password never reaches Supabase', () async {
      final user = await addUser('g5');
      auth.debugSetCurrentUser(user);
      var called = false;
      await expectLater(auth.setPassword('abc', updateRemote: (_) async => called = true), throwsA(isA<PasswordSetException>()));
      expect(called, isFalse);
    });

    test('signed out: refuses', () async {
      await expectLater(auth.setPassword('hunter22', updateRemote: (_) async {}), throwsA(isA<PasswordSetException>()));
    });
  });

  group('which accounts need a password', () {
    test('an empty passwordHash is what marks an account as needing one', () async {
      final google = await addUser('g6');
      final normal = await addUser('g7', hash: BCrypt.hashpw('x1y2z3', BCrypt.gensalt()));
      expect(AuthService.needsPassword(google), isTrue);
      expect(AuthService.needsPassword(normal), isFalse);

      auth.debugSetCurrentUser(google);
      expect(auth.currentUserNeedsPassword, isTrue);
      auth.debugSetCurrentUser(normal);
      expect(auth.currentUserNeedsPassword, isFalse);
      auth.debugSetCurrentUser(null);
      expect(auth.currentUserNeedsPassword, isFalse);
    });
  });

  group('maybePromptToSetPassword', () {
    Future<void> pump(WidgetTester tester, Future<void> Function(BuildContext) body) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => body(ctx), child: const Text('go')))),
      ));
      await tester.tap(find.text('go'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('an account with an empty passwordHash is asked, once', (tester) async {
      final user = await tester.runAsync(() => addUser('g8'));
      auth.debugSetCurrentUser(user);

      await pump(tester, (c) => maybePromptToSetPassword(c, auth: auth));
      expect(find.text('Set a password?'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Set a password?'), findsNothing, reason: 'optional: Not now just continues');

      // Second time: already asked, so no prompt.
      await tester.tap(find.text('go'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Set a password?'), findsNothing);
      await tester.runAsync(db.close);
    });

    testWidgets('an account that already has a password is never asked', (tester) async {
      final user = await tester.runAsync(() => addUser('g9', hash: BCrypt.hashpw('x1y2z3', BCrypt.gensalt())));
      auth.debugSetCurrentUser(user);
      await pump(tester, (c) => maybePromptToSetPassword(c, auth: auth));
      expect(find.text('Set a password?'), findsNothing);
      await tester.runAsync(db.close);
    });
  });
}

/// Admin reset / creation / forced change must put the password on Supabase Auth
/// as well as the local row — otherwise the user can't sign in on a device that
/// has never seen the account ("invalid credentials", CLAUDE.md B2).
void passwordSyncTests() {
  late AppDatabase db;
  late AuthService auth;

  Future<User> addUser(String uuid, {String hash = '', bool force = false}) async {
    await db.createUser(UsersCompanion.insert(
      uuid: uuid,
      firstName: 'Una',
      lastName: 'User',
      email: '$uuid@vm.com',
      passwordHash: hash,
      role: 'warehouse',
      forcePasswordChange: Value(force),
      syncStatus: const Value('synced'),
    ));
    return (await db.getUserByEmail('$uuid@vm.com'))!;
  }

  Future<User> reload(User u) async => (await db.getUserByEmail(u.email))!;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    AuthService.initializeWithDatabase(db);
    auth = AuthService.instance;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => db.close());

  group('admin password reset', () {
    test('calls upsertSupabaseAuthUser with the email and new password, then writes bcrypt + forces a change', () async {
      final user = await addUser('r1', hash: BCrypt.hashpw('old-pass', BCrypt.gensalt()));
      final calls = <(String, String)>[];
      auth.authUpserter = (email, pw) async {
        calls.add((email, pw));
        return true;
      };

      await auth.adminResetPassword(user.uuid, user.email, 'temp-1234');

      expect(calls, [(user.email, 'temp-1234')]);
      final after = await reload(user);
      expect(after.passwordHash, startsWith(r'$2'));
      expect(BCrypt.checkpw('temp-1234', after.passwordHash), isTrue);
      expect(after.forcePasswordChange, isTrue);
      expect(after.syncStatus, 'pending');
    });

    test('a Supabase Auth failure is surfaced, not swallowed — and nothing changes locally', () async {
      final oldHash = BCrypt.hashpw('old-pass', BCrypt.gensalt());
      final user = await addUser('r2', hash: oldHash);
      auth.authUpserter = (_, _) async => false;

      await expectLater(
        auth.adminResetPassword(user.uuid, user.email, 'temp-1234'),
        throwsA(isA<PasswordSetException>().having((e) => e.message, 'message', contains('online login'))),
      );

      final after = await reload(user);
      expect(after.passwordHash, oldHash, reason: 'the old password still works everywhere; the two sides did not diverge');
      expect(after.forcePasswordChange, isFalse);
      expect(after.syncStatus, 'synced');
    });

    test('a too-short password never reaches Supabase', () async {
      final user = await addUser('r3');
      var called = false;
      auth.authUpserter = (_, _) async => called = true;
      await expectLater(auth.adminResetPassword(user.uuid, user.email, 'abc'), throwsA(isA<PasswordSetException>()));
      expect(called, isFalse);
    });
  });

  group('admin account creation', () {
    test('syncPasswordToSupabaseAuth passes the credentials through and reports failure', () async {
      String? seen;
      auth.authUpserter = (email, pw) async {
        seen = '$email|$pw';
        return true;
      };
      await auth.syncPasswordToSupabaseAuth('new@vm.com', 'start-123');
      expect(seen, 'new@vm.com|start-123');

      auth.authUpserter = (_, _) async => false;
      await expectLater(auth.syncPasswordToSupabaseAuth('new@vm.com', 'start-123'), throwsA(isA<PasswordSetException>()));
    });
  });

  group('forced password change screen', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: ChangePasswordScreen(database: db)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> submit(WidgetTester tester, String pw) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), pw);
      await tester.enterText(fields.at(1), pw);
      final button = find.widgetWithText(ElevatedButton, 'Change Password');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('writes a bcrypt hash (not SHA-256), reaches Supabase, and clears the forced-change flag', (tester) async {
      final user = await tester.runAsync(() => addUser('f1', hash: BCrypt.hashpw('temp-1234', BCrypt.gensalt()), force: true));
      auth.debugSetCurrentUser(user);
      String? sentToSupabase;
      auth.remotePasswordUpdater = (p) async => sentToSupabase = p;

      await open(tester);
      await submit(tester, 'my-new-pass-1');

      expect(sentToSupabase, 'my-new-pass-1', reason: 'Supabase Auth was updated');
      final after = (await tester.runAsync(() => reload(user!)))!;
      expect(after.passwordHash, startsWith(r'$2'), reason: 'bcrypt, not a 64-char SHA-256 hex digest');
      expect(after.passwordHash.length, isNot(64));
      expect(BCrypt.checkpw('my-new-pass-1', after.passwordHash), isTrue);
      expect(after.forcePasswordChange, isFalse);
      expect(after.syncStatus, 'pending');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a Supabase failure is shown and nothing is written locally', (tester) async {
      final oldHash = BCrypt.hashpw('temp-1234', BCrypt.gensalt());
      final user = await tester.runAsync(() => addUser('f2', hash: oldHash, force: true));
      auth.debugSetCurrentUser(user);
      auth.remotePasswordUpdater = (_) async => throw const PasswordSetException('Your online session has expired.');

      await open(tester);
      await submit(tester, 'my-new-pass-1');

      expect(find.textContaining('Password not changed'), findsOneWidget);
      expect(find.textContaining('online session has expired'), findsOneWidget);
      final after = (await tester.runAsync(() => reload(user!)))!;
      expect(after.passwordHash, oldHash);
      expect(after.forcePasswordChange, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
