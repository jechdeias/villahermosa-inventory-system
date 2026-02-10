import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../../../core/database/app_database.dart';

/// ViewModel managing authentication state and operations.
/// 
/// Handles user login, loading states, and error management
/// while providing reactive state updates to the UI.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository);

  /// Current authenticated user, null if not logged in.
  User? _currentUser;

  /// Loading state for async operations.
  bool _isLoading = false;

  /// Error message for the last failed operation.
  String? _errorMessage;

  // Getters for reactive state
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Authenticates a user with username and password.
  /// 
  /// Updates loading state and error message accordingly.
  /// Sets currentUser on successful authentication.
  Future<void> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.login(username, password);
      
      if (user != null) {
        _currentUser = user;
        _clearError();
      } else {
        _setError('Invalid username or password');
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user.
  void logout() {
    _currentUser = null;
    _clearError();
    notifyListeners();
  }

  /// Seeds admin user if no users exist.
  /// 
  /// Should be called during app initialization.
  Future<void> seedAdminUserIfNeeded() async {
    try {
      await _authRepository.seedAdminUserIfEmpty();
    } catch (e) {
      _setError('Failed to seed admin user: ${e.toString()}');
    }
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
}
