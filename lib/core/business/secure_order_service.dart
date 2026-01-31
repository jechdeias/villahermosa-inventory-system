import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../sync/sync_manager.dart';
import 'order_workflow.dart';
import 'role_based_access.dart';

/// Secure Order Service - Combines workflow with role-based access
/// Ensures only authorized users can perform specific actions
class SecureOrderService {
  final AppDatabase _database;
  final SyncManager _syncManager;
  final RoleBasedAccess _rbac;
  final OrderWorkflow _workflow;
  
  SecureOrderService(this._database, this._syncManager, this._rbac, this._workflow);
  
  static SecureOrderService? _instance;
  static SecureOrderService get instance => _instance ??= SecureOrderService._();
  
  SecureOrderService._() 
    : _database = AppDatabase(),
      _syncManager = SyncManager.instance,
      _rbac = RoleBasedAccess.instance,
      _workflow = OrderWorkflow.instance;
  
  /// CUSTOMER: Create Order (with permission check)
  Future<Order> createOrderAsCustomer({
    required int customerId,
    required List<OrderItemData> items,
    required String deliveryAddress,
    String? customerNotes,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: customerId,
      action: 'create',
      resource: 'orders',
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Customer cannot create orders',
        userId: customerId,
        action: 'create',
        resource: 'orders',
      );
    }
    
