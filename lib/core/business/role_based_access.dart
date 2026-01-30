import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'order_workflow.dart';

/// Role-Based Access Control
/// Enforces WHO can do WHAT and WHEN
class RoleBasedAccess {
  final AppDatabase _database;
  
  RoleBasedAccess(this._database);
  
  static RoleBasedAccess? _instance;
  static RoleBasedAccess get instance => _instance ??= RoleBasedAccess._();
  
  RoleBasedAccess._() : _database = AppDatabase();
  
  /// Check if user has permission to perform action
  Future<bool> hasPermission({
    required int userId,
    required String action,
    required String resource,
    int? resourceId,
  }) async {
    final user = await _database.getUserById(userId);
    if (user == null || user.isDeleted) {
      return false;
    }
    
    switch (user.role) {
      case 'admin':
        return _hasAdminPermission(action, resource);
      case 'warehouse':
        return await _hasWarehousePermission(userId, action, resource, resourceId);
      case 'delivery':
        return await _hasDeliveryPermission(userId, action, resource, resourceId);
      case 'customer':
        return await _hasCustomerPermission(userId, action, resource, resourceId);
      default:
        return false;
    }
  }
  
  /// ADMIN: Full access to everything
  bool _hasAdminPermission(String action, String resource) {
    // Admin can do everything
    return true;
  }
  
  /// WAREHOUSE: Manage inventory and orders
  Future<bool> _hasWarehousePermission(
    int userId, 
    String action, 
    String resource, 
    int? resourceId,
  ) async {
    switch (resource) {
      case 'orders':
        return _hasWarehouseOrderPermission(action);
      case 'products':
        return _hasWarehouseProductPermission(action);
      case 'stock_movements':
        return _hasWarehouseStockMovementPermission(action);
      case 'customers':
        return _hasWarehouseCustomerPermission(action);
      default:
        return false;
    }
  }
  
