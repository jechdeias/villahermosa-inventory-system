import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../database/app_database.dart';
import '../settings/app_settings.dart';
import '../sync/sync_manager.dart';
import '../theme/app_theme.dart';

/// What the indicator is telling the user.
enum SyncIndicatorState { allSynced, syncing, waitingOffline, offline }

/// The signal people need is "has my work left this device?" — a PENDING COUNT —
/// not "am I connected". This is an offline-first app, so being offline is
/// normal and not alarming; and a green connection dot would sit over stuck data
/// because push() swallows per-record failures and reports success.
///
///   online  + 0 pending → green  "All synced"
///   online  + N pending → amber  "Syncing N items..."
///   offline + N pending → amber  "N items waiting - offline"
///   offline + 0 pending → grey   "Offline"
SyncIndicatorState syncStateFor({required bool online, required int pending}) {
  if (online) return pending == 0 ? SyncIndicatorState.allSynced : SyncIndicatorState.syncing;
  return pending == 0 ? SyncIndicatorState.offline : SyncIndicatorState.waitingOffline;
}

String _items(int n) => '$n ${n == 1 ? 'item' : 'items'}';

String syncLabelFor(SyncIndicatorState state, int pending) => switch (state) {
      SyncIndicatorState.allSynced => 'All synced',
      SyncIndicatorState.syncing => 'Syncing ${_items(pending)}...',
      SyncIndicatorState.waitingOffline => '${_items(pending)} waiting - offline',
      SyncIndicatorState.offline => 'Offline',
    };

Color syncColorFor(SyncIndicatorState state) => switch (state) {
      SyncIndicatorState.allSynced => AppTheme.success,
      SyncIndicatorState.syncing || SyncIndicatorState.waitingOffline => AppTheme.warning,
      SyncIndicatorState.offline => AppTheme.textMuted,
    };

Color _syncBackgroundFor(SyncIndicatorState state) => switch (state) {
      SyncIndicatorState.allSynced => AppTheme.successLight,
      SyncIndicatorState.syncing || SyncIndicatorState.waitingOffline => AppTheme.warningLight,
      SyncIndicatorState.offline => AppTheme.background,
    };

/// "2 orders", "1 customer" — the sheet's per-table wording.
String describePending(String table, int n) {
  const names = {
    'users': ('user', 'users'),
    'products': ('product', 'products'),
    'customers': ('customer', 'customers'),
    'orders': ('order', 'orders'),
    'order_items': ('order line', 'order lines'),
    'stock_movements': ('stock movement', 'stock movements'),
    'payments': ('payment', 'payments'),
    'deliveries': ('delivery', 'deliveries'),
    'delivery_routes': ('route', 'routes'),
    'suppliers': ('supplier', 'suppliers'),
  };
  final (one, many) = names[table] ?? (table, table);
  return '$n ${n == 1 ? one : many}';
}

