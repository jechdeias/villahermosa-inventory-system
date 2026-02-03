/// App Routes
/// 
/// Defines all named routes for the application.
/// UI-only navigation with no business logic.
class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  
  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  
  // Customer Routes
  static const String customerDashboard = '/customer/dashboard';
  static const String customerProfile = '/customer/profile';
  
  // Delivery Routes
  static const String deliveryDashboard = '/delivery/dashboard';
  static const String deliveryRoute = '/delivery/route';
  
  // Warehouse Routes
  static const String warehouseDashboard = '/warehouse/dashboard';
  static const String warehouseInventory = '/warehouse/inventory';
  
  // Legacy Routes (do not extend)
  static const String customerForm = '/customers/form';
  static const String customerList = '/customers/list';
}