  bool _hasWarehouseOrderPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view all orders
      case 'confirm':
        return true; // Can confirm order availability
      case 'pack':
        return true; // Can pack orders
      case 'update':
        return true; // Can update order status
      case 'create':
        return false; // Cannot create orders (customers only)
      case 'delete':
        return false; // Cannot delete orders
      default:
        return false;
    }
  }
  
  bool _hasWarehouseProductPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view all products
      case 'create':
        return true; // Can create products
      case 'update':
        return true; // Can update products
      case 'delete':
        return false; // Cannot delete products (soft delete only)
      default:
        return false;
    }
  }
  
  bool _hasWarehouseStockMovementPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view all stock movements
      case 'create':
        return true; // Can create stock movements (adjustments)
      case 'update':
        return false; // Cannot update stock movements (audit trail)
      case 'delete':
        return false; // Cannot delete stock movements
      default:
        return false;
    }
  }
  
  bool _hasWarehouseCustomerPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view all customers
      case 'create':
        return true; // Can create customers
      case 'update':
        return true; // Can update customers
      case 'delete':
        return false; // Cannot delete customers
      default:
        return false;
    }
  }
  
  /// DELIVERY: Manage deliveries only
  Future<bool> _hasDeliveryPermission(
    int userId, 
    String action, 
    String resource, 
    int? resourceId,
  ) async {
    switch (resource) {
      case 'deliveries':
        return await _hasDeliveryDeliveryPermission(userId, action, resourceId);
      case 'orders':
        return await _hasDeliveryOrderPermission(userId, action, resourceId);
      case 'products':
        return _hasDeliveryProductPermission(action);
      case 'customers':
        return _hasDeliveryCustomerPermission(action);
      default:
        return false;
    }
  }
  
  Future<bool> _hasDeliveryDeliveryPermission(
    int userId, 
    String action, 
    int? resourceId,
  ) async {
    switch (action) {
      case 'view':
        // Can view all deliveries
        return true;
      case 'accept':
        return true; // Can accept delivery assignments
      case 'start':
        return true; // Can start deliveries
      case 'complete':
        return true; // Can complete deliveries
      case 'update':
        // Can only update own deliveries
        if (resourceId != null) {
          final delivery = await _database.getDeliveryById(resourceId);
          return delivery?.deliveryPersonnelId == userId;
        }
        return false;
      case 'create':
        return false; // Cannot create deliveries
      case 'delete':
        return false; // Cannot delete deliveries
      default:
        return false;
    }
  }
  
  Future<bool> _hasDeliveryOrderPermission(
    int userId, 
    String action, 
    int? resourceId,
  ) async {
    switch (action) {
      case 'view':
        // Can view orders assigned to them
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          if (order == null) return false;
          
          // Check if order has delivery assigned to this user
          final deliveries = await _database.customSelect(
            'SELECT id FROM deliveries WHERE order_id = ? AND delivery_personnel_id = ?',
            [resourceId, userId],
          ).get();
          
          return deliveries.isNotEmpty;
        }
        return false;
      default:
        return false;
    }
  }
  
  bool _hasDeliveryProductPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view products (for delivery info)
      default:
        return false;
    }
  }
  
  bool _hasDeliveryCustomerPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view customers (for delivery info)
      default:
        return false;
    }
  }
  
  /// CUSTOMER: Limited to own data and order creation
  Future<bool> _hasCustomerPermission(
    int userId, 
    String action, 
    String resource, 
    int? resourceId,
  ) async {
    switch (resource) {
      case 'orders':
        return await _hasCustomerOrderPermission(userId, action, resourceId);
      case 'customers':
        return await _hasCustomerCustomerPermission(userId, action, resourceId);
      case 'products':
        return _hasCustomerProductPermission(action);
      default:
        return false;
    }
  }
  
  Future<bool> _hasCustomerOrderPermission(
    int userId, 
    String action, 
    int? resourceId,
  ) async {
    switch (action) {
      case 'view':
        // Can view own orders
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          return order?.customerId == userId;
        }
        return false;
      case 'create':
        return true; // Can create orders
      case 'update':
        // Can update own pending orders
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          return order?.customerId == userId && 
                 (order?.status == 'pending' || order?.status == 'confirmed');
        }
        return false;
      case 'cancel':
        // Can cancel own pending orders
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          return order?.customerId == userId && 
                 (order?.status == 'pending' || order?.status == 'confirmed');
        }
        return false;
      default:
        return false;
    }
  }
  
  Future<bool> _hasCustomerCustomerPermission(
    int userId, 
    String action, 
    int? resourceId,
  ) async {
    switch (action) {
      case 'view':
        // Can view own profile
        if (resourceId != null) {
          return resourceId == userId;
        }
        return false;
      case 'update':
        // Can update own profile
        if (resourceId != null) {
          return resourceId == userId;
        }
        return false;
      default:
        return false;
    }
  }
  
  bool _hasCustomerProductPermission(String action) {
    switch (action) {
      case 'view':
        return true; // Can view products
      default:
        return false;
    }
  }
  
  /// Get filtered data based on user role
  Future<List<Order>> getFilteredOrders(int userId) async {
    final user = await _database.getUserById(userId);
    if (user == null || user.isDeleted) {
      return [];
    }
    
    switch (user.role) {
      case 'admin':
        // Admin can see all orders
        return await _database.customSelect(
          'SELECT * FROM orders WHERE is_deleted = 0 ORDER BY created_at DESC',
        ).map((row) => Order.fromData(row.data, _database)).get();
        
      case 'warehouse':
        // Warehouse can see all orders
        return await _database.customSelect(
          'SELECT * FROM orders WHERE is_deleted = 0 ORDER BY created_at DESC',
        ).map((row) => Order.fromData(row.data, _database)).get();
        
      case 'delivery':
        // Delivery can see orders assigned to them
        return await _database.customSelect('''
          SELECT o.* FROM orders o
          INNER JOIN deliveries d ON o.id = d.order_id
          WHERE d.delivery_personnel_id = ? AND o.is_deleted = 0
          ORDER BY o.created_at DESC
        ''', [userId]).map((row) => Order.fromData(row.data, _database)).get();
        
      case 'customer':
        // Customer can see own orders
        return await _database.customSelect(
          'SELECT * FROM orders WHERE customer_id = ? AND is_deleted = 0 ORDER BY created_at DESC',
          [userId],
        ).map((row) => Order.fromData(row.data, _database)).get();
        
      default:
        return [];
    }
  }
  
  Future<List<Delivery>> getFilteredDeliveries(int userId) async {
    final user = await _database.getUserById(userId);
    if (user == null || user.isDeleted) {
      return [];
    }
    
    switch (user.role) {
      case 'admin':
        // Admin can see all deliveries
        return await _database.customSelect(
          'SELECT * FROM deliveries WHERE is_deleted = 0 ORDER BY created_at DESC',
        ).map((row) => Delivery.fromData(row.data, _database)).get();
        
      case 'warehouse':
        // Warehouse can see all deliveries
        return await _database.customSelect(
          'SELECT * FROM deliveries WHERE is_deleted = 0 ORDER BY created_at DESC',
        ).map((row) => Delivery.fromData(row.data, _database)).get();
        
      case 'delivery':
        // Delivery can see own deliveries
        return await _database.customSelect(
          'SELECT * FROM deliveries WHERE delivery_personnel_id = ? AND is_deleted = 0 ORDER BY created_at DESC',
          [userId],
        ).map((row) => Delivery.fromData(row.data, _database)).get();
        
      case 'customer':
        // Customer can see deliveries for their orders
        return await _database.customSelect('''
          SELECT d.* FROM deliveries d
          INNER JOIN orders o ON d.order_id = o.id
          WHERE o.customer_id = ? AND d.is_deleted = 0
          ORDER BY d.created_at DESC
        ''', [userId]).map((row) => Delivery.fromData(row.data, _database)).get();
        
      default:
        return [];
    }
  }
  
  Future<List<Product>> getFilteredProducts(int userId) async {
    final user = await _database.getUserById(userId);
    if (user == null || user.isDeleted) {
      return [];
    }
    
    switch (user.role) {
      case 'admin':
      case 'warehouse':
      case 'delivery':
        // Can see all products
        return await _database.customSelect(
          'SELECT * FROM products WHERE is_deleted = 0 ORDER BY name ASC',
        ).map((row) => Product.fromData(row.data, _database)).get();
        
      case 'customer':
        // Customers can see active products only
        return await _database.customSelect(
          'SELECT * FROM products WHERE is_deleted = 0 AND status = ? ORDER BY name ASC',
          ['active'],
        ).map((row) => Product.fromData(row.data, _database)).get();
        
      default:
        return [];
    }
  }
  
  Future<List<Customer>> getFilteredCustomers(int userId) async {
    final user = await _database.getUserById(userId);
    if (user == null || user.isDeleted) {
      return [];
    }
    
    switch (user.role) {
      case 'admin':
      case 'warehouse':
      case 'delivery':
        // Can see all customers
        return await _database.customSelect(
          'SELECT * FROM customers WHERE is_deleted = 0 ORDER BY name ASC',
        ).map((row) => Customer.fromData(row.data, _database)).get();
        
      case 'customer':
        // Can see own profile only
        return await _database.customSelect(
          'SELECT * FROM customers WHERE id = ? AND is_deleted = 0',
          [userId],
        ).map((row) => Customer.fromData(row.data, _database)).get();
        
      default:
        return [];
    }
  }
}

/// Permission check exception
class PermissionDeniedException implements Exception {
  final String message;
  final String? action;
  final String? resource;
  final int? userId;
  
  PermissionDeniedException(
    this.message, {
    this.action,
    this.resource,
    this.userId,
  });
  
  @override
  String toString() {
    return 'PermissionDeniedException: $message (User: $userId, Action: $action, Resource: $resource)';
  }
}
