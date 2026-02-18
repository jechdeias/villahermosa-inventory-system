import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../sync/sync_manager.dart';

/// Stock Movement Service - Industry Standard Inventory Logic
/// Stock quantity = SUM(StockMovements), not a magic number
class StockMovementService {
  
  StockMovementService(this._database, this._syncManager);
  
  StockMovementService._() : _database = AppDatabase(), _syncManager = SyncManager.instance;
  final AppDatabase _database;
  final SyncManager _syncManager;
  
  static StockMovementService? _instance;
  static StockMovementService get instance => _instance ??= StockMovementService._();
  
  /// Get current stock for a product (calculated from movements)
  Future<int> getCurrentStock(int productId) async {
    final result = await _database.customSelect('''
      SELECT COALESCE(SUM(quantity), 0) as current_stock
      FROM stock_movements 
      WHERE product_id = ? AND is_deleted = 0
    ''', variables: [Variable.withInt(productId)]).getSingleOrNull();
    
    return result!.data['current_stock'] as int;
  }
  
  /// Get stock movement history for a product
  Future<List<Map<String, dynamic>>> getStockMovementHistory(int productId) async => _database.customSelect('''
      SELECT 
        sm.*,
        u.name as user_name,
        p.name as product_name,
        p.sku as product_sku
      FROM stock_movements sm
      LEFT JOIN users u ON sm.created_by = u.id
      LEFT JOIN products p ON sm.product_id = p.id
      WHERE sm.product_id = ? AND sm.is_deleted = 0
      ORDER BY sm.created_at DESC
    ''', variables: [Variable.withInt(productId)]).get().then((rows) => rows.map((row) => row.data).toList());
  
