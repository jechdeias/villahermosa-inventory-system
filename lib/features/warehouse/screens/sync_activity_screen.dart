import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

const _syncedTables = ['products', 'customers', 'orders', 'order_items', 'stock_movements', 'payments', 'deliveries'];

/// Rows still waiting to be pushed, per table (only tables with pending rows).
Future<Map<String, int>> _pendingCounts(AppDatabase db) async {
  final out = <String, int>{};
  for (final t in _syncedTables) {
    final rows = await db.customSelect("SELECT COUNT(*) AS c FROM $t WHERE sync_status = 'pending'").get();
    final n = rows.first.read<int>('c');
    if (n > 0) out[t] = n;
  }
  return out;
}

class WarehouseSyncActivityScreen extends ConsumerStatefulWidget {
  const WarehouseSyncActivityScreen({super.key});

  @override
  ConsumerState<WarehouseSyncActivityScreen> createState() => _WarehouseSyncActivityScreenState();
}

class _WarehouseSyncActivityScreenState extends ConsumerState<WarehouseSyncActivityScreen> {
  late Future<Map<String, int>> _pending = _pendingCounts(ref.read(databaseProvider));
  bool _syncing = false;
  String? _lastError;

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _lastError = null;
    });
    try {
      await SyncManager.instance.syncPendingData();
    } catch (e) {
      _lastError = '$e';
    }
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _pending = _pendingCounts(ref.read(databaseProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstLoad(ref.watch(stockMovementsStreamProvider))) return const WhLoadingShell(route: WhRoutes.sync, statCards: 4);
    final movements = ref.watch(stockMovementsStreamProvider).value ?? [];
    final orders = ref.watch(ordersStreamProvider).value ?? [];
    final products = ref.watch(productsStreamProvider).value ?? [];
    final last = lastSyncTime();

    bool autoSync = true;
    try {
      autoSync = AppSettings.instance.autoSyncOnStartup;
    } catch (_) {}

    String nameOf(String uuid) {
      for (final p in products) {
        if (p.uuid == uuid) return p.name;
      }
      return 'Unknown product';
    }

    final entries = <({DateTime time, Widget Function() build})>[
      if (last != null)
        (
          time: last,
          build: () => WhActivityLogEntry(
                kind: WhActivityKind.success,
                title: 'Sync completed',
                description: 'Local changes pushed and server updates pulled',
                by: 'By: System (auto-sync) • ${timeAgo(last)}',
              ),
        ),
      for (final m in movements.take(15))
        (
          time: m.createdAt,
          build: () => WhActivityLogEntry(
                kind: WhActivityKind.success,
                title: m.movementType == 'in' ? 'Stock-in recorded' : 'Stock-out recorded',
                description: '${m.quantity} × ${nameOf(m.productId)}${(m.referenceId ?? '').isNotEmpty ? ' · ${m.referenceId}' : ' · ${m.reason}'}',
                by: 'By: ${m.userName} • ${timeAgo(m.createdAt)}',
              ),
        ),
      for (final o in orders.where((o) => whOrderStatus(o) == 'ready' || whOrderStatus(o) == 'dispatched').take(10))
        (
          time: o.packedAt ?? o.updatedAt,
          build: () => WhActivityLogEntry(
                kind: WhActivityKind.success,
                title: 'Order ${o.orderNumber} ${whOrderStatus(o) == 'ready' ? 'prepared' : 'dispatched'}',
                description: [o.storeName ?? '', o.routeName ?? ''].where((s) => s.isNotEmpty).join(' · '),
                by: 'By: Warehouse • ${timeAgo(o.packedAt ?? o.updatedAt)}',
              ),
        ),
      for (final p in products.where((p) => isLowStock(p) || isOutOfStock(p)).take(8))
        (
          time: p.updatedAt,
          build: () => WhActivityLogEntry(
                kind: isOutOfStock(p) ? WhActivityKind.error : WhActivityKind.warning,
                title: isOutOfStock(p) ? 'Out of stock' : 'Low stock alert',
                description: '${p.name} is at ${p.currentStock} units (minimum ${p.minStock})',
                by: 'By: System • ${timeAgo(p.updatedAt)}',
              ),
        ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    return WarehouseShell(
      route: WhRoutes.sync,
      child: WhPage(children: [
        WhPageHeader(
          title: 'Sync & Activity',
          subtitle: 'Offline changes are saved on this device and sent to the server when online',
          trailing: WhPrimaryButton(label: _syncing ? 'Syncing…' : 'Sync Now', icon: Icons.sync, onPressed: _syncing ? null : _syncNow),
        ),
        FutureBuilder<Map<String, int>>(
          future: _pending,
          builder: (context, snap) {
            final counts = snap.data ?? const <String, int>{};
            final total = counts.values.fold<int>(0, (s, n) => s + n);
            final detail = counts.isEmpty ? 'Everything is up to date' : counts.entries.map((e) => '${e.value} ${e.key.replaceAll('_', ' ')}').join(', ');
            final ok = _lastError == null && last != null;
            return WhStatRow(cards: [
              WhStatCard(
                label: 'Last Sync',
                value: last == null ? 'Never' : formatClock(last),
                sub: last == null ? 'No sync on this device yet' : '${timeAgo(last)} · ${autoSync ? 'auto-sync' : 'manual'}',
                dotColor: last == null ? WhColors.amber : WhColors.green,
              ),
              WhStatCard(
                label: 'Next Sync',
                value: autoSync ? 'On startup' : 'Manual',
                sub: autoSync ? 'Auto-sync when the app opens' : 'Auto-sync is turned off',
                dotColor: WhColors.blue,
              ),
              WhStatCard(label: 'Pending Changes', value: '$total', sub: detail, dotColor: WhColors.amber),
              WhStatCard(
                label: 'Status',
                value: _lastError != null ? 'Failed' : (last == null ? 'Not synced' : 'Success'),
                valueColor: _lastError != null ? WhColors.red : (ok ? WhColors.green : WhColors.amber),
                sub: _lastError != null ? 'Last attempt failed' : (ok ? 'Connected to server' : 'Tap Sync Now'),
                dotColor: _lastError != null ? WhColors.red : (ok ? WhColors.green : WhColors.amber),
              ),
            ]);
          },
        ),
        WhCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const WhCardTitle('Activity Log', trailing: Text('Today', style: TextStyle(fontSize: 12, color: WhColors.muted))),
            if (_lastError != null)
              WhActivityLogEntry(kind: WhActivityKind.error, title: 'Sync failed', description: _lastError!, by: 'By: System • just now'),
            if (entries.isEmpty && _lastError == null)
              const WhEmpty('Stock movements, prepared orders and alerts will show up here', title: 'No activity yet', icon: Icons.history)
            else
              for (final e in entries.take(12)) e.build(),
          ]),
        ),
      ]),
    );
  }
}
