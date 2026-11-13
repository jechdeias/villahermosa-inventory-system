import 'package:drift/drift.dart';

/// Represents the customers table in the database.
/// 
/// Stores customer information including contact details,
/// credit limits, and business information.
@DataClassName('Customer')
class Customers extends Table {
  /// Auto increment primary key for the customer record.
  IntColumn get id => integer().autoIncrement()();
  
  /// Customer's full name.
  TextColumn get name => text()();
  
  /// Business name (optional).
  TextColumn get businessName => text().nullable()();
  
  /// Customer's email address.
  TextColumn get email => text().nullable()();
  
  /// Customer's phone number.
  TextColumn get phone => text().nullable()();
  
  /// Customer's address.
  TextColumn get address => text().nullable()();
  
  /// Municipality/City.
  TextColumn get municipality => text()();
  
  /// Province/State.
  TextColumn get province => text()();
  
  /// Store type (e.g., Mini Mart, Supermarket, Sari-Sari Store).
  TextColumn get storeType => text()();
  
  /// Credit limit for the customer.
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  
  /// Customer type (regular, wholesale).
  TextColumn get customerType => text().withDefault(const Constant('regular'))();
  
  /// Customer status (active, inactive).
  TextColumn get status => text().withDefault(const Constant('active'))();
  
  /// Contact number for orders.
  TextColumn get contactNumber => text()();
  
  // isActive dropped v13 — zero reads in live code; status field is what
  // filters use. remoteId dropped v13 — write-only, sync resolves by uuid.

  /// Timestamp when the customer record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the customer record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  /// UUID for cross-system synchronization.
  TextColumn get uuid => text().unique()();

  /// Current outstanding credit balance.
  RealColumn get currentCredit => real().nullable()();

  /// Barangay (sub-municipality) of the customer.
  TextColumn get barangay => text().nullable()();

  /// Town/municipality matching Supabase schema.
  TextColumn get town => text().nullable()();

  /// Sales channel (e.g. direct, online, distributor).
  TextColumn get channel => text().nullable()();
}
