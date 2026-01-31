import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../sync/sync_manager.dart';
import 'stock_movement_service.dart';

/// Updated Order Workflow - Uses proper Stock Movement Logic
/// Stock quantity = SUM(StockMovements), not a magic number
class OrderWorkflowUpdated {
  
  OrderWorkflowUpdated(this._database, this._syncManager, this._stockService);
  
  OrderWorkflowUpdated._() 
    : _database = AppDatabase(), 
      _syncManager = SyncManager.instance,
      _stockService = StockMovementService.instance;
  final AppDatabase _database;
  final SyncManager _syncManager;
  final StockMovementService _stockService;
  
  static OrderWorkflowUpdated? _instance;
  static OrderWorkflowUpdated get instance => _instance ??= OrderWorkflowUpdated._();
  
  /// DELIVERY: Confirm Delivery (CRITICAL - Stock Deduction Point)
  /// Now uses proper Stock Movement Service
  Future<void> confirmDeliveryWithStockMovement({
    required int deliveryId,
    required String recipientName,
    required String recipientRelation,
    String? deliveryNotes,
    double? collectedAmount,
    String? paymentMethod,
    String? proofOfDeliveryUrl,
  }) async {
    print('✅ Confirming delivery with proper stock movement logic...');
    
    final delivery = await _database.customSelect(
      'SELECT * FROM deliveries WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(deliveryId)],
    ).getSingleOrNull();
    
    if (delivery == null) {
      throw Exception('Delivery not found');
    }
    
    final deliveryData = delivery.data;
    if (deliveryData['status'] != 'in_progress') {
      throw Exception('Delivery is not in progress');
    }
    
    final order = await _database.customSelect(
      'SELECT * FROM orders WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(deliveryData['order_id'])],
    ).getSingleOrNull();
    
    if (order == null) {
      throw Exception('Order not found');
    }
    
    final orderData = order.data;
    final orderItems = await _database.customSelect(
      'SELECT * FROM order_items WHERE order_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(deliveryData['order_id'])],
    ).get();
    
    // CRITICAL: Record stock movements for all delivered items
    for (final item in orderItems) {
      final itemData = item.data;
      
      // Record STOCK OUT movement using the proper service
      await _stockService.recordStockOut(
        productId: itemData['product_id'] as int,
        quantity: itemData['quantity'] as int,
        userId: deliveryData['delivery_personnel_id'] as int,
        userName: deliveryData['delivery_personnel_name'] as String,
        orderId: deliveryData['order_id'].toString(),
        orderNumber: orderData['order_number'] as String,
        notes: 'Delivered to ${deliveryData['end_location']}',
        unitCost: itemData['unit_price'] as double?,
        fromLocation: 'Warehouse',
        toLocation: deliveryData['end_location'] as String,
      );
      
      // Update order item delivered quantity
      await _database.customUpdate(
        'UPDATE order_items SET delivered_quantity = ?, status = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(itemData['quantity']),
          Variable.withString('delivered'),
          Variable.withString(DateTime.now().toIso8601String()),
          Variable.withInt(itemData['id']),
        ],
      );
    }
    
    // Update delivery status to COMPLETED
    await _database.customUpdate(
      '''UPDATE deliveries SET 
         status = ?, 
         actual_completion_time = ?, 
         recipient_name = ?, 
         recipient_relation = ?, 
         delivery_notes = ?, 
         collected_amount = ?, 
         payment_method = ?, 
         proof_of_delivery_url = ?,
         updated_at = ?,
         sync_status = ?
         WHERE id = ?''',
      variables: [
        Variable.withString('completed'),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString(recipientName),
        Variable.withString(recipientRelation),
        Variable.withString(deliveryNotes ?? ''),
        Variable.withReal(collectedAmount ?? 0.0),
        Variable.withString(paymentMethod ?? ''),
        Variable.withString(proofOfDeliveryUrl ?? ''),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('pending'),
        Variable.withInt(deliveryId),
      ],
    );
    
    // Update order status to DELIVERED
    await _database.customUpdate(
      '''UPDATE orders SET 
         status = ?, 
         actual_delivery_date = ?, 
         payment_status = ?,
         updated_at = ?,
         sync_status = ?
         WHERE id = ?''',
      variables: [
        Variable.withString('delivered'),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString(collectedAmount != null && collectedAmount > 0 ? 'paid' : 'pending'),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('pending'),
        Variable.withInt(deliveryData['order_id']),
      ],
    );
    
    print('Delivery confirmed with proper stock movements recorded');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// CANCEL ORDER: Return stock to inventory
  Future<void> cancelOrderWithStockReturn({
    required int orderId,
    required int userId,
    required String userName,
    String? reason,
  }) async {
    print('🔄 Cancelling order and returning stock to inventory...');
    
    final order = await _database.customSelect(
      'SELECT * FROM orders WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(orderId)],
    ).getSingleOrNull();
    
    if (order == null) {
      throw Exception('Order not found');
    }
    
    final orderData = order.data;
    final status = orderData['status'] as String;
    
    // Only allow cancellation of pending or confirmed orders
    if (!['pending', 'confirmed'].contains(status)) {
      throw Exception('Order cannot be cancelled in current status: $status');
    }
    
    final orderItems = await _database.customSelect(
      'SELECT * FROM order_items WHERE order_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(orderId)],
    ).get();
    
    // Return stock for all items
    for (final item in orderItems) {
      final itemData = item.data;
      
      // Record RETURN movement using the proper service
      await _stockService.recordStockReturn(
        productId: itemData['product_id'] as int,
        quantity: itemData['quantity'] as int,
        userId: userId,
        userName: userName,
        orderId: orderId.toString(),
        orderNumber: orderData['order_number'] as String,
        returnReason: ReturnReason.cancelled_order,
        notes: reason,
        unitCost: itemData['unit_price'] as double?,
        fromLocation: 'Reserved',
        toLocation: 'Warehouse',
      );
      
      // Update order item status
      await _database.customUpdate(
        'UPDATE order_items SET status = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable.withString('cancelled'),
          Variable.withString(DateTime.now().toIso8601String()),
          Variable.withInt(itemData['id']),
        ],
      );
    }
    