/// Global sync status: a small pill (or just a dot when space is tight) shown by
/// every role's shell. Tap for what is pending and a "Sync now" button.
///
/// Display only — it reads [AppDatabase.watchPendingCounts] and connectivity and
/// changes no sync logic. A row whose push can never succeed stays 'pending', so
/// the count never clears: that is deliberate (a stuck count is how someone
/// notices; see the frozen-rows note in CLAUDE.md).
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    super.key,
    this.database,
    this.onDark = false,
    this.dotOnly,
    this.onlineStream,
    this.initialOnline,
    this.onSyncNow,
    this.lastSync,
    this.refreshInterval = const Duration(seconds: 5),
  });

  /// Defaults to the shared [AuthService] database.
  final AppDatabase? database;

  /// Draw for a dark background (the admin/warehouse sidebar).
  final bool onDark;

  /// Force the compact dot (with the pending number, if any). Null = automatic:
  /// dot only on narrow (phone) screens, label on wider ones.
  final bool? dotOnly;

  /// Test seams. Defaults: connectivity_plus, [SyncManager.syncPendingData] and
  /// the persisted last-sync time.
  final Stream<bool>? onlineStream;
  final bool? initialOnline;
  final Future<void> Function()? onSyncNow;
  final DateTime? Function()? lastSync;

  /// How often to re-read the pending count on top of the live stream (zero
  /// disables). SyncEngine marks rows synced with `customUpdate` WITHOUT an
  /// `updates:` set, which Drift cannot turn into a stream notification, so the
  /// stream alone can go stale after a successful push until some other write
  /// lands. A cheap periodic re-read keeps the number honest without touching
  /// sync code. (Real fix, one line: pass `updates: {...}` in
  /// `_markRecordAsSynced` — deliberately not done in a display-only change.)
  final Duration refreshInterval;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  final _counts = ValueNotifier<Map<String, int>>(const {});
  late final _online = ValueNotifier<bool>(widget.initialOnline ?? true);
  StreamSubscription<Map<String, int>>? _countSub;
  StreamSubscription<dynamic>? _connSub;
  Timer? _poll;

  int get _pending => _counts.value.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    final db = _database;
    if (db != null) {
      _countSub = db.watchPendingCounts().listen((c) => _counts.value = c, onError: (_) {});
      if (widget.refreshInterval > Duration.zero) {
        _poll = Timer.periodic(widget.refreshInterval, (_) => refresh());
      }
    }
    _initConnectivity();
  }

  /// Re-reads the count now (also called after "Sync now").
  Future<void> refresh() async {
    final db = _database;
    if (db == null || !mounted) return;
    try {
      final latest = await db.getPendingCounts();
      if (mounted) _counts.value = latest;
    } catch (_) {}
  }

  AppDatabase? get _database {
    if (widget.database != null) return widget.database;
    try {
      return AuthService.instance.database;
    } catch (_) {
      return null; // not signed in / not initialised: nothing to show
    }
  }

  Future<void> _initConnectivity() async {
    if (widget.onlineStream != null) {
      _connSub = widget.onlineStream!.listen((v) => _online.value = v);
      return;
    }
    if (widget.initialOnline != null) return;
    try {
      final connectivity = Connectivity();
      _online.value = !(await connectivity.checkConnectivity()).contains(ConnectivityResult.none);
      _connSub = connectivity.onConnectivityChanged.listen(
        (r) => _online.value = !r.contains(ConnectivityResult.none),
        onError: (_) {},
      );
    } catch (_) {
      // No connectivity plugin (tests, unsupported platform): assume online.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _countSub?.cancel();
    _connSub?.cancel();
    _counts.dispose();
    _online.dispose();
    super.dispose();
  }

  Future<void> _syncNow() async {
    final fn = widget.onSyncNow ?? SyncManager.instance.syncPendingData;
    try {
      await fn();
    } finally {
      await refresh(); // the stream can't see sync's silent "mark synced" writes
    }
  }

  DateTime? _lastSync() {
    if (widget.lastSync != null) return widget.lastSync!();
    try {
      return AppSettings.instance.lastSyncTimestamp;
    } catch (_) {
      return null;
    }
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SyncSheet(counts: _counts, online: _online, onSyncNow: _syncNow, lastSync: _lastSync()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final dotOnly = widget.dotOnly ?? narrow;
    return ListenableBuilder(
      listenable: Listenable.merge([_counts, _online]),
      builder: (context, _) {
        final pending = _pending;
        final state = syncStateFor(online: _online.value, pending: pending);
        final label = syncLabelFor(state, pending);
        final color = syncColorFor(state);
        final dot = Container(
          key: const Key('sync-dot'),
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );

        final Widget body = dotOnly
            ? Tooltip(
                message: label,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    dot,
                    if (pending > 0) ...[
                      const SizedBox(width: 4),
                      Text('$pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.onDark ? Colors.white : color)),
                    ],
                  ]),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.onDark ? Colors.white.withValues(alpha: 0.08) : _syncBackgroundFor(state),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  dot,
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: widget.onDark ? Colors.white : color),
                    ),
                  ),
                ]),
              );

        return Semantics(
          button: true,
          label: 'Sync status: $label',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _openSheet,
            child: body,
          ),
        );
      },
    );
  }
}

class _SyncSheet extends StatefulWidget {
  const _SyncSheet({required this.counts, required this.online, required this.onSyncNow, required this.lastSync});
  final ValueListenable<Map<String, int>> counts;
  final ValueListenable<bool> online;
  final Future<void> Function() onSyncNow;
  final DateTime? lastSync;

  @override
  State<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<_SyncSheet> {
  bool _syncing = false;
  String? _error;

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      await widget.onSyncNow();
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't sync: $e");
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  static String _stamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.counts, widget.online]),
            builder: (context, _) {
              final counts = widget.counts.value;
              final pending = counts.values.fold(0, (a, b) => a + b);
              final online = widget.online.value;
              final state = syncStateFor(online: online, pending: pending);
              final ordered = [
                for (final t in AppDatabase.syncedTableNames)
                  if ((counts[t] ?? 0) > 0) MapEntry(t, counts[t]!),
              ];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: syncColorFor(state), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(syncLabelFor(state, pending),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    widget.lastSync == null ? 'Not synced yet on this device' : 'Last sync: ${_stamp(widget.lastSync!)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  if (ordered.isEmpty)
                    const Text('Nothing is waiting to upload.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted))
                  else ...[
                    const Text('WAITING TO UPLOAD',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    for (final e in ordered)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(describePending(e.key, e.value), style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                      ),
                  ],
                  if (pending > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'If this number never goes down after a sync, something is stuck — tell your administrator.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppTheme.error)),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    // Enabled offline too: connectivity detection can be wrong (VPN, captive
                    // portal) and a failed attempt is reported below, not hidden.
                    onPressed: _syncing ? null : _sync,
                    icon: _syncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_syncing ? 'Syncing...' : 'Sync now'),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

/// Wraps a mobile screen body with a slim right-aligned status row on top, for
/// the shells that have no app bar (customer, sales rep / delivery).
class SyncStatusStrip extends StatelessWidget {
  const SyncStatusStrip({super.key, required this.child, this.background});
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: background,
            padding: const EdgeInsets.fromLTRB(12, 2, 8, 0),
            alignment: Alignment.centerRight,
            height: 30,
            child: const SyncStatusIndicator(),
          ),
          Expanded(child: child),
        ],
      );
}
