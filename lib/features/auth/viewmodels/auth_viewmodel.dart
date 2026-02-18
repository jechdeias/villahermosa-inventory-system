import 'package:flutter/foundation.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';

/// ViewModel managing authentication state and operations.
/// 
/// Handles user login, signup, loading states, and error management
/// while providing reactive state updates to the UI.
class AuthViewModel extends ChangeNotifier {

  AuthViewModel(this._authService);
  final AuthService _authService;

  /// Loading state for async operations.
  bool _isLoading = false;

  /// Error message for the last failed operation.
  String? _errorMessage;

  // Getters for reactive state
  User? get currentUser => _authService.getCurrentUser();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Authenticates a user with email/username and password.
  /// 
  /// Updates loading state and error message accordingly.
  /// Uses AuthService for authentication.
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Basic validation
      if (identifier.isEmpty || password.isEmpty) {
        _setError('Email/username and password are required');
        return false;
      }

      final user = await _authService.login(identifier, password);
      
      if (user != null) {
        _clearError();
        return true;
      } else {
        _setError('Invalid credentials');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs up a new user.
  /// 
  /// Returns true if signup was successful, false otherwise.
  Future<bool> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Basic validation
      if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
        _setError('All fields are required');
        return false;
      }

      if (password.length < 6) {
        _setError('Password must be at least 6 characters');
        return false;
      }

      if (!email.contains('@')) {
        _setError('Please enter a valid email');
        return false;
      }

      final success = await _authService.signUp(
        name: name,
        username: username,
        email: email,
        password: password,
        role: role,
      );

      if (!success) {
        _setError('Email or username already exists');
        return false;
      }

      return true;
    } catch (e) {
      _setError('Signup failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      await _authService.logout();
      _clearError();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    }
  }

  /// Clears error message for UI display.
  void clearError() {
    _clearError();
  }

  /// Sets loading state and notifies listeners.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets error message and notifies listeners.
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clears error message and notifies listeners.
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Create singleton instance
  static AuthViewModel? _instance;
  static AuthViewModel get instance => _instance ??= AuthViewModel(AuthService.instance);
}
