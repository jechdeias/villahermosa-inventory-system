import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'app_database.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Database Tests', () {
    late AppDatabase database;

    setUp(() {
      // Use in-memory database for testing
      database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    });

    tearDown(() async {
      await database.close();
    });

    test('Create and retrieve user', () async {
      // Create a user
      final userId = await database.createUser(
        UsersCompanion.insert(
          name: 'Test User',
          email: 'test@example.com',
          role: 'admin',
        ),
      );

      // Retrieve the user
      final user = await database.getUserById(userId);
      
      expect(user, isNotNull);
      expect(user!.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.role, equals('admin'));
      expect(user.syncStatus, equals('pending'));
    });

    test('Get all users', () async {
      // Create multiple users
      await database.createUser(
        UsersCompanion.insert(
          name: 'Alice',
          email: 'alice@example.com',
          role: 'warehouse',
        ),
      );

      await database.createUser(
        UsersCompanion.insert(
          name: 'Bob',
          email: 'bob@example.com',
          role: 'delivery',
        ),
      );

      // Get all users
      final users = await database.getAllUsers();
      
      expect(users.length, equals(2));
      expect(users[0].name, equals('Alice')); // Should be alphabetically sorted
      expect(users[1].name, equals('Bob'));
    });

    test('Update user', () async {
      // Create a user
      final userId = await database.createUser(
        UsersCompanion.insert(
          name: 'John Doe',
          email: 'john@example.com',
          role: 'admin',
        ),
      );

      // Update the user
      final updated = await database.updateUser(
        userId,
        UsersCompanion(
          name: const Value('John Smith'),
          role: const Value('warehouse'),
        ),
      );

      expect(updated, isTrue);

      // Verify the update
      final user = await database.getUserById(userId);
      expect(user!.name, equals('John Smith'));
      expect(user.role, equals('warehouse'));
    });

    test('Get pending sync users', () async {
      // Create users with different sync statuses
      await database.createUser(
        UsersCompanion.insert(
          name: 'Pending User',
          email: 'pending@example.com',
          role: 'admin',
          syncStatus: const Value('pending'),
        ),
      );

      await database.createUser(
        UsersCompanion.insert(
          name: 'Synced User',
          email: 'synced@example.com',
          role: 'admin',
          syncStatus: const Value('synced'),
        ),
      );

      // Get pending sync users
      final pendingUsers = await database.getPendingSyncUsers();
      
      expect(pendingUsers.length, equals(1));
      expect(pendingUsers[0].name, equals('Pending User'));
    });
  });
}
