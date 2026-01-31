# Role-Based UI Gating Documentation

## Overview

This document explains the role-based UI gating system implemented in the Villahermosa Inventory System. This system enforces access control at the UI level, complementing the existing backend Row Level Security (RLS).

## Architecture

### Core Components

1. **User Roles** (`lib/core/constants/user_roles.dart`)
   - `UserRole` enum: Defines user roles (admin, warehouse, delivery, customer)
   - `UserAction` enum: Defines possible actions (view, create, update, delete, etc.)
   - `ResourceType` enum: Defines system resources (orders, products, customers, etc.)
   - `RoleBasedNavigation` class: Maps roles to allowed screens and permissions

2. **UI Widgets** (`lib/core/widgets/role_based_widgets.dart`)
   - `RoleGuard`: Shows/hides content based on user roles
   - `PermissionGuard`: Shows/hides content based on specific permissions
   - `PermissionButton`: Button that's enabled/disabled based on permissions
   - `PermissionListTile`: ListTile that's shown/hidden based on permissions

3. **Navigation Service** (`lib/core/navigation/role_based_navigation.dart`)
   - `RoleBasedNavigationService`: Manages current user role and permissions
   - `RoleBasedNavigationRail`: Navigation rail filtered by role
   - `RoleBasedBottomNavigationBar`: Bottom navigation filtered by role
   - `RouteGuard`: Protects routes based on user permissions

## Role Definitions

### Admin
- **Access**: Full system access
- **Screens**: dashboard, orders, products, customers, deliveries, warehouse, reports
- **Permissions**: All actions on all resources
- **Use Case**: System administrators, owners

### Warehouse
- **Access**: Inventory and order management
- **Screens**: dashboard, orders, products, customers, stock_movements
- **Permissions**: 
  - Orders: view, confirm, pack, update
  - Products: view, create, update
  - Customers: view, create, update
  - Stock Movements: view, create
- **Use Case**: Warehouse staff, inventory managers

### Delivery
- **Access**: Delivery operations only
- **Screens**: dashboard, deliveries, orders
- **Permissions**:
  - Deliveries: view, accept, start, complete, update (own only)
  - Orders: view (assigned only)
  - Products: view
  - Customers: view
- **Use Case**: Delivery personnel, drivers

### Customer
- **Access**: Limited to own data and order creation
- **Screens**: dashboard, orders, products, profile
- **Permissions**:
  - Orders: view (own), create, update (own pending), cancel (own pending)
  - Products: view
  - Customers: view/update (own profile only)
- **Use Case**: Customers, store owners

## Implementation Examples

### 1. Basic Role Guard
```dart
RoleGuard(
  allowedRoles: [UserRole.admin, UserRole.warehouse],
  currentUserRole: _currentUserRole,
  child: ElevatedButton(
    onPressed: _createProduct,
    child: Text('Add Product'),
  ),
  fallback: Text('Permission denied'),
)
```

### 2. Permission-Based Button
```dart
PermissionButton(
  onPressed: _updateProduct,
  screen: 'products',
  action: UserAction.update,
  currentUserRole: _currentUserRole,
  child: Text('Update Product'),
)
```

### 3. Role-Based Navigation
```dart
RoleBasedBottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: _onTabTapped,
  userRole: _currentUserRole,
)
```

### 4. Conditional Content Display
```dart
// Show cost price only to admin and warehouse
RoleGuard(
  allowedRoles: [UserRole.admin, UserRole.warehouse],
  currentUserRole: _currentUserRole,
  child: Text('Cost Price: ₱${product.costPrice}'),
)

// Show profit margin only to admin
RoleGuard(
  allowedRoles: [UserRole.admin],
  currentUserRole: _currentUserRole,
  child: Text('Profit: ${product.unitPrice - product.costPrice}'),
)
```

## Security Benefits

### Defense in Depth
- **Backend RLS**: Prevents unauthorized data access at database level
- **UI Gating**: Prevents unauthorized actions at interface level
- **Double Protection**: Even if UI is bypassed, backend RLS still protects data

### User Experience
- **Clean Interface**: Users only see relevant options and data
- **Reduced Confusion**: No disabled buttons for actions users can't perform
- **Role Clarity**: Clear visual indication of what each role can do

### Common Questions

**Q: What prevents a delivery person from editing inventory?**
**A: Both RLS and UI-level role gating. The UI won't show inventory edit options to delivery personnel, and the backend RLS will reject any unauthorized requests.

**Q: Can users bypass UI restrictions?**
**A: Even if someone bypasses the UI, the backend RLS will prevent unauthorized data access and modifications.

**Q: How are roles determined?**
**A: Roles are set during authentication and stored in the navigation service. In production, this would come from your auth system.

## Testing the System

### Demo Screen
Run the `RoleBasedUIDemoScreen` to test different roles:
1. Switch between roles using the dropdown menu
2. Observe how navigation options change
3. Test permission-based buttons
4. View role-specific content sections

### Manual Testing
1. **Admin Role**: Should see all options and data
2. **Warehouse Role**: Should see inventory management but not financial data
3. **Delivery Role**: Should only see delivery-related options
4. **Customer Role**: Should only see own orders and product catalog

## Integration Guide

### Adding New Screens
1. Add screen to `RoleBasedNavigation.allowedScreens` for appropriate roles
2. Define permissions in `RoleBasedNavigation.screenPermissions`
3. Use role guards in the screen's UI

### Adding New Permissions
1. Add action to `UserAction` enum if needed
2. Update `RoleBasedNavigation.screenPermissions`
3. Use `PermissionButton` or `PermissionGuard` in UI

### Best Practices
1. **Default to Deny**: Only grant permissions when explicitly needed
2. **Principle of Least Privilege**: Give users minimum access required
3. **Consistent Patterns**: Use the same role-checking patterns throughout
4. **Test All Roles**: Verify each role sees only appropriate content

## File Structure
```
lib/core/
├── constants/
│   └── user_roles.dart              # Role definitions and permissions
├── widgets/
│   └── role_based_widgets.dart      # UI components for role gating
└── navigation/
    └── role_based_navigation.dart    # Navigation and route guards

lib/features/
├── demo/
│   └── role_based_ui_demo_screen.dart  # Demo and testing screen
├── dashboard/
│   └── dashboard_screen.dart       # Example implementation
└── inventory/
    └── product_list_screen_mock.dart  # Example implementation
```

## Conclusion

The role-based UI gating system provides a robust second layer of security that complements backend RLS. It ensures users can only perform actions they're authorized to do, creating a secure and user-friendly interface.
