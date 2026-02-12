import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/user_roles.dart';

/// Widget that conditionally shows children based on user role
class RoleGuard extends StatelessWidget {

  const RoleGuard({
    required this.child, required this.allowedRoles, super.key,
    this.currentUserRole,
    this.fallback,
  });
  final Widget child;
  final List<UserRole> allowedRoles;
  final UserRole? currentUserRole;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole ?? _getCurrentUserRole();
    
    if (allowedRoles.contains(role)) {
      return child;
    }
    
    return fallback ?? const SizedBox.shrink();
  }

  UserRole _getCurrentUserRole() {
    // TODO: This should get the actual user role from the current authenticated user
    // For now, return customer as default since widgets need synchronous role access
    // In a real implementation, this could use a state management solution
    return UserRole.customer;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<UserRole>('allowedRoles', allowedRoles, defaultValue: const <UserRole>{}));
    properties.add(EnumProperty<UserRole?>('currentUserRole', currentUserRole, defaultValue: null));
  }
}

/// Widget that conditionally shows children based on specific permissions
class PermissionGuard extends StatelessWidget {

  const PermissionGuard({
    required this.child, required this.screen, required this.action, super.key,
    this.currentUserRole,
    this.fallback,
  });
  final Widget child;
  final String screen;
  final UserAction action;
  final UserRole? currentUserRole;
  final Widget? fallback;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('screen', screen));
    properties.add(EnumProperty<UserAction>('action', action));
    properties.add(EnumProperty<UserRole?>('currentUserRole', currentUserRole, defaultValue: null));
  }
}

/// Widget that shows content only if user has any of the specified roles
class AnyRoleGuard extends StatelessWidget {

  const AnyRoleGuard({
    required this.child, required this.roles, super.key,
    this.currentUserRole,
    this.fallback,
  });
  final Widget child;
  final List<UserRole> roles;
  final UserRole? currentUserRole;
  final Widget? fallback;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<UserRole>('roles', roles, defaultValue: const <UserRole>{}));
    properties.add(EnumProperty<UserRole?>('currentUserRole', currentUserRole, defaultValue: null));
  }
}

/// Widget that hides content for specific roles
class RoleHide extends StatelessWidget {

  const RoleHide({
    required this.child, required this.hiddenRoles, super.key,
    this.currentUserRole,
  });
  final Widget child;
  final List<UserRole> hiddenRoles;
  final UserRole? currentUserRole;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<UserRole>('hiddenRoles', hiddenRoles, defaultValue: const <UserRole>{}));
    properties.add(EnumProperty<UserRole?>('currentUserRole', currentUserRole, defaultValue: null));
  }
}

/// Button that is enabled/disabled based on permissions
class PermissionButton extends StatelessWidget {

  const PermissionButton({
    required this.onPressed, required this.child, required this.screen, required this.action, super.key,
    this.currentUserRole,
    this.style,
    this.showDisabled = true,
  });
  final VoidCallback onPressed;
  final Widget child;
  final String screen;
  final UserAction action;
  final UserRole? currentUserRole;
  final ButtonStyle? style;
  final bool showDisabled;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed));
    properties.add(StringProperty('screen', screen));
    properties.add(EnumProperty<UserAction>('action', action));
    properties.add(EnumProperty<UserRole?>('currentUserRole', currentUserRole, defaultValue: null));
    properties.add(DiagnosticsProperty<ButtonStyle?>('style', style));
    properties.add(DiagnosticsProperty<bool>('showDisabled', showDisabled));
  }
}

/// ListTile that is shown/hidden based on permissions
class PermissionListTile extends StatelessWidget {

  const PermissionListTile({
    required this.leading, required this.title, required this.screen, required this.action, super.key,
    this.subtitle,
    this.onTap,
    this.currentUserRole,
  });
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final String screen;
  final UserAction action;
  final UserRole? currentUserRole;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
    properties.add(StringProperty('screen', screen));
    properties.add(EnumProperty<UserAction>('action', action));
    properties.add(EnumProperty<UserRole?>('currentUserRole', currentUserRole, defaultValue: null));
  }
}
