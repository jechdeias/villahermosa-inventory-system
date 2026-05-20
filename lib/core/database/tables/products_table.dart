import 'package:drift/drift.dart';

/// Represents the products table in the database.
/// 
/// Stores product information including pricing, inventory levels,
/// and categorization for the inventory management system.
@DataClassName('Product')
class Products extends Table {
  /// Auto increment primary key for the product record.
  IntColumn get id => integer().autoIncrement()();
  
  /// Unique SKU (Stock Keeping Unit) for product identification.
  TextColumn get sku => text().unique()();
  
  /// Product name for display purposes.
  TextColumn get name => text()();
  
  /// Product category for grouping and filtering.
  TextColumn get category => text()();
  
  /// Unit selling price for the product.
  RealColumn get unitPrice => real()();
  
  /// Cost price for the product.
  RealColumn get costPrice => real()();
  
  /// Unit of measurement (e.g., cs, pcs, kg).
  TextColumn get unit => text()();
  
  /// Current stock quantity available.
  IntColumn get currentStock => integer()();
  
  /// Minimum stock level for reordering alerts.
  IntColumn get minStock => integer()();
  
  /// Product status (active, inactive, discontinued).
  TextColumn get status => text().withDefault(const Constant('active'))();
  
  /// Storage location for the product.
  TextColumn get location => text().nullable()();
  
  /// Indicates whether the product is currently active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Timestamp when the product record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the product record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  /// Remote database ID for cross-system synchronization.
  TextColumn get remoteId => text().nullable()();
  
  /// UUID for cross-system synchronization.
  TextColumn get uuid => text().unique()();

  /// Foreign key to the supplier of this product.
  IntColumn get supplierId => integer().nullable()();

  /// Number of units per case for case-based ordering.
  IntColumn get qtyPerCase => integer().withDefault(const Constant(1))();
}
