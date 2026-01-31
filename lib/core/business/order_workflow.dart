import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../sync/sync_manager.dart';
import '../utils/type_validator.dart';

/// Order Workflow - Core Business Logic
/// Implements the complete order lifecycle with proper stock management
class OrderWorkflow {
  final AppDatabase _database;
  final SyncManager _syncManager;
  
  OrderWorkflow(this._database, this._syncManager);
  
  static OrderWorkflow? _instance;
  static OrderWorkflow get instance => _instance ??= OrderWorkflow._();
  
  OrderWorkflow._() : _database = AppDatabase(), _syncManager = SyncManager.instance;
  
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
    final orderNumber = await _generateOrderNumber();
    
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
        throw Exception('Product ${validatedProductId} not found or inactive');
      }
      
      // Check availability (but don't reserve yet)
      if (product.currentStock < validatedQuantity) {
        throw Exception('Insufficient stock for ${product.name}. Available: ${product.currentStock}, Requested: ${validatedQuantity}');
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
      final product = await _database.getProductById(item.productId);
      if (product == null || product.isDeleted) {
        throw Exception('Product ${item.productId} not found');
      }
      
      if (product.currentStock < item.quantity) {
        throw Exception('Insufficient stock for ${product.name}. Available: ${product.currentStock}, Requested: ${item.quantity}');
      }
    }
    
    // Reserve stock (update order status to CONFIRMED)
    await _database.customUpdateOnly(
      OrdersCompanion(
        status: const Value('confirmed'),
        warehouseStatus: const Value('picking'),
        pickerId: Value(warehouseUserId),
        pickedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(orderId),
    );
    
    // Update order items status to PICKED
    for (final item in orderItems) {
      await _database.customUpdateOnly(
        OrderItemsCompanion(
          status: const Value('picked'),
          pickerId: Value(warehouseUserId),
          pickedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
        where: (tbl) => tbl.id.equals(item.id),
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
    await _database.customUpdateOnly(
      OrdersCompanion(
        status: const Value('packed'),
        warehouseStatus: const Value('ready'),
        packerId: Value(packerUserId),
        packedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(orderId),
    );
    
    // Update order items status to PACKED
    final orderItems = await _database.getOrderItemsByOrderId(orderId);
    for (final item in orderItems) {
      await _database.customUpdateOnly(
        OrderItemsCompanion(
          status: const Value('packed'),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
        where: (tbl) => tbl.id.equals(item.id),
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
    final deliveryNumber = await _generateDeliveryNumber();
    
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
    await _database.customUpdateOnly(
      OrdersCompanion(
        status: const Value('dispatched'),
        warehouseStatus: const Value('shipped'),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(orderId),
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
    await _database.customUpdateOnly(
      DeliveriesCompanion(
        status: const Value('in_progress'),
        actualStartTime: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(deliveryId),
    );
    
    // Update order status to OUT_FOR_DELIVERY
    await _database.customUpdateOnly(
      OrdersCompanion(
        status: const Value('out_for_delivery'),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(delivery.orderId),
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
      final product = await _database.getProductById(item.productId);
      if (product == null || product.isDeleted) {
        throw Exception('Product ${item.productId} not found');
      }
      
      // Deduct stock
      final newStock = product.currentStock - item.quantity;
      if (newStock < 0) {
        throw Exception('Insufficient stock for ${product.name}. Current: ${product.currentStock}, Required: ${item.quantity}');
      }
      
      await _database.customUpdateOnly(
        ProductsCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
        where: (tbl) => tbl.id.equals(item.productId),
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
      await _database.customUpdateOnly(
        OrderItemsCompanion(
          deliveredQuantity: Value(item.quantity),
          status: const Value('delivered'),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
        where: (tbl) => tbl.id.equals(item.id),
      );
    }
    
    // Update delivery status to COMPLETED
    await _database.customUpdateOnly(
      DeliveriesCompanion(
        status: const Value('completed'),
        actualCompletionTime: Value(DateTime.now()),
        recipientName: Value(recipientName),
        recipientRelation: Value(recipientRelation),
        deliveryNotes: Value(deliveryNotes),
        collectedAmount: Value(collectedAmount ?? 0.0),
        paymentMethod: Value(paymentMethod),
        proofOfDeliveryUrl: Value(proofOfDeliveryUrl),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(deliveryId),
    );
    
    // Update order status to DELIVERED
    await _database.customUpdateOnly(
      OrdersCompanion(
        status: const Value('delivered'),
        actualDeliveryDate: Value(DateTime.now()),
        paymentStatus: collectedAmount != null && collectedAmount > 0 
            ? const Value('paid') 
            : const Value('pending'),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
      where: (tbl) => tbl.id.equals(delivery.orderId),
    );
    
    print('✅ Delivery confirmed and stock deducted successfully');
    
    // Trigger sync
    await _syncManager.performFullSync();
  }
  
  /// Get pending orders for warehouse staff
  Future<List<Order>> getPendingOrders() async {
    return await _database.customSelect(
      'SELECT * FROM orders WHERE status = ? AND is_deleted = 0 ORDER BY created_at ASC',
      variables: [Variable.withString('pending')],
    ).map((row) => Order.fromData(row.data, _database)).get();
  }
  
  /// Get orders ready for delivery
  Future<List<Order>> getOrdersReadyForDelivery() async {
    return await _database.customSelect(
      'SELECT * FROM orders WHERE status = ? AND is_deleted = 0 ORDER BY created_at ASC',
      variables: [Variable.withString('packed')],
    ).map((row) => Order.fromData(row.data, _database)).get();
  }
  
  /// Get active deliveries for delivery personnel
  Future<List<Delivery>> getActiveDeliveries() async {
    return await _database.customSelect(
      'SELECT * FROM deliveries WHERE status IN (?, ?) AND is_deleted = 0 ORDER BY created_at ASC',
      variables: [Variable.withString('assigned'), Variable.withString('in_progress')],
    ).map((row) => Delivery.fromData(row.data, _database)).get();
  }
  
  /// Utility methods
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD-$timestamp';
  }
  
  String _generateDeliveryNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'DEL-$timestamp';
  }
  
  String _generateUuid() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Data class for order items
class OrderItemData {
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
  
  OrderItemData({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    this.notes,
  });
}
