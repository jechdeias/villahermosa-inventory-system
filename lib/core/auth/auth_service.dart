import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart' as db;

/// Authentication Service
/// Handles user authentication using Supabase and local database
class AuthService {

  AuthService(this._database);
  final db.AppDatabase _database;

  /// Get current authenticated user from Supabase
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in user with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response;
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  /// Sign up user with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
        },
      );
      
      return response;
    } catch (e) {
      throw AuthException('Sign up failed: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  /// Get user role from local database
  Future<String> getUserRole() async {
    if (currentUser == null) {
      throw const AuthException('No authenticated user');
    }

    try {
      // Try to get user from local database first
      final localUser = await _database.getUserByEmail(currentUser!.email!);
      if (localUser != null) {
        return localUser.role;
      }

      // If not found locally, get from Supabase
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('email', currentUser!.email!)
          .single();
      
      return userData['role'] ?? 'customer';
    } catch (e) {
      // Default to customer role if error occurs
      return 'customer';
    }
  }

  /// Get user data from local database
  Future<db.User?> getCurrentUserData() async {
    if (currentUser == null) {
      return null;
    }

    return _database.getUserByEmail(currentUser!.email!);
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }
}

/// Authentication Exception
class AuthException implements Exception {
  
  const AuthException(this.message);
  final String message;
  
  @override
  String toString() => 'AuthException: $message';
}