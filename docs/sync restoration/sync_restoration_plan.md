# Villahermosa Sync Module Restoration Plan
## Quality-First Production-Ready Sync System

---

## 📋 Overview

**Objective**: Restore and enhance the sync module for production-ready offline-first architecture  
**Timeline**: Quality over speed (estimated 5-7 days)  
**Approach**: Systematic, well-tested, production-grade implementation

---

## 🎯 Phase 1: Assessment & Analysis (Day 1)

### Step 1.1: Inventory Current State (1 hour)

**Action**: Document what exists
```bash
# In your project root
cd /path/to/villahermosa_inventory_system

# List all sync-related files
find lib/core/sync -name "*.dart" -type f
find lib/core/services -name "*sync*.dart" -type f

# Check for errors
dart analyze lib/core/sync/
dart analyze lib/core/services/sync_service.dart
```

**Document**:
- [ ] Which files exist
- [ ] What errors appear
- [ ] What Drift APIs are being used
- [ ] Current sync flow architecture

### Step 1.2: Review Drift 2.18.0 Changes (2 hours)

**Key Drift 2.x Breaking Changes**:

1. **Query API Changes**:
   ```dart
   // OLD (Drift 1.x)
   await (select(table)..where((t) => t.id.equals(1))).getSingle();
   
   // NEW (Drift 2.x) - same syntax, but better error handling
   await (select(table)..where((t) => t.id.equals(1))).getSingleOrNull();
   ```

2. **Insert/Update Changes**:
   ```dart
   // OLD
   await into(table).insert(data);
   
   // NEW - explicit modes
   await into(table).insert(data, mode: InsertMode.insertOrReplace);
   ```

3. **Stream Changes**:
   ```dart
   // OLD
   select(table).watch()
   
   // NEW - same, but type safety improved
   select(table).watch() // returns Stream<List<TableData>>
   ```

**Action**: Read official migration guide
- Visit: https://drift.simonbinder.eu/docs/advanced-features/migrations/

### Step 1.3: Analyze Sync Requirements (1 hour)

**Questions to Answer**:
- [ ] What tables need syncing? (All 8 tables?)
- [ ] What's the sync direction? (Bidirectional?)
- [ ] How to handle conflicts? (Last-write-wins? Manual resolution?)
- [ ] When to sync? (Manual, periodic, on connectivity?)

**Document Current Design**:
```
Review files:
- lib/core/sync/sync_engine.dart
- lib/core/sync/sync_manager.dart
- lib/core/database/tables/*.dart (check syncStatus fields)
```

---

## 🔧 Phase 2: Foundation Fixes (Day 2-3)

### Step 2.1: Update Database Schema for Sync (3 hours)

**Verify All Tables Have Sync Fields**:

```dart
// Each table should have:
class TableName extends Table {
  // ... other fields
  
  // Sync infrastructure
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
```

**Action**:
1. Check each table in `lib/core/database/tables/`
2. Add missing sync fields
3. Create migration if needed

**Migration Example**:
```dart
// lib/core/database/migrations.dart
class Migration2To3 extends TableMigration {
  @override
  Future<void> migrate(Migrator m, int from, int to) async {
    if (from < 3) {
      // Add sync fields to existing tables
      await m.addColumn(products, products.syncStatus);
      await m.addColumn(products, products.remoteId);
      // ... repeat for each table
    }
  }
}
```

### Step 2.2: Create Robust Sync Models (2 hours)

**File**: `lib/core/sync/sync_models.dart`

