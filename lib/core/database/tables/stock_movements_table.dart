import 'package:drift/drift.dart';

/// Represents the stock movements table in the database.
/// 
/// Stores all stock movement transactions including stock in, stock out,
/// adjustments, transfers, and their reasons.
@DataClassName('StockMovement')
class StockMovements extends Table {
  /// Auto increment primary key for the stock movement record.
  IntColumn get id => integer().autoIncrement()();
  
  /// Unique identifier for the stock movement (UUID).
  TextColumn get uuid => text().unique()();
  
  /// Foreign key to the product being moved.
  TextColumn get productId => text()();
  
  /// Type of movement (stock_in, stock_out, adjustment, transfer).
  TextColumn get movementType => text()();
  
  /// Quantity moved (positive for stock in, negative for stock out).
  IntColumn get quantity => integer()();
  
  // referenceType dropped v14 — only in zero-caller stock_movement_service.dart.

  /// Reference ID linking to the source document.
  TextColumn get referenceId => text().nullable()();
  
  /// Reason for the stock movement.
  TextColumn get reason => text()();
  
  /// Additional notes about the movement.
  TextColumn get notes => text().nullable()();
  
  /// ID of the user who performed the movement.
  TextColumn get userId => text()();
  
  /// Name of the user who performed the movement.
  TextColumn get userName => text()();
  
  // fromLocation/toLocation dropped v14 — only in zero-caller stock_movement_service.dart.
  // unitCost/totalCost dropped v14 — only in zero-caller stock_movement_service.dart.
  // status dropped v14 — only in zero-caller stock_movement_service.dart + sync pull.
  // isActive dropped v14 — queries use isDeleted; never read in live code.

  /// Timestamp when the stock movement record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the stock movement record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  // remoteId dropped v14 — write-only; sync resolves by uuid.

  /// ID of the user who created this movement (FK→users.id, matches Supabase created_by).
  IntColumn get createdBy => integer().nullable()();
}
