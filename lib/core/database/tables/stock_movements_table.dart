import 'package:drift/drift.dart';

// StockMovements table definition - tracks all inventory changes
@DataClassName('StockMovement')
class StockMovements extends Table {
  // UUID primary key (matches Supabase)
  TextColumn get id => text()(); // UUID
  
  // Product reference
  TextColumn get productId => text()(); // References Products.id
  
  // Movement details
  TextColumn get movementType => text()(); // stock_in, stock_out, adjustment, transfer
  IntColumn get quantity => integer()(); // Positive for stock in, negative for stock out
  TextColumn get referenceType => text().nullable()(); // order, delivery, manual_adjustment, return
  TextColumn get referenceId => text().nullable()(); // Reference to related record ID
  
  // Reason and notes
  TextColumn get reason => text()(); // Reason for the movement
  TextColumn get notes => text().nullable()(); // Additional notes
  
  // User who performed the action
  TextColumn get userId => text()(); // References Users.id
  TextColumn get userName => text()(); // Denormalized for audit trail
  
  // Location tracking
  TextColumn get fromLocation => text().nullable()(); // Source location for transfers
  TextColumn get toLocation => text().nullable()(); // Destination location for transfers
  
  // Financial impact
  RealColumn get unitCost => real().nullable()(); // Cost per unit at time of movement
  RealColumn get totalCost => real().nullable()(); // Total cost impact (quantity * unitCost)
  
  // Status and approval
  TextColumn get status => text().withDefault(const Constant('completed'))(); // pending, completed, cancelled
  TextColumn get approvedBy => text().nullable()(); // User who approved the movement
  DateTimeColumn get approvedAt => dateTime().nullable()(); // Approval timestamp
  
  // Soft delete for sync safety
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Sync tracking
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, conflict
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}
