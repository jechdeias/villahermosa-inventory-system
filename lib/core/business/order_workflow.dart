import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../sync/sync_manager.dart';
import '../utils/type_validator.dart';

/// Order Workflow - Core Business Logic
/// Implements the complete order lifecycle with proper stock management
class OrderWorkflow {
  
  OrderWorkflow(this._database, this._syncManager);
  
  OrderWorkflow._() : _database = AppDatabase(), _syncManager = SyncManager.instance;
  final AppDatabase _database;
  final SyncManager _syncManager;
  
  static OrderWorkflow? _instance;
  static OrderWorkflow get instance => _instance ??= OrderWorkflow._();
  
  /// CUSTOMER: Create Order (offline OK)
  /// Stock is NOT deducted at this stage
  Future<Order> createOrder({
    required String customerId,
    required List<OrderItemData> items,
    required String deliveryAddress,
    String? customerNotes,
  }) async {
    print('🛒 Customer creating order...');
    
    // Validate input types
    final validatedCustomerId = TypeValidator.ensureUuid(customerId);
    
    // Validate customer exists and is active
    final customer = await _database.getCustomerById(validatedCustomerId);
    TypeValidator.ensureExists(customer, 'Customer', validatedCustomerId);
    
    if (customer!.isDeleted) {
      throw Exception('Customer is inactive');
    }
    
    // Calculate totals
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.totalAmount);
    final taxAmount = subtotal * 0.12; // 12% tax
    final totalAmount = subtotal + taxAmount;
    
    // Generate order number
    final orderNumber = _generateOrderNumber();
    
