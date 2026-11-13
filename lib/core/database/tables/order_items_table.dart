import 'package:drift/drift.dart';

/// Represents the order items table in the database.
///
/// Stores individual items within an order, including product details,
/// quantities, pricing, and fulfillment status.
///
/// Intentionally lean (schema v12): columns are only kept when live code
/// reads them. Dropped in v12 — deliveredQuantity, discountAmount,
/// availableStock, stockStatus, pickerId, notes, isActive, remoteId —
/// their only writers were dead code (order_workflow.dart) or nothing
/// ever read them.
@DataClassName('OrderItem')
class OrderItems extends Table {
  /// Auto increment primary key for the order item record.
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for the order item (UUID).
  TextColumn get uuid => text().unique()();

  /// Foreign key to the order this item belongs to (the order's uuid).
  TextColumn get orderId => text()();

  /// Foreign key to the product (the product's uuid).
  TextColumn get productId => text()();

  /// Product SKU at the time of order.
  TextColumn get productSku => text()();

  /// Product name at the time of order.
  TextColumn get productName => text()();

  /// Quantity ordered.
  IntColumn get quantity => integer()();

  /// Unit price at the time of order.
  RealColumn get unitPrice => real()();

  /// Subtotal for this item (quantity * unitPrice).
  RealColumn get subtotal => real()();

  /// Total amount for this item.
  RealColumn get totalAmount => real()();

  /// Item status (pending, picked, packed, delivered, cancelled).
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Timestamp when this item was picked.
  DateTimeColumn get pickedAt => dateTime().nullable()();

  /// Timestamp when the order item record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp when the order item record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}
