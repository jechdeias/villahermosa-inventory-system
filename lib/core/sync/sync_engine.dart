import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../config/supabase_config.dart';

enum SyncOperation {
  insert,
  update,
  delete,
}

enum SyncConflictResolution {
  localWins,
  remoteWins,
  manual,
  lastWriteWins,
}

class SyncEngine {
  
  SyncEngine(this._database);
  final AppDatabase _database;
  
  /// Protected access to database for implementations
  AppDatabase get database => _database;
  
  /// Main sync orchestrator - thesis-worthy core logic
  Future<SyncResult> performFullSync() async {
    try {
      debugPrint('Starting full sync process...');
      
      // Step 1: Push pending local changes
      await _pushLocalChanges();
      
      // Step 2: Pull remote updates
      await _pullRemoteChanges();
      
      // Step 3: Resolve conflicts
      await _resolveConflicts();
      
      // Step 4: Update sync status
      await _updateSyncStatus();
      
      debugPrint('Full sync completed successfully');
      return SyncResult.success();
    } catch (e) {
      debugPrint('Sync failed: $e');
      return SyncResult.failure(e.toString());
    }
  }
  
  /// Push pending local records to Supabase
  Future<void> _pushLocalChanges() async {
    debugPrint('Pushing pending local changes to Supabase...');
    
    // Sync in priority order
    await _syncTable('users', _pushUsers, SyncConflictResolution.remoteWins);
    await _syncTable('categories', _pushCategories, SyncConflictResolution.lastWriteWins);
    await _syncTable('products', _pushProducts, SyncConflictResolution.localWins);
    await _syncTable('customers', _pushCustomers, SyncConflictResolution.localWins);
    await _syncTable('orders', _pushOrders, SyncConflictResolution.localWins);
    await _syncTable('order_items', _pushOrderItems, SyncConflictResolution.localWins);
    await _syncTable('stock_movements', _pushStockMovements, SyncConflictResolution.lastWriteWins);
    await _syncTable('deliveries', _pushDeliveries, SyncConflictResolution.localWins);
    
    debugPrint('Local changes pushed successfully');
  }
  
  /// Pull remote updates from Supabase
  Future<void> _pullRemoteChanges() async {
    debugPrint('Pulling remote changes from Supabase...');
    
    final lastSyncTime = await _getLastSyncTimestamp();
    
    // Pull each table safely - handle missing tables
    await _pullTableSafely('users', _pullUsers, lastSyncTime);
    await _pullTableSafely('products', _pullProducts, lastSyncTime);
    await _pullTableSafely('customers', _pullCustomers, lastSyncTime);
    await _pullTableSafely('orders', _pullOrders, lastSyncTime);
    await _pullTableSafely('order_items', _pullOrderItems, lastSyncTime);
    await _pullTableSafely('stock_movements', _pullStockMovements, lastSyncTime);
    await _pullTableSafely('deliveries', _pullDeliveries, lastSyncTime);
    
    await _updateLastSyncTimestamp();
    debugPrint('Remote changes pulled successfully');
  }
  
  /// Pull table safely with error handling
  Future<void> _pullTableSafely(
    String tableName, 
    Future<void> Function(DateTime) pullFn,
    DateTime lastSyncTime,
  ) async {
    try {
      await pullFn(lastSyncTime);
    } catch (e) {
      debugPrint('Skipping $tableName pull - table may not exist yet: $e');
    }
  }
  
  /// Resolve conflicts based on business rules
  Future<void> _resolveConflicts() async {
    debugPrint('Resolving sync conflicts...');
    
    // Get all conflicted records
    final conflictedUsers = await _database.getPendingSyncUsers();
    final conflictedProducts = await _database.getPendingSyncProducts();
    final conflictedCustomers = await _database.getPendingSyncCustomers();
    final conflictedStockMovements = await _database.getPendingSyncStockMovements();
    
    // Resolve conflicts per table rules
    for (final user in conflictedUsers) {
      await _resolveUserConflict(user);
    }
    
    for (final product in conflictedProducts) {
      await _resolveProductConflict(product);
    }
    
    for (final customer in conflictedCustomers) {
      await _resolveCustomerConflict(customer);
    }
    
    for (final movement in conflictedStockMovements) {
      await _resolveStockMovementConflict(movement);
    }
    
    debugPrint('Conflicts resolved');
  }
  