    // Validate customer role
    final customer = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(customerId)],
    ).getSingleOrNull();
    
    if (customer == null || customer.data['role'] != 'customer') {
      throw Exception('Only customers can create orders');
    }
    
    return await _workflow.createOrder(
      customerId: customerId,
      items: items,
      deliveryAddress: deliveryAddress,
      customerNotes: customerNotes,
    );
  }
  
  /// WAREHOUSE: Confirm Order Availability (with permission check)
  Future<void> confirmOrderAvailabilityAsWarehouse({
    required int orderId,
    required int warehouseUserId,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: warehouseUserId,
      action: 'confirm',
      resource: 'orders',
      resourceId: orderId.toString(),
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Warehouse staff cannot confirm orders',
        userId: warehouseUserId,
        action: 'confirm',
        resource: 'orders',
      );
    }
    
    // Validate warehouse role
    final warehouseUser = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(warehouseUserId)],
    ).getSingleOrNull();
    
    if (warehouseUser == null || warehouseUser.data['role'] != 'warehouse') {
      throw Exception('Only warehouse staff can confirm orders');
    }
    
    await _workflow.confirmOrderAvailability(
      orderId: orderId,
      warehouseUserId: warehouseUserId,
    );
  }
  
  /// WAREHOUSE: Pack Order (with permission check)
  Future<void> packOrderAsWarehouse({
    required int orderId,
    required int packerUserId,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: packerUserId,
      action: 'pack',
      resource: 'orders',
      resourceId: orderId.toString(),
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Warehouse staff cannot pack orders',
        userId: packerUserId,
        action: 'pack',
        resource: 'orders',
      );
    }
    
    // Validate warehouse role
    final warehouseUser = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(packerUserId)],
    ).getSingleOrNull();
    
    if (warehouseUser == null || warehouseUser.data['role'] != 'warehouse') {
      throw Exception('Only warehouse staff can pack orders');
    }
    
    await _workflow.packOrder(
      orderId: orderId,
      packerUserId: packerUserId,
    );
  }
  
  /// DELIVERY: Accept Delivery (with permission check)
  Future<void> acceptDeliveryAsDelivery({
    required int orderId,
    required int deliveryPersonnelId,
    required String deliveryPersonnelName,
    required String deliveryPersonnelPhone,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: deliveryPersonnelId,
      action: 'accept',
      resource: 'deliveries',
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Delivery personnel cannot accept deliveries',
        userId: deliveryPersonnelId,
        action: 'accept',
        resource: 'deliveries',
      );
    }
    
    // Validate delivery role
    final deliveryUser = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(deliveryPersonnelId)],
    ).getSingleOrNull();
    
    if (deliveryUser == null || deliveryUser.data['role'] != 'delivery') {
      throw Exception('Only delivery personnel can accept deliveries');
    }
    
    await _workflow.acceptDelivery(
      orderId: orderId,
      deliveryPersonnelId: deliveryPersonnelId,
      deliveryPersonnelName: deliveryPersonnelName,
      deliveryPersonnelPhone: deliveryPersonnelPhone,
    );
  }
  
  /// DELIVERY: Start Delivery (with permission check)
  Future<void> startDeliveryAsDelivery({
    required int deliveryId,
    required int deliveryPersonnelId,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: deliveryPersonnelId,
      action: 'start',
      resource: 'deliveries',
      resourceId: deliveryId.toString(),
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Delivery personnel cannot start deliveries',
        userId: deliveryPersonnelId,
        action: 'start',
        resource: 'deliveries',
      );
    }
    
    // Validate delivery role
    final deliveryUser = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(deliveryPersonnelId)],
    ).getSingleOrNull();
    
    if (deliveryUser == null || deliveryUser.data['role'] != 'delivery') {
      throw Exception('Only delivery personnel can start deliveries');
    }
    
    await _workflow.startDelivery(deliveryId: deliveryId);
  }
  
  /// DELIVERY: Confirm Delivery (CRITICAL - Stock Deduction Point)
  Future<void> confirmDeliveryAsDelivery({
    required int deliveryId,
    required int deliveryPersonnelId,
    required String recipientName,
    required String recipientRelation,
    String? deliveryNotes,
    double? collectedAmount,
    String? paymentMethod,
    String? proofOfDeliveryUrl,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: deliveryPersonnelId,
      action: 'complete',
      resource: 'deliveries',
      resourceId: deliveryId.toString(),
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Delivery personnel cannot complete deliveries',
        userId: deliveryPersonnelId,
        action: 'complete',
        resource: 'deliveries',
      );
    }
    
    // Validate delivery role
    final deliveryUser = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(deliveryPersonnelId)],
    ).getSingleOrNull();
    
    if (deliveryUser == null || deliveryUser.data['role'] != 'delivery') {
      throw Exception('Only delivery personnel can complete deliveries');
    }
    
    await _workflow.confirmDelivery(
      deliveryId: deliveryId,
      recipientName: recipientName,
      recipientRelation: recipientRelation,
      deliveryNotes: deliveryNotes,
      collectedAmount: collectedAmount,
      paymentMethod: paymentMethod,
      proofOfDeliveryUrl: proofOfDeliveryUrl,
    );
  }
  
  /// Get orders accessible to user (role-based filtering)
  Future<List<Map<String, dynamic>>> getAccessibleOrders(int userId) async {
    final user = await _database.customSelect(
      'SELECT role FROM users WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(userId)],
    ).getSingleOrNull();
    
    if (user == null) {
      return [];
    }
    
    final role = user.data['role'] as String;
    
    switch (role) {
      case 'admin':
        // Admin can see all orders
        return await _database.customSelect('''
          SELECT 
            o.*,
            c.name as customer_name,
            c.email as customer_email,
            COUNT(oi.id) as item_count,
            SUM(oi.total_amount) as total_amount
          FROM orders o
          LEFT JOIN customers c ON o.customer_id = c.id
          LEFT JOIN order_items oi ON o.id = oi.order_id
          WHERE o.is_deleted = 0
          GROUP BY o.id
          ORDER BY o.created_at DESC
        ''').get().then((rows) => rows.map((row) => row.data).toList());
        
      case 'warehouse':
        // Warehouse can see all orders
        return await _database.customSelect('''
          SELECT 
            o.*,
            c.name as customer_name,
            c.email as customer_email,
            COUNT(oi.id) as item_count,
            SUM(oi.total_amount) as total_amount
          FROM orders o
          LEFT JOIN customers c ON o.customer_id = c.id
          LEFT JOIN order_items oi ON o.id = oi.order_id
          WHERE o.is_deleted = 0
          GROUP BY o.id
          ORDER BY o.created_at DESC
        ''').get().then((rows) => rows.map((row) => row.data).toList());
        
      case 'delivery':
        // Delivery can see orders assigned to them
        return await _database.customSelect('''
          SELECT 
            o.*,
            c.name as customer_name,
            c.email as customer_email,
            d.delivery_number,
            d.status as delivery_status,
            COUNT(oi.id) as item_count,
            SUM(oi.total_amount) as total_amount
          FROM orders o
          LEFT JOIN customers c ON o.customer_id = c.id
          LEFT JOIN deliveries d ON o.id = d.order_id
          LEFT JOIN order_items oi ON o.id = oi.order_id
          WHERE d.delivery_personnel_id = ? AND o.is_deleted = 0
          GROUP BY o.id
          ORDER BY o.created_at DESC
        ''', variables: [Variable.withInt(userId)]).get().then((rows) => rows.map((row) => row.data).toList());
        
      case 'customer':
        // Customer can see own orders
        return await _database.customSelect('''
          SELECT 
            o.*,
            COUNT(oi.id) as item_count,
            SUM(oi.total_amount) as total_amount
          FROM orders o
          LEFT JOIN order_items oi ON o.id = oi.order_id
          WHERE o.customer_id = ? AND o.is_deleted = 0
          GROUP BY o.id
          ORDER BY o.created_at DESC
        ''', variables: [Variable.withInt(userId)]).get().then((rows) => rows.map((row) => row.data).toList());
        
      default:
        return [];
    }
  }
  
  /// Get pending orders for warehouse staff
  Future<List<Map<String, dynamic>>> getPendingOrdersForWarehouse(int userId) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: userId,
      action: 'view',
      resource: 'orders',
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Cannot view pending orders',
        userId: userId,
        action: 'view',
        resource: 'orders',
      );
    }
    
    return await _database.customSelect('''
      SELECT 
        o.*,
        c.name as customer_name,
        c.email as customer_email,
        c.phone as customer_phone,
        COUNT(oi.id) as item_count,
        SUM(oi.total_amount) as total_amount
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.status = 'pending' AND o.is_deleted = 0
      GROUP BY o.id
      ORDER BY o.created_at ASC
    ''').get().then((rows) => rows.map((row) => row.data).toList());
  }
  
  /// Get orders ready for delivery
  Future<List<Map<String, dynamic>>> getOrdersReadyForDelivery(int userId) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: userId,
      action: 'view',
      resource: 'deliveries',
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Cannot view orders ready for delivery',
        userId: userId,
        action: 'view',
        resource: 'deliveries',
      );
    }
    
    return await _database.customSelect('''
      SELECT 
        o.*,
        c.name as customer_name,
        c.phone as customer_phone,
        o.delivery_address,
        COUNT(oi.id) as item_count,
        SUM(oi.total_amount) as total_amount
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.status = 'packed' AND o.is_deleted = 0
      GROUP BY o.id
      ORDER BY o.created_at ASC
    ''').get().then((rows) => rows.map((row) => row.data).toList());
  }
  
  /// Get active deliveries for delivery personnel
  Future<List<Map<String, dynamic>>> getActiveDeliveriesForDelivery(int userId) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: userId,
      action: 'view',
      resource: 'deliveries',
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Cannot view active deliveries',
        userId: userId,
        action: 'view',
        resource: 'deliveries',
      );
    }
    
    return await _database.customSelect('''
      SELECT 
        d.*,
        o.order_number,
        o.total_amount,
        c.name as customer_name,
        c.phone as customer_phone,
        o.delivery_address,
        COUNT(oi.id) as item_count
      FROM deliveries d
      LEFT JOIN orders o ON d.order_id = o.id
      LEFT JOIN customers c ON o.customer_id = c.id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE d.delivery_personnel_id = ? 
        AND d.status IN ('assigned', 'in_progress') 
        AND d.is_deleted = 0
      GROUP BY d.id
      ORDER BY d.scheduled_date ASC
    ''', variables: [Variable.withInt(userId)]).get().then((rows) => rows.map((row) => row.data).toList());
  }
  
  /// Get order details with permission check
  Future<Map<String, dynamic>?> getOrderDetails(int userId, int orderId) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: userId,
      action: 'view',
      resource: 'orders',
      resourceId: orderId.toString(),
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Cannot view order details',
        userId: userId,
        action: 'view',
        resource: 'orders',
      );
    }
    
    final order = await _database.customSelect('''
      SELECT 
        o.*,
        c.name as customer_name,
        c.email as customer_email,
        c.phone as customer_phone,
        c.address as customer_address
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.id = ? AND o.is_deleted = 0
    ''', variables: [Variable.withInt(orderId)]).getSingleOrNull();
    
    if (order == null) return null;
    
    // Get order items
    final items = await _database.customSelect('''
      SELECT 
        oi.*,
        p.sku,
        p.unit as product_unit
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ? AND oi.is_deleted = 0
      ORDER BY oi.created_at ASC
    ''', variables: [Variable.withInt(orderId)]).get();
    
    final orderData = order.data;
    orderData['items'] = items.map((item) => item.data).toList();
    
    return orderData;
  }
  
  /// Cancel order (customer or admin only)
  Future<void> cancelOrder({
    required int userId,
    required int orderId,
    String? reason,
  }) async {
    // Check permission
    final checkPermission = await _rbac.checkPermission(
      userId: userId,
      action: 'cancel',
      resource: 'orders',
      resourceId: orderId.toString(),
    );
    
    if (!checkPermission) {
      throw PermissionDeniedException(
        'Cannot cancel order',
        userId: userId,
        action: 'cancel',
        resource: 'orders',
      );
    }
    
    // Check if order can be cancelled
    final order = await _database.customSelect(
      'SELECT status FROM orders WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(orderId)],
    ).getSingleOrNull();
    
    if (order == null) {
      throw Exception('Order not found');
    }
    
    final status = order.data['status'] as String;
    if (!['pending', 'confirmed'].contains(status)) {
      throw Exception('Order cannot be cancelled in current status: $status');
    }
    
    // Update order status
    await _database.customUpdate('UPDATE orders SET status = ?, internal_notes = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [Variable.withString('cancelled'), Variable.withString(reason ?? ''), Variable.withDateTime(DateTime.now()), Variable.withString('pending'), Variable.withInt(orderId)]);
    
    // Update order items status
    await _database.customUpdate('UPDATE order_items SET status = ?, updated_at = ?, sync_status = ? WHERE order_id = ?',
      variables: [Variable.withString('cancelled'), Variable.withDateTime(DateTime.now()), Variable.withString('pending'), Variable.withInt(orderId)]);
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
}
