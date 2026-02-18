import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/users_table.dart';
import 'tables/products_table.dart';
import 'tables/customers_table.dart';
import 'tables/orders_table.dart';
import 'tables/order_items_table.dart';
import 'tables/deliveries_table.dart';
import 'tables/stock_movements_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Products,
  Customers,
  Orders,
  OrderItems,
  Deliveries,
  StockMovements,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
      }
      await m.createAll();
    },
  );

  Future<void> createUser(UsersCompanion user) async {
    await into(users).insert(user);
  }

  Future<List<User>> getAllUsers() async {
    return (select(users)..orderBy([(t) => OrderingTerm(expression: t.firstName)])).get();
  }

  Future<User?> getUserById(int id) async => (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> getUserByEmail(String email) async => (select(users)..where((t) => t.email.equals(email) & t.isDeleted.equals(false) & t.isActive.equals(true))).getSingleOrNull();

  Future<bool> updateUser(String uuid, UsersCompanion user) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(user.copyWith(updatedAt: Value(DateTime.now()))) > 0;

  Future<bool> softDeleteUser(String uuid) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(UsersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  Future<List<User>> getPendingSyncUsers() async => (select(users)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markUserAsSynced(String uuid, String remoteId) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(UsersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Product methods
  Future<void> createProduct(ProductsCompanion product) async {
    await into(products).insert(product);
  }

  Future<List<Product>> getAllProducts() async => (select(products)..where((t) => t.isDeleted.equals(false))).get();

  Future<Product?> getProductById(int id) async => (select(products)..where((t) => t.id.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<Product?> getProductByIntId(int id) async => (select(products)..where((t) => t.id.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<Product?> getProductByUuid(String uuid) async => (select(products)..where((t) => t.uuid.equals(uuid) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<bool> updateProduct(String uuid, ProductsCompanion product) async => await (update(products)..where((t) => t.uuid.equals(uuid)))
        .write(product.copyWith(updatedAt: Value(DateTime.now()))) > 0;

  Future<bool> softDeleteProduct(String uuid) async => await (update(products)..where((t) => t.uuid.equals(uuid)))
        .write(ProductsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  Future<List<Product>> getPendingSyncProducts() async => (select(products)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markProductAsSynced(String uuid, String remoteId) async => await (update(products)..where((t) => t.uuid.equals(uuid)))
        .write(ProductsCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // Customer methods
  Future<void> createCustomer(CustomersCompanion customer) async {
    await into(customers).insert(customer);
  }

  Future<List<Customer>> getAllCustomers() async => (select(customers)..where((t) => t.isDeleted.equals(false))).get();

  Future<Customer?> getCustomerById(String id) async => (select(customers)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<bool> updateCustomer(String uuid, CustomersCompanion customer) async => await (update(customers)..where((t) => t.uuid.equals(uuid)))
        .write(customer.copyWith(updatedAt: Value(DateTime.now()))) > 0;

  Future<bool> softDeleteCustomer(String uuid) async => await (update(customers)..where((t) => t.uuid.equals(uuid)))
        .write(CustomersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  Future<List<Customer>> getPendingSyncCustomers() async => (select(customers)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<bool> markCustomerAsSynced(String uuid, String remoteId) async => await (update(customers)..where((t) => t.uuid.equals(uuid)))
        .write(CustomersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  Future<Customer?> getCustomerByEmail(String email) async => (select(customers)..where((t) => t.email.equals(email) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<List<Customer>> searchCustomersByName(String name) async => (select(customers)
    ..where((t) => t.name.contains(name) & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)])
  ).get();

  // Order methods
  Future<void> createOrder(OrdersCompanion order) async {
    await into(orders).insert(order);
  }

  Future<Order?> getOrderById(String id) async => (select(orders)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<List<Order>> getOrdersByCustomerId(String customerId) async => (select(orders)..where((t) => t.customerId.equals(customerId) & t.isDeleted.equals(false))).get();

  Future<List<Order>> getPendingOrders() async => (select(orders)
    ..where((t) => t.status.equals('pending') & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
  ).get();

  Future<List<Order>> getOrdersReadyForDelivery() async => (select(orders)
    ..where((t) => t.warehouseStatus.equals('ready') & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
  ).get();

  // Order Item methods
  Future<void> createOrderItem(OrderItemsCompanion orderItem) async {
    await into(orderItems).insert(orderItem);
  }

  Future<List<OrderItem>> getOrderItemsByOrderId(String orderId) async => (select(orderItems)..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false))).get();

  Future<OrderItem?> getOrderItemById(String id) async => (select(orderItems)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  /// Custom update method for complex SQL operations
  @override
  Future<int> customUpdate(
    String sql, {
    List<Variable> variables = const [],
    UpdateKind? updateKind,
    Set<ResultSetImplementation>? updates,
  }) async {
    return await super.customUpdate(
      sql,
      variables: variables,
      updateKind: updateKind,
      updates: updates,
    );
  }

  // Delivery methods
  Future<void> createDelivery(DeliveriesCompanion delivery) async {
    await into(deliveries).insert(delivery);
  }

  Future<Delivery?> getDeliveryById(String id) async => (select(deliveries)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<List<Delivery>> getActiveDeliveries() async => (select(deliveries)
    ..where((t) => t.status.equals('in_progress') & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.expectedStartTime)])
  ).get();

  Future<List<Delivery>> getDeliveriesByOrderId(String orderId) async => (select(deliveries)..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false))).get();

  // Stock Movement methods
  Future<void> createStockMovement(StockMovementsCompanion stockMovement) async {
    await into(stockMovements).insert(stockMovement);
  }

  Future<List<StockMovement>> getStockMovementsByProductId(String productId) async => (select(stockMovements)
    ..where((t) => t.productId.equals(productId) & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
  ).get();

  Future<List<StockMovement>> getPendingSyncStockMovements() async => (select(stockMovements)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<List<Order>> getPendingSyncOrders() async => (select(orders)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<List<OrderItem>> getPendingSyncOrderItems() async => (select(orderItems)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<List<Delivery>> getPendingSyncDeliveries() async => (select(deliveries)..where((t) => t.syncStatus.equals('pending'))).get();
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'villahermosa_inventory.db'));
  return NativeDatabase(file);
});