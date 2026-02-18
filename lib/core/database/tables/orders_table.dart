import 'package:drift/drift.dart';

/// Represents the orders table in the database.
/// 
/// Stores order information including customer details, status,
/// payment information, and delivery information.
@DataClassName('Order')
class Orders extends Table {
  /// Auto increment primary key for the order record.
  IntColumn get id => integer().autoIncrement()();
  
  /// Unique identifier for the order (UUID).
  TextColumn get uuid => text().unique()();
  
  /// Foreign key to the customer who placed the order.
  TextColumn get customerId => text()();
  
  /// Human-readable order number.
  TextColumn get orderNumber => text()();
  
  /// Current order status (pending, confirmed, packed, delivered, cancelled).
  TextColumn get status => text().withDefault(const Constant('pending'))();
  
  /// Delivery address for the order.
  TextColumn get deliveryAddress => text()();
  
  /// Customer notes for the order.
  TextColumn get customerNotes => text().nullable()();
  
  /// Order subtotal before tax.
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  
  /// Tax amount calculated on the order.
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  
  /// Total amount including tax.
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  
  /// Payment status (pending, partial, paid, failed).
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  
  /// Warehouse processing status (pending, picking, packed, ready, shipped).
  TextColumn get warehouseStatus => text().withDefault(const Constant('pending'))();
  
  /// Order priority (low, normal, high, urgent).
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  
  /// ID of the warehouse staff member who picked the order.
  TextColumn get pickerId => text().nullable()();
  
  /// Timestamp when the order was picked.
  DateTimeColumn get pickedAt => dateTime().nullable()();
  
  /// ID of the warehouse staff member who packed the order.
  TextColumn get packerId => text().nullable()();
  
  /// Timestamp when the order was packed.
  DateTimeColumn get packedAt => dateTime().nullable()();
  
  /// Expected delivery date.
  DateTimeColumn get expectedDeliveryDate => dateTime().nullable()();
  
  /// Actual delivery date.
  DateTimeColumn get actualDeliveryDate => dateTime().nullable()();
  
  /// Indicates whether the order is currently active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Timestamp when the order record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the order record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  /// Remote database ID for cross-system synchronization.
  TextColumn get remoteId => text().nullable()();
}
