import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Repository handling user authentication operations.
/// 
/// Provides secure login functionality with password hashing and
/// automatic admin user seeding for initial system setup.
class AuthRepository {
  final AppDatabase _database;

  AuthRepository(this._database);

  /// Authenticates a user with username and password.
  /// 
  /// Returns the User object if authentication succeeds, null otherwise.
  /// Uses SHA256 hashing for secure password comparison.
  Future<User?> login(String username, String password) async {
    try {
      // Hash the provided password
      final passwordHash = _hashPassword(password);
      
      // Find user by username first
      final user = await _database.getUserByUsername(username);
      
      // Verify password hash and user is active
      if (user != null && 
          user.passwordHash == passwordHash && 
          user.isActive && 
          !user.isDeleted) {
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
        username: 'admin',
        passwordHash: _hashPassword('admin123'),
        fullName: 'System Administrator',
        role: 'admin',
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
      
      await _database.createUser(adminUser);
    } catch (e) {
      // Log error but don't throw to prevent app startup issues
      print('Error seeding admin user: $e');
    }
  }

  /// Hashes a password using SHA256 algorithm.
  /// 
  /// Returns the hex-encoded hash of the password string.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
