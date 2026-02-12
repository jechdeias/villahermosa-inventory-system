# Sync Module Troubleshooting Guide

## 🔧 Common Errors & Solutions

---

## Error Category: Database/Drift

### Error: "The getter 'syncStatus' isn't defined for the type 'Product'"

**Cause**: Table doesn't have sync fields defined

**Solution**:
```dart
// In lib/core/database/tables/products_table.dart
class Products extends Table {
  // ... existing fields
  
  // Add these sync fields
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
```

Then regenerate:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Error: "A value of type 'Null' can't be returned from the method 'getSingle'"

**Cause**: Drift 2.x requires explicit null handling

**Old Code**:
```dart
final product = await (select(products)..where((t) => t.id.equals(1))).getSingle();
```

**New Code**:
```dart
final product = await (select(products)..where((t) => t.id.equals(1))).getSingleOrNull();
if (product == null) {
  // Handle not found
  throw Exception('Product not found');
}
```

---

### Error: "Insert mode is required"

**Cause**: Drift 2.x requires explicit insert mode

**Old Code**:
```dart
await into(products).insert(product);
```

**New Code**:
```dart
await into(products).insert(
  product,
  mode: InsertMode.insertOrReplace, // or InsertMode.insert
);
```

---

### Error: "Cannot convert String to int for ID field"

**Cause**: Mixed UUID/Integer ID convention

**Solution**: Use TypeValidator
```dart
import '../utils/type_validator.dart';

// When converting from Supabase (String) to local (int)
final localId = TypeValidator.toInt(supabaseId);

// When converting from local (int) to Supabase (String)
final remoteId = TypeValidator.toString(localId);
```

---

## Error Category: Supabase

### Error: "No 'Authorization' header was specified"

**Cause**: Supabase client not initialized with auth token

**Solution**:
```dart
// In sync_engine.dart
Future<void> _pushRecord(String tableName, Map<String, dynamic> record) async {
  try {
    // Get current session
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('User not authenticated');
    }
    
    await _supabase
        .from(tableName)
        .insert(record)
        .select()
        .single();
  } catch (e) {
    print('Push error: $e');
    rethrow;
  }
}
```

---

### Error: "Row Level Security policy violation"

**Cause**: Supabase RLS policies blocking sync operations

**Solution**: Check your RLS policies in Supabase dashboard

```sql
-- Example: Allow users to read their own data
CREATE POLICY "Users can read own data"
ON products FOR SELECT
USING (auth.uid() = user_id);

-- Example: Allow users to insert their own data
CREATE POLICY "Users can insert own data"
ON products FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Example: Allow users to update their own data
CREATE POLICY "Users can update own data"
ON products FOR UPDATE
USING (auth.uid() = user_id);
```

---

### Error: "duplicate key value violates unique constraint"

**Cause**: Trying to insert record with ID that already exists

**Solution**: Use upsert instead of insert
```dart
// Instead of insert
await _supabase.from(tableName).insert(record);

// Use upsert
await _supabase.from(tableName).upsert(
  record,
  onConflict: 'id', // or 'uuid', depending on your unique column
);
```

---

## Error Category: Sync Logic

### Error: "Infinite sync loop detected"

**Cause**: Sync triggers itself repeatedly

**Solution**: Add sync guards
```dart
class SyncEngine {
  bool _isSyncing = false;
  
  Future<SyncResult> performSync() async {
    // Guard against concurrent syncs
    if (_isSyncing) {
      return SyncResult(
        success: false,
        error: 'Sync already in progress',
      );
    }
    
    _isSyncing = true;
    try {
      // Sync logic here
    } finally {
      _isSyncing = false; // Always reset
    }
  }
}
```

---

### Error: "Sync conflicts not resolving"

**Cause**: Timestamp comparison logic incorrect

**Debug**:
```dart
print('Local timestamp: ${conflict.localUpdated}');
print('Remote timestamp: ${conflict.remoteUpdated}');
print('Local is after: ${conflict.localUpdated.isAfter(conflict.remoteUpdated)}');
```

**Common Issues**:
1. Timezones not normalized
2. Milliseconds vs seconds comparison
3. String vs DateTime comparison

**Solution**:
```dart
// Always use UTC for consistency
final localTime = conflict.localUpdated.toUtc();
final remoteTime = conflict.remoteUpdated.toUtc();

// Compare
if (localTime.isAfter(remoteTime)) {
  // Local wins
} else {
  // Remote wins
}
```

---

### Error: "Some records not syncing"

**Cause**: Filtering logic incorrect

**Debug**:
```dart
// Check pending records
final pending = await (select(products)
  ..where((t) => t.syncStatus.equals('pending')))
  .get();

print('Pending products: ${pending.length}');
for (final p in pending) {
  print('ID: ${p.id}, Name: ${p.name}, Status: ${p.syncStatus}');
}
```

**Common Issues**:
1. syncStatus not being set on create
2. syncStatus not updated after successful sync
3. Filtering on wrong field

---

## Error Category: Performance

### Error: "Sync taking >10 seconds"

**Cause**: Inefficient database queries or network calls

**Solutions**:

1. **Add indexes**:
```dart
// In your table definition
@override
List<Index> get customIndices => [
  Index('products_sync_status_idx', [syncStatus]),
  Index('products_remote_id_idx', [remoteId]),
];
```

2. **Batch operations**:
```dart
// Instead of individual updates
for (final record in records) {
  await _supabase.from('products').update(record);
}

// Use batch
await _supabase.from('products').upsert(records);
```