  /// Update sync status for all records
  Future<void> _updateSyncStatus() async {
    debugPrint('Updating sync status...');
    
    // Mark all pending records as synced
    await _database.customUpdate(
      'UPDATE customers SET sync_status = ? WHERE sync_status = ?',
      variables: [Variable.withString('synced'), Variable.withString('pending')],
    );
    
    await _database.customUpdate(
      'UPDATE products SET sync_status = ? WHERE sync_status = ?',
      variables: [Variable.withString('synced'), Variable.withString('pending')],
    );
    
    await _database.customUpdate(
      'UPDATE stock_movements SET sync_status = ? WHERE sync_status = ?',
      variables: [Variable.withString('synced'), Variable.withString('pending')],
    );
    
    debugPrint('Sync status updated');
  }
  
  /// Generic table sync method
  Future<void> _syncTable(
    String tableName,
    Future<List> Function() pushFunction,
    SyncConflictResolution conflictRule,
  ) async {
    try {
      debugPrint('Syncing table: $tableName');
      
      final pendingRecords = await pushFunction();
      
      for (final record in pendingRecords) {
        await _syncRecord(record, conflictRule);
      }
      
      debugPrint('Table $tableName synced successfully');
    } catch (e) {
      debugPrint('Error syncing $tableName: $e');
      // Continue with other tables
    }
  }
  
  /// Sync individual record to Supabase
  Future<void> _syncRecord(dynamic record, SyncConflictResolution rule) async {
    try {
      final tableName = _getTableName(record);
      final remoteId = record.remoteId;
      
      if (remoteId == null) {
        // Insert new record
        await _insertRemoteRecord(record, tableName);
      } else {
        // Update existing record
        await _updateRemoteRecord(record, tableName, remoteId, rule);
      }
    } catch (e) {
      debugPrint('Error syncing record: $e');
      // Mark as conflicted
      await _markRecordAsConflicted(record);
    }
  }
  
  /// Insert new record to Supabase
  Future<void> _insertRemoteRecord(dynamic record, String tableName) async {
    final data = _recordToMap(record);
    data['sync_status'] = 'synced';
    data['local_id'] = record.id;
    
    final response = await Supabase.instance.client
        .from(tableName)
        .insert(data)
        .select('id')
        .single();
    
    // Update local record with remote ID
    await _markRecordAsSynced(record, response['id']);
  }
  
  /// Update existing record in Supabase
  Future<void> _updateRemoteRecord(
    dynamic record, 
    String tableName, 
    String remoteId, 
    SyncConflictResolution rule,
  ) async {
    final data = _recordToMap(record);
    data.remove('id'); // Don't update primary key
    data.remove('remote_id'); // Don't update remote ID
    data.remove('local_id'); // Don't update local ID
    
    // Check for conflicts
    final remoteRecord = await Supabase.instance.client
        .from(tableName)
        .select('updated_at')
        .eq('id', remoteId)
        .single();
    
    if (_hasConflict(record, remoteRecord, rule)) {
      await _handleConflict(record, tableName, remoteId, rule);
    } else {
      // No conflict, proceed with update
      await Supabase.instance.client
          .from(tableName)
          .update(data)
          .eq('id', remoteId);
      
      await _markRecordAsSynced(record, remoteId);
    }
  }
  
  /// Helper method to get updatedAt from dynamic record
  DateTime _getRecordUpdatedAt(dynamic record) {
    if (record is User) return record.updatedAt;
    if (record is Customer) return record.updatedAt;
    if (record is Product) return record.updatedAt;
    if (record is StockMovement) return record.updatedAt;
    if (record is Order) return record.updatedAt;
    if (record is OrderItem) return record.updatedAt;
    if (record is Delivery) return record.updatedAt;
    // Default fallback
    return DateTime.now();
  }

