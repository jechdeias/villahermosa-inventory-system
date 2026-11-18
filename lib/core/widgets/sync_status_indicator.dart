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

/// Everything the indicator and the strip show, in one place: the pending count
/// (per table), connectivity, and when to re-read them.
///
/// * Local writes notify through Drift, so [AppDatabase.watchPendingCounts]
///   covers them.
/// * Sync's own "mark synced" writes do NOT (see [SyncManager.syncCompleted]), so
///   the count is also re-read whenever a sync cycle finishes. No timer.
class SyncStatusModel extends ChangeNotifier {
  SyncStatusModel({
    AppDatabase? database,
    Stream<bool>? onlineStream,
    bool? initialOnline,
    ValueListenable<int>? syncCompleted,
  })  : _db = database ?? _sharedDatabase(),
        _online = initialOnline ?? true {
    final db = _db;
    if (db != null) {
      _countSub = db.watchPendingCounts().listen(_setCounts, onError: (_) {});
    }
    _syncCompleted = syncCompleted ?? _sharedSyncSignal();
    _syncCompleted?.addListener(refresh);
    _initConnectivity(onlineStream, initialOnline);
  }

  final AppDatabase? _db;
  ValueListenable<int>? _syncCompleted;
  StreamSubscription<Map<String, int>>? _countSub;
  StreamSubscription<dynamic>? _connSub;
  Map<String, int> _counts = const {};
  bool _online;
  bool _disposed = false;

  static AppDatabase? _sharedDatabase() {
    try {
      return AuthService.instance.database;
    } catch (_) {
      return null; // not signed in / not initialised: nothing to show
    }
  }

  static ValueListenable<int>? _sharedSyncSignal() {
    try {
      return SyncManager.instance.syncCompleted;
    } catch (_) {
      return null;
    }
  }

  Map<String, int> get counts => _counts;
  bool get online => _online;
  int get pending => _counts.values.fold(0, (a, b) => a + b);
  SyncIndicatorState get state => syncStateFor(online: _online, pending: pending);

  /// Worth taking up space for: something is waiting to upload, or the device is
  /// offline. "Online and nothing pending" is the uninteresting default.
  bool get needsAttention => pending > 0 || !_online;

  void _setCounts(Map<String, int> next) {
    if (_disposed) return;
    _counts = next;
    notifyListeners();
  }

  void _setOnline(bool value) {
    if (_disposed || _online == value) return;
    _online = value;
    notifyListeners();
  }

  /// Re-reads the count from the database now (one-shot, so it can't be answered
  /// from Drift's cached stream value).
  Future<void> refresh() async {
    final db = _db;
    if (db == null || _disposed) return;
    try {
      _setCounts(await db.getPendingCounts());
    } catch (_) {}
  }

  Future<void> _initConnectivity(Stream<bool>? onlineStream, bool? initialOnline) async {
    if (onlineStream != null) {
      _connSub = onlineStream.listen(_setOnline);
      return;
    }
    if (initialOnline != null) return;
    try {
      final connectivity = Connectivity();
      _setOnline(!(await connectivity.checkConnectivity()).contains(ConnectivityResult.none));
      if (_disposed) return;
      _connSub = connectivity.onConnectivityChanged.listen(
        (r) => _setOnline(!r.contains(ConnectivityResult.none)),
        onError: (_) {},
      );
    } catch (_) {
      // No connectivity plugin (tests, unsupported platform): assume online.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _syncCompleted?.removeListener(refresh);
    _countSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

/// Owns one [SyncStatusModel] for a subtree (a shell), so the strip and the
/// always-visible dot share one set of database/connectivity subscriptions.
class SyncStatusScope extends StatefulWidget {
  const SyncStatusScope({
    super.key,
    required this.child,
    this.database,
    this.onlineStream,
    this.initialOnline,
    this.syncCompleted,
  });

  final Widget child;

  /// Test seams; defaults are the shared database, connectivity_plus and
  /// [SyncManager.syncCompleted].
  final AppDatabase? database;
  final Stream<bool>? onlineStream;
  final bool? initialOnline;
  final ValueListenable<int>? syncCompleted;

  static SyncStatusModel? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SyncStatusInherited>()?.notifier;

  @override
  State<SyncStatusScope> createState() => _SyncStatusScopeState();
}

class _SyncStatusScopeState extends State<SyncStatusScope> {
  late final SyncStatusModel _model = SyncStatusModel(
    database: widget.database,
    onlineStream: widget.onlineStream,
    initialOnline: widget.initialOnline,
    syncCompleted: widget.syncCompleted,
  );

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SyncStatusInherited(notifier: _model, child: widget.child);
}

class _SyncStatusInherited extends InheritedNotifier<SyncStatusModel> {
  const _SyncStatusInherited({required SyncStatusModel super.notifier, required super.child});
}

/// Global sync status: a small pill (or just a dot when space is tight) shown by
/// every role's shell. Tap for what is pending and a "Sync now" button.
///
/// Display only — it reads [AppDatabase.watchPendingCounts], connectivity and the
/// sync-completed signal, and changes no sync logic. A row whose push can never
/// succeed stays 'pending', so the count never clears: that is deliberate (a
/// stuck count is how someone notices; see the frozen-rows note in CLAUDE.md).
///
/// Inside a [SyncStatusScope] it shares that scope's model; on its own it makes
/// (and disposes) its own.
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
    this.syncCompleted,
  });

  /// Defaults to the shared [AuthService] database.
  final AppDatabase? database;

  /// Draw for a dark background (the admin/warehouse sidebar).
  final bool onDark;

