import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/auth/data/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AuthRepository.signup checks connectivity before deciding whether to
  // sync to Supabase. There's no real platform plugin in a unit test, so
  // the method channel needs a mock handler or every signup call throws
  // MissingPluginException. Report "offline" — these tests only exercise
  // local password hashing/verification, not real network sync.
  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(connectivityChannel, (call) async {
    if (call.method == 'check') return ['none'];
    return null;
  });

  group('Authentication Tests', () {
    late AppDatabase database;
    late AuthRepository authRepository;

    setUp(() async {
      database = AppDatabase.forTesting(drift.DatabaseConnection.delayed(
        Future.value(() async {
          return drift.DatabaseConnection(NativeDatabase.memory());
        }()),
      ));
      await database.customStatement('PRAGMA foreign_keys = ON');
      authRepository = AuthRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('Signup stores passwordHash', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'testpassword123';
      const firstName = 'Test';
      const lastName = 'User';

      // Act
      final result = await authRepository.signup(firstName, lastName, email, password);

      // Assert
      expect(result, isTrue);

      // Verify user was created with hashed password
      final user = await database.getUserByEmail(email);
      expect(user, isNotNull);
      expect(user?.email, equals(email));
      expect(user?.firstName, equals(firstName));
      expect(user?.lastName, equals(lastName));
      expect(user?.role, equals('customer'));
      expect(user?.passwordHash, isNotNull);
      expect(user?.passwordHash, isNot(equals(password))); // Should be hashed
      expect(BCrypt.checkpw(password, user!.passwordHash), isTrue); // Bcrypt, not SHA256
    });

    test('Login verifies passwordHash', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'testpassword123';
      const firstName = 'Test';
      const lastName = 'User';

      await authRepository.signup(firstName, lastName, email, password);

      // Act & Assert - Correct password
      final user = await authRepository.login(email, password);
      expect(user, isNotNull);
      expect(user!.email, equals(email));

      // Act & Assert - Incorrect password
      expect(
        () => authRepository.login(email, 'wrongpassword'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Login throws AuthException for invalid credentials', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'testpassword123';
      const firstName = 'Test';
      const lastName = 'User';

      await authRepository.signup(firstName, lastName, email, password);

      // Act & Assert
      expect(
        () => authRepository.login(email, 'wrongpassword'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Admin user seeding creates passwordHash', () async {
      // Act
      await authRepository.seedAdminUserIfEmpty();

      // Assert
      final users = await database.getAllUsers();
      expect(users.length, equals(1));
      
      final admin = users.first;
      expect(admin.email, equals('admin@villahermosa.com'));
      expect(admin.firstName, equals('System'));
      expect(admin.lastName, equals('Administrator'));
      expect(admin.role, equals('admin'));
      expect(admin.passwordHash, isNotNull);
      expect(BCrypt.checkpw('admin123', admin.passwordHash), isTrue); // Bcrypt, not SHA256
    });
  });
}
