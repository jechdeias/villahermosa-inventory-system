import 'package:drift/drift.dart';
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

  /// Sign up new user
  Future<bool> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Check if email or username already exists
      final existingUser = await _database.customSelect(
        'SELECT id FROM users WHERE (email = ? OR name = ?) AND is_deleted = 0',
        variables: [
          Variable.withString(email),
          Variable.withString(username),
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
          name: username,
          email: email,
          passwordHash: hashedPassword,
          role: role,
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

  /// Login user with email or username
  Future<User?> login(String identifier, String password) async {
    try {
      // Find user by email or username
      final result = await _database.customSelect(
        'SELECT * FROM users WHERE (email = ? OR name = ?) AND is_deleted = 0 AND is_active = 1',
        variables: [
          Variable.withString(identifier),
          Variable.withString(identifier),
        ],
      ).getSingleOrNull();

      if (result == null) {
        return null; // User not found
      }

      final userData = result.data;
      final storedHash = userData['password_hash'] as String;
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        return null; // Password mismatch
      }

      // Get full user object
      final user = await _database.getUserByEmail(identifier);
      if (user == null) return null;

      // Set current user session
      _currentUser = user;
      _isAuthenticated = true;

      return user;
    } catch (e) {
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
  }

  /// Simple password hash (placeholder - replace with proper crypto)
  String _hashPassword(String password) {
    // Simple hash for demonstration - replace with proper crypto in production
    return password.split('').map((char) => char.codeUnitAt(0).toString()).join('');
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
}
