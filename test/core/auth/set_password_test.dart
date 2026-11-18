import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:villahermosa_inventory_system/core/auth/auth_service.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/auth/set_password_dialog.dart';

/// A Google-created account has `passwordHash: ''` (see loginWithOAuthSession).
/// setPassword gives it a password on Supabase Auth AND a local bcrypt hash.
void main() {
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
