import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Users table definition
@DataClassName('User')
class Users extends Table {
  // UUID primary key (matches Supabase)
  TextColumn get id => text()(); // UUID
  
  // User fields
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get role => text()(); // admin, warehouse, delivery, customer
  
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

// Database class
@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Constructor for testing with in-memory database
  AppDatabase.forTesting(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => 1;

  // CRUD operations for Users
  Future<void> createUser(UsersCompanion user) async {
    await into(users).insert(user);
  }

  Future<List<User>> getAllUsers() async {
    return await (select(users)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<User?> getUserById(String id) async {
    return await (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<User?> getUserByEmail(String email) async {
    return await (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();
  }

  Future<bool> updateUser(String id, UsersCompanion user) async {
    return await (update(users)..where((t) => t.id.equals(id)))
        .write(user.copyWith(updatedAt: Value(DateTime.now()))) > 0;
  }

  Future<bool> softDeleteUser(String id) async {
    return await (update(users)..where((t) => t.id.equals(id)))
        .write(UsersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;
  }

  // Sync-related queries
  Future<List<User>> getPendingSyncUsers() async {
    return await (select(users)..where((t) => t.syncStatus.equals('pending'))).get();
  }

  Future<bool> markUserAsSynced(String id, String remoteId) async {
    return await (update(users)..where((t) => t.id.equals(id)))
        .write(UsersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;
  }
}

// Database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'villahermosa_inventory.db'));
    return NativeDatabase(file);
  });
}