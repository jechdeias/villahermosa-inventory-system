import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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

      // Hash password with bcrypt (secure)
      final hashedPassword = _hashPassword(password);

      // Create new user in local Drift first
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

      // Create Supabase Auth user in background (non-blocking)
      _attemptSupabaseSignup(email, password);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Attempt to create Supabase Auth user (non-blocking)
  Future<void> _attemptSupabaseSignup(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('✅ Supabase Auth user created');
    } catch (e) {
      debugPrint('⚠️ Supabase Auth signup failed: $e');
    }
  }

  /// Login user with email only
  Future<User?> login(String identifier, String password) async {
    try {
      debugPrint('🔐 Attempting login for: $identifier');
      
      // STEP 1: Try local Drift auth first (works offline)
      final localUser = await _localLogin(identifier, password);
      
      if (localUser == null) return null;
      
      // STEP 2: Try Supabase Auth and wait for session
      debugPrint('🔑 Local auth succeeded, attempting Supabase Auth...');
      await _attemptSupabaseAuth(identifier, password);
      debugPrint('📋 Session after auth: ${Supabase.instance.client.auth.currentSession != null ? "Active" : "None"}');
      
      return localUser;
    } catch (e) {
      debugPrint('💥 Login error: $e');
      return null;
    }
  }

  /// Local Drift authentication (offline-first)
  Future<User?> _localLogin(String email, String password) async {
    try {
      // Find user by email only
      final user = await _database.getUserByEmail(email);
      
      if (user == null) {
        debugPrint('❌ User not found: $email');
        return null;
      }
      
      final storedHash = user.passwordHash;
      final passwordValid = _verifyPassword(password, storedHash);
      
      debugPrint('🔑 Stored hash: ${storedHash.substring(0, 20)}...');
      debugPrint('🔑 Password valid: $passwordValid');

      if (!passwordValid) {
        debugPrint('❌ Password mismatch for: $email');
        return null; // Password mismatch
      }
      
      debugPrint('✅ Local login successful for: $email');
      
      // Set current user session
      _currentUser = user;
      _isAuthenticated = true;

      return user;
    } catch (e) {
      debugPrint('💥 Local login error: $e');
      return null;
    }
  }

  /// Attempt Supabase Auth authentication (blocking)
  Future<void> _attemptSupabaseAuth(String email, String password) async {
    try {
      debugPrint('🔑 Attempting Supabase Auth: $email');
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        debugPrint('✅ Supabase Auth established');
        debugPrint('🎫 Token: ${response.session!.accessToken.substring(0, 30)}...');
      } else {
        debugPrint('⚠️ No session returned from Supabase Auth');
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Auth failed: ${e.message}');
      debugPrint('❌ Status code: ${e.statusCode}');
    } catch (e) {
      debugPrint('❌ Supabase Auth error: $e');
    }
    
    // Always log current session state
    final currentSession = Supabase.instance.client.auth.currentSession;
    debugPrint('📋 Current session: ${currentSession != null ? "Active" : "None"}');
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signout failed: $e');
    }
    // Always clear local session regardless
    await _clearLocalSession();
  }

  /// Clear local session
  Future<void> _clearLocalSession() async {
    _currentUser = null;
    _isAuthenticated = false;
  }

  /// Check and restore Supabase session on app startup
  Future<void> checkSupabaseSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Supabase session restored');
      } else {
        debugPrint('ℹ️ No existing Supabase session');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to check Supabase session: $e');
    }
  }

  /// Get current Supabase session (for sync operations)
  String? get supabaseAccessToken {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  /// Check if Supabase is authenticated
  bool get isSupabaseAuthenticated {
    return Supabase.instance.client.auth.currentSession != null;
  }

  /// SHA256 password hash (for legacy migration only)
String _sha256Hash(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// Bcrypt password hash (secure)
String _hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

/// Verify password with bcrypt fallback to SHA256 for migration
bool _verifyPassword(String password, String hash) {
  // Handle legacy SHA256 hashes during migration
  try {
    // Try bcrypt first
    return BCrypt.checkpw(password, hash);
  } catch (e) {
    // Fall back to SHA256 for existing accounts
    final sha256Hash = _sha256Hash(password);
    if (sha256Hash == hash) {
      // Migrate this account to bcrypt silently
      _migratePasswordToBcrypt(password, hash);
      return true;
    }
    return false;
  }
}

/// Migrate existing SHA256 passwords to bcrypt
Future<void> _migratePasswordToBcrypt(String password, String oldHash) async {
  try {
    final newHash = _hashPassword(password);
    await (_database.update(_database.users)
      ..where((u) => u.passwordHash.equals(oldHash)))
      .write(UsersCompanion(
        passwordHash: Value(newHash),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ));
    debugPrint('✅ Password migrated to bcrypt');
  } catch (e) {
    debugPrint('⚠️ Password migration failed: $e');
  }
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