  /// STOCK IN: Supplier delivery
  Future<void> recordStockIn({
    required int productId,
    required int quantity,
    required int userId,
    required String userName,
    String? supplierName,
    String? purchaseOrderNumber,
    String? notes,
    double? unitCost,
    String? fromLocation,
    String? toLocation,
  }) async {
    if (quantity <= 0) {
      throw Exception('Stock IN quantity must be positive');
    }
    
    final product = await _database.customSelect(
      'SELECT name, sku FROM products WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(productId)],
    ).getSingleOrNull();
    
    if (product == null) {
      throw Exception('Product not found');
    }
    
    await _database.into(_database.stockMovements).insert(
      StockMovementsCompanion.insert(
        uuid: _generateUuid(),
        productId: productId.toString(),
        movementType: 'stock_in',
        quantity: quantity, // Positive for stock in
        referenceType: const Value('supplier_delivery'),
        referenceId: Value(purchaseOrderNumber ?? ''),
        reason: 'Supplier delivery: ${supplierName ?? 'Unknown supplier'}',
        notes: Value(notes),
        userId: userId.toString(),
        userName: userName,
        fromLocation: Value(fromLocation ?? 'Supplier'),
        toLocation: Value(toLocation ?? 'Warehouse'),
        unitCost: Value(unitCost),
        totalCost: Value(unitCost != null ? unitCost * quantity : null),
        status: const Value('completed'),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    
    print('✅ Stock IN recorded: +$quantity units for ${product.data['name']}');
    await _syncManager.performFullSync();
  }
  
  /// STOCK OUT: Customer order (only when delivery is confirmed)
  Future<void> recordStockOut({
    required int productId,
    required int quantity,
    required int userId,
    required String userName,
    required String orderId,
    required String orderNumber,
    String? notes,
    double? unitCost,
    String? fromLocation,
    String? toLocation,
  }) async {
    if (quantity <= 0) {
      throw Exception('Stock OUT quantity must be positive');
    }
    
    // Check current stock availability
    final currentStock = await getCurrentStock(productId);
    if (currentStock < quantity) {
      throw Exception('Insufficient stock. Available: $currentStock, Required: $quantity');
    }
    
    final product = await _database.customSelect(
      'SELECT name, sku FROM products WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(productId)],
    ).getSingleOrNull();
    
    if (product == null) {
      throw Exception('Product not found');
    }
    
    await _database.into(_database.stockMovements).insert(
      StockMovementsCompanion.insert(
        uuid: _generateUuid(),
        productId: productId.toString(),
        movementType: 'stock_out',
        quantity: -quantity, // Negative for stock out
        referenceType: const Value('order'),
        referenceId: Value(orderId),
        reason: 'Customer order: $orderNumber',
        notes: Value(notes),
        userId: userId.toString(),
        userName: userName,
        fromLocation: Value(fromLocation ?? 'Warehouse'),
        toLocation: Value(toLocation ?? 'Customer'),
        unitCost: Value(unitCost),
        totalCost: Value(unitCost != null ? unitCost * quantity : null),
        status: const Value('completed'),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    
    print('✅ Stock OUT recorded: -$quantity units for ${product.data['name']} (Order: $orderNumber)');
    await _syncManager.performFullSync();
  }
  
  /// ADJUSTMENT: Damage, loss, or correction
  Future<void> recordStockAdjustment({
    required int productId,
    required int quantity, // Can be positive (correction) or negative (damage/loss)
    required int userId,
    required String userName,
    required String reason,
    required AdjustmentType adjustmentType,
    String? notes,
    double? unitCost,
    String? location,
  }) async {
    if (quantity == 0) {
      throw Exception('Adjustment quantity cannot be zero');
    }
    
    final product = await _database.customSelect(
      'SELECT name, sku FROM products WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(productId)],
    ).getSingleOrNull();
    
    if (product == null) {
      throw Exception('Product not found');
    }
    
    // For negative adjustments, check if we have enough stock
    if (quantity < 0) {
      final currentStock = await getCurrentStock(productId);
      if (currentStock + quantity < 0) {
        throw Exception('Insufficient stock for adjustment. Available: $currentStock, Adjustment: $quantity');
      }
    }
    
    await _database.into(_database.stockMovements).insert(
      StockMovementsCompanion.insert(
        uuid: _generateUuid(),
        productId: productId.toString(),
        movementType: 'adjustment',
        quantity: quantity, // Can be positive or negative
        referenceType: const Value('manual_adjustment'),
        referenceId: const Value(''),
        reason: '${adjustmentType.name}: $reason',
        notes: Value(notes),
        userId: userId.toString(),
        userName: userName,
        fromLocation: Value(location ?? 'Warehouse'),
        toLocation: Value(location ?? 'Warehouse'),
        unitCost: Value(unitCost),
        totalCost: Value(unitCost != null ? unitCost * quantity.abs() : null),
        status: const Value('completed'),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    
    final action = quantity > 0 ? 'added' : 'removed';
    print('✅ Stock ADJUSTMENT recorded: $action ${quantity.abs()} units for ${product.data['name']} (${adjustmentType.name})');
    await _syncManager.performFullSync();
  }
  
  /// RETURN: Cancelled order or returned goods
  Future<void> recordStockReturn({
    required int productId,
    required int quantity,
    required int userId,
    required String userName,
    required String orderId,
    required String orderNumber,
    required ReturnReason returnReason,
    String? notes,
    double? unitCost,
    String? fromLocation,
    String? toLocation,
  }) async {
    if (quantity <= 0) {
      throw Exception('Return quantity must be positive');
    }
    
    final product = await _database.customSelect(
      'SELECT name, sku FROM products WHERE id = ? AND is_deleted = 0',
      variables: [Variable.withInt(productId)],
    ).getSingleOrNull();
    
    if (product == null) {
      throw Exception('Product not found');
    }
    
    await _database.into(_database.stockMovements).insert(
      StockMovementsCompanion.insert(
        uuid: _generateUuid(),
        productId: productId.toString(),
        movementType: 'stock_in', // Returns are stock IN
        quantity: quantity, // Positive for stock in
        referenceType: const Value('return'),
        referenceId: Value(orderId),
        reason: '${returnReason.name}: Order $orderNumber',
        notes: Value(notes),
        userId: userId.toString(),
        userName: userName,
        fromLocation: Value(fromLocation ?? 'Customer'),
        toLocation: Value(toLocation ?? 'Warehouse'),
        unitCost: Value(unitCost),
        totalCost: Value(unitCost != null ? unitCost * quantity : null),
        status: const Value('completed'),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    
    print('✅ Stock RETURN recorded: +$quantity units for ${product.data['name']} (${returnReason.name})');
    await _syncManager.performFullSync();
  }
  
  /// Get low stock alerts
  Future<List<Map<String, dynamic>>> getLowStockAlerts() async => _database.customSelect('''
      SELECT 
        p.id,
        p.name,
        p.sku,
        p.min_stock,
        COALESCE(SUM(sm.quantity), 0) as current_stock,
        p.min_stock - COALESCE(SUM(sm.quantity), 0) as shortage
      FROM products p
      LEFT JOIN stock_movements sm ON p.id = sm.product_id AND sm.is_deleted = 0
      WHERE p.is_deleted = 0 AND p.status = 'active'
      GROUP BY p.id
      HAVING COALESCE(SUM(sm.quantity), 0) < p.min_stock
      ORDER BY shortage DESC
    ''').get().then((rows) => rows.map((row) => row.data).toList());
  
  /// Get stock summary for all products
  Future<List<Map<String, dynamic>>> getStockSummary() async => _database.customSelect('''
      SELECT 
        p.id,
        p.name,
        p.sku,
        p.category,
        p.unit,
        p.min_stock,
        p.max_stock,
        p.unit_price,
        p.cost_price,
        COALESCE(SUM(sm.quantity), 0) as current_stock,
        CASE 
          WHEN COALESCE(SUM(sm.quantity), 0) <= 0 THEN 'OUT_OF_STOCK'
          WHEN COALESCE(SUM(sm.quantity), 0) < p.min_stock THEN 'LOW_STOCK'
          WHEN p.max_stock IS NOT NULL AND COALESCE(SUM(sm.quantity), 0) > p.max_stock THEN 'OVERSTOCK'
          ELSE 'IN_STOCK'
        END as stock_status,
        COALESCE(SUM(sm.quantity), 0) * p.unit_price as total_value
      FROM products p
      LEFT JOIN stock_movements sm ON p.id = sm.product_id AND sm.is_deleted = 0
      WHERE p.is_deleted = 0
      GROUP BY p.id
      ORDER BY p.name ASC
    ''').get().then((rows) => rows.map((row) => row.data).toList());
  
  /// Get stock movement report by date range
  Future<List<Map<String, dynamic>>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
    int? productId,
    String? movementType,
  }) async {
    var whereClause = 'sm.created_at BETWEEN ? AND ? AND sm.is_deleted = 0';
    final variables = <Variable>[
      Variable.withString(startDate.toIso8601String()),
      Variable.withString(endDate.toIso8601String()),
    ];
    
    if (productId != null) {
      whereClause += ' AND sm.product_id = ?';
      variables.add(Variable.withInt(productId));
    }
    
    if (movementType != null) {
      whereClause += ' AND sm.movement_type = ?';
      variables.add(Variable.withString(movementType));
    }
    
    return _database.customSelect('''
      SELECT 
        sm.*,
        p.name as product_name,
        p.sku as product_sku,
        u.name as user_name
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      LEFT JOIN users u ON sm.user_id = u.id
      WHERE $whereClause
      ORDER BY sm.created_at DESC
    ''', variables: variables).get().then((rows) => rows.map((row) => row.data).toList());
  }
  
  /// Update product current_stock field (for display purposes only)
  /// This should be called periodically to keep the field in sync
  Future<void> updateProductStockQuantities() async {
    print('🔄 Updating product stock quantities from movements...');
    
    final products = await _database.customSelect(
      'SELECT id FROM products WHERE is_deleted = 0',
    ).get();
    
    for (final product in products) {
      final productId = product.data['id'] as int;
      final currentStock = await getCurrentStock(productId);
      
      await _database.customUpdate(
        'UPDATE products SET current_stock = ?, updated_at = ?, sync_status = ? WHERE id = ?',
        variables: [
          Variable.withInt(currentStock),
          Variable.withDateTime(DateTime.now()),
          Variable.withString('pending'),
          Variable.withInt(productId),
        ],
      );
    }
    
    print('✅ Updated stock quantities for ${products.length} products');
    await _syncManager.performFullSync();
  }
  
  /// Utility method to generate UUID
  String _generateUuid() => DateTime.now().millisecondsSinceEpoch.toString();
}

/// Types of stock adjustments
enum AdjustmentType {
  damage,
  loss,
  correction,
  expiration,
  theft,
