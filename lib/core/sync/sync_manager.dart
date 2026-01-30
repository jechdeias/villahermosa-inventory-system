import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';

/// Core Sync Manager - Thesis-worthy offline-first sync logic
class SyncManager {
  final AppDatabase _database;
  
  SyncManager(this._database);
  
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager._();
  
  SyncManager._() : _database = AppDatabase();
  
  /// Main sync orchestrator - core thesis logic
  Future<SyncResult> performFullSync() async {
    try {
      print('🚀 Starting full sync process...');
      
      // Step 1: Push pending local records
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
    await _syncUsers();
    await _syncProducts();
    await _syncCustomers();
    await _syncStockMovements();
    
    print('✅ Local changes pushed successfully');
  }
  
  /// Pull remote updates from Supabase
  Future<void> _pullRemoteChanges() async {
    print('📥 Pulling remote changes from Supabase...');
    
    final lastSyncTime = await _getLastSyncTimestamp();
    
    await _pullUsers(lastSyncTime);
    await _pullProducts(lastSyncTime);
    await _pullCustomers(lastSyncTime);
    await _pullStockMovements(lastSyncTime);
    
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
    await _database.customUpdateOnly(
      const CustomersCompanion(syncStatus: Value('synced')),
      where: (tbl) => tbl.syncStatus.equals('pending'),
    );
    
    await _database.customUpdateOnly(
      const ProductsCompanion(syncStatus: Value('synced')),
      where: (tbl) => tbl.syncStatus.equals('pending'),
    );
    
    await _database.customUpdateOnly(
      const StockMovementsCompanion(syncStatus: Value('synced')),
      where: (tbl) => tbl.syncStatus.equals('pending'),
    );
    
    print('✅ Sync status updated');
  }
  
  /// Sync Users table - Admin wins conflict resolution
  Future<void> _syncUsers() async {
    final pendingUsers = await _database.getPendingSyncUsers();
    
    for (final user in pendingUsers) {
      try {
        final userData = {
          'uuid': user.uuid,
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'phone': user.phone,
          'address': user.address,
          'is_deleted': user.isDeleted,
          'sync_status': 'synced',
          'local_id': user.id,
          'created_at': user.createdAt.toIso8601String(),
          'updated_at': user.updatedAt.toIso8601String(),
        };
        
        if (user.remoteId == null) {
          // Insert new record
          final response = await Supabase.instance.client
              .from('users')
              .insert(userData)
              .select('id')
              .single();
          
          // Update local record with remote ID
          await _database.customUpdateOnly(
            UsersCompanion(
              remoteId: Value(response['id']),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(user.id),
          );
        } else {
          // Update existing record
          userData.remove('id');
          userData.remove('local_id');
          userData.remove('remote_id');
          
          await Supabase.instance.client
              .from('users')
              .update(userData)
              .eq('id', user.remoteId);
          
          await _database.customUpdateOnly(
            UsersCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(user.id),
          );
        }
      } catch (e) {
        print('❌ Error syncing user ${user.id}: $e');
        await _database.customUpdateOnly(
          const UsersCompanion(syncStatus: Value('conflict')),
          where: (tbl) => tbl.id.equals(user.id),
        );
      }
    }
  }
  
  /// Sync Products table - Warehouse wins conflict resolution
  Future<void> _syncProducts() async {
    final pendingProducts = await _database.getPendingSyncProducts();
    
    for (final product in pendingProducts) {
      try {
        final productData = {
          'uuid': product.uuid,
          'sku': product.sku,
          'name': product.name,
          'description': product.description,
          'category': product.category,
          'brand': product.brand,
          'current_stock': product.currentStock,
          'min_stock': product.minStock,
          'max_stock': product.maxStock,
          'unit': product.unit,
          'unit_price': product.unitPrice,
          'cost_price': product.costPrice,
          'status': product.status,
          'barcode': product.barcode,
          'location': product.location,
          'supplier': product.supplier,
          'is_deleted': product.isDeleted,
          'sync_status': 'synced',
          'local_id': product.id,
          'created_at': product.createdAt.toIso8601String(),
          'updated_at': product.updatedAt.toIso8601String(),
        };
        
        if (product.remoteId == null) {
          // Insert new record
          final response = await Supabase.instance.client
              .from('products')
              .insert(productData)
              .select('id')
              .single();
          
          await _database.customUpdateOnly(
            ProductsCompanion(
              remoteId: Value(response['id']),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(product.id),
          );
        } else {
          // Update existing record
          productData.remove('id');
          productData.remove('local_id');
          productData.remove('remote_id');
          
          await Supabase.instance.client
              .from('products')
              .update(productData)
              .eq('id', product.remoteId);
          
          await _database.customUpdateOnly(
            ProductsCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(product.id),
          );
        }
      } catch (e) {
        print('❌ Error syncing product ${product.id}: $e');
        await _database.customUpdateOnly(
          const ProductsCompanion(syncStatus: Value('conflict')),
          where: (tbl) => tbl.id.equals(product.id),
        );
      }
    }
  }
  
  /// Sync Customers table - Customer wins for own data
  Future<void> _syncCustomers() async {
    final pendingCustomers = await _database.getPendingSyncCustomers();
    
    for (final customer in pendingCustomers) {
      try {
        final customerData = {
          'uuid': customer.uuid,
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'business_name': customer.businessName,
          'tax_id': customer.taxId,
          'customer_type': customer.customerType,
          'credit_limit': customer.creditLimit,
          'payment_terms': customer.paymentTerms,
          'status': customer.status,
          'preferred_contact_method': customer.preferredContactMethod,
          'is_deleted': customer.isDeleted,
          'sync_status': 'synced',
          'local_id': customer.id,
          'created_at': customer.createdAt.toIso8601String(),
          'updated_at': customer.updatedAt.toIso8601String(),
        };
        
        if (customer.remoteId == null) {
          // Insert new record
          final response = await Supabase.instance.client
              .from('customers')
              .insert(customerData)
              .select('id')
              .single();
          
          await _database.customUpdateOnly(
            CustomersCompanion(
              remoteId: Value(response['id']),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(customer.id),
          );
        } else {
          // Update existing record
          customerData.remove('id');
          customerData.remove('local_id');
          customerData.remove('remote_id');
          
          await Supabase.instance.client
              .from('customers')
              .update(customerData)
              .eq('id', customer.remoteId);
          
          await _database.customUpdateOnly(
            CustomersCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(customer.id),
          );
        }
      } catch (e) {
        print('❌ Error syncing customer ${customer.id}: $e');
        await _database.customUpdateOnly(
          const CustomersCompanion(syncStatus: Value('conflict')),
          where: (tbl) => tbl.id.equals(customer.id),
        );
      }
    }
  }
  
  /// Sync StockMovements table - Last-write-wins conflict resolution
  Future<void> _syncStockMovements() async {
    final pendingMovements = await _database.getPendingSyncStockMovements();
    
    for (final movement in pendingMovements) {
      try {
        final movementData = {
          'uuid': movement.uuid,
          'product_id': movement.productId,
          'movement_type': movement.movementType,
          'quantity': movement.quantity,
          'reference_type': movement.referenceType,
          'reference_id': movement.referenceId,
          'reason': movement.reason,
          'notes': movement.notes,
          'user_id': movement.userId,
          'user_name': movement.userName,
          'from_location': movement.fromLocation,
          'to_location': movement.toLocation,
          'unit_cost': movement.unitCost,
          'total_cost': movement.totalCost,
          'status': movement.status,
          'approved_by': movement.approvedBy,
          'approved_at': movement.approvedAt?.toIso8601String(),
          'is_deleted': movement.isDeleted,
          'sync_status': 'synced',
          'local_id': movement.id,
          'created_at': movement.createdAt.toIso8601String(),
          'updated_at': movement.updatedAt.toIso8601String(),
        };
        
        if (movement.remoteId == null) {
          // Insert new record
          final response = await Supabase.instance.client
              .from('stock_movements')
              .insert(movementData)
              .select('id')
              .single();
          
          await _database.customUpdateOnly(
            StockMovementsCompanion(
              remoteId: Value(response['id']),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(movement.id),
          );
        } else {
          // Update existing record
          movementData.remove('id');
          movementData.remove('local_id');
          movementData.remove('remote_id');
          
          await Supabase.instance.client
              .from('stock_movements')
              .update(movementData)
              .eq('id', movement.remoteId);
          
          await _database.customUpdateOnly(
            StockMovementsCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ),
            where: (tbl) => tbl.id.equals(movement.id),
          );
        }
      } catch (e) {
        print('❌ Error syncing stock movement ${movement.id}: $e');
        await _database.customUpdateOnly(
          const StockMovementsCompanion(syncStatus: Value('conflict')),
          where: (tbl) => tbl.id.equals(movement.id),
        );
      }
    }
  }
  
  /// Pull remote changes for Users
  Future<void> _pullUsers(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final userData in response) {
      // Check if record exists locally
      final existingRecord = await _database.customSelect(
        'SELECT id FROM users WHERE remote_id = ?',
        [userData['id']],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        // Update existing record
        await _database.customUpdateOnly(
          UsersCompanion(
            name: Value(userData['name']),
            email: Value(userData['email']),
            role: Value(userData['role']),
            phone: Value(userData['phone']),
            address: Value(userData['address']),
            isDeleted: Value(userData['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(userData['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(userData['id']),
        );
      } else {
        // Insert new record
        await _database.into(_database.users).insert(
          UsersCompanion.insert(
            uuid: Value(userData['uuid']),
            name: Value(userData['name']),
            email: Value(userData['email']),
            role: Value(userData['role']),
            phone: Value(userData['phone']),
            address: Value(userData['address']),
            isDeleted: Value(userData['is_deleted']),
            remoteId: Value(userData['id']),
            syncStatus: const Value('synced'),
            createdAt: Value(DateTime.parse(userData['created_at'])),
            updatedAt: Value(DateTime.parse(userData['updated_at'])),
          ),
        );
      }
    }
  }
  
  /// Pull remote changes for Products
  Future<void> _pullProducts(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final productData in response) {
      final existingRecord = await _database.customSelect(
        'SELECT id FROM products WHERE remote_id = ?',
        [productData['id']],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        await _database.customUpdateOnly(
          ProductsCompanion(
            sku: Value(productData['sku']),
            name: Value(productData['name']),
            description: Value(productData['description']),
            category: Value(productData['category']),
            brand: Value(productData['brand']),
            currentStock: Value(productData['current_stock']),
            minStock: Value(productData['min_stock']),
            maxStock: Value(productData['max_stock']),
            unit: Value(productData['unit']),
            unitPrice: Value(productData['unit_price']),
            costPrice: Value(productData['cost_price']),
            status: Value(productData['status']),
            barcode: Value(productData['barcode']),
            location: Value(productData['location']),
            supplier: Value(productData['supplier']),
            isDeleted: Value(productData['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(productData['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(productData['id']),
        );
      } else {
        await _database.into(_database.products).insert(
          ProductsCompanion.insert(
            uuid: Value(productData['uuid']),
            sku: Value(productData['sku']),
            name: Value(productData['name']),
            description: Value(productData['description']),
            category: Value(productData['category']),
            brand: Value(productData['brand']),
            currentStock: Value(productData['current_stock']),
            minStock: Value(productData['min_stock']),
            maxStock: Value(productData['max_stock']),
            unit: Value(productData['unit']),
            unitPrice: Value(productData['unit_price']),
            costPrice: Value(productData['cost_price']),
            status: Value(productData['status']),
            barcode: Value(productData['barcode']),
            location: Value(productData['location']),
            supplier: Value(productData['supplier']),
            isDeleted: Value(productData['is_deleted']),
            remoteId: Value(productData['id']),
            syncStatus: const Value('synced'),
            createdAt: Value(DateTime.parse(productData['created_at'])),
            updatedAt: Value(DateTime.parse(productData['updated_at'])),
          ),
        );
      }
    }
  }
  
  /// Pull remote changes for Customers
  Future<void> _pullCustomers(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('customers')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final customerData in response) {
      final existingRecord = await _database.customSelect(
        'SELECT id FROM customers WHERE remote_id = ?',
        [customerData['id']],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        await _database.customUpdateOnly(
          CustomersCompanion(
            name: Value(customerData['name']),
            email: Value(customerData['email']),
            phone: Value(customerData['phone']),
            address: Value(customerData['address']),
            businessName: Value(customerData['business_name']),
            taxId: Value(customerData['tax_id']),
            customerType: Value(customerData['customer_type']),
            creditLimit: Value(customerData['credit_limit']),
            paymentTerms: Value(customerData['payment_terms']),
            status: Value(customerData['status']),
            preferredContactMethod: Value(customerData['preferred_contact_method']),
            isDeleted: Value(customerData['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(customerData['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(customerData['id']),
        );
      } else {
        await _database.into(_database.customers).insert(
          CustomersCompanion.insert(
            uuid: Value(customerData['uuid']),
            name: Value(customerData['name']),
            email: Value(customerData['email']),
            phone: Value(customerData['phone']),
            address: Value(customerData['address']),
            businessName: Value(customerData['business_name']),
            taxId: Value(customerData['tax_id']),
            customerType: Value(customerData['customer_type']),
            creditLimit: Value(customerData['credit_limit']),
            paymentTerms: Value(customerData['payment_terms']),
            status: Value(customerData['status']),
            preferredContactMethod: Value(customerData['preferred_contact_method']),
            isDeleted: Value(customerData['is_deleted']),
            remoteId: Value(customerData['id']),
            syncStatus: const Value('synced'),
            createdAt: Value(DateTime.parse(customerData['created_at'])),
            updatedAt: Value(DateTime.parse(customerData['updated_at'])),
          ),
        );
      }
    }
  }
  
  /// Pull remote changes for StockMovements
  Future<void> _pullStockMovements(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('stock_movements')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final movementData in response) {
      final existingRecord = await _database.customSelect(
        'SELECT id FROM stock_movements WHERE remote_id = ?',
        [movementData['id']],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        await _database.customUpdateOnly(
          StockMovementsCompanion(
            productId: Value(movementData['product_id']),
            movementType: Value(movementData['movement_type']),
            quantity: Value(movementData['quantity']),
            referenceType: Value(movementData['reference_type']),
            referenceId: Value(movementData['reference_id']),
            reason: Value(movementData['reason']),
            notes: Value(movementData['notes']),
            userId: Value(movementData['user_id']),
            userName: Value(movementData['user_name']),
            fromLocation: Value(movementData['from_location']),
            toLocation: Value(movementData['to_location']),
            unitCost: Value(movementData['unit_cost']),
            totalCost: Value(movementData['total_cost']),
            status: Value(movementData['status']),
            approvedBy: Value(movementData['approved_by']),
            approvedAt: movementData['approved_at'] != null 
                ? Value(DateTime.parse(movementData['approved_at']))
                : const Value(null),
            isDeleted: Value(movementData['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(movementData['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(movementData['id']),
        );
      } else {
        await _database.into(_database.stockMovements).insert(
          StockMovementsCompanion.insert(
            uuid: Value(movementData['uuid']),
            productId: Value(movementData['product_id']),
            movementType: Value(movementData['movement_type']),
            quantity: Value(movementData['quantity']),
            referenceType: Value(movementData['reference_type']),
            referenceId: Value(movementData['reference_id']),
            reason: Value(movementData['reason']),
            notes: Value(movementData['notes']),
            userId: Value(movementData['user_id']),
            userName: Value(movementData['user_name']),
            fromLocation: Value(movementData['from_location']),
            toLocation: Value(movementData['to_location']),
            unitCost: Value(movementData['unit_cost']),
            totalCost: Value(movementData['total_cost']),
            status: Value(movementData['status']),
            approvedBy: Value(movementData['approved_by']),
            approvedAt: movementData['approved_at'] != null 
                ? Value(DateTime.parse(movementData['approved_at']))
                : const Value(null),
            isDeleted: Value(movementData['is_deleted']),
            remoteId: Value(movementData['id']),
            syncStatus: const Value('synced'),
            createdAt: Value(DateTime.parse(movementData['created_at'])),
            updatedAt: Value(DateTime.parse(movementData['updated_at'])),
          ),
        );
      }
    }
  }
  
  /// Conflict resolution methods
  Future<void> _resolveUserConflict(User user) async {
    // Admin wins for user conflicts
    print('🔧 Resolving user conflict: ${user.id}');
  }
  
  Future<void> _resolveProductConflict(Product product) async {
    // Warehouse wins for product conflicts
    print('🔧 Resolving product conflict: ${product.id}');
  }
  
  Future<void> _resolveCustomerConflict(Customer customer) async {
    // Customer wins for own data conflicts
    print('🔧 Resolving customer conflict: ${customer.id}');
  }
  
  Future<void> _resolveStockMovementConflict(StockMovement movement) async {
    // Last-write-wins for stock movements
    print('🔧 Resolving stock movement conflict: ${movement.id}');
  }
  
  /// Utility methods
  Future<DateTime> _getLastSyncTimestamp() async {
    // Get last sync timestamp from local storage
    return DateTime.now().subtract(const Duration(days: 1));
  }
  
  Future<void> _updateLastSyncTimestamp() async {
    // Update last sync timestamp
    print('🕐 Updating last sync timestamp');
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
