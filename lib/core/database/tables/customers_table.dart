import 'package:drift/drift.dart';

// Customers table definition
@DataClassName('Customer')
class Customers extends Table {
  // UUID primary key (matches Supabase)
  TextColumn get id => text()(); // UUID
  
  // Customer information
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  
  // Business information
  TextColumn get businessName => text().nullable()(); // For business customers
  TextColumn get taxId => text().nullable()(); // Tax identification number
  TextColumn get customerType => text().withDefault(const Constant('individual'))(); // individual, business
  
  // Credit and payment terms
  RealColumn get creditLimit => real().nullable()(); // Credit limit for business customers
  TextColumn get paymentTerms => text().nullable()(); // e.g., "NET 30", "COD"
  
  // Status and preferences
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, inactive, suspended
  TextColumn get preferredContactMethod => text().withDefault(const Constant('email'))(); // email, phone, sms
  
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
