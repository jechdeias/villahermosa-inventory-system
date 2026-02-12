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
        'id': record.id,
        'name': record.name,
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
    
    if (record is Order) {
      return {
        'id': record.id,
        'customer_id': record.customerId,
        'sales_rep_id': record.salesRepId,
        'order_date': record.orderDate.toIso8601String(),
        'status': record.status,
        'order_number': record.orderNumber,
        'subtotal': record.subtotal,
        'tax_amount': record.taxAmount,
        'discount_amount': record.discountAmount,
        'total_amount': record.totalAmount,
        'payment_status': record.paymentStatus,
        'delivery_address': record.deliveryAddress,
        'delivery_contact': record.deliveryContact,
        'delivery_phone': record.deliveryPhone,
        'requested_delivery_date': record.requestedDeliveryDate?.toIso8601String(),
        'actual_delivery_date': record.actualDeliveryDate?.toIso8601String(),
        'warehouse_status': record.warehouseStatus,
        'picker_id': record.pickerId,
        'picked_at': record.pickedAt?.toIso8601String(),
        'packer_id': record.packerId,
        'packed_at': record.packedAt?.toIso8601String(),
        'customer_notes': record.customerNotes,
        'internal_notes': record.internalNotes,
        'priority': record.priority,
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
        'product_sku': record.productSku,
        'product_name': record.productName,
        'product_category': record.productCategory,
        'quantity': record.quantity,
        'delivered_quantity': record.deliveredQuantity,
        'unit_price': record.unitPrice,
        'subtotal': record.subtotal,
        'discount_amount': record.discountAmount,
        'total_amount': record.totalAmount,
        'available_stock': record.availableStock,
        'stock_status': record.stockStatus,
        'status': record.status,
        'picker_id': record.pickerId,
        'picked_at': record.pickedAt?.toIso8601String(),
        'notes': record.notes,
        'cancellation_reason': record.cancellationReason,
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
        'delivery_personnel_id': record.deliveryPersonnelId,
        'delivery_personnel_name': record.deliveryPersonnelName,
        'delivery_personnel_phone': record.deliveryPersonnelPhone,
        'delivery_number': record.deliveryNumber,
        'scheduled_date': record.scheduledDate.toIso8601String(),
        'actual_start_time': record.actualStartTime?.toIso8601String(),
        'actual_completion_time': record.actualCompletionTime?.toIso8601String(),
        'status': record.status,
        'sub_status': record.subStatus,
        'route': record.route,
        'route_order': record.routeOrder,
        'vehicle_number': record.vehicleNumber,
        'start_location': record.startLocation,
        'end_location': record.endLocation,
        'start_latitude': record.startLatitude,
        'start_longitude': record.startLongitude,
        'end_latitude': record.endLatitude,
        'end_longitude': record.endLongitude,
        'proof_of_delivery_type': record.proofOfDeliveryType,
        'proof_of_delivery_url': record.proofOfDeliveryUrl,
        'recipient_name': record.recipientName,
        'recipient_relation': record.recipientRelation,
        'delivery_notes': record.deliveryNotes,
        'collected_amount': record.collectedAmount,
        'payment_method': record.paymentMethod,
        'check_number': record.checkNumber,
        'issue_type': record.issueType,
        'issue_description': record.issueDescription,
        'resolution': record.resolution,
        'priority': record.priority,
        'attempt_count': record.attemptCount,
        'next_attempt_date': record.nextAttemptDate?.toIso8601String(),
        'is_deleted': record.isDeleted,
        'sync_status': record.syncStatus,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };
    }
    
    if (record is Category) {
      return {
        'id': record.id,
        'name': record.name,
        'description': record.description,
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
      case 'orders':
        await database.customUpdate(
          'UPDATE orders SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'order_items':
        await database.customUpdate(
          'UPDATE order_items SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'deliveries':
        await database.customUpdate(
          'UPDATE deliveries SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'categories':
        await database.customUpdate(
          'UPDATE categories SET remote_id = ?, sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString(remoteId),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.now()),
            Variable.withInt(record.id),
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
      case 'orders':
        await database.customUpdate(
          'UPDATE orders SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'order_items':
        await database.customUpdate(
          'UPDATE order_items SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'deliveries':
        await database.customUpdate(
          'UPDATE deliveries SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(record.id),
          ],
        );
        break;
      case 'categories':
        await database.customUpdate(
          'UPDATE categories SET sync_status = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withString('conflict'),
            Variable.withDateTime(DateTime.now()),
            Variable.withInt(record.id),
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
            if (data['approved_at'] != null) Variable.withDateTime(DateTime.parse(data['approved_at'])) else const Variable(null),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'orders':
        await database.customUpdate(
          '''UPDATE orders SET customer_id = ?, sales_rep_id = ?, order_date = ?, status = ?, 
              order_number = ?, subtotal = ?, tax_amount = ?, discount_amount = ?, total_amount = ?, 
              payment_status = ?, delivery_address = ?, delivery_contact = ?, delivery_phone = ?, 
              requested_delivery_date = ?, actual_delivery_date = ?, warehouse_status = ?, 
              picker_id = ?, picked_at = ?, packer_id = ?, packed_at = ?, customer_notes = ?, 
              internal_notes = ?, priority = ?, is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['customer_id']),
            Variable.withString(data['sales_rep_id']),
            Variable.withDateTime(DateTime.parse(data['order_date'])),
            Variable.withString(data['status']),
            Variable.withString(data['order_number']),
            Variable.withReal(data['subtotal']),
            Variable.withReal(data['tax_amount']),
            Variable.withReal(data['discount_amount']),
            Variable.withReal(data['total_amount']),
            Variable.withString(data['payment_status']),
            Variable.withString(data['delivery_address']),
            Variable.withString(data['delivery_contact']),
            Variable.withString(data['delivery_phone']),
            if (data['requested_delivery_date'] != null) Variable.withDateTime(DateTime.parse(data['requested_delivery_date'])) else const Variable(null),
            if (data['actual_delivery_date'] != null) Variable.withDateTime(DateTime.parse(data['actual_delivery_date'])) else const Variable(null),
            Variable.withString(data['warehouse_status']),
            Variable.withString(data['picker_id']),
            if (data['picked_at'] != null) Variable.withDateTime(DateTime.parse(data['picked_at'])) else const Variable(null),
            Variable.withString(data['packer_id']),
            if (data['packed_at'] != null) Variable.withDateTime(DateTime.parse(data['packed_at'])) else const Variable(null),
            Variable.withString(data['customer_notes']),
            Variable.withString(data['internal_notes']),
            Variable.withString(data['priority']),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'order_items':
        await database.customUpdate(
          '''UPDATE order_items SET order_id = ?, product_id = ?, product_sku = ?, product_name = ?, 
              product_category = ?, quantity = ?, delivered_quantity = ?, unit_price = ?, 
              subtotal = ?, discount_amount = ?, total_amount = ?, available_stock = ?, 
              stock_status = ?, status = ?, picker_id = ?, picked_at = ?, notes = ?, 
              cancellation_reason = ?, is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['order_id']),
            Variable.withString(data['product_id']),
            Variable.withString(data['product_sku']),
            Variable.withString(data['product_name']),
            Variable.withString(data['product_category']),
            Variable.withInt(data['quantity']),
            Variable.withInt(data['delivered_quantity']),
            Variable.withReal(data['unit_price']),
            Variable.withReal(data['subtotal']),
            Variable.withReal(data['discount_amount']),
            Variable.withReal(data['total_amount']),
            Variable.withInt(data['available_stock']),
            Variable.withString(data['stock_status']),
            Variable.withString(data['status']),
            Variable.withString(data['picker_id']),
            if (data['picked_at'] != null) Variable.withDateTime(DateTime.parse(data['picked_at'])) else const Variable(null),
            Variable.withString(data['notes']),
            Variable.withString(data['cancellation_reason']),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'deliveries':
        await database.customUpdate(
          '''UPDATE deliveries SET order_id = ?, delivery_personnel_id = ?, delivery_personnel_name = ?, 
              delivery_personnel_phone = ?, delivery_number = ?, scheduled_date = ?, actual_start_time = ?, 
              actual_completion_time = ?, status = ?, sub_status = ?, route = ?, route_order = ?, 
              vehicle_number = ?, start_location = ?, end_location = ?, start_latitude = ?, 
              start_longitude = ?, end_latitude = ?, end_longitude = ?, proof_of_delivery_type = ?, 
              proof_of_delivery_url = ?, recipient_name = ?, recipient_relation = ?, delivery_notes = ?, 
              collected_amount = ?, payment_method = ?, check_number = ?, issue_type = ?, 
              issue_description = ?, resolution = ?, priority = ?, attempt_count = ?, 
              next_attempt_date = ?, is_deleted = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['order_id']),
            Variable.withString(data['delivery_personnel_id']),
            Variable.withString(data['delivery_personnel_name']),
            Variable.withString(data['delivery_personnel_phone']),
            Variable.withString(data['delivery_number']),
            Variable.withDateTime(DateTime.parse(data['scheduled_date'])),
            if (data['actual_start_time'] != null) Variable.withDateTime(DateTime.parse(data['actual_start_time'])) else const Variable(null),
            if (data['actual_completion_time'] != null) Variable.withDateTime(DateTime.parse(data['actual_completion_time'])) else const Variable(null),
            Variable.withString(data['status']),
            Variable.withString(data['sub_status']),
            Variable.withString(data['route']),
            Variable.withInt(data['route_order']),
            Variable.withString(data['vehicle_number']),
            Variable.withString(data['start_location']),
            Variable.withString(data['end_location']),
            Variable.withReal(data['start_latitude']),
            Variable.withReal(data['start_longitude']),
            Variable.withReal(data['end_latitude']),
            Variable.withReal(data['end_longitude']),
            Variable.withString(data['proof_of_delivery_type']),
            Variable.withString(data['proof_of_delivery_url']),
            Variable.withString(data['recipient_name']),
            Variable.withString(data['recipient_relation']),
            Variable.withString(data['delivery_notes']),
            Variable.withReal(data['collected_amount']),
            Variable.withString(data['payment_method']),
            Variable.withString(data['check_number']),
            Variable.withString(data['issue_type']),
            Variable.withString(data['issue_description']),
            Variable.withString(data['resolution']),
            Variable.withString(data['priority']),
            Variable.withInt(data['attempt_count']),
            if (data['next_attempt_date'] != null) Variable.withDateTime(DateTime.parse(data['next_attempt_date'])) else const Variable(null),
            Variable.withBool(data['is_deleted']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id']),
          ],
        );
        break;
      case 'categories':
        await database.customUpdate(
          '''UPDATE categories SET name = ?, description = ?, sync_status = ?, updated_at = ? 
              WHERE remote_id = ?''',
          variables: [
            Variable.withString(data['name']),
            Variable.withString(data['description']),
            Variable.withString('synced'),
            Variable.withDateTime(DateTime.parse(data['updated_at'])),
            Variable.withString(data['id'].toString()),
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