3. **Pagination**:
```dart
// Instead of fetching all
final all = await _supabase.from('products').select();

// Use pagination
const pageSize = 100;
var page = 0;
while (true) {
  final batch = await _supabase
      .from('products')
      .select()
      .range(page * pageSize, (page + 1) * pageSize - 1);
  
  if (batch.isEmpty) break;
  
  // Process batch
  await processBatch(batch);
  
  page++;
}
```

---

## Error Category: Connectivity

### Error: "Sync fails when offline"

**Cause**: Not handling offline gracefully

**Solution**:
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncEngine {
  final Connectivity _connectivity;
  
  Future<SyncResult> performSync() async {
    // Check connectivity first
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult == ConnectivityResult.none) {
      return SyncResult(
        success: false,
        error: 'No internet connection',
      );
    }
    
    // Proceed with sync
  }
}
```

---

### Error: "Sync doesn't auto-trigger after going online"

**Cause**: Connectivity listener not set up properly

**Solution**:
```dart
class SyncService {
  late StreamSubscription<ConnectivityResult> _subscription;
  
  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Debounce to avoid rapid triggers
        Future.delayed(Duration(seconds: 2), () {
          performSync();
        });
      }
    });
  }
  
  void dispose() {
    _subscription.cancel();
  }
}
```

---

## Error Category: Data Integrity

### Error: "Foreign key constraint violation"

**Cause**: Syncing child records before parent records

**Solution**: Sync in dependency order
```dart
Future<SyncResult> performSync() async {
  // Order matters!
  await _syncTable('categories');    // No dependencies
  await _syncTable('products');      // Depends on categories
  await _syncTable('customers');     // No dependencies
  await _syncTable('orders');        // Depends on customers
  await _syncTable('order_items');   // Depends on orders AND products
  await _syncTable('deliveries');    // Depends on orders
  
  return SyncResult(success: true);
}
```

---

### Error: "Deleted records reappearing"

**Cause**: Not respecting soft delete flag

**Solution**:
```dart
// When pulling from remote
Future<void> _pullRemoteChanges() async {
  final remoteRecords = await _supabase
      .from('products')
      .select()
      .eq('is_deleted', false)  // Only get non-deleted
      .gt('updated_at', lastSync.toIso8601String());
  
  // Also fetch deleted records to delete locally
  final deletedRecords = await _supabase
      .from('products')
      .select()
      .eq('is_deleted', true)
      .gt('updated_at', lastSync.toIso8601String());
  
  // Mark deleted locally
  for (final record in deletedRecords) {
    await _markDeleted('products', record['id']);
  }
}
```

---

## Debugging Techniques

### 1. Enable Verbose Logging

```dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
  level: Level.debug, // Set to Level.debug for detailed logs
);

// In sync code
logger.d('Starting sync for products');
logger.i('Synced ${records.length} records');
logger.w('Conflict detected: $conflict');
logger.e('Sync failed', error, stackTrace);
```

### 2. Add Sync Metrics

```dart
class SyncMetrics {
  DateTime? lastSyncTime;
  int totalRecordsSynced = 0;
  int totalConflicts = 0;
  int totalErrors = 0;
  Duration? lastSyncDuration;
  
  void recordSync(SyncResult result, Duration duration) {
    lastSyncTime = DateTime.now();
    totalRecordsSynced += result.recordsSynced;
    totalConflicts += result.conflicts.length;
    if (!result.success) totalErrors++;
    lastSyncDuration = duration;
  }
  
  @override
  String toString() {
    return '''
Sync Metrics:
- Last sync: $lastSyncTime
- Total synced: $totalRecordsSynced records
- Total conflicts: $totalConflicts
- Total errors: $totalErrors
- Last duration: ${lastSyncDuration?.inSeconds}s
''';
  }
}
```

### 3. Create Sync Logs Table

```dart
// Store sync history for debugging
class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get operation => text()(); // 'push', 'pull', 'conflict'
  TextColumn get tableName => text()();
  IntColumn get recordsAffected => integer()();
  BoolColumn get success => boolean()();
  TextColumn get error => text().nullable()();
}
```

---

## Testing Checklist

When debugging sync issues, verify:

- [ ] Database has all sync fields
- [ ] Drift code regenerated after schema changes
- [ ] Supabase connected and authenticated
- [ ] RLS policies allow sync operations
- [ ] Internet connectivity available
- [ ] No concurrent sync operations
- [ ] Sync order respects foreign keys
- [ ] Soft deletes handled correctly
- [ ] Timestamps in UTC
- [ ] ID type conversions correct
- [ ] Error handling catches all exceptions
- [ ] Logs show detailed information

---

## Getting More Help

If stuck after trying these solutions:

1. **Check logs**: Look for the first error in chain
2. **Isolate issue**: Test one table at a time
3. **Simplify**: Remove complexity until it works
4. **Ask for help**: 
   - Drift Discord: https://discord.gg/drift
   - Stack Overflow: Tag `drift` + `flutter` + `supabase`
   - Supabase Discord: https://discord.supabase.com

Include in your question:
- Exact error message
- Relevant code snippet
- Drift version
- Supabase client version
- What you've tried

---

**Remember**: Most sync issues are either:
1. Database schema mismatch
2. Supabase authentication/RLS
3. Network connectivity handling
4. Timestamp/timezone confusion
5. ID type conversion

Start with the simplest explanation first!
