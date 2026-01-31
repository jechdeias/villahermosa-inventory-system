import 'package:flutter/material.dart';
import '../constants/user_roles.dart';

/// Widget that conditionally shows children based on user role
class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final UserRole? currentUserRole;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.currentUserRole,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    
    if (allowedRoles.contains(role)) {
      return child;
    }
    
    return fallback ?? const SizedBox.shrink();
  }

  UserRole _getCurrentUserRole() {
    // TODO: Get actual user role from auth service
    // For now, return customer as default
    return UserRole.customer;
  }
}

/// Widget that conditionally shows children based on specific permissions
class PermissionGuard extends StatelessWidget {
  final Widget child;
  final String screen;
  final UserAction action;
  final UserRole? currentUserRole;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.child,
    required this.screen,
    required this.action,
    this.currentUserRole,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    final permissions = RoleBasedNavigation.screenPermissions[role];
    final screenPermissions = permissions?[screen] ?? [];
    
    if (screenPermissions.contains(action)) {
      return child;
    }
    
    return fallback ?? const SizedBox.shrink();
  }

  UserRole _getCurrentUserRole() {
    // TODO: Get actual user role from auth service
    // For now, return customer as default
    return UserRole.customer;
  }
}

/// Widget that shows content only if user has any of the specified roles
class AnyRoleGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole> roles;
  final UserRole? currentUserRole;
  final Widget? fallback;

  const AnyRoleGuard({
    super.key,
    required this.child,
    required this.roles,
    this.currentUserRole,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    
    if (roles.contains(role)) {
      return child;
    }
    
    return fallback ?? const SizedBox.shrink();
  }

  UserRole _getCurrentUserRole() {
    // TODO: Get actual user role from auth service
    // For now, return customer as default
    return UserRole.customer;
  }
}

/// Widget that hides content for specific roles
class RoleHide extends StatelessWidget {
  final Widget child;
  final List<UserRole> hiddenRoles;
  final UserRole? currentUserRole;

  const RoleHide({
    super.key,
    required this.child,
    required this.hiddenRoles,
    this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    
    if (hiddenRoles.contains(role)) {
      return const SizedBox.shrink();
    }
    
    return child;
  }

  UserRole _getCurrentUserRole() {
    // TODO: Get actual user role from auth service
    // For now, return customer as default
    return UserRole.customer;
  }
}

/// Button that is enabled/disabled based on permissions
class PermissionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String screen;
  final UserAction action;
  final UserRole? currentUserRole;
  final ButtonStyle? style;
  final bool showDisabled;

  const PermissionButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.screen,
    required this.action,
    this.currentUserRole,
    this.style,
    this.showDisabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    final permissions = RoleBasedNavigation.screenPermissions[role];
    final screenPermissions = permissions?[screen] ?? [];
    final hasPermission = screenPermissions.contains(action);
    
    if (!hasPermission && !showDisabled) {
      return const SizedBox.shrink();
    }
    
    return ElevatedButton(
      onPressed: hasPermission ? onPressed : null,
      style: style,
      child: child,
    );
  }

  UserRole _getCurrentUserRole() {
    // TODO: Get actual user role from auth service
    // For now, return customer as default
    return UserRole.customer;
  }
}

/// ListTile that is shown/hidden based on permissions
class PermissionListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final String screen;
  final UserAction action;
  final UserRole? currentUserRole;

  const PermissionListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.screen,
    required this.action,
    this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    final permissions = RoleBasedNavigation.screenPermissions[role];
    final screenPermissions = permissions?[screen] ?? [];
    final hasPermission = screenPermissions.contains(action);
    
    if (!hasPermission) {
      return const SizedBox.shrink();
    }
    
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  UserRole _getCurrentUserRole() {
    // TODO: Get actual user role from auth service
    // For now, return customer as default
    return UserRole.customer;
  }
}
