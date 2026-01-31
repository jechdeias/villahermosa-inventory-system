/// User roles and permissions for the inventory system
enum UserRole {
  admin('admin'),
  warehouse('warehouse'),
  delivery('delivery'),
  customer('customer');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String role) => UserRole.values.firstWhere(
      (e) => e.value == role,
      orElse: () => UserRole.customer,
    );
}

/// Actions that can be performed on resources
enum UserAction {
  view('view'),
  create('create'),
  update('update'),
  delete('delete'),
  confirm('confirm'),
  pack('pack'),
  accept('accept'),
  start('start'),
  complete('complete'),
  cancel('cancel');

  const UserAction(this.value);
  final String value;

  static UserAction fromString(String action) => UserAction.values.firstWhere(
      (e) => e.value == action,
      orElse: () => UserAction.view,
    );
}

/// Resources that can be accessed
enum ResourceType {
  orders('orders'),
  products('products'),
  customers('customers'),
  deliveries('deliveries'),
  stockMovements('stock_movements'),
  dashboard('dashboard'),
  reports('reports');

  const ResourceType(this.value);
  final String value;

  static ResourceType fromString(String resource) => ResourceType.values.firstWhere(
      (e) => e.value == resource,
      orElse: () => ResourceType.orders,
    );
}

/// Role-based navigation configuration
class RoleBasedNavigation {
  static const Map<UserRole, List<String>> allowedScreens = {
    UserRole.admin: [
      'dashboard',
      'orders',
      'products',
      'customers',
      'deliveries',
      'warehouse',
      'reports',
    ],
    UserRole.warehouse: [
      'dashboard',
      'orders',
      'products',
      'customers',
      'stock_movements',
    ],
    UserRole.delivery: [
      'dashboard',
      'deliveries',
      'orders',
    ],
    UserRole.customer: [
      'dashboard',
      'orders',
      'products',
      'profile',
    ],
  };

  static const Map<UserRole, Map<String, List<UserAction>>> screenPermissions = {
    UserRole.admin: {
      'dashboard': [UserAction.view],
      'orders': [UserAction.view, UserAction.create, UserAction.update, UserAction.delete],
      'products': [UserAction.view, UserAction.create, UserAction.update, UserAction.delete],
      'customers': [UserAction.view, UserAction.create, UserAction.update, UserAction.delete],
      'deliveries': [UserAction.view, UserAction.create, UserAction.update, UserAction.delete],
      'warehouse': [UserAction.view, UserAction.create, UserAction.update],
      'reports': [UserAction.view],
    },
    UserRole.warehouse: {
      'dashboard': [UserAction.view],
      'orders': [UserAction.view, UserAction.confirm, UserAction.pack, UserAction.update],
      'products': [UserAction.view, UserAction.create, UserAction.update],
      'customers': [UserAction.view, UserAction.create, UserAction.update],
      'stock_movements': [UserAction.view, UserAction.create],
    },
    UserRole.delivery: {
      'dashboard': [UserAction.view],
      'deliveries': [UserAction.view, UserAction.accept, UserAction.start, UserAction.complete],
      'orders': [UserAction.view],
    },
    UserRole.customer: {
      'dashboard': [UserAction.view],
      'orders': [UserAction.view, UserAction.create, UserAction.update, UserAction.cancel],
      'products': [UserAction.view],
      'profile': [UserAction.view, UserAction.update],
    },
  };
}
