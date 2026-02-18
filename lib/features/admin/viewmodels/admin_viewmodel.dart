import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

/// Admin View Model
/// 
/// Handles administrative operations including user management
class AdminViewModel extends ChangeNotifier {
  
  final AppDatabase _database;
  List<User> _allUsers = [];
  List<User> _pendingUsers = [];
  List<User> _activeUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminViewModel(this._database);

  // Getters
  List<User> get allUsers => _allUsers;
  List<User> get pendingUsers => _pendingUsers;
  List<User> get activeUsers => _activeUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all users and categorize them
  Future<void> loadAllUsers() async {
    _setLoading(true);
    _clearError();

    try {
      final users = await _database.getAllUsers();
      
      _allUsers = users;
      _pendingUsers = users.where((user) => user.role == 'pending').toList();
      _activeUsers = users.where((user) => user.role != 'pending').toList();
    } catch (e) {
      _setError('Failed to load users: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Approve a pending user with assigned role
  Future<void> approveUser(String userId, String assignedRole) async {
    try {
      await _database.approveUser(userId, assignedRole);
      await loadAllUsers(); // Refresh the list
      _clearError();
    } catch (e) {
      _setError('Failed to approve user: $e');
    }
  }

  /// Deactivate a user
  Future<void> deactivateUser(String userId) async {
    try {
      await _database.deactivateUser(userId);
      await loadAllUsers(); // Refresh the list
      _clearError();
    } catch (e) {
      _setError('Failed to deactivate user: $e');
    }
  }

  /// Get role color for UI
  Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF6366F1); // deep purple
      case 'warehouse':
        return const Color(0xFF2196F3); // blue
      case 'customer':
        return const Color(0xFF4CAF50); // green
      case 'delivery':
        return const Color(0xFFFF9800); // orange
      default:
        return Colors.grey;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
