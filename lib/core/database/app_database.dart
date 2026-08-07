import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'tables/users_table.dart';
import 'tables/products_table.dart';
import 'tables/customers_table.dart';
import 'tables/orders_table.dart';
import 'tables/order_items_table.dart';
import 'tables/deliveries_table.dart';
import 'tables/stock_movements_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/payments_table.dart';
import 'tables/delivery_routes_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Products,
  Customers,
  Orders,
  OrderItems,
  Deliveries,
  StockMovements,
  Suppliers,
  Payments,
  DeliveryRoutes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : _isTestInstance = false, super(_openConnection());

  AppDatabase.forTesting(DatabaseConnection super.connection) : _isTestInstance = true;

  /// Skips demo-data seeding in beforeOpen — tests expect a clean database.
  final bool _isTestInstance;

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Columns added in v2
      if (from < 2) {
        try { await m.addColumn(users, users.remoteId); } catch (_) {}
        try { await m.addColumn(users, users.forcePasswordChange); } catch (_) {}
        try { await m.addColumn(products, products.remoteId); } catch (_) {}
        try { await m.addColumn(customers, customers.remoteId); } catch (_) {}
        try { await m.addColumn(orders, orders.remoteId); } catch (_) {}
        try { await m.addColumn(orderItems, orderItems.remoteId); } catch (_) {}
        try { await m.addColumn(deliveries, deliveries.remoteId); } catch (_) {}
        try { await m.addColumn(stockMovements, stockMovements.remoteId); } catch (_) {}
      }
      // Columns added in v3 (uuid on every table)
      if (from < 3) {
        try { await m.addColumn(users, users.uuid); } catch (_) {}
        try { await m.addColumn(products, products.uuid); } catch (_) {}
        try { await m.addColumn(customers, customers.uuid); } catch (_) {}
        try { await m.addColumn(orders, orders.uuid); } catch (_) {}
        try { await m.addColumn(orderItems, orderItems.uuid); } catch (_) {}
        try { await m.addColumn(deliveries, deliveries.uuid); } catch (_) {}
        try { await m.addColumn(stockMovements, stockMovements.uuid); } catch (_) {}
      }
      // New table added in v4
      if (from < 4) {
        try { await m.createTable(suppliers); } catch (_) {}
      }
      // Columns added in v5 (Supabase schema alignment)
      if (from < 5) {
        try { await m.addColumn(customers, customers.currentCredit); } catch (_) {}
        try { await m.addColumn(customers, customers.barangay); } catch (_) {}
        try { await m.addColumn(customers, customers.town); } catch (_) {}
        try { await m.addColumn(customers, customers.channel); } catch (_) {}
        try { await m.addColumn(products, products.supplierId); } catch (_) {}
        try { await m.addColumn(products, products.qtyPerCase); } catch (_) {}
        try { await m.addColumn(deliveries, deliveries.deliveryDate); } catch (_) {}
        try { await m.addColumn(stockMovements, stockMovements.createdBy); } catch (_) {}
      }
      // Columns added in v6 (orders screen: cached display fields)
      if (from < 6) {
        try { await m.addColumn(orders, orders.storeName); } catch (_) {}
        try { await m.addColumn(orders, orders.routeId); } catch (_) {}
        try { await m.addColumn(orders, orders.routeName); } catch (_) {}
        try { await m.addColumn(orders, orders.salesRepId); } catch (_) {}
        try { await m.addColumn(orders, orders.salesRepName); } catch (_) {}
        try { await m.addColumn(orders, orders.itemCount); } catch (_) {}
      }
      // v7/v8: payments table (migration may have been skipped on some devices)
      if (from < 8) {
        try { await m.createTable(payments); } catch (_) {}
      }
      // v9: delivery routes table
      if (from < 9) {
        try { await m.createTable(deliveryRoutes); } catch (_) {}
      }
    },
    beforeOpen: (details) async {
      // Nuclear option: guarantee payments table exists regardless of
      // migration history by using raw SQL IF NOT EXISTS.
      await customStatement(
        'CREATE TABLE IF NOT EXISTS payments ('
        '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
        '  payment_id TEXT NOT NULL,'
        '  order_id INTEGER NOT NULL,'
        '  order_code TEXT NOT NULL,'
        '  store_name TEXT NOT NULL,'
        '  sales_rep_id INTEGER NOT NULL,'
        '  sales_rep_name TEXT NOT NULL,'
        '  order_amount REAL NOT NULL,'
        '  amount_paid REAL NOT NULL DEFAULT 0,'
        '  balance REAL NOT NULL,'
        '  payment_method TEXT,'
        '  payment_date INTEGER NOT NULL,'
        '  status TEXT NOT NULL DEFAULT \'unpaid\','
        '  notes TEXT,'
        '  sync_status TEXT NOT NULL DEFAULT \'pending\''
        ')',
      );
      if (!_isTestInstance) {
        await _seedPaymentsIfEmpty();
        await _seedProductsIfEmpty();
        await _seedCustomersIfEmpty();
      }

      await customStatement(
        'CREATE TABLE IF NOT EXISTS delivery_routes ('
        '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
        '  uuid TEXT NOT NULL UNIQUE,'
        '  route_name TEXT NOT NULL,'
        '  municipality TEXT NOT NULL,'
        '  assigned_rep_name TEXT,'
        '  delivery_days TEXT NOT NULL,'
        '  customer_count INTEGER NOT NULL DEFAULT 0,'
        '  status TEXT NOT NULL DEFAULT \'active\','
        '  is_deleted INTEGER NOT NULL DEFAULT 0,'
        '  sync_status TEXT NOT NULL DEFAULT \'pending\','
        '  created_at INTEGER NOT NULL DEFAULT (unixepoch()),'
        '  updated_at INTEGER NOT NULL DEFAULT (unixepoch())'
        ')',
      );
    },
  );

  Future<void> createUser(UsersCompanion user) async {
    await into(users).insert(user);
  }

  Future<List<User>> getAllUsers() async {
    final allUsers = await (select(users)..orderBy([(t) => OrderingTerm(expression: t.firstName)])).get();
    
    // Debug: Print all users and their roles
    debugPrint('=== DEBUG: All Users in Database ===');
    for (final user in allUsers) {
      debugPrint('User: ${user.firstName} ${user.lastName}, Role: ${user.role}, Active: ${user.isActive}, Deleted: ${user.isDeleted}');
    }
    debugPrint('Total users found: ${allUsers.length}');
    debugPrint('====================================');
    
    // Filter out deleted users
    return allUsers.where((user) => !user.isDeleted).toList();
  }

  Stream<List<User>> getAllUsersStream() => (select(users)
        ..where((t) => t.isDeleted.equals(false) | t.isDeleted.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.firstName)])
      ).watch();

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

  // Stream methods for real-time updates
  Stream<int> getTotalUsersCountStream() {
    return customSelect(
      'SELECT COUNT(*) as count FROM users WHERE is_deleted = 0',
    ).watch().map((rows) => rows.first.read<int>('count'));
  }

  Stream<int> getActiveUsersCountStream() {
    return customSelect(
      'SELECT COUNT(*) as count FROM users WHERE is_active = 1 AND is_deleted = 0',
    ).watch().map((rows) => rows.first.read<int>('count'));
  }

  Stream<int> getAdminUsersCountStream() {
    return customSelect(
      'SELECT COUNT(*) as count FROM users WHERE role = "admin" AND is_deleted = 0',
    ).watch().map((rows) => rows.first.read<int>('count'));
  }

  Stream<int> getSalesRepUsersCountStream() {
    return customSelect(
      'SELECT COUNT(*) as count FROM users WHERE role = "sales_rep" AND is_deleted = 0',
    ).watch().map((rows) => rows.first.read<int>('count'));
  }

  Future<bool> markUserAsSynced(String uuid, String remoteId) async => await (update(users)..where((t) => t.uuid.equals(uuid)))
        .write(UsersCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        )) > 0;

  // User management methods
  Future<void> approveUser(String userId, String assignedRole) async {
    await (update(users)..where((u) => u.uuid.equals(userId))).write(
      UsersCompanion(
        role: Value(assignedRole),
        isActive: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deactivateUser(String userId) async {
    await (update(users)..where((u) => u.uuid.equals(userId))).write(
      UsersCompanion(
        isActive: const Value(false),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Rejects a user account
  Future<void> rejectUser(String userId) async {
    await (update(users)..where((u) => u.uuid.equals(userId))).write(
      UsersCompanion(
        role: const Value('rejected'),
        isActive: const Value(false),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Product methods
  Future<void> createProduct(ProductsCompanion product) async {
    await into(products).insert(product);
  }

  Future<List<Product>> getAllProducts() async => (select(products)..where((t) => t.isDeleted.equals(false))).get();

  Stream<List<Product>> watchAllProducts() => (select(products)
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)])
  ).watch();

  /// Adjusts a product's stock count and logs a StockMovement record.
  Future<void> adjustProductStock({
    required String productUuid,
    required int delta,
    required String reason,
    String? notes,
    required String userUuid,
    required String userName,
    String? referenceId,
  }) async {
    await transaction(() async {
      final product = await (select(products)..where((t) => t.uuid.equals(productUuid))).getSingle();
      await (update(products)..where((t) => t.uuid.equals(productUuid))).write(
        ProductsCompanion(
          currentStock: Value(product.currentStock + delta),
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await into(stockMovements).insert(StockMovementsCompanion.insert(
        uuid: const Uuid().v4(),
        productId: productUuid,
        movementType: delta >= 0 ? 'in' : 'out',
        quantity: delta.abs(),
        reason: reason,
        notes: Value(notes),
        referenceId: Value(referenceId),
        userId: userUuid,
        userName: userName,
        syncStatus: const Value('pending'),
      ));
    });
  }

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

  Stream<List<Customer>> watchAllCustomers() => (select(customers)
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)])
  ).watch();

  Future<Customer?> getCustomerById(String id) async => (select(customers)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<Customer?> getCustomerByIntId(int id) async => (select(customers)..where((t) => t.id.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

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
  Future<int> createOrder(OrdersCompanion order) => into(orders).insert(order);

  Future<Order?> getOrderById(String id) async => (select(orders)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Future<List<Order>> getOrdersByCustomerId(String customerId) async => (select(orders)..where((t) => t.customerId.equals(customerId) & t.isDeleted.equals(false))).get();

  Future<List<Order>> getOrdersByRouteName(String routeName) async => (select(orders)
    ..where((t) => t.routeName.equals(routeName) & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
  ).get();

  Future<List<Order>> getPendingOrders() async => (select(orders)
    ..where((t) => t.status.equals('pending') & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
  ).get();

  Future<List<Order>> getOrdersReadyForDelivery() async => (select(orders)
    ..where((t) => t.warehouseStatus.equals('ready') & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
  ).get();

  // Order Item methods
  Future<int> createOrderItem(OrderItemsCompanion orderItem) => into(orderItems).insert(orderItem);

  Future<List<OrderItem>> getOrderItemsByOrderId(String orderId) async => (select(orderItems)..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false))).get();

  Future<OrderItem?> getOrderItemById(String id) async => (select(orderItems)..where((t) => t.uuid.equals(id) & t.isDeleted.equals(false))).getSingleOrNull();

  Stream<List<OrderItem>> watchAllOrderItems() => (select(orderItems)
    ..where((t) => t.isDeleted.equals(false))
  ).watch();

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

  Stream<List<StockMovement>> watchAllStockMovements() => (select(stockMovements)
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
  ).watch();

  Future<List<Order>> getPendingSyncOrders() async => (select(orders)..where((t) => t.syncStatus.equals('pending'))).get();

  Stream<List<Order>> watchAllOrders() => (select(orders)
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
  ).watch();

  Stream<List<Order>> watchOrdersBySalesRep(String repName) => (select(orders)
    ..where((t) => t.salesRepName.equals(repName) & t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
  ).watch();

  Future<String> generateOrderNumber() async {
    final all = await (select(orders)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    int maxNum = 2400;
    for (final o in all) {
      final match = RegExp(r'ORD-(\d+)').firstMatch(o.orderNumber);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return 'ORD-${maxNum + 1}';
  }

  Future<void> updateOrderStatus(String uuid, String status) async {
    await (update(orders)..where((t) => t.uuid.equals(uuid))).write(
      OrdersCompanion(
        status: Value(status),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> seedOrdersForDemo() async {
    final existing = await (select(orders)..where((t) => t.orderNumber.equals('ORD-2401'))).getSingleOrNull();
    if (existing != null) return;

    const seedOrders = [
      ('ORD-2401', 'seed-ord-2401', 'Sari-Sari Store A', 'Route 1 - Centro', 'Juan dela Cruz', 12, 12450.0, 'pending',  '2024-12-15'),
      ('ORD-2405', 'seed-ord-2405', 'Mini Mart E',        'Route 2 - North',  'Maria Santos',  25, 34200.0, 'pending',  '2024-12-15'),
      ('ORD-2408', 'seed-ord-2408', 'Grocery H',          'Route 3 - South',  'Pedro Reyes',   34, 56780.0, 'pending',  '2024-12-14'),
      ('ORD-2403', 'seed-ord-2403', 'Corner Store B',     'Route 1 - Centro', 'Juan dela Cruz', 18, 23500.0, 'completed','2024-12-13'),
      ('ORD-2406', 'seed-ord-2406', 'Tindahan F',         'Route 2 - North',  'Maria Santos',  21, 19650.0, 'completed','2024-12-12'),
      ('ORD-2402', 'seed-ord-2402', 'Store C',            'Route 1 - Centro', 'Juan dela Cruz',  8,  8750.0, 'cancelled','2024-12-10'),
    ];

    for (final (num, uuid, store, route, rep, items, amount, status, dateStr) in seedOrders) {
      await into(orders).insert(OrdersCompanion(
        uuid:            Value(uuid),
        orderNumber:     Value(num),
        customerId:      const Value('seed-customer'),
        deliveryAddress: Value(store),
        storeName:       Value(store),
        routeName:       Value(route),
        salesRepName:    Value(rep),
        itemCount:       Value(items),
        totalAmount:     Value(amount),
        status:          Value(status),
        syncStatus:      const Value('synced'),
        createdAt:       Value(DateTime.parse(dateStr)),
        updatedAt:       Value(DateTime.parse(dateStr)),
      ));
    }

    // Seed items for ORD-2401
    const items2401 = [
      ('seed-item-2401-1', 'Coca-Cola 1.5L',        6,  72.0,  432.0),
      ('seed-item-2401-2', 'Lucky Me Pancit Canton', 24, 14.0,  336.0),
      ('seed-item-2401-3', 'Birch Tree Milk 150g',   12, 38.0,  456.0),
      ('seed-item-2401-4', 'Regent Cheese Rings',    30,  8.0,  240.0),
    ];
    for (final (uuid, name, qty, price, sub) in items2401) {
      await into(orderItems).insert(OrderItemsCompanion(
        uuid:              Value(uuid),
        orderId:           const Value('seed-ord-2401'),
        productId:         const Value('seed-product'),
        productSku:        Value(name.replaceAll(' ', '-').toLowerCase()),
        productName:       Value(name),
        quantity:          Value(qty),
        unitPrice:         Value(price),
        subtotal:          Value(sub),
        totalAmount:       Value(sub),
        availableStock:    const Value(100),
        syncStatus:        const Value('synced'),
      ));
    }
  }

  Future<List<OrderItem>> getPendingSyncOrderItems() async => (select(orderItems)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<List<Delivery>> getPendingSyncDeliveries() async => (select(deliveries)..where((t) => t.syncStatus.equals('pending'))).get();

  // Supplier methods
  Future<List<Supplier>> getAllSuppliers() async =>
      (select(suppliers)..where((t) => t.isDeleted.equals(false))).get();

  Stream<List<Supplier>> watchAllSuppliers() => (select(suppliers)
    ..where((t) => t.isDeleted.equals(false))
  ).watch();

  Future<Supplier?> getSupplierByUuid(String uuid) async =>
      (select(suppliers)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  Future<void> upsertSupplier(SuppliersCompanion supplier) async {
    await into(suppliers).insertOnConflictUpdate(supplier);
  }

  Future<List<Supplier>> getPendingSyncSuppliers() async =>
      (select(suppliers)..where((t) => t.syncStatus.equals('pending'))).get();

  // Delivery route methods
  Stream<List<DeliveryRoute>> watchAllDeliveryRoutes() => (select(deliveryRoutes)
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.routeName)])
  ).watch();

  Future<void> createDeliveryRoute(DeliveryRoutesCompanion route) async {
    await into(deliveryRoutes).insert(route);
  }

  Future<void> updateDeliveryRoute(String uuid, DeliveryRoutesCompanion route) async {
    await (update(deliveryRoutes)..where((t) => t.uuid.equals(uuid)))
        .write(route.copyWith(updatedAt: Value(DateTime.now())));
  }

  // Payment methods
  Stream<List<Payment>> watchAllPayments() => (select(payments)
    ..orderBy([(t) => OrderingTerm(expression: t.paymentDate, mode: OrderingMode.desc)])
  ).watch();

  Future<Payment?> getPaymentById(int id) async =>
      (select(payments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<Payment>> watchPaymentsBySalesRep(String repName) => (select(payments)
    ..where((t) => t.salesRepName.equals(repName))
    ..orderBy([(t) => OrderingTerm(expression: t.paymentDate, mode: OrderingMode.desc)])
  ).watch();

  Future<int> createPayment(PaymentsCompanion payment) => into(payments).insert(payment);

  Future<String> generatePaymentId() async {
    final all = await select(payments).get();
    int maxNum = 0;
    for (final p in all) {
      final match = RegExp(r'PAY-(\d+)').firstMatch(p.paymentId);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return 'PAY-${(maxNum + 1).toString().padLeft(3, '0')}';
  }

  Future<void> updatePayment(int id, PaymentsCompanion companion) async {
    await (update(payments)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<List<Payment>> getPendingSyncPayments() async =>
      (select(payments)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<void> _seedPaymentsIfEmpty() async {
    final countExpr = payments.id.count();
    final count = await (selectOnly(payments)..addColumns([countExpr]))
        .map((r) => r.read(countExpr))
        .getSingle();
    if ((count ?? 0) > 0) return;
    await seedPaymentsForDemo();
  }

  Future<void> seedPaymentsForDemo() async {
    final existing = await (select(payments)..where((t) => t.paymentId.equals('PAY-001'))).getSingleOrNull();
    if (existing != null) return;

    const seedPayments = [
      ('PAY-001', 1, 'ORD-2401', 'Sari-Sari Store A', 1, 'Juan dela Cruz', 12450.0, 12450.0, 0.0,    'Cash',  '2024-12-15', 'paid'),
      ('PAY-002', 2, 'ORD-2405', 'Mini Mart E',        2, 'Maria Santos',   34200.0, 10000.0, 24200.0, 'GCash', '2024-12-15', 'partial'),
      ('PAY-003', 3, 'ORD-2408', 'Grocery H',          3, 'Pedro Reyes',    56780.0, 0.0,     56780.0, null,    '2024-12-14', 'unpaid'),
      ('PAY-004', 4, 'ORD-2403', 'Corner Store B',     1, 'Juan dela Cruz', 23500.0, 23500.0, 0.0,    'Cash',  '2024-12-13', 'paid'),
      ('PAY-005', 5, 'ORD-2406', 'Tindahan F',         2, 'Maria Santos',   19650.0, 0.0,     19650.0, null,    '2024-12-12', 'credit'),
      ('PAY-006', 6, 'ORD-2402', 'Store C',            1, 'Juan dela Cruz',  8750.0,  8750.0,     0.0, null,    '2024-12-10', 'paid'),
    ];

    for (final (pid, oid, ocode, store, repId, repName, orderAmt, paid, bal, method, dateStr, status) in seedPayments) {
      await into(payments).insert(PaymentsCompanion(
        paymentId:     Value(pid),
        orderId:       Value(oid),
        orderCode:     Value(ocode),
        storeName:     Value(store),
        salesRepId:    Value(repId),
        salesRepName:  Value(repName),
        orderAmount:   Value(orderAmt),
        amountPaid:    Value(paid),
        balance:       Value(bal),
        paymentMethod: Value(method),
        paymentDate:   Value(DateTime.parse(dateStr)),
        status:        Value(status),
        syncStatus:    const Value('synced'),
      ));
    }
  }

  Future<void> _seedProductsIfEmpty() async {
    final countExpr = products.id.count();
    final count = await (selectOnly(products)..addColumns([countExpr]))
        .map((r) => r.read(countExpr))
        .getSingle();
    if ((count ?? 0) > 0) return;
    await seedProductsForDemo();
  }

  Future<void> seedProductsForDemo() async {
    final existing = await (select(products)..where((t) => t.sku.equals('COKE-1.5L'))).getSingleOrNull();
    if (existing != null) return;

    const seedProducts = [
      ('COKE-1.5L',    'Coca-Cola 1.5L',            'Beverages',     72.0, 58.0, 'btl', 120, 24),
      ('LM-PC-55G',    'Lucky Me Pancit Canton',    'Snacks',        14.0, 10.5, 'pc',  300, 48),
      ('BT-MILK-150G', 'Birch Tree Milk 150g',      'Dairy',         38.0, 30.0, 'pc',  150, 30),
      ('RG-CHEESE',    'Regent Cheese Rings',        'Snacks',         8.0,  5.5, 'pc',  200, 40),
      ('NES-3IN1',     'Nescafe 3-in-1',             'Beverages',      9.0,  6.5, 'pc',  250, 50),
      ('SG-SOAP',      'Safeguard Soap',             'Personal Care', 32.0, 24.0, 'pc',   90, 20),
      ('CT-TUNA',      'Century Tuna',               'Canned Goods',  28.0, 21.0, 'can', 180, 36),
      ('KP-CANDY',     'Kopiko Coffee Candy',        'Snacks',         5.0,  3.0, 'pc',  400, 60),
      ('ARG-CB',       'Argentina Corned Beef',      'Canned Goods',  45.0, 36.0, 'can', 100, 20),
      ('PT-CHIPS',     'Piattos Chips',              'Snacks',        22.0, 16.0, 'pc',  140, 28),
    ];

    for (final (sku, name, category, price, cost, unit, stock, minStock) in seedProducts) {
      await into(products).insert(ProductsCompanion(
        uuid:         Value('seed-product-$sku'),
        sku:          Value(sku),
        name:         Value(name),
        category:     Value(category),
        unitPrice:    Value(price),
        costPrice:    Value(cost),
        unit:         Value(unit),
        currentStock: Value(stock),
        minStock:     Value(minStock),
        syncStatus:   const Value('synced'),
      ));
    }
  }

  Future<void> _seedCustomersIfEmpty() async {
    final countExpr = customers.id.count();
    final count = await (selectOnly(customers)..addColumns([countExpr]))
        .map((r) => r.read(countExpr))
        .getSingle();
    if ((count ?? 0) > 0) return;
    await seedCustomersForDemo();
  }

  Future<void> seedCustomersForDemo() async {
    final existing = await (select(customers)..where((t) => t.uuid.equals('seed-customer-a'))).getSingleOrNull();
    if (existing != null) return;

    const seedCustomers = [
      ('seed-customer-a', 'Sari-Sari Store A',            'Boac',       'Poblacion',  'Sari-Sari Store', '0917-100-0001'),
      ('seed-customer-b', 'Corner Store B',                'Boac',       'Tabi',       'Sari-Sari Store', '0917-100-0002'),
      ('seed-customer-c', 'Store C',                       'Buenavista', 'Poctoy',     'Sari-Sari Store', '0917-100-0003'),
      ('seed-customer-e', 'Mini Mart E',                    'Mogpog',    'Poblacion',  'Mini Mart',       '0917-100-0004'),
      ('seed-customer-f', 'Tindahan F',                     'Torrijos',  'Poblacion',  'Sari-Sari Store', '0917-100-0005'),
      ('seed-customer-h', 'Grocery H',                      'Santa Cruz','Poblacion',  'Grocery',         '0917-100-0006'),
      ('seed-customer-i', "Aling Nena's Store",              'Gasan',     'Poblacion',  'Sari-Sari Store', '0917-100-0007'),
      ('seed-customer-j', 'Kuya Bong Sari-Sari',             'Boac',      'Malbog',     'Sari-Sari Store', '0917-100-0008'),
      ('seed-customer-k', 'Reyes General Merchandise',       'Santa Cruz','Poblacion',  'Grocery',         '0917-100-0009'),
      ('seed-customer-l', 'Dela Cruz Mini Grocery',          'Mogpog',    'Poblacion',  'Mini Mart',       '0917-100-0010'),
    ];

    for (final (uuid, name, town, barangay, storeType, contact) in seedCustomers) {
      await into(customers).insert(CustomersCompanion(
        uuid:           Value(uuid),
        name:           Value(name),
        municipality:   Value(town),
        province:       const Value('Marinduque'),
        town:           Value(town),
        barangay:       Value(barangay),
        storeType:      Value(storeType),
        contactNumber:  Value(contact),
        channel:        Value(storeType),
        syncStatus:     const Value('synced'),
      ));
    }
  }

  Future<void> resetUserPassword(String uuid, String newPasswordHash) async {
    await (update(users)..where((u) => u.uuid.equals(uuid))).write(
      UsersCompanion(
        passwordHash: Value(newPasswordHash),
        forcePasswordChange: Value(true),
        syncStatus: Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateUserPassword(String uuid, String newPasswordHash) async {
    await (update(users)..where((u) => u.uuid.equals(uuid))).write(
      UsersCompanion(
        passwordHash: Value(newPasswordHash),
        forcePasswordChange: Value(false),
        syncStatus: Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'villahermosa_inventory.db'));
  return NativeDatabase(file);
});