    // Create order in PENDING status
    final orderId = _generateUuid();
    await _database.into(_database.orders).insert(
      OrdersCompanion.insert(
        id: orderId,
        customerId: customerId,
        orderNumber: orderNumber,
        status: const Value('pending'),
        deliveryAddress: deliveryAddress,
        customerNotes: Value(customerNotes),
        subtotal: Value(subtotal),
        taxAmount: Value(taxAmount),
        totalAmount: Value(totalAmount),
        paymentStatus: const Value('pending'),
        warehouseStatus: const Value('pending'),
        priority: const Value('normal'),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    
    // Create order items with current product info snapshot
    for (final item in items) {
      // Validate product ID
      final validatedProductId = TypeValidator.ensureIntId(item.productId);
      final validatedQuantity = TypeValidator.validateStockQuantity(item.quantity);
      
      final product = await _database.getProductByIntId(validatedProductId);
      TypeValidator.ensureExists(product, 'Product', validatedProductId);
      
      if (product!.isDeleted) {
        throw Exception('Product $validatedProductId not found or inactive');
      }
      
      // Check availability (but don't reserve yet)
      if (product.currentStock < validatedQuantity) {
        throw Exception('Insufficient stock for ${product.name}. Available: ${product.currentStock}, Requested: $validatedQuantity');
      }
      
      await _database.into(_database.orderItems).insert(
        OrderItemsCompanion.insert(
          id: _generateUuid(),
          orderId: orderId,
          productId: validatedProductId.toString(),
          productSku: product.sku,
          productName: product.name,
          quantity: validatedQuantity,
          deliveredQuantity: const Value(0),
          unitPrice: item.unitPrice,
          subtotal: item.subtotal,
          discountAmount: Value(item.discountAmount),
          totalAmount: item.totalAmount,
          availableStock: product.currentStock,
          stockStatus: Value(product.currentStock >= validatedQuantity ? 'available' : 'backorder'),
          status: const Value('pending'),
          notes: Value(item.notes),
          syncStatus: const Value('pending'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    
    print('✅ Order created successfully: $orderNumber');
    
    // Trigger sync
    await _syncManager.performFullSync();
    
    return (await _database.getOrderById(orderId))!;
  }
  
  /// WAREHOUSE: Confirm Order and Reserve Stock
  Future<void> confirmOrderAvailability({
    required String orderId,
    required int warehouseUserId,
  }) async {
    print('📦 Warehouse confirming order availability...');
    
    // Validate order exists and is in PENDING status
    final order = await _database.getOrderById(orderId);
    if (order == null || order.isDeleted) {
      throw Exception('Order not found');
    }
    
    if (order.status != 'pending') {
      throw Exception('Order is not in pending status');
    }
    
    // Get all order items
    final orderItems = await _database.getOrderItemsByOrderId(orderId);
    
    // Check stock availability for all items
    for (final item in orderItems) {
      final product = await _database.getProductById(int.parse(item.productId));
      if (product == null || product.isDeleted) {
        throw Exception('Product ${item.productId} not found');
      }
      
      if (product.currentStock < item.quantity) {
        throw Exception('Insufficient stock for ${product.name}. Available: ${product.currentStock}, Requested: ${item.quantity}');
      }
    }
    
    // Reserve stock (update order status to CONFIRMED)
    await _database.customUpdate(
      'UPDATE orders SET status = ?, warehouse_status = ?, picker_id = ?, picked_at = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('confirmed'),
        Variable.withString('picking'),
        Variable.withString(warehouseUserId.toString()),
        Variable.withDateTime(DateTime.now()),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(orderId),
      ],
    );
    
    // Update order items status to PICKED
    for (final item in orderItems) {
      await _database.customUpdate(
        'UPDATE order_items SET status = ?, picker_id = ?, picked_at = ?, updated_at = ?, sync_status = ? WHERE id = ?',
        variables: [
          Variable.withString('picked'),
          Variable.withString(warehouseUserId.toString()),
          Variable.withDateTime(DateTime.now()),
          Variable.withDateTime(DateTime.now()),
          Variable.withString('pending'),
          Variable.withString(item.id),
        ],
      );
    }
    
    print('✅ Order availability confirmed and stock reserved');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// WAREHOUSE: Pack Order
  Future<void> packOrder({
    required String orderId,
    required int packerUserId,
  }) async {
    print('📦 Warehouse packing order...');
    
    final order = await _database.getOrderById(orderId);
    if (order == null || order.isDeleted) {
      throw Exception('Order not found');
    }
    
    if (order.status != 'confirmed') {
      throw Exception('Order is not confirmed');
    }
    
    // Update order status to PACKED
    await _database.customUpdate(
      'UPDATE orders SET status = ?, warehouse_status = ?, packer_id = ?, packed_at = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('packed'),
        Variable.withString('ready'),
        Variable.withString(packerUserId.toString()),
        Variable.withDateTime(DateTime.now()),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(orderId),
      ],
    );
    
    // Update order items status to PACKED
    final orderItems = await _database.getOrderItemsByOrderId(orderId);
    for (final item in orderItems) {
      await _database.customUpdate(
        'UPDATE order_items SET status = ?, updated_at = ?, sync_status = ? WHERE id = ?',
        variables: [
          Variable.withString('packed'),
          Variable.withDateTime(DateTime.now()),
          Variable.withString('pending'),
          Variable.withString(item.id),
        ],
      );
    }
    
    print('✅ Order packed successfully');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// DELIVERY: Accept Delivery Assignment
  Future<void> acceptDelivery({
    required String orderId,
    required int deliveryPersonnelId,
    required String deliveryPersonnelName,
    required String deliveryPersonnelPhone,
  }) async {
    print('🚚 Delivery personnel accepting order...');
    
    final order = await _database.getOrderById(orderId);
    if (order == null || order.isDeleted) {
      throw Exception('Order not found');
    }
    
    if (order.status != 'packed') {
      throw Exception('Order is not packed');
    }
    
    // Create delivery record
    final deliveryNumber = _generateDeliveryNumber();
    
    await _database.into(_database.deliveries).insert(
      DeliveriesCompanion.insert(
        id: _generateUuid(),
        orderId: orderId,
        deliveryPersonnelId: deliveryPersonnelId.toString(),
        deliveryPersonnelName: deliveryPersonnelName,
        deliveryPersonnelPhone: deliveryPersonnelPhone,
        deliveryNumber: deliveryNumber,
        scheduledDate: DateTime.now(),
        route: 'Standard Route',
        routeOrder: 1,
        startLocation: 'Warehouse',
        endLocation: order.deliveryAddress,
        status: const Value('assigned'),
        priority: Value(order.priority),
        attemptCount: const Value(0),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    
    // Update order status to DISPATCHED
    await _database.customUpdate(
      'UPDATE orders SET status = ?, warehouse_status = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('dispatched'),
        Variable.withString('shipped'),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(orderId),
      ],
    );
    
    print('✅ Delivery accepted successfully: $deliveryNumber');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// DELIVERY: Start Delivery
  Future<void> startDelivery({
    required String deliveryId,
  }) async {
    print('🚚 Starting delivery...');
    
    final delivery = await _database.getDeliveryById(deliveryId);
    if (delivery == null || delivery.isDeleted) {
      throw Exception('Delivery not found');
    }
    
    if (delivery.status != 'assigned') {
      throw Exception('Delivery is not assigned');
    }
    
    // Update delivery status to IN_PROGRESS
    await _database.customUpdate(
      'UPDATE deliveries SET status = ?, actual_start_time = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('in_progress'),
        Variable.withDateTime(DateTime.now()),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(deliveryId),
      ],
    );
    
    // Update order status to OUT_FOR_DELIVERY
    await _database.customUpdate(
      'UPDATE orders SET status = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('out_for_delivery'),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(delivery.orderId),
      ],
    );
    
    print('✅ Delivery started');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// DELIVERY: Confirm Delivery (CRITICAL - Stock Deduction Point)
  Future<void> confirmDelivery({
    required String deliveryId,
    required String recipientName,
    required String recipientRelation,
    String? deliveryNotes,
    double? collectedAmount,
    String? paymentMethod,
    String? proofOfDeliveryUrl,
  }) async {
    print('✅ Confirming delivery and deducting stock...');
    
    final delivery = await _database.getDeliveryById(deliveryId);
    if (delivery == null || delivery.isDeleted) {
      throw Exception('Delivery not found');
    }
    
    if (delivery.status != 'in_progress') {
      throw Exception('Delivery is not in progress');
    }
    
    final order = await _database.getOrderById(delivery.orderId);
    if (order == null || order.isDeleted) {
      throw Exception('Order not found');
    }
    
    final orderItems = await _database.getOrderItemsByOrderId(delivery.orderId);
    
    // CRITICAL: Deduct stock for all delivered items
    for (final item in orderItems) {
      final product = await _database.getProductById(int.parse(item.productId));
      if (product == null || product.isDeleted) {
        throw Exception('Product ${item.productId} not found');
      }
      
      // Deduct stock
      final newStock = product.currentStock - item.quantity;
      if (newStock < 0) {
        throw Exception('Insufficient stock for ${product.name}. Current: ${product.currentStock}, Required: ${item.quantity}');
      }
      
      await _database.customUpdate(
        'UPDATE products SET current_stock = ?, updated_at = ?, sync_status = ? WHERE id = ?',
        variables: [
          Variable.withInt(newStock),
          Variable.withDateTime(DateTime.now()),
          Variable.withString('pending'),
          Variable.withString(item.productId),
        ],
      );
      
      // Log stock movement
      await _database.createStockMovement(
        StockMovementsCompanion.insert(
          id: _generateUuid(),
          productId: item.productId.toString(),
          movementType: 'stock_out',
          quantity: -item.quantity, // Negative for stock out
          referenceType: const Value('delivery'),
          referenceId: Value(delivery.id),
          reason: 'Order ${order.orderNumber} delivered',
          notes: Value('Delivered to ${delivery.endLocation}'),
          userId: delivery.deliveryPersonnelId,
          userName: delivery.deliveryPersonnelName,
          fromLocation: Value(product.location),
          toLocation: Value(delivery.endLocation),
          unitCost: Value(product.costPrice),
          totalCost: Value(product.costPrice * item.quantity),
          status: const Value('completed'),
          syncStatus: const Value('pending'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      
      // Update order item delivered quantity
      await _database.customUpdate(
        'UPDATE order_items SET delivered_quantity = ?, status = ?, updated_at = ?, sync_status = ? WHERE id = ?',
        variables: [
          Variable.withInt(item.quantity),
          Variable.withString('delivered'),
          Variable.withDateTime(DateTime.now()),
          Variable.withString('pending'),
          Variable.withString(item.id),
        ],
      );
    }
    
    // Update delivery status to COMPLETED
    await _database.customUpdate(
      'UPDATE deliveries SET status = ?, actual_completion_time = ?, recipient_name = ?, recipient_relation = ?, delivery_notes = ?, collected_amount = ?, payment_method = ?, proof_of_delivery_url = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('completed'),
        Variable.withDateTime(DateTime.now()),
        Variable.withString(recipientName),
        Variable.withString(recipientRelation),
        Variable.withString(deliveryNotes ?? ''),
        Variable.withReal(collectedAmount ?? 0.0),
        Variable.withString(paymentMethod ?? ''),
        Variable.withString(proofOfDeliveryUrl ?? ''),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(deliveryId),
      ],
    );
    
    // Update order status to DELIVERED
    await _database.customUpdate(
      'UPDATE orders SET status = ?, actual_delivery_date = ?, payment_status = ?, updated_at = ?, sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString('delivered'),
        Variable.withDateTime(DateTime.now()),
        Variable.withString(collectedAmount != null && collectedAmount > 0 ? 'paid' : 'pending'),
        Variable.withDateTime(DateTime.now()),
        Variable.withString('pending'),
        Variable.withString(delivery.orderId),
      ],
    );
    
    print('✅ Delivery confirmed and stock deducted successfully');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// Get pending orders for warehouse staff
  Future<List<Order>> getPendingOrders() async => (_database.select(_database.orders)
          ..where((tbl) => tbl.status.equals('pending') & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  
  /// Get orders ready for delivery
  Future<List<Order>> getOrdersReadyForDelivery() async => (_database.select(_database.orders)
          ..where((tbl) => tbl.status.equals('packed') & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  
  /// Get active deliveries for delivery personnel
  Future<List<Delivery>> getActiveDeliveries() async => (_database.select(_database.deliveries)
          ..where((tbl) => (tbl.status.equals('assigned') | tbl.status.equals('in_progress')) & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  
  /// Utility methods
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD-$timestamp';
  }
  
  String _generateDeliveryNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'DEL-$timestamp';
  }
  
  String _generateUuid() => DateTime.now().millisecondsSinceEpoch.toString();
}

/// Data class for order items
class OrderItemData {
  
  OrderItemData({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    this.notes,
  });
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
}
