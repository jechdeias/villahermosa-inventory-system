import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../database/app_database.dart';
import 'sync_engine.dart';

/// Concrete implementation of SyncEngine with real record conversion
class SyncEngineImpl extends SyncEngine {
  SyncEngineImpl(super.database);

  @override
  Map<String, dynamic> _recordToMap(dynamic record) {
    if (record is User) {
      return {
        'uuid': record.uuid,
        'name': record.name,
        'email': record.email,
        'role': record.role,
        'phone': record.phone,
        'address': record.address,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Product) {
      return {
        'uuid': record.uuid,
        'sku': record.sku,
        'name': record.name,
        'description': record.description,
        'category': record.category,
        'brand': record.brand,
        'current_stock': record.currentStock,
        'min_stock': record.minStock,
        'max_stock': record.maxStock,
        'unit': record.unit,
        'unit_price': record.unitPrice,
        'cost_price': record.costPrice,
        'status': record.status,
        'barcode': record.barcode,
        'location': record.location,
        'supplier': record.supplier,
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Customer) {
      return {
        'uuid': record.uuid,
        'name': record.name,
        'email': record.email,
        'phone': record.phone,
        'address': record.address,
        'business_name': record.businessName,
        'tax_id': record.taxId,
        'customer_type': record.customerType,
        'credit_limit': record.creditLimit,
        'payment_terms': record.paymentTerms,
        'status': record.status,
        'preferred_contact_method': record.preferredContactMethod,
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
        'reference_type': record.referenceType,
        'reference_id': record.referenceId,
        'reason': record.reason,
        'notes': record.notes,
        'user_id': record.userId,
        'user_name': record.userName,
        'from_location': record.fromLocation,
        'to_location': record.toLocation,
        'unit_cost': record.unitCost,
        'total_cost': record.totalCost,
        'status': record.status,
        'approved_by': record.approvedBy,
        'approved_at': record.approvedAt?.toIso8601String(),
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    // Add other record types as needed
    return {};
  }

  @override
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

  @override
  bool _hasConflict(dynamic record, Map<String, dynamic> remoteRecord, SyncConflictResolution rule) {
    if (rule == SyncConflictResolution.lastWriteWins) {
      final localUpdatedAt = DateTime.parse(record.updatedAt.toString());
      final remoteUpdatedAt = DateTime.parse(remoteRecord['updated_at']);
      return localUpdatedAt != remoteUpdatedAt;
    }
    return false;
  }

  @override
  Future<void> _markRecordAsSynced(dynamic record, String remoteId) async {
    final tableName = _getTableName(record);
    
    switch (tableName) {
      case 'users':
        await database.customUpdate(
          'UPDATE users SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'products':
        await database.customUpdate(
          'UPDATE products SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'customers':
        await database.customUpdate(
          'UPDATE customers SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'stock_movements':
        await database.customUpdate(
          'UPDATE stock_movements SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
    }
  }

  @override
  Future<void> _markRecordAsConflicted(dynamic record) async {
    final tableName = _getTableName(record);
    
    switch (tableName) {
      case 'users':
        await database.customUpdate(
          'UPDATE users SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'products':
        await database.customUpdate(
          'UPDATE products SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'customers':
        await database.customUpdate(
          'UPDATE customers SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'stock_movements':
        await database.customUpdate(
          'UPDATE stock_movements SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
    }
  }

  @override
  Future<void> _updateLocalRecord(String tableName, Map<String, dynamic> data) async {
    switch (tableName) {
      case 'users':
        await database.customUpdate(
          '''UPDATE users SET name = ?, email = ?, role = ?, phone = ?, 
              address = ?, is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['name']),
            Variable.withString(data['email']),
            Variable.withString(data['role']),
            Variable.withString(data['phone']),
            Variable.withString(data['address']),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'products':
        await database.customUpdate(
          '''UPDATE products SET sku = ?, name = ?, description = ?, category = ?, 
              brand = ?, current_stock = ?, min_stock = ?, max_stock = ?, unit = ?, 
              unit_price = ?, cost_price = ?, status = ?, barcode = ?, location = ?, 
              supplier = ?, is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['sku']),
            Variable.withString(data['name']),
            Variable.withString(data['description']),
            Variable.withString(data['category']),
            Variable.withString(data['brand']),
            Variable.withInt(data['current_stock']),
            Variable.withInt(data['min_stock']),
            Variable.withInt(data['max_stock']),
            Variable.withString(data['unit']),
            Variable.withReal(data['unit_price']),
            Variable.withReal(data['cost_price']),
            Variable.withString(data['status']),
            Variable.withString(data['barcode']),
            Variable.withString(data['location']),
            Variable.withString(data['supplier']),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'customers':
        await database.customUpdate(
          '''UPDATE customers SET name = ?, email = ?, phone = ?, address = ?, 
              business_name = ?, tax_id = ?, customer_type = ?, credit_limit = ?, 
              payment_terms = ?, status = ?, preferred_contact_method = ?, 
              is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['name']),
            Variable.withString(data['email']),
            Variable.withString(data['phone']),
            Variable.withString(data['address']),
            Variable.withString(data['business_name']),
            Variable.withString(data['tax_id']),
            Variable.withString(data['customer_type']),
            Variable.withReal(data['credit_limit']),
            Variable.withString(data['payment_terms']),
            Variable.withString(data['status']),
            Variable.withString(data['preferred_contact_method']),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'stock_movements':
        await database.customUpdate(
          '''UPDATE stock_movements SET product_id = ?, movement_type = ?, quantity = ?, 
              reference_type = ?, reference_id = ?, reason = ?, notes = ?, user_id = ?, 
              user_name = ?, from_location = ?, to_location = ?, unit_cost = ?, 
              total_cost = ?, status = ?, approved_by = ?, approved_at = ?, 
              is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['product_id']),
            Variable.withString(data['movement_type']),
            Variable.withInt(data['quantity']),
            Variable.withString(data['reference_type']),
            Variable.withString(data['reference_id']),
            Variable.withString(data['reason']),
            Variable.withString(data['notes']),
            Variable.withString(data['user_id']),
            Variable.withString(data['user_name']),
            Variable.withString(data['from_location']),
            Variable.withString(data['to_location']),
            Variable.withReal(data['unit_cost']),
            Variable.withReal(data['total_cost']),
            Variable.withString(data['status']),
            Variable.withString(data['approved_by']),
            data['approved_at'] != null 
                ? Variable.withDateTime(DateTime.parse(data['approved_at']))
                : const Variable(null),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
    }
  }

  @override
  Future<void> _pullUsers(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final userData in response) {
      await _updateLocalRecord('users', userData);
    }
  }

  @override
  Future<void> _pullProducts(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final productData in response) {
      await _updateLocalRecord('products', productData);
    }
  }

  @override
  Future<void> _pullCustomers(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('customers')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final customerData in response) {
      await _updateLocalRecord('customers', customerData);
    }
  }

  @override
  Future<void> _pullStockMovements(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('stock_movements')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final movementData in response) {
      await _updateLocalRecord('stock_movements', movementData);
    }
  }

  @override
  Future<void> _pullOrders(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('orders')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final orderData in response) {
      await _updateLocalRecord('orders', orderData);
    }
  }

  @override
  Future<void> _pullOrderItems(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('order_items')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final itemData in response) {
      await _updateLocalRecord('order_items', itemData);
    }
  }

  @override
  Future<void> _pullDeliveries(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('deliveries')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final deliveryData in response) {
      await _updateLocalRecord('deliveries', deliveryData);
    }
  }

  @override
  Future<void> _pullCategories(DateTime lastSyncTime) async {
    final response = await Supabase.instance.client
        .from('categories')
        .select()
        .gte('updated_at', lastSyncTime.toIso8601String());
    
    for (final categoryData in response) {
      await _updateLocalRecord('categories', categoryData);
    }
  }
}