```dart
/// Sync status for tracking record state
enum SyncStatus {
  pending,   // Local changes not synced
  synced,    // In sync with remote
  conflict,  // Conflict detected
  error;     // Sync failed
  
  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

/// Sync operation result
class SyncResult {
  final bool success;
  final int recordsSynced;
  final List<SyncConflict> conflicts;
  final String? error;
  final DateTime timestamp;
  
  SyncResult({
    required this.success,
    this.recordsSynced = 0,
    this.conflicts = const [],
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasErrors => error != null;
}

/// Represents a sync conflict
class SyncConflict {
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localUpdated;
  final DateTime remoteUpdated;
  
  SyncConflict({
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.remoteData,
    required this.localUpdated,
    required this.remoteUpdated,
  });
  
  /// Automatic resolution: last-write-wins
  Map<String, dynamic> resolveLastWriteWins() {
    return localUpdated.isAfter(remoteUpdated) ? localData : remoteData;
  }
}

/// Configuration for sync operations
class SyncConfig {
  final bool autoSync;
  final Duration syncInterval;
  final bool syncOnConnectivity;
  final ConflictResolutionStrategy conflictStrategy;
  
  const SyncConfig({
    this.autoSync = true,
    this.syncInterval = const Duration(minutes: 5),
    this.syncOnConnectivity = true,
    this.conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
  });
}

enum ConflictResolutionStrategy {
  lastWriteWins,
  manualReview,
  localPriority,
  remotePriority,
}
```

### Step 2.3: Implement Core Sync Engine (4 hours)

**File**: `lib/core/sync/sync_engine.dart`

```dart
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import 'sync_models.dart';

class SyncEngine {
  final AppDatabase _database;
  final SupabaseClient _supabase;
  final SyncConfig config;
  
  SyncEngine(this._database, this._supabase, {
    this.config = const SyncConfig(),
  });
  
  /// Main sync operation: push local changes, pull remote changes
  Future<SyncResult> performSync() async {
    try {
      final conflicts = <SyncConflict>[];
      int recordsSynced = 0;
      
      // Step 1: Push local changes to remote
      final pushResult = await _pushLocalChanges();
      recordsSynced += pushResult.recordsSynced;
      conflicts.addAll(pushResult.conflicts);
      
      // Step 2: Pull remote changes to local
      final pullResult = await _pullRemoteChanges();
      recordsSynced += pullResult.recordsSynced;
      conflicts.addAll(pullResult.conflicts);
      
      // Step 3: Resolve conflicts if any
      if (conflicts.isNotEmpty) {
        await _resolveConflicts(conflicts);
      }
      
      return SyncResult(
        success: true,
        recordsSynced: recordsSynced,
        conflicts: conflicts,
      );
      
    } catch (e, stackTrace) {
      print('Sync error: $e\n$stackTrace');
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Push pending local changes to Supabase
  Future<SyncResult> _pushLocalChanges() async {
    int synced = 0;
    
    // Get all pending records from each table
    final pendingProducts = await _database.getPendingSyncRecords('products');
    final pendingOrders = await _database.getPendingSyncRecords('orders');
    // ... repeat for each table
    
    // Push products
    for (final record in pendingProducts) {
      await _pushRecord('products', record);
      synced++;
    }
    
    // Push orders
    for (final record in pendingOrders) {
      await _pushRecord('orders', record);
      synced++;
    }
    
    return SyncResult(success: true, recordsSynced: synced);
  }
  
  /// Pull remote changes from Supabase
  Future<SyncResult> _pullRemoteChanges() async {
    int synced = 0;
    
    // Get last sync timestamp
    final lastSync = await _database.getLastSyncTimestamp();
    
    // Fetch updated records from each table
    final remoteProducts = await _supabase
        .from('products')
        .select()
        .gt('updated_at', lastSync.toIso8601String())
        .execute();
    
    if (remoteProducts.data != null) {
      for (final record in remoteProducts.data as List) {
        await _pullRecord('products', record);
        synced++;
      }
    }
    
    // Update last sync timestamp
    await _database.updateLastSyncTimestamp(DateTime.now());
    
    return SyncResult(success: true, recordsSynced: synced);
  }
  
  /// Push a single record to Supabase
  Future<void> _pushRecord(String tableName, Map<String, dynamic> record) async {
    final remoteId = record['remoteId'] as String?;
    
    if (remoteId == null) {
      // New record - insert
      final response = await _supabase.from(tableName).insert(record).select().single();
      
      // Update local record with remote ID
      await _database.updateRemoteId(
        tableName,
        record['id'],
        response['id'] as String,
      );
    } else {
      // Existing record - update
      await _supabase.from(tableName).update(record).eq('id', remoteId);
    }
    
    // Mark as synced
    await _database.updateSyncStatus(tableName, record['id'], SyncStatus.synced);
  }
  
  /// Pull a single record from Supabase
  Future<void> _pullRecord(String tableName, Map<String, dynamic> record) async {
    final remoteId = record['id'] as String;
    
    // Check if record exists locally
    final localRecord = await _database.getRecordByRemoteId(tableName, remoteId);
    
    if (localRecord == null) {
      // New record - insert locally
      await _database.insertRemoteRecord(tableName, record);
    } else {
      // Existing record - update locally
      await _database.updateFromRemote(tableName, localRecord['id'], record);
    }
  }
  
  /// Resolve sync conflicts
  Future<void> _resolveConflicts(List<SyncConflict> conflicts) async {
    for (final conflict in conflicts) {
      switch (config.conflictStrategy) {
        case ConflictResolutionStrategy.lastWriteWins:
          final resolved = conflict.resolveLastWriteWins();
          await _database.updateRecord(conflict.tableName, conflict.recordId, resolved);
          break;
        
        case ConflictResolutionStrategy.localPriority:
          // Keep local version
          await _database.updateSyncStatus(
            conflict.tableName,
            conflict.recordId,
            SyncStatus.synced,
          );
          break;
        
        case ConflictResolutionStrategy.remotePriority:
          // Use remote version
          await _database.updateRecord(
            conflict.tableName,
            conflict.recordId,
            conflict.remoteData,
          );
          break;
        
        case ConflictResolutionStrategy.manualReview:
          // Mark for manual review
          await _database.updateSyncStatus(
            conflict.tableName,
            conflict.recordId,
            SyncStatus.conflict,
          );
          break;
      }
    }
  }
}
```

