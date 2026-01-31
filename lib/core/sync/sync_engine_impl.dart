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
        await database.customUpdateOnly(
          UsersCompanion(
            name: Value(data['name']),
            email: Value(data['email']),
            role: Value(data['role']),
            phone: Value(data['phone']),
            address: Value(data['address']),
            isDeleted: Value(data['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(data['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(data['id']),
        );
        break;
      case 'products':
        await database.customUpdateOnly(
          ProductsCompanion(
            sku: Value(data['sku']),
            name: Value(data['name']),
            description: Value(data['description']),
            category: Value(data['category']),
            brand: Value(data['brand']),
            currentStock: Value(data['current_stock']),
            minStock: Value(data['min_stock']),
            maxStock: Value(data['max_stock']),
            unit: Value(data['unit']),
            unitPrice: Value(data['unit_price']),
            costPrice: Value(data['cost_price']),
            status: Value(data['status']),
            barcode: Value(data['barcode']),
            location: Value(data['location']),
            supplier: Value(data['supplier']),
            isDeleted: Value(data['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(data['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(data['id']),
        );
        break;
      case 'customers':
        await database.customUpdateOnly(
          CustomersCompanion(
            name: Value(data['name']),
            email: Value(data['email']),
            phone: Value(data['phone']),
            address: Value(data['address']),
            businessName: Value(data['business_name']),
            taxId: Value(data['tax_id']),
            customerType: Value(data['customer_type']),
            creditLimit: Value(data['credit_limit']),
            paymentTerms: Value(data['payment_terms']),
            status: Value(data['status']),
            preferredContactMethod: Value(data['preferred_contact_method']),
            isDeleted: Value(data['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(data['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(data['id']),
        );
        break;
      case 'stock_movements':
        await database.customUpdateOnly(
          StockMovementsCompanion(
            productId: Value(data['product_id']),
            movementType: Value(data['movement_type']),
            quantity: Value(data['quantity']),
            referenceType: Value(data['reference_type']),
            referenceId: Value(data['reference_id']),
            reason: Value(data['reason']),
            notes: Value(data['notes']),
            userId: Value(data['user_id']),
            userName: Value(data['user_name']),
            fromLocation: Value(data['from_location']),
            toLocation: Value(data['to_location']),
            unitCost: Value(data['unit_cost']),
            totalCost: Value(data['total_cost']),
            status: Value(data['status']),
            approvedBy: Value(data['approved_by']),
            approvedAt: data['approved_at'] != null 
                ? Value(DateTime.parse(data['approved_at']))
                : const Value(null),
            isDeleted: Value(data['is_deleted']),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.parse(data['updated_at'])),
          ),
          where: (tbl) => tbl.remoteId.equals(data['id']),
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
