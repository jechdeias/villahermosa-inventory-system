import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/user_roles.dart';

/// Service to manage role-based navigation
class RoleBasedNavigationService {
  static UserRole? _currentUserRole;
  
  static void setCurrentUserRole(UserRole role) {
    _currentUserRole = role;
  }
  
  static UserRole getCurrentUserRole() => _currentUserRole ?? UserRole.customer;
  
  static List<String> getAllowedScreens() => RoleBasedNavigation.allowedScreens[getCurrentUserRole()] ?? [];
  
  static bool canAccessScreen(String screenName) => getAllowedScreens().contains(screenName);
  
  static bool hasPermission(String screen, UserAction action) {
    final permissions = RoleBasedNavigation.screenPermissions[getCurrentUserRole()];
    final screenPermissions = permissions?[screen] ?? [];
    return screenPermissions.contains(action);
  }
}

/// Role-based navigation rail widget
class RoleBasedNavigationRail extends StatelessWidget {

  const RoleBasedNavigationRail({
    required this.selectedIndex, required this.onDestinationSelected, super.key,
    this.userRole,
  });
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    final role = userRole ?? RoleBasedNavigationService.getCurrentUserRole();
    final allowedScreens = RoleBasedNavigation.allowedScreens[role] ?? [];
    
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: Colors.grey[900],
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
      destinations: _buildDestinations(allowedScreens),
    );
  }

  List<NavigationRailDestination> _buildDestinations(List<String> screens) {
    final destinations = <NavigationRailDestination>[];
    
    for (final screen in screens) {
      destinations.add(_getDestinationForScreen(screen));
    }
    
    return destinations;
  }

  NavigationRailDestination _getDestinationForScreen(String screen) {
    switch (screen) {
      case 'dashboard':
        return const NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        );
      case 'orders':
        return const NavigationRailDestination(
          icon: Icon(Icons.shopping_cart),
          label: Text('Orders'),
        );
      case 'products':
        return const NavigationRailDestination(
          icon: Icon(Icons.inventory_2),
          label: Text('Products'),
        );
      case 'customers':
        return const NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Customers'),
        );
      case 'deliveries':
        return const NavigationRailDestination(
          icon: Icon(Icons.local_shipping),
          label: Text('Deliveries'),
        );
      case 'warehouse':
        return const NavigationRailDestination(
          icon: Icon(Icons.warehouse),
          label: Text('Warehouse'),
        );
      case 'reports':
        return const NavigationRailDestination(
          icon: Icon(Icons.analytics),
          label: Text('Reports'),
        );
      case 'stock_movements':
        return const NavigationRailDestination(
          icon: Icon(Icons.swap_vert),
          label: Text('Stock Movements'),
        );
      case 'profile':
        return const NavigationRailDestination(
          icon: Icon(Icons.person),
          label: Text('Profile'),
        );
      default:
        return const NavigationRailDestination(
          icon: Icon(Icons.help),
          label: Text('Unknown'),
        );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('selectedIndex', selectedIndex));
    properties.add(ObjectFlagProperty<Function(int p1)>.has('onDestinationSelected', onDestinationSelected));
    properties.add(EnumProperty<UserRole?>('userRole', userRole, defaultValue: null));
  }
}

/// Role-based bottom navigation bar widget
class RoleBasedBottomNavigationBar extends StatelessWidget {

  const RoleBasedBottomNavigationBar({
    required this.currentIndex, required this.onTap, super.key,
    this.userRole,
  });
  final int currentIndex;
  final Function(int) onTap;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    final role = userRole ?? RoleBasedNavigationService.getCurrentUserRole();
    final allowedScreens = RoleBasedNavigation.allowedScreens[role] ?? [];
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: _buildItems(allowedScreens),
    );
  }

  List<BottomNavigationBarItem> _buildItems(List<String> screens) {
    final items = <BottomNavigationBarItem>[];
    
    for (final screen in screens) {
      items.add(_getItemForScreen(screen));
    }
    
    return items;
  }

  BottomNavigationBarItem _getItemForScreen(String screen) {
    switch (screen) {
      case 'dashboard':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        );
      case 'orders':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Orders',
        );
      case 'products':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Products',
        );
      case 'customers':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Customers',
        );
      case 'deliveries':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Deliveries',
        );
      case 'warehouse':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.warehouse),
          label: 'Warehouse',
        );
      case 'reports':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Reports',
        );
      case 'stock_movements':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.swap_vert),
          label: 'Stock Movements',
        );
      case 'profile':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        );
      default:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.help),
          label: 'Unknown',
        );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('currentIndex', currentIndex));
    properties.add(ObjectFlagProperty<Function(int p1)>.has('onTap', onTap));
    properties.add(EnumProperty<UserRole?>('userRole', userRole, defaultValue: null));
  }
}

/// Route guard for navigation
class RouteGuard {
  static bool canAccessRoute(String routeName, {UserRole? userRole}) {
    final role = userRole ?? RoleBasedNavigationService.getCurrentUserRole();
    final allowedScreens = RoleBasedNavigation.allowedScreens[role] ?? [];
    
    // Extract screen name from route
    final screenName = routeName.split('/').last;
    return allowedScreens.contains(screenName);
  }
  
  static String getFallbackRoute({UserRole? userRole}) {
    final role = userRole ?? RoleBasedNavigationService.getCurrentUserRole();
    final allowedScreens = RoleBasedNavigation.allowedScreens[role] ?? [];
    
    // Return first allowed screen as fallback
    return allowedScreens.isNotEmpty ? '/${allowedScreens.first}' : '/dashboard';
  }
  
  /// Navigate to appropriate dashboard based on user role
  static void navigate(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        break;
      case 'warehouse':
        Navigator.pushReplacementNamed(context, '/warehouse/dashboard');
        break;
      case 'delivery':
        Navigator.pushReplacementNamed(context, '/delivery/dashboard');
        break;
      case 'customer':
        Navigator.pushReplacementNamed(context, '/customer/dashboard');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/customer/dashboard');
        break;
    }
  }
}