---

## 🧪 Phase 3: Database Extensions (Day 3-4)

### Step 3.1: Add Sync Helper Methods to Database (3 hours)

**File**: `lib/core/database/app_database.dart`

Add these methods to your `AppDatabase` class:

```dart
// In AppDatabase class

/// Get all records with pending sync status
Future<List<Map<String, dynamic>>> getPendingSyncRecords(String tableName) async {
  // This needs to be implemented per table due to Drift's type safety
  // Example for products:
  if (tableName == 'products') {
    final results = await (select(products)
      ..where((t) => t.syncStatus.equals('pending')))
      .get();
    
    return results.map((row) => row.toJson()).toList();
  }
  // Repeat for each table...
  throw UnimplementedError('Table $tableName not implemented');
}

/// Update remote ID after successful sync
Future<void> updateRemoteId(String tableName, dynamic localId, String remoteId) async {
  if (tableName == 'products') {
    await (update(products)..where((t) => t.id.equals(localId as int)))
      .write(ProductsCompanion(remoteId: Value(remoteId)));
  }
  // Repeat for each table...
}

/// Update sync status
Future<void> updateSyncStatus(String tableName, dynamic recordId, SyncStatus status) async {
  if (tableName == 'products') {
    await (update(products)..where((t) => t.id.equals(recordId as int)))
      .write(ProductsCompanion(syncStatus: Value(status.name)));
  }
  // Repeat for each table...
}

/// Get record by remote ID
Future<Map<String, dynamic>?> getRecordByRemoteId(String tableName, String remoteId) async {
  if (tableName == 'products') {
    final result = await (select(products)
      ..where((t) => t.remoteId.equals(remoteId)))
      .getSingleOrNull();
    
    return result?.toJson();
  }
  // Repeat for each table...
  return null;
}

/// Get last sync timestamp
Future<DateTime> getLastSyncTimestamp() async {
  // Store in a settings table or shared preferences
  // For now, return a default
  return DateTime.now().subtract(Duration(hours: 24));
}

/// Update last sync timestamp
Future<void> updateLastSyncTimestamp(DateTime timestamp) async {
  // Store in settings table or shared preferences
}
```

