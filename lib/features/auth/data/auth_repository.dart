import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

/// Repository handling user authentication operations.
/// 
/// Provides secure login functionality with password hashing and
/// automatic admin user seeding for initial system setup.
class AuthRepository {

  AuthRepository(this._database);
  final AppDatabase _database;

  /// Creates a new user account.
  /// 
  /// Returns true if signup succeeds, false if user already exists or error occurs.
  /// Uses SHA256 hashing for secure password storage.
  Future<bool> signup(String firstName, String lastName, String email, String password, String role) async {
    try {
      // Check if user already exists
      final existingUser = await _database.getUserByEmail(email);
      if (existingUser != null) {
        return false; // User already exists
      }

      // Create new user
      final newUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        passwordHash: _hashPassword(password),
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        isActive: const Value(true),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );

      await _database.createUser(newUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Authenticates a user with email and password.
  /// 
  /// Returns User object if authentication succeeds, null otherwise.
  /// Uses SHA256 hashing for secure password comparison.
  /// Throws AuthException if credentials are invalid.
  Future<User?> login(String email, String password) async {
    try {
      // Hash provided password
      final passwordHash = _hashPassword(password);
      
      // Find user by email only
      final user = await _database.getUserByEmail(email);
      
      // Verify password hash and user is active
      if (user != null && 
          user.passwordHash == passwordHash && 
          user.isActive && 
          !user.isDeleted) {
        return user;
      }
      
      // If user exists but password doesn't match, throw exception
      if (user != null && user.isActive && !user.isDeleted) {
        throw AuthException("Invalid credentials");
      }
      
      return null;
    } catch (e) {
      // Re-throw AuthException, return null for other errors
      if (e is AuthException) {
        rethrow;
      }
      return null;
    }
  }

  /// Creates a default admin user if no users exist in the database.
  /// 
  /// This ensures the system has at least one administrator account
  /// for initial setup and access.
  /// 
  /// Admin credentials for testing:
  /// Email: admin@villahermosa.com
  /// Password: admin123
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
        uuid: const Uuid().v4(),
        firstName: 'System',
        lastName: 'Administrator',
        passwordHash: _hashPassword('admin123'),
        email: 'admin@villahermosa.com',
        role: 'admin',
        isActive: const Value(true),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
      
      await _database.createUser(adminUser);
    } catch (e) {
      // Log error but don't throw to prevent app startup issues
      debugPrint('Error seeding admin user: $e');
    }
  }

  /// Hashes a password using SHA256 algorithm.
  /// 
  /// Returns hex-encoded hash of password string.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