    // Update order status
    await _database.customUpdate(
      '''UPDATE orders SET 
         status = ?, 
         internal_notes = ?,
         updated_at = ?,
         sync_status = ?
         WHERE id = ?''',
      variables: [
        Variable.withString('cancelled'),
        Variable.withString(reason ?? ''),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString('pending'),
        Variable.withInt(orderId),
      ],
    );
    
    print('✅ Order cancelled and stock returned to inventory');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// Get real-time stock for a product
  Future<int> getRealTimeStock(int productId) async => await _stockService.getCurrentStock(productId);
  
  /// Check if order can be fulfilled (stock availability)
  Future<bool> canFulfillOrder(int orderId) async {
    final orderItems = await _database.customSelect(
      'SELECT product_id, quantity FROM order_items WHERE order_id = ? AND is_deleted = 0',
      variables: [Variable.withInt(orderId)],
    ).get();
    
    for (final item in orderItems) {
      final itemData = item.data;
      final currentStock = await _stockService.getCurrentStock(itemData['product_id'] as int);
      
      if (currentStock < (itemData['quantity'] as int)) {
        return false; // Not enough stock
      }
    }
    
    return true; // All items available
  }
  
  /// Get stock availability report for order items
  Future<List<Map<String, dynamic>>> getOrderStockAvailability(int orderId) async => await _database.customSelect('''
      SELECT 
        oi.*,
        p.name as product_name,
        p.sku as product_sku,
        COALESCE(SUM(sm.quantity), 0) as current_stock,
        (oi.quantity - COALESCE(SUM(sm.quantity), 0)) as shortage,
        CASE 
          WHEN COALESCE(SUM(sm.quantity), 0) >= oi.quantity THEN 'AVAILABLE'
          ELSE 'INSUFFICIENT'
        END as availability_status
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      LEFT JOIN stock_movements sm ON p.id = sm.product_id AND sm.is_deleted = 0
      WHERE oi.order_id = ? AND oi.is_deleted = 0
      GROUP BY oi.id
      ORDER BY oi.created_at ASC
    ''', variables: [Variable.withInt(orderId)]).get().then((rows) => rows.map((row) => row.data).toList());
  
  /// Get inventory valuation
  Future<Map<String, dynamic>> getInventoryValuation() async {
    final result = await _database.customSelect('''
      SELECT 
        COUNT(DISTINCT p.id) as total_products,
        SUM(COALESCE(sm.quantity, 0)) as total_quantity,
        SUM(COALESCE(sm.quantity, 0) * p.cost_price) as total_cost_value,
        SUM(COALESCE(sm.quantity, 0) * p.unit_price) as total_retail_value,
        SUM(COALESCE(sm.quantity, 0) * (p.unit_price - p.cost_price)) as total_profit_value
      FROM products p
      LEFT JOIN stock_movements sm ON p.id = sm.product_id AND sm.is_deleted = 0
      WHERE p.is_deleted = 0 AND p.status = 'active'
      GROUP BY p.id
    ''').getSingleOrNull();
    
    return result?.data ?? {
      'total_products': 0,
      'total_quantity': 0,
      'total_cost_value': 0.0,
      'total_retail_value': 0.0,
      'total_profit_value': 0.0,
    };
  }
  
  /// Get stock movement summary by type
  Future<List<Map<String, dynamic>>> getStockMovementSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var whereClause = 'sm.is_deleted = 0';
    var variables = <Variable>[];
    
    if (startDate != null) {
      whereClause += ' AND sm.created_at >= ?';
      variables.add(Variable.withString(startDate.toIso8601String()));
    }
    
    if (endDate != null) {
      whereClause += ' AND sm.created_at <= ?';
      variables.add(Variable.withString(endDate.toIso8601String()));
    }
    
    return _database.customSelect('''
      SELECT 
        sm.movement_type,
        sm.reference_type,
        COUNT(*) as transaction_count,
        SUM(CASE WHEN sm.quantity > 0 THEN sm.quantity ELSE 0 END) as total_in,
        SUM(CASE WHEN sm.quantity < 0 THEN ABS(sm.quantity) ELSE 0 END) as total_out,
        SUM(sm.total_cost) as total_cost
      FROM stock_movements sm
      WHERE $whereClause
      GROUP BY sm.movement_type, sm.reference_type
      ORDER BY sm.movement_type, sm.reference_type
    ''', variables: variables).get().then((rows) => rows.map((row) => row.data).toList());
  }
  
  /// Utility method to generate UUID
  String _generateUuid() => DateTime.now().millisecondsSinceEpoch.toString();
}