### Step 3.2: Create Typed Sync Repositories (4 hours)

Instead of string-based table names, create type-safe sync repositories:

**File**: `lib/core/sync/repositories/product_sync_repository.dart`

```dart
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../sync_models.dart';

class ProductSyncRepository {
  final AppDatabase _database;
  
  ProductSyncRepository(this._database);
  
  /// Get all pending products
  Future<List<Product>> getPendingProducts() async {
    return await (_database.select(_database.products)
      ..where((t) => t.syncStatus.equals('pending')))
      .get();
  }
  
  /// Mark product as synced
  Future<void> markSynced(int productId, String remoteId) async {
    await (_database.update(_database.products)
      ..where((t) => t.id.equals(productId)))
      .write(ProductsCompanion(
        remoteId: Value(remoteId),
        syncStatus: Value(SyncStatus.synced.name),
        updatedAt: Value(DateTime.now()),
      ));
  }
  
  /// Get product by remote ID
  Future<Product?> getByRemoteId(String remoteId) async {
    return await (_database.select(_database.products)
      ..where((t) => t.remoteId.equals(remoteId)))
      .getSingleOrNull();
  }
  
  /// Insert product from remote
  Future<int> insertFromRemote(Map<String, dynamic> data) async {
    return await _database.into(_database.products).insert(
      ProductsCompanion.insert(
        uuid: data['uuid'] as String,
        name: data['name'] as String,
        price: data['price'] as double,
        stockQuantity: data['stock_quantity'] as int,
        remoteId: Value(data['id'] as String),
        syncStatus: Value(SyncStatus.synced.name),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        updatedAt: Value(DateTime.parse(data['updated_at'] as String)),
      ),
    );
  }
  
  /// Update product from remote
  Future<void> updateFromRemote(int localId, Map<String, dynamic> data) async {
    await (_database.update(_database.products)
      ..where((t) => t.id.equals(localId)))
      .write(ProductsCompanion(
        name: Value(data['name'] as String),
        price: Value(data['price'] as double),
        stockQuantity: Value(data['stock_quantity'] as int),
        syncStatus: Value(SyncStatus.synced.name),
        updatedAt: Value(DateTime.parse(data['updated_at'] as String)),
      ));
  }
}
```

**Repeat this pattern for**:
- `order_sync_repository.dart`
- `customer_sync_repository.dart`
- `delivery_sync_repository.dart`
- etc.

---

## 🧪 Phase 4: Testing (Day 5)

### Step 4.1: Unit Tests (3 hours)

**File**: `test/sync/sync_engine_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:villahermosa_inventory_system/core/sync/sync_engine.dart';

void main() {
  group('SyncEngine', () {
    late SyncEngine syncEngine;
    late MockDatabase mockDatabase;
    late MockSupabase mockSupabase;
    
    setUp(() {
      mockDatabase = MockDatabase();
      mockSupabase = MockSupabase();
      syncEngine = SyncEngine(mockDatabase, mockSupabase);
    });
    
    test('should sync pending records to remote', () async {
      // Arrange
      when(mockDatabase.getPendingProducts()).thenReturn([
        Product(id: 1, name: 'Test Product'),
      ]);
      
      // Act
      final result = await syncEngine.performSync();
      
      // Assert
      expect(result.success, true);
      expect(result.recordsSynced, greaterThan(0));
    });
    
    test('should handle sync conflicts', () async {
      // Test conflict resolution
    });
    
    test('should handle network errors gracefully', () async {
      // Test error handling
    });
  });
}
```

### Step 4.2: Integration Tests (2 hours)

