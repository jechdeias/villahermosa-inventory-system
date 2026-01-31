import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/customers_table.dart';
import 'tables/products_table.dart';
import 'tables/stock_movements_table.dart';
import 'tables/categories.drift.dart';
import 'tables/orders.drift.dart';
import 'tables/order_items.drift.dart';
import 'tables/deliveries.drift.dart';

part 'app_database.g.dart';

// Users table definition
@DataClassName('User')
class Users extends Table {
  // Local integer primary key (SQLite)
  IntColumn get id => integer().autoIncrement()();
  
  // UUID for Supabase sync
  TextColumn get uuid => text().unique()(); // Local UUID for this record
  
  // User fields
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get role => text()(); // admin, warehouse, delivery, customer
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  
  // Soft delete for sync safety
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  // Sync tracking
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, conflict
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Database class
@DriftDatabase(tables: [
  Users,
  Customers, 
  Products, 
  StockMovements,
  Categories,
  Orders,
  OrderItems,
  Deliveries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Constructor for testing with in-memory database
  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;

  // CRUD operations for Users
  Future<void> createUser(UsersCompanion user) async {
    await into(users).insert(user);
  }

  Future<List<User>> getAllUsers() async => await (select(users)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();

  Future<User?> getUserById(int id) async => await (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> getUserByEmail(String email) async => await (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();

  Future<bool> updateUser(String uuid, UsersCompanion user) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(user.copyWith(updatedAt: Value(DateTime.now()))) > 0;

  Future<bool> softDeleteUser(String uuid) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(UsersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries
  Future<List<User>> getPendingSyncUsers() async => await (select(users)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markUserAsSynced(String uuid, String remoteId) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(UsersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // CRUD operations for Customers
  Future<void> createCustomer(CustomersCompanion customer) async {
    await into(customers).insert(customer);
  }

  Future<List<Customer>> getAllCustomers() async => await (select(customers)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

  Future<Customer?> getCustomerById(String uuid) async => await (select(customers)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  Future<Customer?> getCustomerByEmail(String email) async => await (select(customers)
          ..where((t) => t.email.equals(email) & t.isDeleted.equals(false)))
        .getSingleOrNull();

  Future<List<Customer>> searchCustomersByName(String name) async => await (select(customers)
          ..where((t) => t.name.contains(name) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

  Future<bool> updateCustomer(String uuid, CustomersCompanion customer) async => await (update(customers)..where((t) => t.uuid.equals(uuid)))
        .write(customer.copyWith(updatedAt: Value(DateTime.now()))) > 0;

  Future<bool> softDeleteCustomer(String uuid) async => await (update(customers)..where((t) => t.uuid.equals(uuid)))
        .write(CustomersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries for Customers
  Future<List<Customer>> getPendingSyncCustomers() async => await (select(customers)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markCustomerAsSynced(int id, String remoteId) async => await (update(customers)..where((t) => t.id.equals(id)))
        .write(CustomersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // CRUD operations for Products
  Future<void> createProduct(ProductsCompanion product) async {
    await into(products).insert(product);
  }

  Future<List<Product>> getAllProducts() async => await (select(products)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

  Future<Product?> getProductById(int id) async => await (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Product?> getProductBySku(String sku) async => await (select(products)
          ..where((t) => t.sku.equals(sku) & t.isDeleted.equals(false)))
        .getSingleOrNull();

  Future<List<Product>> searchProductsByName(String name) async => await (select(products)
          ..where((t) => t.name.contains(name) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

  Future<List<Product>> getProductsByCategory(String category) async => await (select(products)
          ..where((t) => t.category.equals(category) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

  Future<List<Product>> getLowStockProducts() async => await (select(products)
          ..where((t) => 
            t.currentStock.isSmallerThan(t.minStock) & 
            t.isDeleted.equals(false) & 
            t.status.equals('active')
          )
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

  Future<bool> updateProduct(int id, ProductsCompanion product) async => await (update(products)..where((t) => t.id.equals(id)))
        .write(product.copyWith(updatedAt: Value(DateTime.now()))) > 0;

  Future<bool> softDeleteProduct(int id) async => await (update(products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries for Products
  Future<List<Product>> getPendingSyncProducts() async => await (select(products)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markProductAsSynced(int id, String remoteId) async => await (update(products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // CRUD operations for StockMovements
  Future<void> createStockMovement(StockMovementsCompanion movement) async {
    await into(stockMovements).insert(movement);
  }

  Future<List<StockMovement>> getStockMovementsByProduct(String productId) async => await (select(stockMovements)
          ..where((t) => t.productId.equals(productId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();

  Future<List<StockMovement>> getStockMovementsByType(String movementType) async => await (select(stockMovements)
          ..where((t) => t.movementType.equals(movementType) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();

  Future<List<StockMovement>> getRecentStockMovements({int limit = 50}) async => await (select(stockMovements)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();

  Future<bool> softDeleteStockMovement(String id) async => await (update(stockMovements)..where((t) => t.id.equals(id)))
        .write(StockMovementsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries for StockMovements
  Future<List<StockMovement>> getPendingSyncStockMovements() async => await (select(stockMovements)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markStockMovementAsSynced(String id, String remoteId) async => await (update(stockMovements)..where((t) => t.id.equals(id)))
        .write(StockMovementsCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries for Orders
  Future<List<Order>> getPendingSyncOrders() async => await (select(orders)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markOrderAsSynced(String id, String remoteId) async => await (update(orders)..where((t) => t.id.equals(id)))
        .write(OrdersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries for OrderItems
  Future<List<OrderItem>> getPendingSyncOrderItems() async => await (select(orderItems)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markOrderItemAsSynced(String id, String remoteId) async => await (update(orderItems)..where((t) => t.id.equals(id)))
        .write(OrderItemsCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Sync-related queries for Deliveries
  Future<List<Delivery>> getPendingSyncDeliveries() async => await (select(deliveries)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markDeliveryAsSynced(String id, String remoteId) async => await (update(deliveries)..where((t) => t.id.equals(id)))
        .write(DeliveriesCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Order operations
  Future<Order?> getOrderById(String id) async => await (select(orders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<OrderItem>> getOrderItemsByOrderId(String orderId) async => await (select(orderItems)
          ..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();

  // Delivery operations  
  Future<Delivery?> getDeliveryById(String id) async => await (select(deliveries)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Product operations with integer ID support
  Future<Product?> getProductByIntId(int id) async => await (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
}

// Database connection
LazyDatabase _openConnection() => LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'villahermosa_inventory.db'));
    return NativeDatabase(file);
  });