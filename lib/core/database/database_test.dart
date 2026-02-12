import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

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
      await database.createUser(
        UsersCompanion.insert(
          uuid: const Uuid().v4(),
          name: 'Test User',
          passwordHash: 'hashedpassword',
          email: 'testuser@example.com',
          role: 'admin',
        ),
      );

      // Retrieve the user
      final user = await database.getUserByEmail('testuser@example.com');
      
      expect(user, isNotNull);
      expect(user!.name, equals('Test User'));
      expect(user.email, equals('testuser@example.com'));
    });

    test('Get all users', () async {
      // Create multiple users
      await database.createUser(
        UsersCompanion.insert(
          uuid: const Uuid().v4(),
          name: 'Alice',
          passwordHash: 'hashedpassword',
          email: 'alice@example.com',
          role: 'customer',
        ),
      );

      await database.createUser(
        UsersCompanion.insert(
          uuid: const Uuid().v4(),
          name: 'Bob',
          passwordHash: 'hashedpassword',
          email: 'bob@example.com',
          role: 'delivery',
        ),
      );

      // Get all users
      final users = await database.getAllUsers();
      
      expect(users.length, equals(2));
    });

    test('Update user', () async {
      // Create a user
      await database.createUser(
        UsersCompanion.insert(
          uuid: const Uuid().v4(),
          name: 'John Doe',
          passwordHash: 'hashedpassword',
          email: 'john@example.com',
          role: 'admin',
        ),
      );

      // Update the user
      final existingUser = await database.getUserByEmail('john@example.com');
      expect(existingUser, isNotNull);
      
      final updated = await database.updateUser(
        existingUser!.uuid,
        const UsersCompanion(
          name: Value('John Smith'),
          role: Value('warehouse'),
        ),
      );

      expect(updated, isTrue);

      // Verify the update
      final user = await database.getUserByEmail('john@example.com');
      expect(user!.name, equals('John Smith'));
      expect(user.role, equals('warehouse'));
    });

    test('Get pending sync users', () async {
      // Create users with different sync statuses
      await database.createUser(
        UsersCompanion.insert(
          uuid: const Uuid().v4(),
          name: 'Pending User',
          passwordHash: 'hashedpassword',
          email: 'pending@example.com',
          role: 'admin',
          syncStatus: const Value('pending'),
        ),
      );

      await database.createUser(
        UsersCompanion.insert(
          uuid: const Uuid().v4(),
          name: 'Synced User',
          passwordHash: 'hashedpassword',
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
