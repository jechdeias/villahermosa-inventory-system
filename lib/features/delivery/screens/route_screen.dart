/// Delivery Route Screen
///
/// Shows all delivery routes assigned to the logged-in sales rep,
/// with the orders under each route and their current status.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import 'delivery_confirmation_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _routeRepNameProvider = Provider<String>((ref) {
  final u = AuthService.instance.getCurrentUser();
  if (u == null) return '';
  final first = (u.firstName ?? '').trim();
  final last  = (u.lastName  ?? '').trim();
  return '$first $last'.trim();
});

final _repRoutesProvider = StreamProvider<List<DeliveryRoute>>((ref) {
  final name = ref.watch(_routeRepNameProvider);
  if (name.isEmpty) {
    return AuthService.instance.database.watchAllDeliveryRoutes();
  }
  return AuthService.instance.database
      .watchAllDeliveryRoutes()
      .map((routes) => routes.where((r) =>
          (r.assignedRepName ?? '').toLowerCase() == name.toLowerCase()).toList());
});

final _repRouteOrdersProvider = StreamProvider<List<Order>>((ref) {
  final name = ref.watch(_routeRepNameProvider);
  if (name.isEmpty) return const Stream.empty();
  return AuthService.instance.database.watchOrdersBySalesRep(name);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class DeliveryRouteScreen extends ConsumerWidget {
  const DeliveryRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAV = ref.watch(_repRoutesProvider);
    final ordersAV = ref.watch(_repRouteOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Routes'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: routesAV.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (routes) => ordersAV.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data:   (orders) => _RouteBody(routes: routes, orders: orders),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _RouteBody extends StatelessWidget {
  const _RouteBody({required this.routes, required this.orders});
  final List<DeliveryRoute> routes;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No routes assigned',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text('Ask your admin to assign you to a delivery route.',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final route = routes[i];
        final routeOrders = orders
            .where((o) => o.routeName == route.routeName)
            .toList();
        return _RouteCard(route: route, orders: routeOrders);
      },
    );
  }
}

// ── Route card ────────────────────────────────────────────────────────────────

class _RouteCard extends StatefulWidget {
  const _RouteCard({required this.route, required this.orders});
  final DeliveryRoute route;
  final List<Order> orders;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _expanded = true;

  int get _pendingCount => widget.orders
      .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .length;

  int get _doneCount => widget.orders
      .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.delivered)
      .length;

  Color get _routeStatusColor {
    if (widget.orders.isEmpty) return const Color(0xFF6B7280);
    if (_pendingCount == 0)    return const Color(0xFF16A34A);
    if (_doneCount > 0)        return const Color(0xFF2563EB);
    return const Color(0xFFD97706);
  }

  String get _routeStatusLabel {
    if (widget.orders.isEmpty) return 'No orders';
    if (_pendingCount == 0)    return 'All done';
    if (_doneCount > 0)        return 'In progress';
    return 'Not started';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Route header ─────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.route, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.route.routeName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        const SizedBox(height: 2),
                        Text(widget.route.municipality,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _routeStatusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_routeStatusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _routeStatusColor)),
                      ),
                      const SizedBox(height: 4),
                      Text('${widget.orders.length} order${widget.orders.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),

          // ── Order list ───────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            if (widget.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No orders on this route.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              )
            else
              for (final order in widget.orders)
                _RouteOrderRow(order: order),
          ],
        ],
      ),
    );
  }
}

// ── Order row inside route card ───────────────────────────────────────────────

class _RouteOrderRow extends StatelessWidget {
  const _RouteOrderRow({required this.order});
  final Order order;

  Color get _color {
    switch (order.status) {
      case OrderStatus.completed:
      case OrderStatus.delivered:  return const Color(0xFF16A34A);
      case OrderStatus.outForDelivery: return const Color(0xFF2563EB);
      case OrderStatus.cancelled:  return const Color(0xFFEF4444);
      default:                     return const Color(0xFF6B7280);
    }
  }

  String get _label {
    switch (order.status) {
      case OrderStatus.completed:  return 'Completed';
      case OrderStatus.delivered:  return 'Delivered';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.cancelled:  return 'Cancelled';
      default:                     return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: order.status == OrderStatus.outForDelivery
          ? () => Navigator.push(
                context,
                AppTheme.route((_) => DeliveryConfirmationScreen(
                  deliveryId: order.uuid,
                  customerName: order.storeName ?? '',
                  deliveryAddress: order.deliveryAddress,
                )),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(order.orderNumber,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    if (order.storeName?.isNotEmpty == true) ...[
                      const Text(' · ', style: TextStyle(color: Color(0xFF9CA3AF))),
                      Flexible(
                        child: Text(order.storeName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ),
                    ],
                  ]),
                  if (order.deliveryAddress.isNotEmpty)
                    Text(order.deliveryAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _color)),
            ),
            if (order.status == OrderStatus.outForDelivery)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA3AF)),
              ),
          ],
        ),
      ),
    );
  }
}
