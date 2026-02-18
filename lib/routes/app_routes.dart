/// App Routes Configuration
/// Central route definitions for the Villahermosa Inventory System
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String signup = '/signup';
  
  // Dashboard routes
  static const String adminDashboard = '/admin/dashboard';
  static const String warehouseDashboard = '/warehouse/dashboard';
  static const String customerDashboard = '/customer/dashboard';
  static const String deliveryDashboard = '/delivery/dashboard';
  
  // Feature routes
  static const String users = '/admin/users';
  static const String inventory = '/warehouse/inventory';
  static const String orders = '/warehouse/orders';
  static const String deliveries = '/delivery/routes';
  static const String profile = '/customer/profile';
  static const String customerProfile = '/customer/profile';
  static const String deliveryRoute = '/delivery/route';
  
  // Prevent instantiation
  AppRoutes._();
}
