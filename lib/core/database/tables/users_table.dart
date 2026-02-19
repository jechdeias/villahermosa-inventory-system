import 'package:drift/drift.dart';

/// Represents the users table in the database.
/// 
/// Stores user account information including authentication credentials,
/// roles, and sync status for offline-first functionality.
@DataClassName('User')
class Users extends Table {
  /// Auto increment primary key for the user record.
  IntColumn get id => integer().autoIncrement()();
  
  /// User's first name for identification purposes.
  TextColumn get firstName => text()();
  
  /// User's last name for identification purposes.
  TextColumn get lastName => text()();
  
  /// User's email address for authentication and identification.
  TextColumn get email => text().unique()();
  
  /// Hashed password for secure authentication storage.
  /// Never stores plain text passwords for security reasons.
  TextColumn get passwordHash => text()();
  
  /// User role determining permissions and access level.
  /// Valid values: admin, warehouse, customer, delivery.
  TextColumn get role => text()();
  
  /// User's phone number (optional).
  TextColumn get phone => text().nullable()();
  
  /// User's address (optional).
  TextColumn get address => text().nullable()();
  
  /// Indicates whether the user account is currently active.
  /// Inactive users cannot authenticate or access the system.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Timestamp when the user record was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Timestamp when the user record was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Soft delete flag for logical deletion.
  /// Allows recovery of deleted records and maintains data integrity.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// Synchronization status with remote backend.
  /// Tracks whether local changes need to be synced.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  /// Remote database ID for cross-system synchronization.
  /// Null for local-only records until synced.
  TextColumn get remoteId => text().nullable()();
  
  /// UUID for cross-system synchronization.
  TextColumn get uuid => text().unique()();
  
  /// Flag to force user to change password on next login.
  /// Set to true when admin resets user password.
  BoolColumn get forcePasswordChange => boolean().withDefault(const Constant(false))();
}
