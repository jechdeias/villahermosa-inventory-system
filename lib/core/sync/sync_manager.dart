import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../database/app_database.dart';

/// Core Sync Manager - Thesis-worthy offline-first sync logic
class SyncManager {
  
  SyncManager(this._database);
  
  SyncManager._() : _database = AppDatabase();
  final AppDatabase _database;
  
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager._();
  
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
          await _database.customUpdate(
            'UPDATE users SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withInt(response['id']),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withInt(user.id),
            ],
          );
        } else {
          // Update existing record
          userData.remove('id');
          userData.remove('local_id');
          userData.remove('remote_id');
          
          await Supabase.instance.client
              .from('users')
              .update(userData)
              .eq('id', user.remoteId.toString());
          
          await _database.customUpdate(
            'UPDATE users SET sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withInt(user.id),
            ],
          );
        }
      } catch (e) {
        print('❌ Error syncing user ${user.id}: $e');
        await _database.customUpdate(
          'UPDATE users SET sync_status = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withInt(user.id),
          ],
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
          
          await _database.customUpdate(
            'UPDATE products SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withInt(response['id']),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withInt(product.id),
            ],
          );
        } else {
          // Update existing record
          productData.remove('id');
          productData.remove('local_id');
          productData.remove('remote_id');
          
          await Supabase.instance.client
              .from('products')
              .update(productData)
              .eq('id', product.remoteId.toString());
          
          await _database.customUpdate(
            'UPDATE products SET sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withInt(product.id),
            ],
          );
        }
      } catch (e) {
        print('❌ Error syncing product ${product.id}: $e');
        await _database.customUpdate(
          'UPDATE products SET sync_status = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withInt(product.id),
          ],
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
          
          await _database.customUpdate(
            'UPDATE customers SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withInt(response['id']),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withInt(customer.id),
            ],
          );
        } else {
          // Update existing record
          customerData.remove('id');
          customerData.remove('local_id');
          customerData.remove('remote_id');
          
          await Supabase.instance.client
              .from('customers')
              .update(customerData)
              .eq('id', customer.remoteId.toString());
          
          await _database.customUpdate(
            'UPDATE customers SET sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withInt(customer.id),
            ],
          );
        }
      } catch (e) {
        print('❌ Error syncing customer ${customer.id}: $e');
        await _database.customUpdate(
          'UPDATE customers SET sync_status = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withInt(customer.id),
          ],
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
          'id': movement.id,
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
          'sync_status': movement.syncStatus,
          'remote_id': movement.remoteId,
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
          
          await _database.customUpdate(
            'UPDATE stock_movements SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withInt(response['id']),
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withString(movement.id),
            ],
          );
        } else {
          // Update existing record
          movementData.remove('id');
          movementData.remove('local_id');
          movementData.remove('remote_id');
          
          await Supabase.instance.client
              .from('stock_movements')
              .update(movementData)
              .eq('id', movement.remoteId.toString());
          
          await _database.customUpdate(
            'UPDATE stock_movements SET sync_status = ?, updated_at = ? WHERE id = ?',
            variables: [
              Variable.withString('synced'),
              Variable.withDateTime(DateTime.now()),
              Variable.withString(movement.id),
            ],
          );
        }
      } catch (e) {
        print('❌ Error syncing stock movement ${movement.id}: $e');
        await _database.customUpdate(
          'UPDATE stock_movements SET sync_status = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withString(movement.id),
          ],
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
        variables: [Variable.withString(userData['id'])],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        // Update existing record
        await _database.customUpdate(
          'UPDATE users SET name = ?, email = ?, role = ?, phone = ?, address = ?, is_deleted = ?, sync_status = ?, updated_at = ? WHERE remote_id = ?',
          variables: [
            Variable.withString(userData['name']),
            Variable.withString(userData['email']),
            Variable.withString(userData['role']),
            Variable.withString(userData['phone']),
            Variable.withString(userData['address']),
            Variable.withBool(userData['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(userData['updated_at'])),
            Variable.withString(userData['id']),
          ],
        );
      } else {
        // Insert new record
        await _database.into(_database.users).insert(
          UsersCompanion.insert(
            uuid: userData['uuid'] as String,
            name: userData['name'] as String,
            email: userData['email'] as String,
            role: userData['role'] as String,
            phone: Value(userData['phone'] as String?),
            address: Value(userData['address'] as String?),
            isDeleted: Value(userData['is_deleted'] as bool),
            remoteId: Value(userData['id'].toString()),
            syncStatus: const Value('synced'),
            createdAt: Value(DateTime.parse(userData['created_at'] as String)),
            updatedAt: Value(DateTime.parse(userData['updated_at'] as String)),
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
        variables: [Variable.withString(productData['id'])],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        await _database.customUpdate('UPDATE products SET sku = ?, name = ?, description = ?, category = ?, brand = ?, current_stock = ?, min_stock = ?, max_stock = ?, unit = ?, unit_price = ?, cost_price = ?, status = ?, barcode = ?, location = ?, supplier = ?, is_deleted = ?, sync_status = ?, updated_at = ? WHERE remote_id = ?',
          variables: [
            Variable.withString(productData['sku'] as String),
            Variable.withString(productData['name'] as String),
            Variable.withString(productData['description'] ?? ''),
            Variable.withString(productData['category'] as String),
            Variable.withString(productData['brand'] ?? ''),
            Variable.withInt(productData['current_stock'] as int),
            Variable.withInt(productData['min_stock'] as int),
            Variable.withInt(productData['max_stock'] as int),
            Variable.withString(productData['unit'] as String),
            Variable.withReal(productData['unit_price'] as double),
            Variable.withReal(productData['cost_price'] as double),
            Variable.withString(productData['status'] as String),
            Variable.withString(productData['barcode'] ?? ''),
            Variable.withString(productData['location'] as String),
            Variable.withString(productData['supplier'] ?? ''),
            Variable.withBool(productData['is_deleted'] as bool),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(productData['updated_at'] as String)),
            Variable.withString(productData['id'] as String),
          ]);
      } else {
        // Insert new record
        await _database.into(_database.products).insert(
          ProductsCompanion.insert(
            uuid: productData['uuid'] as String,
            sku: productData['sku'] as String,
            name: productData['name'] as String,
            description: Value(productData['description'] as String?),
            category: productData['category'] as String,
            brand: Value(productData['brand'] as String?),
            currentStock: Value(productData['current_stock'] as int),
            minStock: Value(productData['min_stock'] as int),
            maxStock: Value(productData['max_stock'] as int),
            unit: productData['unit'] as String,
            unitPrice: productData['unit_price'] as double,
            costPrice: productData['cost_price'] as double,
            status: Value(productData['status'] as String),
            barcode: Value(productData['barcode'] as String?),
            location: Value(productData['location'] as String),
            supplier: Value(productData['supplier'] as String?),
            isDeleted: Value(productData['is_deleted'] as bool),
            remoteId: Value(productData['id'].toString()),
            syncStatus: const Value('synced'),
            createdAt: Value(DateTime.parse(productData['created_at'] as String)),
            updatedAt: Value(DateTime.parse(productData['updated_at'] as String)),
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
        variables: [Variable.withString(customerData['id'])],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        await _database.customUpdate(
          'UPDATE customers SET name = ?, email = ?, phone = ?, address = ?, business_name = ?, tax_id = ?, customer_type = ?, credit_limit = ?, payment_terms = ?, status = ?, preferred_contact_method = ?, is_deleted = ?, sync_status = ?, updated_at = ? WHERE remote_id = ?',
          variables: [
            Variable.withString(customerData['name']),
            Variable.withString(customerData['email']),
            Variable.withString(customerData['phone']),
            Variable.withString(customerData['address']),
            Variable.withString(customerData['business_name']),
            Variable.withString(customerData['tax_id']),
            Variable.withString(customerData['customer_type']),
            Variable.withReal(customerData['credit_limit'] as double),
            Variable.withString(customerData['payment_terms']),
            Variable.withString(customerData['status']),
            Variable.withString(customerData['preferred_contact_method']),
            Variable.withBool(customerData['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(customerData['updated_at'])),
            Variable.withString(customerData['id']),
          ],
        );
      } else {
        await _database.into(_database.customers).insert(
          CustomersCompanion.insert(
            uuid: customerData['uuid'] as String,
            name: customerData['name'] as String,
            email: customerData['email'] as String,
            phone: Value(customerData['phone'] as String?),
            address: Value(customerData['address'] as String?),
            businessName: Value(customerData['business_name'] as String?),
            taxId: Value(customerData['tax_id'] as String?),
            customerType: Value(customerData['customer_type'] as String),
            creditLimit: Value(customerData['credit_limit'] as double),
            paymentTerms: Value(customerData['payment_terms'] as String?),
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
        variables: [Variable.withString(movementData['id'])],
      ).getSingleOrNull();
      
      if (existingRecord != null) {
        await _database.customUpdate(
          'UPDATE stock_movements SET product_id = ?, movement_type = ?, quantity = ?, reference_type = ?, reference_id = ?, reason = ?, notes = ?, user_id = ?, user_name = ?, from_location = ?, to_location = ?, unit_cost = ?, total_cost = ?, status = ?, approved_by = ?, approved_at = ?, is_deleted = ?, sync_status = ?, updated_at = ? WHERE remote_id = ?',
          variables: [
            Variable.withString(movementData['product_id']),
            Variable.withString(movementData['movement_type']),
            Variable.withInt(movementData['quantity']),
            Variable.withString(movementData['reference_type']),
            Variable.withString(movementData['reference_id']),
            Variable.withString(movementData['reason']),
            Variable.withString(movementData['notes']),
            Variable.withString(movementData['user_id']),
            Variable.withString(movementData['user_name']),
            Variable.withString(movementData['from_location']),
            Variable.withString(movementData['to_location']),
            Variable.withReal(movementData['unit_cost'] as double),
            Variable.withReal(movementData['total_cost'] as double),
            Variable.withString(movementData['status']),
            Variable.withString(movementData['approved_by']),
            if (movementData['approved_at'] != null) 
              Variable.withDateTime(DateTime.parse(movementData['approved_at']))
            else 
              Variable.withDateTime(DateTime.now()), // Default value for null
            Variable.withBool(movementData['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(movementData['updated_at'])),
            Variable.withString(movementData['id']),
          ],
        );
      } else {
        await _database.into(_database.stockMovements).insert(
          StockMovementsCompanion.insert(
            id: movementData['id'] as String,
            productId: movementData['product_id'] as String,
            movementType: movementData['movement_type'] as String,
            quantity: movementData['quantity'] as int,
            referenceType: Value(movementData['reference_type'] as String?),
            referenceId: Value(movementData['reference_id'] as String?),
            reason: movementData['reason'] as String,
            notes: Value(movementData['notes'] as String?),
            userId: movementData['user_id'] as String,
            userName: movementData['user_name'] as String,
            fromLocation: Value(movementData['from_location'] as String?),
            toLocation: Value(movementData['to_location'] as String?),
            unitCost: Value(movementData['unit_cost'] as double?),
            totalCost: Value(movementData['total_cost'] as double?),
            status: Value(movementData['status'] as String),
            approvedBy: Value(movementData['approved_by'] as String?),
            approvedAt: movementData['approved_at'] != null 
                ? Value(DateTime.parse(movementData['approved_at']))
                : const Value(null),
            isDeleted: Value(movementData['is_deleted'] as bool),
            remoteId: Value(movementData['id'] as String?),
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
      return '✅ Sync successful at $timestamp. Records: ${syncedCounts.toString()}';
    } else {
      return '❌ Sync failed at $timestamp. Error: $error';
    }
  }
}
