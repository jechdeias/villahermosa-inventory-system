import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/config/supabase_config.dart';

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

  /// Creates a new customer account.
  /// 
  /// Returns true if signup succeeds, false if user already exists or error occurs.
  /// Uses SHA256 hashing for secure password storage.
  /// 
  /// All public signups create customer accounts with auto-approval.
  Future<bool> signup(String firstName, String lastName, String email, String password) async {
    try {
      debugPrint('📝 Customer signup attempt: $firstName $lastName, $email');
      
      // Check if user already exists
      final existingUser = await _database.getUserByEmail(email);
      if (existingUser != null) {
        debugPrint('❌ Signup failed: User already exists - $email');
        return false; // User already exists
      }

      // All public signups are customers with auto-approval
      const String finalRole = 'customer';
      const bool isActive = true;
      
      debugPrint('👤 Creating customer account with auto-approval: $email');

      // Check connectivity before setting sync status
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResults.contains(ConnectivityResult.none);
      
      debugPrint('🌐 Connectivity check: isOnline=$isOnline');
      
      // Create new user with appropriate sync status
      final newUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        passwordHash: _hashPassword(password),
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: finalRole,
        isActive: Value(isActive),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(isOnline ? 'synced' : 'pending'),
      );

      await _database.createUser(newUser);
      debugPrint('✅ Local SQLite save successful: role=$finalRole, active=$isActive, syncStatus=${isOnline ? 'synced' : 'pending'}');
      
      // Verify local save immediately
      final savedUser = await _database.getUserByEmail(email);
      if (savedUser != null) {
        debugPrint('🔍 Verification - Local user found: ${savedUser.email}');
        debugPrint('🔍 Verification - Role stored: ${savedUser.role}');
        debugPrint('🔍 Verification - isActive: ${savedUser.isActive}');
        debugPrint('🔍 Verification - syncStatus: ${savedUser.syncStatus}');
        debugPrint('🔍 Verification - UUID: ${savedUser.uuid}');
      } else {
        debugPrint('❌ Verification failed: User not found in local DB after save');
      }
      
      // Only attempt Supabase sync if online
      if (isOnline) {
        debugPrint('☁️ Online - triggering Supabase sync for new customer...');
        final syncResult = await _syncUserToSupabase(savedUser!);
        debugPrint('☁️ Supabase sync result: $syncResult');
        
        // Send verification email via Supabase Auth
        try {
          await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
            emailRedirectTo: 'io.supabase.villahermosa://login-callback',
          );
          debugPrint('✅ Verification email sent to: $email');
        } catch (e) {
          debugPrint('⚠️ Failed to send verification email: $e');
          // Don't fail signup - user is created locally
        }
      } else {
        debugPrint('📴 Offline - user saved locally with pending status, will sync later');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error creating customer: $e');
      return false;
    }
  }

  /// Creates a new staff account (admin only).
  /// 
  /// Returns true if staff account was created successfully, false otherwise.
  /// Staff accounts require admin approval (isActive=false).
  Future<bool> createStaffAccount(String firstName, String lastName, String email, String password, String role) async {
    try {
      debugPrint('👷 Staff account creation: $firstName $lastName, $email, role: $role');
      
      // Validate role is staff-only
      if (!['warehouse', 'delivery'].contains(role)) {
        debugPrint('❌ Invalid staff role: $role. Only warehouse and delivery allowed.');
        return false;
      }
      
      // Check if user already exists
      final existingUser = await _database.getUserByEmail(email);
      if (existingUser != null) {
        debugPrint('❌ Staff creation failed: User already exists - $email');
        return false;
      }

      // Staff accounts require admin approval
      const bool isActive = false;
      
      debugPrint('👷 Creating staff account with pending approval: $email ($role)');

      // Check connectivity before setting sync status
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResults.contains(ConnectivityResult.none);
      
      debugPrint('🌐 Staff connectivity check: isOnline=$isOnline');
      
      // Create new staff user with appropriate sync status
      final newStaffUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        passwordHash: _hashPassword(password),
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        isActive: Value(isActive),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(isOnline ? 'synced' : 'pending'),
      );

      await _database.createUser(newStaffUser);
      debugPrint('✅ Local SQLite save successful: role=$role, active=$isActive, syncStatus=${isOnline ? 'synced' : 'pending'}');
      
      // Verify local save immediately
      final savedUser = await _database.getUserByEmail(email);
      if (savedUser != null) {
        debugPrint('🔍 Staff Verification - Local user found: ${savedUser.email}');
        debugPrint('🔍 Staff Verification - Role stored: ${savedUser.role}');
        debugPrint('🔍 Staff Verification - isActive: ${savedUser.isActive}');
        debugPrint('🔍 Staff Verification - syncStatus: ${savedUser.syncStatus}');
        debugPrint('🔍 Staff Verification - UUID: ${savedUser.uuid}');
      } else {
        debugPrint('❌ Staff Verification failed: User not found in local DB after save');
      }
      
      // Only attempt Supabase sync if online
      if (isOnline) {
        debugPrint('☁️ Online - triggering Supabase sync for new staff...');
        final syncResult = await _syncUserToSupabase(savedUser!);
        debugPrint('☁️ Supabase sync result: $syncResult');
      } else {
        debugPrint('📴 Offline - staff user saved locally with pending status, will sync later');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error creating staff account: $e');
      return false;
    }
  }

  /// Sync user to Supabase
  Future<bool> _syncUserToSupabase(User user) async {
    try {
      // Create service client for sync operations
      final serviceClient = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.serviceKey,
        headers: {'X-Client-Info': 'service_role'},
      );
      
      final userData = {
        'uuid': user.uuid,
        'firstName': user.firstName,    // ← Fix: Use camelCase for Supabase
        'lastName': user.lastName,      // ← Fix: Use camelCase for Supabase
        'email': user.email,
        'password_hash': user.passwordHash,
        'role': user.role,
        'is_active': user.isActive,
        'is_deleted': user.isDeleted,
        'sync_status': 'synced',
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
      };
      
      debugPrint('☁️ Syncing to Supabase with data: $userData');
      
      final result = await serviceClient
          .from('users')
          .upsert(userData)
          .select()
          .maybeSingle();
          
      debugPrint('☁️ Supabase upsert result: $result');
      return result != null;
    } catch (e) {
      debugPrint('❌ Supabase sync error: $e');
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
      debugPrint('🌱 Checking if admin user seeding is needed...');
      
      // Check if any users exist
      final existingUsers = await _database.getAllUsers();
      
      if (existingUsers.isNotEmpty) {
        debugPrint('✅ Users already exist, skipping admin seeding');
        // Users already exist, no need to seed
        return;
      }
      
      debugPrint('📝 Creating default admin user...');
      
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
      debugPrint('✅ Admin user created successfully: admin@villahermosa.com');
    } catch (e) {
      // Log error but don't throw to prevent app startup issues
      debugPrint('💥 Error seeding admin user: $e');
    }
  }

  /// Creates test users for development and testing purposes
  /// 
  /// This method creates sample users with different roles to test
  /// admin user management interface.
  Future<void> createTestUsers() async {
    try {
      debugPrint('🧪 Creating test users...');
      
      // Create pending user
      final pendingUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        firstName: 'John',
        lastName: 'Doe',
        passwordHash: _hashPassword('password123'),
        email: 'john.doe@example.com',
        role: 'pending', // This user needs approval
        isActive: const Value(true),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
      
      // Create warehouse user
      final warehouseUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        firstName: 'Jane',
        lastName: 'Smith',
        passwordHash: _hashPassword('password123'),
        email: 'jane.smith@example.com',
        role: 'warehouse',
        isActive: const Value(true),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
      
      // Create customer user
      final customerUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        firstName: 'Bob',
        lastName: 'Wilson',
        passwordHash: _hashPassword('password123'),
        email: 'bob.wilson@example.com',
        role: 'customer',
        isActive: const Value(true),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
      
      // Create delivery user
      final deliveryUser = UsersCompanion.insert(
        uuid: const Uuid().v4(),
        firstName: 'Mike',
        lastName: 'Johnson',
        passwordHash: _hashPassword('password123'),
        email: 'mike.johnson@example.com',
        role: 'delivery',
        isActive: const Value(true),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
      
      await _database.createUser(pendingUser);
      await _database.createUser(warehouseUser);
      await _database.createUser(customerUser);
      await _database.createUser(deliveryUser);
      
      debugPrint('✅ Test users created successfully');
      debugPrint('📋 Test accounts created:');
      debugPrint('   - john.doe@example.com (pending) - password123');
      debugPrint('   - jane.smith@example.com (warehouse) - password123');
      debugPrint('   - bob.wilson@example.com (customer) - password123');
      debugPrint('   - mike.johnson@example.com (delivery) - password123');
    } catch (e) {
      debugPrint('❌ Error creating test users: $e');
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
