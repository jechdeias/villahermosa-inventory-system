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

  // taxAmount dropped v14 — never read in UI; Supabase schema has no tax logic.
  // paymentStatus dropped v14 — write-only in new_order_flow; payments table owns this.
  // priority dropped v14 — write-only; no UI reads or admin filters.
  // pickerId/pickedAt/packerId dropped v14 — only in zero-caller warehouse_providers.dart.
  // isActive dropped v14 — queries use isDeleted; never read in live code.

  /// Total amount including tax.
  RealColumn get totalAmount => real().withDefault(const Constant(0))();

  /// Warehouse processing status (pending, picking, packed, ready, shipped).
  TextColumn get warehouseStatus => text().withDefault(const Constant('pending'))();

  /// Timestamp when the order was packed.
  DateTimeColumn get packedAt => dateTime().nullable()();
  
  /// Expected delivery date.
  DateTimeColumn get expectedDeliveryDate => dateTime().nullable()();
  
  /// Actual delivery date.
  DateTimeColumn get actualDeliveryDate => dateTime().nullable()();
  
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

  /// Cached store/customer display name for fast list rendering.
  TextColumn get storeName => text().nullable()();

  /// Route identifier (optional).
  IntColumn get routeId => integer().nullable()();

  /// Cached route display name for fast list rendering.
  TextColumn get routeName => text().nullable()();

  /// Foreign key to the sales representative user.
  IntColumn get salesRepId => integer().nullable()();

  /// Cached sales rep display name for fast list rendering.
  TextColumn get salesRepName => text().nullable()();

  /// Cached total item count across all order items.
  IntColumn get itemCount => integer().withDefault(const Constant(0))();

  /// Order code (short human-readable identifier, e.g. "ORD-2409").
  /// Matches Supabase's order_code column which payments reference.
  TextColumn get orderCode => text().nullable()();

  /// Date the order was placed. Matches Supabase's order_date column.
  DateTimeColumn get orderDate => dateTime().nullable()();
}
