import 'package:drift/drift.dart';

/// Represents the deliveries table in the database.
/// 
/// Stores delivery information including personnel details, status,
/// timing, and proof of delivery information.
@DataClassName('Delivery')
class Deliveries extends Table {
  /// Auto increment primary key for the delivery record.
  IntColumn get id => integer().autoIncrement()();
  
  /// Unique identifier for the delivery (UUID).
  TextColumn get uuid => text().unique()();
  
  /// Foreign key to the order being delivered.
  TextColumn get orderId => text()();
  
  /// Delivery number for human reference.
  TextColumn get deliveryNumber => text()();
  
  /// ID of the delivery personnel.
  TextColumn get deliveryPersonnelId => text()();
  
  /// Name of the delivery personnel.
  TextColumn get deliveryPersonnelName => text()();
  
  /// Phone number of the delivery personnel.
  TextColumn get deliveryPersonnelPhone => text()();
  
  /// Expected start time for delivery.
  DateTimeColumn get expectedStartTime => dateTime()();
  
  /// Expected completion time for delivery.
  DateTimeColumn get expectedCompletionTime => dateTime()();
  
  /// Actual start time of delivery.
  DateTimeColumn get actualStartTime => dateTime().nullable()();
  
  /// Actual completion time of delivery.
  DateTimeColumn get actualCompletionTime => dateTime().nullable()();
  
  /// Delivery status (pending, in_progress, completed, failed, cancelled).
  TextColumn get status => text().withDefault(const Constant('pending'))();
  
  /// Name of the person who received the delivery.
  TextColumn get recipientName => text().nullable()();
  
  /// Relationship of recipient to customer.
  TextColumn get recipientRelation => text().nullable()();
  
  /// Notes about the delivery.
  TextColumn get deliveryNotes => text().nullable()();
  
  /// Amount collected during delivery (for COD orders).
  RealColumn get collectedAmount => real().withDefault(const Constant(0))();
  
  /// Payment method used (cash, card, transfer, etc.).
  TextColumn get paymentMethod => text().nullable()();
  
  /// URL to proof of delivery document/photo.
  TextColumn get proofOfDeliveryUrl => text().nullable()();
  
  /// GPS coordinates of delivery location.
  TextColumn get deliveryCoordinates => text().nullable()();
  
  /// Indicates whether the delivery is currently active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Timestamp when the delivery record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the delivery record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  /// Remote database ID for cross-system synchronization.
  TextColumn get remoteId => text().nullable()();

  /// Actual delivery date matching Supabase schema.
  DateTimeColumn get deliveryDate => dateTime().nullable()();
}
