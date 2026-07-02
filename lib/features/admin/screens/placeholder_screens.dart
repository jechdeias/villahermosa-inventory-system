import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

// ── Stock Movements ───────────────────────────────────────────────────────────

class AdminStockScreen extends StatefulWidget {
  const AdminStockScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> {
  late Future<List<StockMovement>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _movementsFuture = widget.database.getPendingSyncStockMovements();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/stock',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: FutureBuilder<List<StockMovement>>(
          future: _movementsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final movements = snap.data ?? [];
            if (movements.isEmpty) {
              return const _EmptyState(icon: Icons.trending_up, label: 'No stock movements');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = movements[i];
                final isIn = m.movementType == 'in';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      child: Icon(
                        isIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIn ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text('${m.movementType.toUpperCase()}  •  Qty: ${m.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Ref: ${m.referenceId ?? '-'}\n'
                        '${m.createdAt.toLocal().toString().substring(0, 16)}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Deliveries ────────────────────────────────────────────────────────────────

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  late Future<List<Delivery>> _deliveriesFuture;

  @override
  void initState() {
    super.initState();
    _deliveriesFuture = widget.database.getActiveDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/deliveries',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: FutureBuilder<List<Delivery>>(
          future: _deliveriesFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final deliveries = snap.data ?? [];
            if (deliveries.isEmpty) {
              return const _EmptyState(icon: Icons.local_shipping_outlined, label: 'No active deliveries');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deliveries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = deliveries[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.local_shipping, color: Color(0xFF1565C0), size: 20),
                    ),
                    title: Text('Delivery #${d.uuid.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Status: ${d.status}\n'
                        'Expected: ${d.expectedStartTime.toLocal().toString().substring(0, 16)}'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(d.status, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFE3F2FD),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Reports (placeholder) ─────────────────────────────────────────────────────

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/reports',
      child: const _EmptyState(icon: Icons.bar_chart_outlined, label: 'Reports coming soon'),
    );
  }
}

// ── Settings (placeholder) ────────────────────────────────────────────────────

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/settings',
      child: const _EmptyState(icon: Icons.settings_outlined, label: 'Settings coming soon'),
    );
  }
}

// ── Shared empty-state widget ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }
}
