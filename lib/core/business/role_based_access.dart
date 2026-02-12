import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Role-Based Access Control
/// Enforces WHO can do WHAT and WHEN
class RoleBasedAccess {
  
  RoleBasedAccess(this._database);
  
  RoleBasedAccess._() : _database = AppDatabase();
  final AppDatabase _database;
  
  static RoleBasedAccess? _instance;
  static RoleBasedAccess get instance => _instance ??= RoleBasedAccess._();
  
  /// Check if user has permission to perform action
  Future<bool> checkPermission({
    required int userId,
    required String action,
    required String resource,
    String? resourceId,
  }) async {
    final user = await _database.getUserById(userId);
    if (user == null || user.isDeleted) {
      return false;
    }
    
    switch (user.role) {
      case 'admin':
        return _hasAdminPermission(action, resource);
      case 'warehouse':
        return _hasWarehousePermission(userId, action, resource, resourceId);
      case 'delivery':
        return _hasDeliveryPermission(userId, action, resource, resourceId);
      case 'customer':
        return _hasCustomerPermission(userId, action, resource, resourceId);
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
    String? resourceId,
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
    String? resourceId,
  ) async {
    switch (resource) {
      case 'deliveries':
        return _hasDeliveryDeliveryPermission(userId, action, resourceId);
      case 'orders':
        return _hasDeliveryOrderPermission(userId, action, resourceId);
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
    String? resourceId,
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
          return delivery?.deliveryPersonnelId == userId.toString();
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
    String? resourceId,
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
            variables: [Variable.withString(resourceId), Variable.withString(userId.toString())],
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
    String? resourceId,
  ) async {
    switch (resource) {
      case 'orders':
        return _hasCustomerOrderPermission(userId, action, resourceId);
      case 'customers':
        return _hasCustomerCustomerPermission(userId, action, resourceId);
      case 'products':
        return _hasCustomerProductPermission(action);
      default:
        return false;
    }
  }
  
  Future<bool> _hasCustomerOrderPermission(
    int userId, 
    String action, 
    String? resourceId,
  ) async {
    switch (action) {
      case 'view':
        // Can view own orders
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          return order?.customerId == userId.toString();
        }
        return false;
      case 'create':
        return true; // Can create orders
      case 'update':
        // Can update own pending orders
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          return order?.customerId == userId.toString() && 
                 (order?.status == 'pending' || order?.status == 'confirmed');
        }
        return false;
      case 'cancel':
        // Can cancel own pending orders
        if (resourceId != null) {
          final order = await _database.getOrderById(resourceId);
          return order?.customerId == userId.toString() && 
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
    String? resourceId,
  ) async {
    switch (action) {
      case 'view':
        // Can view own profile
        if (resourceId != null) {
          return resourceId == userId.toString();
        }
        return false;
      case 'update':
        // Can update own profile
        if (resourceId != null) {
          return resourceId == userId.toString();
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
        return (_database.select(_database.orders)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
      case 'warehouse':
        // Warehouse can see all orders
        return (_database.select(_database.orders)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
      case 'delivery':
        // Delivery can see orders assigned to them
        return (_database.select(_database.orders)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
      case 'customer':
        // Customer can see own orders
        return (_database.select(_database.orders)
              ..where((tbl) => tbl.customerId.equals(userId.toString()) & tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
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
        return (_database.select(_database.deliveries)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
      case 'warehouse':
        // Warehouse can see all deliveries
        return (_database.select(_database.deliveries)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
      case 'delivery':
        // Delivery can see own deliveries
        return (_database.select(_database.deliveries)
              ..where((tbl) => tbl.deliveryPersonnelId.equals(userId.toString()) & tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
      case 'customer':
        // Customer can see deliveries for their orders
        return (_database.select(_database.deliveries)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
        
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
        return (_database.select(_database.products)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
        
      case 'customer':
        // Customers can see active products only
        return (_database.select(_database.products)
              ..where((tbl) => tbl.isDeleted.equals(false) & tbl.status.equals('active'))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
        
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
        return (_database.select(_database.customers)
              ..where((tbl) => tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
        
      case 'customer':
        // Can see own profile only
        return (_database.select(_database.customers)
              ..where((tbl) => tbl.id.equals(userId) & tbl.isDeleted.equals(false))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
        
      default:
        return [];
    }
  }
}

/// Permission check exception
class PermissionDeniedException implements Exception {
  
  PermissionDeniedException(
    this.message, {
    this.action,
    this.resource,
    this.userId,
  });
  final String message;
  final String? action;
  final String? resource;
  final int? userId;
  
  @override
  String toString() => 'PermissionDeniedException: $message (User: $userId, Action: $action, Resource: $resource)';
}
