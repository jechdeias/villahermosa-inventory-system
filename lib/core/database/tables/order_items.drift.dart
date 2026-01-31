import 'package:drift/drift.dart';

@DataClassName('OrderItem')
class OrderItems extends Table {
  // UUID primary key (matches Supabase)
  TextColumn get id => text()(); // UUID
  
  // Order and product references
  TextColumn get orderId => text()(); // References Orders.id
  TextColumn get productId => text()(); // References Products.id
  
  // Item details at time of order
  TextColumn get productSku => text()(); // Denormalized for audit trail
  TextColumn get productName => text()(); // Denormalized for audit trail
  TextColumn get productCategory => text().nullable()(); // Denormalized for reporting
  
  // Quantities and pricing
  IntColumn get quantity => integer()();
  IntColumn get deliveredQuantity => integer().withDefault(const Constant(0))(); // Actual delivered quantity
  RealColumn get unitPrice => real()(); // Price per unit at time of order
  RealColumn get subtotal => real()(); // quantity * unitPrice
  RealColumn get discountAmount => real().withDefault(const Constant(0))(); // Line item discount
  RealColumn get totalAmount => real()(); // subtotal - discountAmount
  
  // Stock information
  IntColumn get availableStock => integer()(); // Stock available at time of order
  TextColumn get stockStatus => text().withDefault(const Constant('available'))(); // available | backorder | discontinued
  
  // Status tracking
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending | picked | packed | delivered | cancelled
  TextColumn get pickerId => text().nullable()(); // User who picked this item
  DateTimeColumn get pickedAt => dateTime().nullable()();
  
  // Notes
  TextColumn get notes => text().nullable()(); // Line item specific notes
  TextColumn get cancellationReason => text().nullable()(); // Reason if cancelled
  
  // Soft delete for sync safety
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Sync tracking
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending | synced | conflict
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}
