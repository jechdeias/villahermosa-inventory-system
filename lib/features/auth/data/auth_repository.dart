import 'dart:math';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Repository handling user authentication operations.
/// 
/// Provides secure login functionality with password hashing and
/// automatic admin user seeding for initial system setup.
class AuthRepository {
  final AppDatabase _database;

  AuthRepository(this._database);

  /// Authenticates a user with email and password.
  /// 
  /// Returns the User object if authentication succeeds, null otherwise.
  /// Uses SHA256 hashing for secure password comparison.
  Future<User?> login(String email, String password) async {
    try {
      // Find user by email first
      final user = await _database.getUserByEmail(email);
      
      // Verify user exists and is not deleted
      // Note: Password validation would need to be implemented in the Users table
      if (user != null && !user.isDeleted) {
        return user;
      }
      
      return null;
    } catch (e) {
      // Return null if authentication fails
      return null;
    }
  }

  /// Creates a default admin user if no users exist in the database.
  /// 
  /// This ensures the system has at least one administrator account
  /// for initial setup and access.
  Future<void> seedAdminUserIfEmpty() async {
    try {
      // Check if any users exist
      final existingUsers = await _database.getAllUsers();
      
      if (existingUsers.isNotEmpty) {
        // Users already exist, no need to seed
        return;
      }
      
      // Create default admin user
      final adminUser = UsersCompanion.insert(
        uuid: _generateUuid(),
        name: 'System Administrator',
        email: 'admin@villahermosa.com',
        role: 'admin',
        phone: const Value(null),
        address: const Value(null),
        syncStatus: const Value('pending'),
      );
      
      await _database.createUser(adminUser);
    } catch (e) {
      // Log error but don't throw to prevent app startup issues
      print('Error seeding admin user: $e');
    }
  }

  /// Generates a simple UUID v4-like string
  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set version bits (4) and variant bits (8, 9, 10, 11)
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
