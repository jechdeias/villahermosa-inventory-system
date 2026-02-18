import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:villahermosa_inventory_system/core/database/app_database.dart';
import 'package:villahermosa_inventory_system/features/auth/data/auth_repository.dart';

void main() {
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
      const role = 'admin';

      // Act
      final result = await authRepository.signup(firstName, lastName, email, password, role);

      // Assert
      expect(result, isTrue);

      // Verify user was created with hashed password
      final user = await database.getUserByEmail(email);
      expect(user, isNotNull);
      expect(user?.email, equals(email));
      expect(user?.firstName, equals(firstName));
      expect(user?.lastName, equals(lastName));
      expect(user?.role, equals(role));
      expect(user?.passwordHash, isNotNull);
      expect(user?.passwordHash, isNot(equals(password))); // Should be hashed
      expect(user?.passwordHash.length, equals(64)); // SHA256 hex length
    });

    test('Login verifies passwordHash', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'testpassword123';
      const firstName = 'Test';
      const lastName = 'User';
      const role = 'admin';

      await authRepository.signup(firstName, lastName, email, password, role);

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
      const role = 'admin';

      await authRepository.signup(firstName, lastName, email, password, role);

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
      expect(admin.passwordHash.length, equals(64)); // SHA256 hex length
    });
  });
}
