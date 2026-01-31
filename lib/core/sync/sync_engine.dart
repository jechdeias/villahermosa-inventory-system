import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../database/app_database.dart';

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
  final AppDatabase _database;
  
  SyncEngine(this._database);
  
  /// Protected access to database for implementations
  AppDatabase get database => _database;
  
  /// Main sync orchestrator - thesis-worthy core logic
  Future<SyncResult> performFullSync() async {
    try {
      print('🚀 Starting full sync process...');
      
      // Step 1: Push pending local changes
      await _pushLocalChanges();
      
      // Step 2: Pull remote updates
      await _pullRemoteChanges();
      
      // Step 3: Resolve conflicts
      await _resolveConflicts();
      
      // Step 4: Update sync status
      await _updateSyncStatus();
      
      print('✅ Full sync completed successfully');
      return SyncResult.success();
    } catch (e) {
      print('❌ Sync failed: $e');
      return SyncResult.failure(e.toString());
    }
  }
  
  /// Push pending local records to Supabase
  Future<void> _pushLocalChanges() async {
    print('📤 Pushing local changes to Supabase...');
    
    // Sync in priority order
    await _syncTable('users', _pushUsers, SyncConflictResolution.remoteWins);
    await _syncTable('categories', _pushCategories, SyncConflictResolution.lastWriteWins);
    await _syncTable('products', _pushProducts, SyncConflictResolution.localWins);
    await _syncTable('customers', _pushCustomers, SyncConflictResolution.localWins);
    await _syncTable('orders', _pushOrders, SyncConflictResolution.localWins);
    await _syncTable('order_items', _pushOrderItems, SyncConflictResolution.localWins);
    await _syncTable('stock_movements', _pushStockMovements, SyncConflictResolution.lastWriteWins);
    await _syncTable('deliveries', _pushDeliveries, SyncConflictResolution.localWins);
    
    print('✅ Local changes pushed successfully');
  }
  
  /// Pull remote updates from Supabase
  Future<void> _pullRemoteChanges() async {
    print('📥 Pulling remote changes from Supabase...');
    
    final lastSyncTime = await _getLastSyncTimestamp();
    
    // Pull each table
    await _pullTable('users', _pullUsers, lastSyncTime);
    await _pullTable('categories', _pullCategories, lastSyncTime);
    await _pullTable('products', _pullProducts, lastSyncTime);
    await _pullTable('customers', _pullCustomers, lastSyncTime);
    await _pullTable('orders', _pullOrders, lastSyncTime);
    await _pullTable('order_items', _pullOrderItems, lastSyncTime);
    await _pullTable('stock_movements', _pullStockMovements, lastSyncTime);
    await _pullTable('deliveries', _pullDeliveries, lastSyncTime);
    
    await _updateLastSyncTimestamp();
    print('✅ Remote changes pulled successfully');
  }
  
  /// Resolve conflicts based on business rules
  Future<void> _resolveConflicts() async {
    print('⚖️ Resolving sync conflicts...');
    
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
    
    print('✅ Conflicts resolved');
  }
  
  /// Update sync status for all records
  Future<void> _updateSyncStatus() async {
    print('🔄 Updating sync status...');
    
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
    
    print('✅ Sync status updated');
  }
  
  /// Generic table sync method
  Future<void> _syncTable(
    String tableName,
    Future<List> Function() pushFunction,
    SyncConflictResolution conflictRule,
  ) async {
    try {
      print('🔄 Syncing table: $tableName');
      
      final pendingRecords = await pushFunction();
      
      for (final record in pendingRecords) {
        await _syncRecord(record, conflictRule);
      }
      
      print('✅ Table $tableName synced successfully');
    } catch (e) {
      print('❌ Error syncing $tableName: $e');
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
      print('❌ Error syncing record: $e');
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
        if (record.updatedAt.isAfter(DateTime.parse(remoteData['updated_at']))) {
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
  
  /// Pull remote changes for a table
  Future<void> _pullTable(
    String tableName,
    Future<void> Function(DateTime) pullFunction,
    DateTime lastSyncTime,
  ) async {
    try {
      await pullFunction(lastSyncTime);
    } catch (e) {
      print('❌ Error pulling $tableName: $e');
    }
  }
  
  /// Table-specific push methods
  Future<List<User>> _pushUsers() async {
    return await _database.getPendingSyncUsers();
  }
  
  Future<List<Category>> _pushCategories() async {
    // Implementation needed
    return [];
  }
  
  Future<List<Product>> _pushProducts() async {
    return await _database.getPendingSyncProducts();
  }
  
  Future<List<Customer>> _pushCustomers() async {
    return await _database.getPendingSyncCustomers();
  }
  
  Future<List<Order>> _pushOrders() async {
    // Implementation needed
    return [];
  }
  
  Future<List<OrderItem>> _pushOrderItems() async {
    // Implementation needed
    return [];
  }
  
  Future<List<StockMovement>> _pushStockMovements() async {
    return await _database.getPendingSyncStockMovements();
  }
  
  Future<List<Delivery>> _pushDeliveries() async {
    // Implementation needed
    return [];
  }
  
  /// Table-specific pull methods
  Future<void> _pullUsers(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final userData in response) {
      await _updateLocalRecord('users', userData);
    }
  }
  
  Future<void> _pullCategories(DateTime lastSyncTime) async {
    // Implementation needed
  }
  
  Future<void> _pullProducts(DateTime lastSyncTime) async {
    // Implementation needed
  }
  
  Future<void> _pullCustomers(DateTime lastSyncTime) async {
    // Implementation needed
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
    // Convert record to Map for Supabase
    // Implementation depends on record type
    return {};
  }
  
  String _getTableName(dynamic record) {
    // Get table name from record type
    return '';
  }
  
  bool _hasConflict(dynamic record, Map<String, dynamic> remoteRecord, SyncConflictResolution rule) {
    // Check if there's a conflict based on timestamps and rule
    return false;
  }
  
  Future<void> _markRecordAsSynced(dynamic record, String remoteId) async {
    // Update local record sync status
  }
  
  Future<void> _markRecordAsConflicted(dynamic record) async {
    // Mark record as conflicted
  }
  
  Future<void> _updateLocalRecord(String tableName, Map<String, dynamic> data) async {
    // Update local record with remote data
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
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, int> syncedCounts;
  
  SyncResult.success({
    this.syncedCounts = const {},
  }) : success = true, error = null, timestamp = DateTime.now();
  
  SyncResult.failure(this.error, {
    this.syncedCounts = const {},
  }) : success = false, timestamp = DateTime.now();
  
  @override
  String toString() {
    if (success) {
      return '✅ Sync successful at $timestamp. Records: ${syncedCounts.toString()}';
    } else {
      return '❌ Sync failed at $timestamp. Error: $error';
    }
  }
}
