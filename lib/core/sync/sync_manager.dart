import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../database/app_database.dart';
import 'sync_engine.dart';

class SyncManager {
  final AppDatabase _database;
  final SyncEngine _syncEngine;
  
  static SyncManager? _instance;

  SyncManager(this._database, this._syncEngine);

  static SyncManager get instance {
    if (_instance == null) {
      throw Exception('SyncManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Starts a push without waiting for it, for use right after a local write
  /// (the change is already safe in Drift; offline just means it goes up on
  /// the next sync). Never throws — including when SyncManager isn't
  /// initialised, as in tests.
  static void syncInBackground() {
    try {
      instance.syncPendingData().catchError((Object _) {});
    } catch (_) {}
  }

  static void initialize(AppDatabase database) {
    _instance ??= SyncManager(database, SyncEngine(database));
  }

  Future<Map<String, dynamic>> push() async {
    try {
      debugPrint('Starting push operation...');
      final pendingCounts = await _getPendingRecordCounts();
      final totalPending = pendingCounts.values
          .fold(0, (sum, count) => sum + count);
      await _syncEngine.performPush();
      debugPrint('Push completed. Records pushed: ');
      return {
        'success': true,
        'recordsPushed': totalPending,
        'error': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Push failed: ');
      return {
        'success': false,
        'recordsPushed': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// True only when there is an active Supabase Auth session. RLS returns
  /// zero rows to an unauthenticated client, so a pull without one would look
  /// like it worked while fetching nothing.
  bool get _hasSupabaseSession {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false; // Supabase not initialised
    }
  }

  Future<Map<String, dynamic>> pull() async {
    if (!_hasSupabaseSession) {
      debugPrint('Pull skipped: no active Supabase session (sign in first)');
      return {
        'success': true,
        'skipped': true,
        'recordsPulled': 0,
        'error': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    try {
      debugPrint('Starting pull operation...');
      final initialCounts = await _getTotalRecordCounts();
      await _syncEngine.performPull();
      final finalCounts = await _getTotalRecordCounts();
      int recordsPulled = 0;
      finalCounts.forEach((table, count) {
        recordsPulled += count - (initialCounts[table] ?? 0);
      });
      debugPrint('Pull completed. Records pulled: ');
      return {
        'success': true,
        'recordsPulled': recordsPulled,
        'error': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Pull failed: ');
      return {
        'success': false,
        'recordsPulled': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> performFullSync() async {
    try {
      debugPrint('Starting full sync...');
      final pushResult = await push();
      final pullResult = await pull();
      return {
        'success':
            pushResult['success'] == true &&
            pullResult['success'] == true,
        'recordsPushed': pushResult['recordsPushed'] ?? 0,
        'recordsPulled': pullResult['recordsPulled'] ?? 0,
        'error': pushResult['error'] ?? pullResult['error'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Full sync failed: ');
      return {
        'success': false,
        'recordsPushed': 0,
        'recordsPulled': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> syncPendingRecords() async {
    debugPrint('Syncing all pending records...');
    await push();
  }

  Future<void> syncPendingData() async {
    debugPrint('🔄 Syncing all pending records...');
    await push();
  }

  Future<Map<String, int>> _getPendingRecordCounts() async {
    final counts = <String, int>{};
    try {
      for (final table in [
        'users',
        'products',
        'customers',
        'orders',
        'stock_movements',
      ]) {
        try {
          final result = await _database.customSelect(
            'SELECT COUNT(*) as count FROM $table '
            'WHERE sync_status = ?',
            variables: [Variable.withString('pending')],
          ).getSingle();
          counts[table] = result.read<int>('count');
        } catch (e) {
          counts[table] = 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting pending counts: ');
    }
    return counts;
  }

  Future<Map<String, int>> _getTotalRecordCounts() async {
    final counts = <String, int>{};
    try {
      for (final table in [
        'users',
        'products',
        'customers',
        'orders',
        'stock_movements',
      ]) {
        try {
          final result = await _database.customSelect(
            'SELECT COUNT(*) as count FROM ',
          ).getSingle();
          counts[table] = result.read<int>('count');
        } catch (e) {
          counts[table] = 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting total counts: ');
    }
    return counts;
  }
}
