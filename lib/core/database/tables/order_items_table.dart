import 'package:drift/drift.dart';

/// Represents the order items table in the database.
/// 
/// Stores individual items within an order, including product details,
/// quantities, pricing, and fulfillment status.
@DataClassName('OrderItem')
class OrderItems extends Table {
  /// Auto increment primary key for the order item record.
  IntColumn get id => integer().autoIncrement()();
  
  /// Unique identifier for the order item (UUID).
  TextColumn get uuid => text().unique()();
  
  /// Foreign key to the order this item belongs to.
  TextColumn get orderId => text()();
  
  /// Foreign key to the product.
  TextColumn get productId => text()();
  
  /// Product SKU at the time of order.
  TextColumn get productSku => text()();
  
  /// Product name at the time of order.
  TextColumn get productName => text()();
  
  /// Quantity ordered.
  IntColumn get quantity => integer()();
  
  /// Quantity delivered.
  IntColumn get deliveredQuantity => integer().withDefault(const Constant(0))();
  
  /// Unit price at the time of order.
  RealColumn get unitPrice => real()();
  
  /// Subtotal for this item (quantity * unitPrice).
  RealColumn get subtotal => real()();
  
  /// Discount amount applied to this item.
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  
  /// Total amount for this item (subtotal - discount).
  RealColumn get totalAmount => real()();
  
  /// Available stock at the time of order.
  IntColumn get availableStock => integer()();
  
  /// Stock status (available, backorder, out_of_stock).
  TextColumn get stockStatus => text().withDefault(const Constant('available'))();
  
  /// Item status (pending, picked, packed, delivered, cancelled).
  TextColumn get status => text().withDefault(const Constant('pending'))();
  
  /// ID of the warehouse staff member who picked this item.
  TextColumn get pickerId => text().nullable()();
  
  /// Timestamp when this item was picked.
  DateTimeColumn get pickedAt => dateTime().nullable()();
  
  /// Notes specific to this item.
  TextColumn get notes => text().nullable()();
  
  /// Indicates whether the item is currently active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Timestamp when the order item record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the order item record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  /// Remote database ID for cross-system synchronization.
  TextColumn get remoteId => text().nullable()();
}