**File**: `test/integration/sync_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Complete sync workflow', (tester) async {
    // 1. Create product offline
    // 2. Trigger sync
    // 3. Verify product appears in Supabase
    // 4. Modify on another device
    // 5. Sync again
    // 6. Verify local update
  });
}
```

---

## 🚀 Phase 5: Integration & Deployment (Day 6-7)

### Step 5.1: Connect to UI (2 hours)

**File**: `lib/core/services/sync_service.dart`

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_models.dart';

class SyncService {
  final SyncEngine _syncEngine;
  final Connectivity _connectivity;
  bool _isSyncing = false;
  
  SyncService(this._syncEngine, this._connectivity) {
    _initializeAutoSync();
  }
  
  void _initializeAutoSync() {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        performSync();
      }
    });
  }
  
  /// Manually trigger sync
  Future<SyncResult> performSync() async {
    if (_isSyncing) {
      return SyncResult(success: false, error: 'Sync already in progress');
    }
    
    _isSyncing = true;
    try {
      final result = await _syncEngine.performSync();
      return result;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
}
```

### Step 5.2: Add Sync UI Indicators (2 hours)

**File**: `lib/shared/widgets/sync_indicator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SyncIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        if (syncService.isSyncing) {
          return Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Syncing...', style: TextStyle(fontSize: 12)),
            ],
          );
        }
        
        return Row(
          children: [
            Icon(Icons.cloud_done, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text('Synced', style: TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }
}
```

### Step 5.3: Production Checklist (2 hours)

- [ ] All tables have sync fields
- [ ] Sync engine handles all tables
- [ ] Conflict resolution tested
- [ ] Error handling comprehensive
- [ ] UI shows sync status
- [ ] Auto-sync on connectivity works
- [ ] Manual sync button works
- [ ] Offline mode works without errors
- [ ] Performance acceptable (<2s for typical sync)
- [ ] Logging for debugging

---

## 📊 Success Metrics

### Functional Requirements
- ✅ Local changes sync to Supabase
- ✅ Remote changes sync to local
- ✅ Conflicts are detected and resolved
- ✅ Works offline gracefully
- ✅ Auto-syncs on connectivity

### Quality Requirements
- ✅ All tests pass
- ✅ No data loss scenarios
- ✅ Type-safe operations
- ✅ Comprehensive error handling
- ✅ Performance within limits

### User Experience
- ✅ Sync status visible to users
- ✅ Manual sync option available
- ✅ Conflicts surfaced appropriately
- ✅ No blocking operations

---

## 🔍 Debugging Tips

### Common Issues

1. **"Table doesn't have sync fields"**
   - Add migration to add fields
   - Regenerate database: `flutter pub run build_runner build`

2. **"Type mismatch errors"**
   - Check UUID vs Integer ID conventions
   - Use TypeValidator utilities

3. **"Conflicts not resolving"**
   - Verify timestamp comparisons
   - Check conflict resolution strategy

4. **"Sync too slow"**
   - Add indexes on sync fields
   - Batch operations
   - Use pagination for large datasets

### Logging

Add comprehensive logging:
```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Starting sync...');
logger.i('Synced $count records');
logger.w('Conflict detected: $conflict');
logger.e('Sync failed: $error');
```

---

## 📚 Resources

- Drift Documentation: https://drift.simonbinder.eu/
- Supabase Flutter: https://supabase.com/docs/reference/dart
- Offline-First Architecture: https://offlinefirst.org/

---

## ✅ Completion Criteria

You can consider the sync module **production-ready** when:

1. All unit tests pass
2. Integration tests pass
3. Manual testing confirms:
   - Create record offline → syncs when online
   - Modify remote → pulls to local
   - Conflict scenarios → resolve correctly
   - Network errors → graceful degradation
4. Performance metrics met
5. Code review completed
6. Documentation updated

---

**Next Action**: Start with Phase 1 assessment. Run the commands and document your findings before proceeding to implementation.
