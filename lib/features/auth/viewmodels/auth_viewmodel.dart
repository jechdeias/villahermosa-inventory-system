import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../data/auth_repository.dart';

/// ViewModel managing authentication state and operations.
/// 
/// Handles user login, signup, loading states, and error management
/// while providing reactive state updates to the UI.
class AuthViewModel extends ChangeNotifier {

  final AuthService _authService;
  final AuthRepository _authRepository;

  AuthViewModel(this._authService, [AppDatabase? database]) 
    : _authRepository = AuthRepository(database ?? AppDatabase());

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
        
        // Check if user needs to change password
        if (user.forcePasswordChange) {
          // Don't proceed to dashboard, let navigation handle redirect
          return true;
        }
        
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

  /// Signs up a new customer account.
  /// 
  /// Returns true if signup was successful, false otherwise.
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      return await _authRepository.signup(firstName, lastName, email, password);
    } catch (e) {
      _setError('Signup failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with Google via Supabase OAuth.
  ///
  /// On mobile, Supabase opens a browser for the Google consent flow and
  /// returns via deep-link.  On desktop/web it opens the system browser.
  /// Returns true when the OAuth flow was launched successfully (the actual
  /// session arrival is asynchronous via Supabase's auth state listener).
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.villahermosa://login-callback',
      );
      // OAuth launches a browser; the result arrives via deep-link.
      // Loading will clear when the caller re-checks after returning.
      return true;
    } catch (e) {
      _setError('Google sign-in failed: ${e.toString()}');
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
  static AuthViewModel get instance => _instance ??= AuthViewModel(AuthService.instance, null);
}
