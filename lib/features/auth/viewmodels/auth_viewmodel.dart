import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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

  /// Signs in with Google.
  ///
  /// On Android: uses the native Google Sign-In SDK (no browser popup).
  /// On other platforms: falls back to Supabase OAuth web flow.
  /// Returns true when sign-in succeeded and the local session is ready.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Native Android flow — uses google_sign_in package.
        final googleSignIn = GoogleSignIn(
          clientId: '331867448304-saipigd6cpsquunjvv9r88cl3lidc127.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled
          _setLoading(false);
          return false;
        }
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;
        if (idToken == null) {
          _setError('Google sign-in failed: no ID token received');
          return false;
        }
        // Exchange Google tokens for a Supabase session
        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        // Session is now active — loginWithOAuthSession will be called
        // by the auth state listener in main.dart
        return true;
      } else {
        // Desktop / web — browser OAuth flow
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.villahermosa://login-callback',
        );
        return true;
      }
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
