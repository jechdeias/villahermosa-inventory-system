import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, RealtimeChannel;
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

  /// Starts a push+pull without waiting, for use right after a local write.
  /// Never throws — including when SyncManager isn't initialised, as in tests.
  static void syncInBackground() {
    try {
      instance.syncPendingData().catchError((Object _) {});
    } catch (_) {}
  }

  static void initialize(AppDatabase database) {
    _instance ??= SyncManager(database, SyncEngine(database));
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  /// Active Supabase Realtime channels. Kept so we can remove them on
  /// [stopRealtime] (e.g. logout).
  final List<RealtimeChannel> _realtimeChannels = [];

  /// Debounce: ignore a Realtime event that fires within this window of the
  /// previous pull — avoids hammering the DB if many rows change at once.
  static const _realtimeDebounce = Duration(seconds: 2);
  DateTime _lastRealtimePull = DateTime(2000);
  Timer? _realtimeDebounceTimer;

  /// Tables we subscribe to. Any INSERT/UPDATE/DELETE on these triggers a pull
  /// so every device sees the change within seconds.
  static const _realtimeTables = [
    'orders',
    'order_items',
    'payments',
    'customers',
    'products',
    'users',
    'stock_movements',
    'deliveries',
    'delivery_routes',
  ];

  /// Subscribe to Supabase Realtime for every business-critical table.
  /// Call once after a successful login (or after bootstrapUsers on a fresh
  /// install). Safe to call multiple times — existing subscriptions are
  /// removed first.
  void startRealtime() {
    if (!_hasSupabaseSession) {
      debugPrint('⚡ Realtime skipped: no Supabase session');
      return;
    }
    stopRealtime(); // clean up stale channels before re-subscribing

    final client = Supabase.instance.client;

    for (final table in _realtimeTables) {
      final channel = client
          .channel('realtime:$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (_) => _onRealtimeEvent(table),
          )
          .subscribe((status, [err]) {
            if (err != null) {
              debugPrint('⚡ Realtime $table error: $err');
            } else {
              debugPrint('⚡ Realtime $table: $status');
            }
          });
      _realtimeChannels.add(channel);
    }

    debugPrint('⚡ Realtime subscriptions started (${_realtimeTables.length} tables)');
  }

  /// Remove all Realtime subscriptions. Call on logout.
  void stopRealtime() {
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = null;
    for (final ch in _realtimeChannels) {
      Supabase.instance.client.removeChannel(ch);
    }
    _realtimeChannels.clear();
    debugPrint('⚡ Realtime subscriptions stopped');
  }

  void _onRealtimeEvent(String table) {
    final now = DateTime.now();
    // Skip if we pulled very recently — debounce burst updates
    if (now.difference(_lastRealtimePull) < _realtimeDebounce) {
      // Reset the timer so we pull once after the burst settles
      _realtimeDebounceTimer?.cancel();
      _realtimeDebounceTimer = Timer(_realtimeDebounce, _doRealtimePull);
      return;
    }
    _realtimeDebounceTimer?.cancel();
    _doRealtimePull();
  }

  void _doRealtimePull() {
    _lastRealtimePull = DateTime.now();
    debugPrint('⚡ Realtime change detected — pulling...');
    pull().catchError((e) {
      debugPrint('⚡ Realtime pull error: $e');
    });
  }

  // ── Core sync ops ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> push() async {
    try {
      debugPrint('Starting push operation...');
      final pendingCounts = await _getPendingRecordCounts();
      final totalPending = pendingCounts.values.fold(0, (sum, count) => sum + count);
      await _syncEngine.performPush();
      debugPrint('Push completed. Records pushed: $totalPending');
      return {
        'success': true,
        'recordsPushed': totalPending,
        'error': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Push failed: $e');
      return {
        'success': false,
        'recordsPushed': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Completes delivered orders nobody confirmed within 72h (local-only).
  /// Never throws.
  Future<int> autoConfirmDeliveries() async {
    try {
      return await _syncEngine.autoConfirmDeliveries();
    } catch (e) {
      debugPrint('Auto-confirm deliveries failed: $e');
      return 0;
    }
  }

  /// True only when there is an active Supabase Auth session.
  bool get _hasSupabaseSession {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
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
      await autoConfirmDeliveries();
      final finalCounts = await _getTotalRecordCounts();
      int recordsPulled = 0;
      finalCounts.forEach((table, count) {
        recordsPulled += count - (initialCounts[table] ?? 0);
      });
      debugPrint('Pull completed. Records pulled: $recordsPulled');
      return {
        'success': true,
        'recordsPulled': recordsPulled,
        'error': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Pull failed: $e');
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
        'success': pushResult['success'] == true && pullResult['success'] == true,
        'recordsPushed': pushResult['recordsPushed'] ?? 0,
        'recordsPulled': pullResult['recordsPulled'] ?? 0,
        'error': pushResult['error'] ?? pullResult['error'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Full sync failed: $e');
      return {
        'success': false,
        'recordsPushed': 0,
        'recordsPulled': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Push pending rows then pull remote changes. Use this after every local
  /// write so other devices see the change immediately.
  Future<void> syncPendingData() async {
    debugPrint('🔄 Syncing pending data...');
    await push();
    await pull();
  }

  /// Pull all users from Supabase on a fresh install (empty local DB).
  /// Never throws — login callers should proceed even when this fails.
  Future<void> bootstrapUsers() async {
    if (!_hasSupabaseSession) {
      debugPrint('bootstrapUsers skipped: no active Supabase session');
      return;
    }
    try {
      await _syncEngine.bootstrapUsers();
    } catch (e) {
      debugPrint('bootstrapUsers failed (non-fatal): $e');
    }
  }

  // kept for back-compat (some callers use this name)
  Future<void> syncPendingRecords() => syncPendingData();

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> _getPendingRecordCounts() async {
    final counts = <String, int>{};
    try {
      for (final table in ['users', 'products', 'customers', 'orders', 'stock_movements']) {
        try {
          final result = await _database.customSelect(
            'SELECT COUNT(*) as count FROM $table WHERE sync_status = ?',
            variables: [Variable.withString('pending')],
          ).getSingle();
          counts[table] = result.read<int>('count');
        } catch (e) {
          counts[table] = 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting pending counts: $e');
    }
    return counts;
  }

  Future<Map<String, int>> _getTotalRecordCounts() async {
    final counts = <String, int>{};
    try {
      for (final table in ['users', 'products', 'customers', 'orders', 'stock_movements']) {
        try {
          final result = await _database.customSelect(
            'SELECT COUNT(*) as count FROM $table',
          ).getSingle();
          counts[table] = result.read<int>('count');
        } catch (e) {
          counts[table] = 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting total counts: $e');
    }
    return counts;
  }
}
