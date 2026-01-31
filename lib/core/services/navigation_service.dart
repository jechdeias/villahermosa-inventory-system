import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../business/role_based_access.dart';

/// Navigation Service
/// Handles role-based navigation and routing
class NavigationService {
  final AuthService _authService;
  final RoleBasedAccess _roleBasedAccess;

  NavigationService(this._authService, this._roleBasedAccess);

  /// Get dashboard widget based on user role
  Widget getDashboardForRole(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'warehouse':
        return const WarehouseDashboard();
      case 'delivery':
        return const DeliveryDashboard();
      case 'customer':
        return const CustomerDashboard();
      default:
        return const CustomerDashboard(); // Default fallback
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
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
      );
    } catch (e) {
      // Fallback to customer dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/customer/dashboard',
        (route) => false,
      );
    }
  }
}

// Placeholder dashboard widgets - these will be implemented later
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Admin Dashboard - Coming Soon'),
      ),
    );
  }
}

class WarehouseDashboard extends StatelessWidget {
  const WarehouseDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Warehouse Dashboard - Coming Soon'),
      ),
    );
  }
}

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Delivery Dashboard - Coming Soon'),
      ),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Customer Dashboard - Coming Soon'),
      ),
    );
  }
}
