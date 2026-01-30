import 'package:drift/drift.dart';

@DataClassName('Order')
class Orders extends Table {
  // UUID primary key (matches Supabase)
  TextColumn get id => text()(); // UUID
  
  // Customer and sales rep
  TextColumn get customerId => text()(); // References Customers.id
  TextColumn get salesRepId => text().nullable()(); // References Users.id (sales rep)
  
  // Order details
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('draft'))(); // draft | confirmed | dispatched | delivered | cancelled
  TextColumn get orderNumber => text().unique()(); // Human-readable order number
  
  // Financial
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))(); // pending | paid | partial | overdue
  
  // Delivery information
  TextColumn get deliveryAddress => text()();
  TextColumn get deliveryContact => text().nullable()();
  TextColumn get deliveryPhone => text().nullable()();
  DateTimeColumn get requestedDeliveryDate => dateTime().nullable()();
  DateTimeColumn get actualDeliveryDate => dateTime().nullable()();
  
  // Warehouse processing
  TextColumn get warehouseStatus => text().withDefault(const Constant('pending'))(); // pending | picking | packed | ready | shipped
  TextColumn get pickerId => text().nullable()(); // User who picked the order
  DateTimeColumn get pickedAt => dateTime().nullable()();
  TextColumn get packerId => text().nullable()(); // User who packed the order
  DateTimeColumn get packedAt => dateTime().nullable()();
  
  // Notes and metadata
  TextColumn get customerNotes => text().nullable()();
  TextColumn get internalNotes => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('normal'))(); // low | normal | high | urgent
  
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
