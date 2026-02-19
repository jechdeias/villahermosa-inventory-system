import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

/// Authentication Service
/// Handles user authentication and session management
class AuthService {
  AuthService(this._database);
  final AppDatabase _database;
  
  User? _currentUser;
  bool _isAuthenticated = false;

  /// Check if user is authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Get current user data
  User? getCurrentUser() => _currentUser;

  /// Get current user data (async for compatibility)
  Future<User?> getCurrentUserData() async => _currentUser;

  /// Get current user role
  Future<String> getUserRole() async {
    return _currentUser?.role ?? 'customer';
  }

  /// Signs up a new user.
  /// 
  /// Returns true if signup was successful, false otherwise.
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? role, // Optional parameter
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if email already exists
      final existingUser = await _database.customSelect(
        'SELECT id FROM users WHERE email = ? AND is_deleted = 0',
        variables: [
          Variable.withString(email),
        ],
      ).getSingleOrNull();

      if (existingUser != null) {
        return false; // User already exists
      }

      // Hash password (simple hash for now)
      final hashedPassword = _hashPassword(password);

      // Create new user
      await _database.createUser(
        UsersCompanion.insert(
          uuid: DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: firstName, // Use firstName field
          lastName: lastName, // Use lastName field
          email: email,
          passwordHash: hashedPassword,
          role: role ?? 'pending', // Default to pending
          isActive: const Value(true),
          isDeleted: const Value(false),
          syncStatus: const Value('pending'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login user with email only
  Future<User?> login(String identifier, String password) async {
    try {
      debugPrint('🔐 Attempting login for: $identifier');
      
      // Find user by email only
      final result = await _database.customSelect(
        'SELECT * FROM users WHERE email = ? AND is_deleted = 0 AND is_active = 1',
        variables: [
          Variable.withString(identifier),
        ],
      ).getSingleOrNull();

      if (result == null) {
        debugPrint('❌ User not found: $identifier');
        return null; // User not found
      }

      final userData = result.data;
      if (userData == null) {
        debugPrint('❌ User data is null for: $identifier');
        return null;
      }
      
      final storedHash = userData['password_hash'] as String?;
      if (storedHash == null) {
        debugPrint('❌ Password hash is null for: $identifier');
        return null;
      }
      
      final inputHash = _hashPassword(password);
      
      debugPrint('🔑 Stored hash: $storedHash');
      debugPrint('🔑 Input hash: $inputHash');

      if (storedHash != inputHash) {
        debugPrint('❌ Password mismatch for: $identifier');
        return null; // Password mismatch
      }

      // Get full user object
      final user = await _database.getUserByEmail(identifier);
      if (user == null) {
        debugPrint('❌ Could not retrieve user object for: $identifier');
        return null;
      }
      
      debugPrint('✅ Login successful for: $identifier');
      
      // Set current user session
      _currentUser = user;
      _isAuthenticated = true;

      return user;
    } catch (e) {
      debugPrint('💥 Login error: $e');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
  }

  /// SHA256 password hash (matches AuthRepository)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Static instance for singleton pattern
  static AuthService? _instance;
  
  static AuthService get instance {
    _instance ??= AuthService(AppDatabase());
    return _instance!;
  }
  
  /// Initialize with shared database instance (call from main.dart)
  static void initializeWithDatabase(AppDatabase database) {
    _instance = AuthService(database);
  }

  /// Sets loading state (for AuthViewModel compatibility)
  void _setLoading(bool loading) {
    // This method is for AuthViewModel compatibility
    // In a real implementation, this would update UI state
  }

  /// Clears error state (for AuthViewModel compatibility)
  void _clearError() {
    // This method is for AuthViewModel compatibility
    // In a real implementation, this would clear UI error state
  }
}
