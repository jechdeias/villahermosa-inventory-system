import 'package:drift/drift.dart';

// Products table definition
@DataClassName('Product')
class Products extends Table {
  // Local integer primary key (SQLite)
  IntColumn get id => integer().autoIncrement()();
  
  // UUID for Supabase sync
  TextColumn get uuid => text().unique()(); // Local UUID for this record
  
  // Product identification
  TextColumn get sku => text().unique()(); // Stock Keeping Unit
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()();
  TextColumn get brand => text().nullable()();
  
  // Inventory tracking
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(0))(); // Reorder point
  IntColumn get maxStock => integer().nullable()(); // Maximum capacity
  TextColumn get unit => text()(); // e.g., "pcs", "boxes", "kg", "liters"
  RealColumn get weight => real().nullable()(); // Weight per unit
  TextColumn get dimensions => text().nullable()(); // e.g., "10x5x2 cm"
  
  // Pricing
  RealColumn get unitPrice => real()(); // Selling price per unit
  RealColumn get costPrice => real()(); // Cost price per unit
  RealColumn get wholesalePrice => real().nullable()(); // Wholesale price
  TextColumn get currency => text().withDefault(const Constant('PHP'))(); // Currency code
  
  // Supplier information
  TextColumn get supplier => text().nullable()(); // Primary supplier name
  TextColumn get supplierSku => text().nullable()(); // Supplier's SKU
  IntColumn get leadTimeDays => integer().nullable()(); // Days for reorder
  
  // Product status and metadata
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, inactive, discontinued
  TextColumn get location => text().nullable()(); // Warehouse location/aisle
  TextColumn get barcode => text().nullable()(); // Barcode number
  TextColumn get tags => text().nullable()(); // Comma-separated tags for search
  
  // Soft delete for sync safety
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Sync tracking
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, conflict
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
}
