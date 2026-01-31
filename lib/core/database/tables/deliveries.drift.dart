import 'package:drift/drift.dart';

@DataClassName('Delivery')
class Deliveries extends Table {
  // UUID primary key (matches Supabase)
  TextColumn get id => text()(); // UUID
  
  // Order reference
  TextColumn get orderId => text()(); // References Orders.id (1:1 relationship)
  
  // Delivery personnel
  TextColumn get deliveryPersonnelId => text()(); // References Users.id (delivery role)
  TextColumn get deliveryPersonnelName => text()(); // Denormalized for audit trail
  TextColumn get deliveryPersonnelPhone => text()(); // Contact number
  
  // Delivery details
  TextColumn get deliveryNumber => text().unique()(); // Human-readable delivery number
  DateTimeColumn get scheduledDate => dateTime()(); // Planned delivery date
  DateTimeColumn get actualStartTime => dateTime().nullable()(); // When delivery started
  DateTimeColumn get actualCompletionTime => dateTime().nullable()(); // When delivery completed
  
  // Status tracking
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending | assigned | in_progress | completed | failed | cancelled
  TextColumn get subStatus => text().nullable()(); // More detailed status (e.g., "customer_not_found", "payment_issue")
  
  // Route information
  TextColumn get route => text()(); // Delivery route name
  IntColumn get routeOrder => integer()(); // Order in the delivery route
  TextColumn get vehicleNumber => text().nullable()(); // Vehicle used for delivery
  
  // Location tracking
  TextColumn get startLocation => text()(); // Starting point (warehouse)
  TextColumn get endLocation => text()(); // Delivery address
  RealColumn get startLatitude => real().nullable()(); // GPS coordinates
  RealColumn get startLongitude => real().nullable()();
  RealColumn get endLatitude => real().nullable()();
  RealColumn get endLongitude => real().nullable()();
  
  // Proof of delivery
  TextColumn get proofOfDeliveryType => text().nullable()(); // photo | signature | none
  TextColumn get proofOfDeliveryUrl => text().nullable()(); // URL to photo or signature image
  TextColumn get recipientName => text().nullable()(); // Person who received delivery
  TextColumn get recipientRelation => text().nullable()(); // Relationship to customer (owner, staff, etc.)
  TextColumn get deliveryNotes => text().nullable()(); // Notes from delivery personnel
  
  // Financial
  RealColumn get collectedAmount => real().withDefault(const Constant(0.0))(); // Cash collected on delivery
  TextColumn get paymentMethod => text().nullable()(); // cash | check | digital
  TextColumn get checkNumber => text().nullable()(); // If paid by check
  
  // Issues and exceptions
  TextColumn get issueType => text().nullable()(); // late_delivery | damaged_goods | wrong_items | customer_refused
  TextColumn get issueDescription => text().nullable()(); // Detailed description of issue
  TextColumn get resolution => text().nullable()(); // How the issue was resolved
  
  // Metadata
  TextColumn get priority => text().withDefault(const Constant('normal'))(); // low | normal | high | urgent
  IntColumn get attemptCount => integer().withDefault(const Constant(0))(); // Number of delivery attempts
  DateTimeColumn get nextAttemptDate => dateTime().nullable()(); // For failed deliveries
  
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
