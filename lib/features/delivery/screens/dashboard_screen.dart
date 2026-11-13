/// Delivery Dashboard Screen
///
/// Shows all orders assigned to the logged-in sales rep, grouped by route.
/// Ready orders can be confirmed inline (manual button or QR scan).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../sales/screens/sales_scan_screen.dart';
import '../../sales/services/delivery_confirmation.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _repNameProvider = Provider<String>((ref) {
  final u = AuthService.instance.getCurrentUser();
  if (u == null) return '';
  final first = (u.firstName ?? '').trim();
  final last  = (u.lastName  ?? '').trim();
  return '$first $last'.trim();
});

final _repOrdersProvider = StreamProvider<List<Order>>((ref) {
  final name = ref.watch(_repNameProvider);
  if (name.isEmpty) return const Stream.empty();
  return AuthService.instance.database.watchOrdersBySalesRep(name);
});

// ── Dashboard ─────────────────────────────────────────────────────────────────

class DeliveryDashboardScreen extends ConsumerWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repName  = ref.watch(_repNameProvider);
    final ordersAV = ref.watch(_repOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Deliveries'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('Syncing…')));
              try {
                await SyncManager.instance.syncPendingData();
                messenger.showSnackBar(const SnackBar(content: Text('Sync finished')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
              }
            },
          ),
        ],
      ),
      body: ordersAV.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (orders) => _DeliveryBody(repName: repName, orders: orders),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DeliveryBody extends StatelessWidget {
  const _DeliveryBody({required this.repName, required this.orders});
  final String repName;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    // Active = not completed/cancelled
    final active = orders.where((o) =>
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled).toList();

    final done = orders.where((o) =>
        o.status == OrderStatus.completed ||
        o.status == OrderStatus.delivered).length;

    // Group by route name (null → 'Unassigned')
    final Map<String, List<Order>> byRoute = {};
    for (final o in active) {
      final key = (o.routeName?.isNotEmpty == true) ? o.routeName! : 'Unassigned';
      byRoute.putIfAbsent(key, () => []).add(o);
    }

    return RefreshIndicator(
      onRefresh: () => SyncManager.instance.syncPendingData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary chips ───────────────────────────────────────────────
          _SummaryRow(
            repName: repName,
            total:  orders.length,
            active: active.length,
            done:   done,
          ),
          const SizedBox(height: 16),

          // ── QR scan shortcut ────────────────────────────────────────────
          _QrShortcut(),
          const SizedBox(height: 20),

          // ── Route groups ────────────────────────────────────────────────
          if (active.isEmpty)
            const _EmptyState()
          else
            for (final entry in byRoute.entries) ...[
              _RouteHeader(routeName: entry.key, count: entry.value.length),
              const SizedBox(height: 8),
              for (final order in entry.value)
                _OrderCard(order: order),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.repName,
    required this.total,
    required this.active,
    required this.done,
  });
  final String repName;
  final int total, active, done;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        repName.isNotEmpty ? 'Hi, $repName 👋' : 'My Deliveries',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _Chip(label: '$active active',  color: AppTheme.primary),
        const SizedBox(width: 8),
        _Chip(label: '$done delivered', color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        _Chip(label: '$total total',    color: const Color(0xFF6B7280)),
      ]),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  );
}

// ── QR shortcut ───────────────────────────────────────────────────────────────

class _QrShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, AppTheme.route((_) => const SalesScanScreen())),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text('Scan QR to Confirm Delivery',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    ),
  );
}

// ── Route header ──────────────────────────────────────────────────────────────

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.routeName, required this.count});
  final String routeName;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.map_outlined, size: 16, color: Color(0xFF6B7280)),
      const SizedBox(width: 6),
      Text(routeName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      ),
    ],
  );
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _confirming = false;

  Color get _statusColor {
    switch (widget.order.status) {
      case OrderStatus.outForDelivery: return const Color(0xFF2563EB);
      case OrderStatus.delivered:
      case OrderStatus.completed:     return const Color(0xFF16A34A);
      default:
        switch (widget.order.warehouseStatus) {
          case 'ready':  return const Color(0xFF16A34A);
          case 'packed': return const Color(0xFF2563EB);
          case 'picked': return const Color(0xFFD97706);
          default:       return const Color(0xFF6B7280);
        }
    }
  }

  String get _statusLabel {
    switch (widget.order.status) {
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered:      return 'Delivered';
      case OrderStatus.completed:      return 'Completed';
      case OrderStatus.processing:     return 'Processing';
      default:
        switch (widget.order.warehouseStatus) {
          case 'ready':  return 'Ready';
          case 'packed': return 'Packed';
          case 'picked': return 'Picked';
          default:       return 'Pending';
        }
    }
  }

  bool get _canConfirm => widget.order.status == OrderStatus.outForDelivery;

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = AuthService.instance.database;
      await markOrderDelivered(db, widget.order, method: deliveryMethodManual);
      messenger.showSnackBar(const SnackBar(
        content: Text('Delivery confirmed!'),
        backgroundColor: Color(0xFF16A34A),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: order number + status badge ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(o.orderNumber,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Store / address ───────────────────────────────────────────
            if (o.storeName?.isNotEmpty == true)
              Text(o.storeName!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
            if (o.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(o.deliveryAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ),
              ]),
            ],
            const SizedBox(height: 8),

            // ── Meta row ─────────────────────────────────────────────────
            Row(children: [
              const Icon(Icons.shopping_bag_outlined, size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('${o.itemCount} item${o.itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
              const Icon(Icons.payments_outlined, size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('₱${o.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            ]),

            // ── Confirm button (only for out_for_delivery orders) ─────────
            if (_canConfirm) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _confirming ? null : _confirm,
                  icon: _confirming
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(_confirming ? 'Confirming…' : 'Confirm Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 60),
      Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text('No active deliveries',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
      const SizedBox(height: 6),
      Text('Deliveries assigned to you will appear here.',
          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
    ],
  );
}
