import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:villahermosa_inventory_system/core/database/app_database.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Customers Database Tests', () {
    late AppDatabase database;

    setUp(() {
      // Use in-memory database for testing
      database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    });

    tearDown(() async {
      await database.close();
    });

    test('Create and retrieve customer', () async {
      // Create a customer with UUID
      const customerId = '550e8400-e29b-41d4-a716-446655440100';
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: customerId,
          name: 'John Customer',
          email: const Value('customer@example.com'),
          phone: const Value('+1234567890'),
          address: const Value('123 Main St'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      // Retrieve the customer
      final customer = await database.getCustomerById(customerId);
      
      expect(customer, isNotNull);
      expect(customer!.name, equals('John Customer'));
      expect(customer.email, equals('customer@example.com'));
      expect(customer.phone, equals('+1234567890'));
      expect(customer.address, equals('123 Main St'));
      expect(customer.customerType, equals('regular'));
      expect(customer.status, equals('active'));
      expect(customer.syncStatus, equals('pending'));
    });

    test('Get all customers', () async {
      // Create multiple customers
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: '550e8400-e29b-41d4-a716-446655440101',
          name: 'Alice Customer',
          email: const Value('alice@example.com'),
          customerType: const Value('individual'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      database.createCustomer(
        CustomersCompanion.insert(
          uuid: '550e8400-e29b-41d4-a716-446655440102',
          name: 'Bob Business',
          email: const Value('bob@business.com'),
          businessName: const Value('Bob Enterprises'),
          customerType: const Value('business'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Wholesale',
          contactNumber: '+1234567890',
        ),
      );

      // Get all customers
      final customers = await database.getAllCustomers();
      
      expect(customers.length, equals(2));
      expect(customers[0].name, equals('Alice Customer')); // Should be alphabetically sorted
      expect(customers[1].name, equals('Bob Business'));
    });

    test('Search customers by name', () async {
      // Create customers
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: '550e8400-e29b-41d4-a716-446655440103',
          name: 'Alice Smith',
          email: const Value('alice@example.com'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      database.createCustomer(
        CustomersCompanion.insert(
          uuid: '550e8400-e29b-41d4-a716-446655440104',
          name: 'Bob Johnson',
          email: const Value('bob@example.com'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      // Search for "Alice"
      final results = await database.searchCustomersByName('Alice');
      
      expect(results.length, equals(1));
      expect(results[0].name, equals('Alice Smith'));
    });

    test('Update customer', () async {
      // Create a customer
      const customerId = '550e8400-e29b-41d4-a716-446655440105';
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: customerId,
          name: 'John Customer',
          email: const Value('john@example.com'),
          customerType: const Value('individual'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      // Update the customer
      final updated = await database.updateCustomer(
        customerId,
        const CustomersCompanion(
          name: Value('John Updated'),
          phone: Value('+9876543210'),
          customerType: Value('business'),
        ),
      );

      expect(updated, isTrue);

      // Verify the update
      final customer = await database.getCustomerById(customerId);
      expect(customer!.name, equals('John Updated'));
      expect(customer.phone, equals('+9876543210'));
      expect(customer.customerType, equals('business'));
    });

    test('Soft delete customer', () async {
      // Create a customer
      const customerId = '550e8400-e29b-41d4-a716-446655440106';
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: customerId,
          name: 'To Be Deleted',
          email: const Value('delete@example.com'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      // Soft delete the customer
      final deleted = await database.softDeleteCustomer(customerId);
      expect(deleted, isTrue);

      // Customer should not appear in getAllCustomers
      final customers = await database.getAllCustomers();
      expect(customers.where((c) => c.uuid == customerId), isEmpty);

      // And should not be retrievable by ID (since it's soft deleted)
      final customer = await database.getCustomerById(customerId);
      expect(customer, isNull);
    });

    test('Get pending sync customers', () async {
      // Create customers with different sync statuses
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: '550e8400-e29b-41d4-a716-446655440107',
          name: 'Pending Customer',
          email: const Value('pending@example.com'),
          syncStatus: const Value('pending'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      database.createCustomer(
        CustomersCompanion.insert(
          uuid: '550e8400-e29b-41d4-a716-446655440108',
          name: 'Synced Customer',
          email: const Value('synced@example.com'),
          syncStatus: const Value('synced'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      // Get pending sync customers
      final pendingCustomers = await database.getPendingSyncCustomers();
      
      expect(pendingCustomers.length, equals(1));
      expect(pendingCustomers[0].name, equals('Pending Customer'));
    });

    test('Mark customer as synced', () async {
      // Create a customer
      const customerId = '550e8400-e29b-41d4-a716-446655440109';
      const remoteId = 'remote-uuid-123';
      
      database.createCustomer(
        CustomersCompanion.insert(
          uuid: customerId,
          name: 'Sync Test Customer',
          email: const Value('sync@example.com'),
          syncStatus: const Value('pending'),
          municipality: 'Sample City',
          province: 'Sample Province',
          storeType: 'Retail',
          contactNumber: '+1234567890',
        ),
      );

      // Mark as synced
      final customer = await database.getCustomerByEmail('sync@example.com');
      expect(customer, isNotNull);
      final synced = await database.markCustomerAsSynced(customer!.uuid, remoteId);
      expect(synced, isTrue);

      // Verify the sync status
      final syncedCustomer = await database.getCustomerByEmail('sync@example.com');
      expect(syncedCustomer!.syncStatus, equals('synced'));
      expect(syncedCustomer.remoteId, equals(remoteId));
    });
  });
}
