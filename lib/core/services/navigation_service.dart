import 'package:flutter/material.dart';

import '../../features/admin/screens/dashboard_screen.dart';
import '../../features/admin/screens/user_accounts_screen.dart';
import '../../features/customer/screens/dashboard_screen.dart';
import '../../features/delivery/screens/dashboard_screen.dart';
import '../../features/warehouse/screens/dashboard_screen.dart';
import '../../features/auth/account_pending_screen.dart';
import '../auth/auth_service.dart';
import '../business/role_based_access.dart';
import '../database/app_database.dart';
import '../sync/sync_manager.dart';

/// Navigation Service
/// Handles role-based navigation and routing
class NavigationService {

  NavigationService(this._authService, this._roleBasedAccess, this._database, this._syncManager);
  final AuthService _authService;
  final RoleBasedAccess _roleBasedAccess;
  final AppDatabase _database;
  final SyncManager _syncManager;

  /// Get dashboard widget based on user role
  Widget getDashboardForRole(String role) {
    switch (role) {
      case 'admin':
        return AdminDashboardScreen(database: _database, syncManager: _syncManager);
      case 'warehouse':
        return WarehouseDashboardScreen(database: _database, syncManager: _syncManager);
      case 'delivery':
        return const DeliveryDashboardScreen();
      case 'customer':
        return const CustomerDashboardScreen();
      case 'pending':
        return const AccountPendingScreen();
      case 'users':
        return UserAccountsScreen(database: _database, syncManager: SyncManager.instance);
      default:
        return const CustomerDashboardScreen(); // Default fallback
    }
  }

  /// Check if user can access specific route
  Future<bool> canAccessRoute(String route) async {
    if (!_authService.isAuthenticated) {
      return false;
    }

    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) {
        return false;
      }

      // Use existing role-based access logic
      return await _roleBasedAccess.checkPermission(
        userId: user.id,
        action: 'view',
        resource: route,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get initial route based on user role
  Future<String> getInitialRoute() async {
    if (!_authService.isAuthenticated) {
      return '/login';
    }

    try {
      final role = await _authService.getUserRole();
      switch (role) {
        case 'admin':
          return '/admin/dashboard';
        case 'warehouse':
          return '/warehouse/dashboard';
        case 'delivery':
          return '/delivery/dashboard';
        case 'customer':
          return '/customer/dashboard';
        default:
          return '/customer/dashboard';
      }
    } catch (e) {
      return '/login';
    }
  }

  /// Navigate to appropriate dashboard
  Future<void> navigateToDashboard(BuildContext context) async {
    try {
      final route = await getInitialRoute();
      
      if (!context.mounted) return;
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
      );
    } catch (e) {
      // Fallback to customer dashboard
      if (!context.mounted) return;
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/customer/dashboard',
        (route) => false,
      );
    }
  }
}