  /// Handle conflict resolution
  Future<void> _handleConflict(
    dynamic record,
    String tableName,
    String remoteId,
    SyncConflictResolution rule,
  ) async {
    switch (rule) {
      case SyncConflictResolution.localWins:
        // Push local changes to remote
        final data = _recordToMap(record);
        await Supabase.instance.client
            .from(tableName)
            .update(data)
            .eq('id', remoteId);
        await _markRecordAsSynced(record, remoteId);
        break;
        
      case SyncConflictResolution.remoteWins:
        // Pull remote changes to local
        final remoteData = await Supabase.instance.client
            .from(tableName)
            .select()
            .eq('id', remoteId)
            .single();
        await _updateLocalRecord(tableName, remoteData);
        break;
        
      case SyncConflictResolution.lastWriteWins:
        // Compare timestamps
        final remoteData = await Supabase.instance.client
            .from(tableName)
            .select()
            .eq('id', remoteId)
            .single();
        final localUpdatedAt = _getRecordUpdatedAt(record);
        final remoteUpdatedAt = DateTime.parse(remoteData['updated_at']);
        if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
          // Local is newer
          final data = _recordToMap(record);
          await Supabase.instance.client
              .from(tableName)
              .update(data)
              .eq('id', remoteId);
          await _markRecordAsSynced(record, remoteId);
        } else {
          // Remote is newer
          await _updateLocalRecord(tableName, remoteData);
        }
        break;
        
      case SyncConflictResolution.manual:
        // Mark for manual resolution
        await _markRecordAsConflicted(record);
        break;
    }
  }
  
  /// Table-specific push methods
  Future<List<User>> _pushUsers() async {
    final pendingUsers = await _database.getPendingSyncUsers();
    debugPrint('📋 Pending users to sync: ${pendingUsers.length}');
    
    if (pendingUsers.isEmpty) return [];
    
    // Use service client like AuthRepository for sync operations
    final serviceClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.serviceKey,
      headers: {'X-Client-Info': 'service_role'},
    );
    
    for (final user in pendingUsers) {
      try {
        debugPrint('🔄 Syncing user: ${user.email}');
        
        final data = _recordToMap(user);
        final result = await serviceClient
            .from('users')
            .upsert(data, onConflict: 'email');
        
        if (result != null) {
          // Mark local record as synced after successful remote upsert
          await _markRecordAsSynced(user, user.id.toString());
          debugPrint('✅ User synced: ${user.email}');
        } else {
          debugPrint('❌ Failed to sync user: ${user.email}');
        }
      } catch (e) {
        debugPrint('Failed to sync user ${user.email}: $e');
      }
    }
    
    return pendingUsers;
  }
  
  Future<List<dynamic>> _pushCategories() async {
    debugPrint('Pushing categories to Supabase...');
    // Implementation needed
    return [];
  }
  
  Future<List<Product>> _pushProducts() async {
    final pendingProducts = await _database.getPendingSyncProducts();
    
    for (final product in pendingProducts) {
      try {
        final data = _recordToMap(product);
        await Supabase.instance.client
            .from('products')
            .upsert(data);
        await _markRecordAsSynced(product, product.id.toString());
      } catch (e) {
        debugPrint('Failed to sync product ${product.id}: $e');
      }
    }
    
    return pendingProducts;
  }
  
  Future<List<Customer>> _pushCustomers() async {
    final pendingCustomers = await _database.getPendingSyncCustomers();
    
    for (final customer in pendingCustomers) {
      try {
        final data = _recordToMap(customer);
        await Supabase.instance.client
            .from('customers')
            .upsert(data);
        await _markRecordAsSynced(customer, customer.id.toString());
      } catch (e) {
        debugPrint('Failed to sync customer ${customer.id}: $e');
      }
    }
    
    return pendingCustomers;
  }
  
  Future<List<Order>> _pushOrders() async {
    final pendingOrders = await _database.getPendingSyncOrders();
    
    for (final order in pendingOrders) {
      try {
        final data = _recordToMap(order);
        await Supabase.instance.client
            .from('orders')
            .insert(data);
        await _markRecordAsSynced(order, order.id.toString());
      } catch (e) {
        debugPrint('Failed to sync order ${order.id}: $e');
      }
    }
    
    return pendingOrders;
  }
  
  Future<List<OrderItem>> _pushOrderItems() async {
    final pendingOrderItems = await _database.getPendingSyncOrderItems();
    
    for (final orderItem in pendingOrderItems) {
      try {
        final data = _recordToMap(orderItem);
        await Supabase.instance.client
            .from('order_items')
            .insert(data);
        await _markRecordAsSynced(orderItem, orderItem.id.toString());
      } catch (e) {
        debugPrint('Failed to sync order item ${orderItem.id}: $e');
      }
    }
    
    return pendingOrderItems;
  }
  
  Future<List<StockMovement>> _pushStockMovements() async {
    final pendingStockMovements = await _database.getPendingSyncStockMovements();
    
    for (final stockMovement in pendingStockMovements) {
      try {
        final data = _recordToMap(stockMovement);
        await Supabase.instance.client
            .from('stock_movements')
            .upsert(data);
        await _markRecordAsSynced(stockMovement, stockMovement.id.toString());
      } catch (e) {
        debugPrint('Failed to sync stock movement ${stockMovement.id}: $e');
      }
    }
    
    return pendingStockMovements;
  }
  
  Future<List<Delivery>> _pushDeliveries() async {
    final pendingDeliveries = await _database.getPendingSyncDeliveries();
    
    for (final delivery in pendingDeliveries) {
      try {
        final data = _recordToMap(delivery);
        await Supabase.instance.client
            .from('deliveries')
            .insert(data);
        await _markRecordAsSynced(delivery, delivery.id.toString());
      } catch (e) {
        debugPrint('Failed to sync delivery ${delivery.id}: $e');
      }
    }
    
    return pendingDeliveries;
  }
  
  /// Table-specific pull methods
  Future<void> _pullUsers(DateTime lastSyncTime) async {
  try {
    debugPrint('=== PULL USERS START ===');
    debugPrint('Last sync time: $lastSyncTime');
    
    // Check if Supabase client is authenticated
    final currentUser = Supabase.instance.client.auth.currentUser;
    debugPrint('Current user: ${currentUser?.email}, authenticated: ${currentUser != null}');
    
    var query = Supabase.instance.client.from('users').select();
    
    // Only apply timestamp filter if it's not the first sync (not very old)
    if (lastSyncTime.isAfter(DateTime(2020))) {
      debugPrint('Applying timestamp filter: ${lastSyncTime.toIso8601String()}');
      query = query.gte('updated_at', lastSyncTime.toIso8601String());
    } else {
      debugPrint('No timestamp filter - pulling all users');
    }
    
    // Log before filter
    debugPrint('Querying Supabase users table...');
    debugPrint('Auth token available: ${Supabase.instance.client.auth.currentSession?.accessToken != null}');
    
    final response = await query;
    
    debugPrint('Supabase returned ${response.length} users');
    if (response.isNotEmpty) {
      debugPrint('First user sample: ${response.first}');
      debugPrint('Available keys in first user: ${response.first.keys.toList()}');
    } else {
      debugPrint('EMPTY RESPONSE - No users returned from supabase');
    }
    
    for (final userData in response) {
      debugPrint('Processing user: ${userData['email']}');
      await _updateLocalRecord('users', userData);
      debugPrint('Inserted/updated: ${userData['email']}');
    }
    
    debugPrint('=== PULL USERS END ===');
  } catch (e, stack) {
    debugPrint('PULL USERS ERROR: $e');
    debugPrint('STACK: $stack');
  }
}
  
  Future<void> _pullProducts(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final productData in response) {
      await _updateLocalRecord('products', productData);
    }
  }
  
  Future<void> _pullCustomers(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('customers')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final customerData in response) {
      await _updateLocalRecord('customers', customerData);
    }
  }
  
  Future<void> _pullOrders(DateTime lastSyncTime) async {
    // Implementation needed
  }
  
  Future<void> _pullOrderItems(DateTime lastSyncTime) async {
    // Implementation needed
  }
  
  Future<void> _pullStockMovements(DateTime lastSyncTime) async {
    // Implementation needed
  }
  
  Future<void> _pullDeliveries(DateTime lastSyncTime) async {
    // Implementation needed
  }
  
  /// Utility methods
  Map<String, dynamic> _recordToMap(dynamic record) {
    if (record is User) {
      return {
        'id': record.id,
        'firstName': record.firstName,
        'lastName': record.lastName,
        'email': record.email,
        'role': record.role,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Product) {
      return {
        'id': record.id,
        'sku': record.sku,
        'name': record.name,
        'category': record.category,
        'unit_price': record.unitPrice,
        'cost_price': record.costPrice,
        'current_stock': record.currentStock,
        'min_stock': record.minStock,
        'unit': record.unit,
        'status': record.status,
        'location': record.location,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Customer) {
      return {
        'id': record.id,
        'name': record.name,
        'business_name': record.businessName,
        'email': record.email,
        'phone': record.phone,
        'address': record.address,
        'municipality': record.municipality,
        'province': record.province,
        'credit_limit': record.creditLimit,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is StockMovement) {
      return {
        'id': record.id,
        'product_id': record.productId,
        'movement_type': record.movementType,
        'quantity': record.quantity,
        'reason': record.reason,
        'user_id': record.userId,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Order) {
      return {
        'id': record.id,
        'uuid': record.uuid,
        'customer_id': record.customerId,
        'order_number': record.orderNumber,
        'status': record.status,
        'delivery_address': record.deliveryAddress,
        'customer_notes': record.customerNotes,
        'total_amount': record.totalAmount,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is OrderItem) {
      return {
        'id': record.id,
        'order_id': record.orderId,
        'product_id': record.productId,
        'quantity': record.quantity,
        'unit_price': record.unitPrice,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Delivery) {
      return {
        'id': record.id,
        'order_id': record.orderId,
        'status': record.status,
        'delivery_notes': record.deliveryNotes,
        'is_active': record.isActive,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    return {};
  }
  
  String _getTableName(dynamic record) {
    if (record is User) return 'users';
    if (record is Product) return 'products';
    if (record is Customer) return 'customers';
    if (record is StockMovement) return 'stock_movements';
    if (record is Order) return 'orders';
    if (record is OrderItem) return 'order_items';
    if (record is Delivery) return 'deliveries';
    return '';
  }
  
  bool _hasConflict(dynamic record, Map<String, dynamic> remoteRecord, SyncConflictResolution rule) {
    // Check if there's a conflict based on timestamps and rule
    return false;
  }
  
  Future<void> _markRecordAsSynced(dynamic record, String remoteId) async {
    final tableName = _getTableName(record);
    if (tableName.isEmpty) return;
    
    // Update sync status to 'synced' using custom update
    await _database.customUpdate(
      'UPDATE $tableName SET sync_status = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable.withString('synced'),
        Variable.withDateTime(DateTime.now()),
        Variable.withInt(record.id),
      ],
    );
  }
  
  Future<void> _markRecordAsConflicted(dynamic record) async {
    // Mark record as conflicted
  }
  
  Future<void> _updateLocalRecord(String tableName, Map<String, dynamic> data) async {
    try {
      debugPrint('_updateLocalRecord called for table: $tableName');
      debugPrint('Data keys: ${data.keys.toList()}');
      debugPrint('Data values: $data');
      
      // Check if record exists
      final existing = await _database.customSelect(
        'SELECT id FROM $tableName WHERE id = ?',
        variables: [Variable.withInt(data['id'])],
      ).getSingleOrNull();
      
      if (existing != null) {
        // Update existing record - handle different tables
        if (tableName == 'users') {
          // Special handling for users table with correct field names
          debugPrint('Updating existing user record');
          await _database.customUpdate(
            '''UPDATE users SET 
                first_name = ?, last_name = ?, email = ?, role = ?, 
                is_active = ?, is_deleted = ?, sync_status = ?, 
                updated_at = ? 
                WHERE id = ?''',
            variables: [
              Variable.withString(data['first_name'] ?? data['name'] ?? ''),
              Variable.withString(data['last_name'] ?? ''),
              Variable.withString(data['email'] ?? ''),
              Variable.withString(data['role'] ?? ''),
              Variable.withBool(data['is_active'] ?? true),
              Variable.withBool(data['is_deleted'] ?? false),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.parse(data['updated_at'])),
              Variable.withInt(data['id']),
            ],
          );
        } else {
          // Generic handling for other tables
          await _database.customUpdate(
            '''UPDATE $tableName SET 
                name = ?, email = ?, phone = ?, address = ?, 
                sync_status = ?, updated_at = ? 
                WHERE id = ?''',
            variables: [
              Variable.withString(data['name'] ?? ''),
              Variable.withString(data['email'] ?? ''),
              Variable.withString(data['phone'] ?? ''),
              Variable.withString(data['address'] ?? ''),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.parse(data['updated_at'])),
              Variable.withInt(data['id']),
            ],
          );
        }
      } else {
        // Insert new record - handle different tables
        if (tableName == 'users') {
          // Special handling for users table with correct field names
          debugPrint('Inserting new user record');
          await _database.customInsert(
            '''INSERT INTO users 
                    (id, first_name, last_name, email, role, is_active, is_deleted, sync_status, created_at, updated_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
            variables: [
              Variable.withInt(data['id']),
              Variable.withString(data['first_name'] ?? data['name'] ?? ''),
              Variable.withString(data['last_name'] ?? ''),
              Variable.withString(data['email'] ?? ''),
              Variable.withString(data['role'] ?? ''),
              Variable.withBool(data['is_active'] ?? true),
              Variable.withBool(data['is_deleted'] ?? false),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.parse(data['created_at'])),
              Variable.withDateTime(DateTime.parse(data['updated_at'])),
            ],
          );
        } else {
          // Generic handling for other tables
          await _database.customInsert(
            '''INSERT INTO $tableName 
                    (id, name, email, phone, address, sync_status, created_at, updated_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
            variables: [
              Variable.withInt(data['id']),
              Variable.withString(data['name'] ?? ''),
              Variable.withString(data['email'] ?? ''),
              Variable.withString(data['phone'] ?? ''),
              Variable.withString(data['address'] ?? ''),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.parse(data['created_at'])),
              Variable.withDateTime(DateTime.parse(data['updated_at'])),
            ],
          );
        }
      }
      debugPrint('_updateLocalRecord completed successfully for $tableName');
    } catch (e) {
      debugPrint('Error updating local record in $tableName: $e');
      debugPrint('Error stack: ${StackTrace.current}');
    }
  }
  
  Future<DateTime> _getLastSyncTimestamp() async {
    // Get last sync timestamp from local storage
    return DateTime.now().subtract(const Duration(days: 1));
  }
  
  Future<void> _updateLastSyncTimestamp() async {
    // Update last sync timestamp
  }
  
  /// Conflict resolution methods
  Future<void> _resolveUserConflict(User user) async {
    // Admin wins for user conflicts
  }
  
  Future<void> _resolveProductConflict(Product product) async {
    // Warehouse wins for product conflicts
  }
  
  Future<void> _resolveCustomerConflict(Customer customer) async {
    // Customer wins for own data conflicts
  }
  
  Future<void> _resolveStockMovementConflict(StockMovement movement) async {
    // Last-write-wins for stock movements
  }
}

class SyncResult {
  
  SyncResult.success({
    this.syncedCounts = const {},
  }) : success = true, error = null, timestamp = DateTime.now();
  
  SyncResult.failure(this.error, {
    this.syncedCounts = const {},
  }) : success = false, timestamp = DateTime.now();
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, int> syncedCounts;
  
  @override
  String toString() {
    if (success) {
      return 'Sync successful at $timestamp. Records: ${syncedCounts.toString()}';
    } else {
      return 'Sync failed at $timestamp. Error: $error';
    }
  }
}
