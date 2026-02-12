import 'package:flutter/material.dart';

import '../../core/constants/user_roles.dart';
import '../../core/navigation/role_based_navigation.dart';
import '../../core/widgets/role_based_widgets.dart';

/// Simple test screen to verify role-based UI gating works
class RoleGatingTestScreen extends StatelessWidget {
  const RoleGatingTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set a test role
    RoleBasedNavigationService.setCurrentUserRole(UserRole.customer);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Gating Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Testing Role-Based UI Gating:', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // This should be hidden for customer role
            const RoleGuard(
              allowedRoles: [UserRole.admin, UserRole.warehouse],
              currentUserRole: UserRole.customer,
              fallback: Card(
                color: Colors.grey,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Content Hidden - Insufficient Permissions'),
                ),
              ),
              child: Card(
                color: Colors.red,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Admin/Warehouse Only Content', 
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // This should be visible for customer role
            const RoleGuard(
              allowedRoles: [UserRole.admin, UserRole.customer],
              currentUserRole: UserRole.customer,
              child: Card(
                color: Colors.green,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Customer Can See This', 
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Permission button test
            PermissionButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer can view products')),
              ),
              screen: 'products',
              action: UserAction.view,
              currentUserRole: UserRole.customer,
              child: const Text('View Products'),
            ),
            
            const SizedBox(height: 8),
            
            // This should be disabled for customer
            PermissionButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This should not appear')),
              ),
              screen: 'products',
              action: UserAction.delete,
              currentUserRole: UserRole.customer,
              child: const Text('Delete Products'),
            ),
          ],
        ),
      ),
    );
  }
}