  /// Force the compact dot (with the pending number, if any). Null = automatic:
  /// dot only on narrow (phone) screens, label on wider ones.
  final bool? dotOnly;

  /// Test seams. Defaults: connectivity_plus, [SyncManager.syncPendingData], the
  /// persisted last-sync time and [SyncManager.syncCompleted].
  final Stream<bool>? onlineStream;
  final bool? initialOnline;
  final Future<void> Function()? onSyncNow;
  final DateTime? Function()? lastSync;
  final ValueListenable<int>? syncCompleted;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  SyncStatusModel? _ownModel;

  SyncStatusModel _modelFor(BuildContext context) =>
      SyncStatusScope.maybeOf(context) ??
      (_ownModel ??= SyncStatusModel(
        database: widget.database,
        onlineStream: widget.onlineStream,
        initialOnline: widget.initialOnline,
        syncCompleted: widget.syncCompleted,
      ));

  @override
  void dispose() {
    _ownModel?.dispose();
    super.dispose();
  }

  void _openSheet(SyncStatusModel model) =>
      showSyncStatusSheet(context, model, onSyncNow: widget.onSyncNow, lastSync: widget.lastSync);

  @override
  Widget build(BuildContext context) {
    final model = _modelFor(context);
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final dotOnly = widget.dotOnly ?? narrow;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final pending = model.pending;
        final state = model.state;
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
            onTap: () => _openSheet(model),
            child: body,
          ),
        );
      },
    );
  }
}

/// Opens the sync status sheet: what is pending (per table), the last sync time
/// and a "Sync now" button. Used by the indicator and by the strip's hairline.
/// [onSyncNow] / [lastSync] are test seams; defaults are
/// [SyncManager.syncPendingData] and the persisted last-sync time.
Future<void> showSyncStatusSheet(
  BuildContext context,
  SyncStatusModel model, {
  Future<void> Function()? onSyncNow,
  DateTime? Function()? lastSync,
}) {
  Future<void> syncNow() async {
    // The sync-completed signal re-reads the count when the cycle ends.
    final fn = onSyncNow ?? SyncManager.instance.syncPendingData;
    await fn();
  }

  DateTime? last() {
    if (lastSync != null) return lastSync();
    try {
      return AppSettings.instance.lastSyncTimestamp;
    } catch (_) {
      return null;
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _SyncSheet(model: model, onSyncNow: syncNow, lastSync: last()),
  );
}

class _SyncSheet extends StatefulWidget {
  const _SyncSheet({required this.model, required this.onSyncNow, required this.lastSync});
  final SyncStatusModel model;
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
            listenable: widget.model,
            builder: (context, _) {
              final counts = widget.model.counts;
              final pending = widget.model.pending;
              final state = widget.model.state;
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

/// Height of the expanded strip.
const double kSyncStripHeight = 30;

/// Height of the collapsed strip: a hairline in the "all synced" green.
const double kSyncHairlineHeight = 3;

/// How tall the invisible tap target over the collapsed hairline is.
const double kSyncHairlineTapHeight = 20;

/// A status row above a mobile screen body, for the shells with no app bar
/// (customer, sales rep / delivery).
///
/// * online, nothing pending → a 3px hairline in the green token (so "all
///   synced" is always confirmable at a glance), with an invisible ~20px tap
///   target that opens the sync sheet;
/// * rows pending, or offline → animates open to the full [kSyncStripHeight]
///   strip carrying the pill.
///
/// The tap target is laid over the top of the screen's content (it adds no
/// height), so while the strip is collapsed a tap in that top ~20px opens the
/// sheet instead of reaching the content under it; screens keep their first
/// controls ~16px below the top, so in practice it only covers padding.
///
/// Needs a [SyncStatusScope] above it; wraps itself in one if there is none.
class SyncStatusStrip extends StatelessWidget {
  const SyncStatusStrip({super.key, required this.child, this.background, this.onSyncNow, this.lastSync});
  final Widget child;
  final Color? background;

  /// Test seams, passed on to the sheet.
  final Future<void> Function()? onSyncNow;
  final DateTime? Function()? lastSync;

  @override
  Widget build(BuildContext context) {
    final model = SyncStatusScope.maybeOf(context);
    if (model == null) {
      return SyncStatusScope(child: SyncStatusStrip(background: background, onSyncNow: onSyncNow, lastSync: lastSync, child: child));
    }
    // Reduced motion: no slide, it just changes height. (Not AnimatedSize with a
    // zero duration: that throws a layout assertion when it unmounts.)
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final attention = model.needsAttention;
        final bar = attention
            ? Container(
                key: const Key('sync-strip'),
                color: background,
                padding: const EdgeInsets.fromLTRB(12, 2, 8, 0),
                alignment: Alignment.centerRight,
                height: kSyncStripHeight,
                child: const SyncStatusIndicator(dotOnly: false),
              )
            : Semantics(
                button: true,
                label: 'Sync status: ${syncLabelFor(SyncIndicatorState.allSynced, 0)}',
                child: Container(
                  key: const Key('sync-strip-collapsed'),
                  height: kSyncHairlineHeight,
                  color: syncColorFor(SyncIndicatorState.allSynced),
                ),
              );
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                reduceMotion
                    ? bar
                    : AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: bar,
                      ),
                Expanded(child: child),
              ],
            ),
            if (!attention)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: kSyncHairlineTapHeight,
                child: GestureDetector(
                  key: const Key('sync-hairline-target'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showSyncStatusSheet(context, model, onSyncNow: onSyncNow, lastSync: lastSync),
                ),
              ),
          ],
        );
      },
    );
  }
}
