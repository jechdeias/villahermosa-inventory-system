import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehouseIncomingOrdersScreen extends ConsumerStatefulWidget {
  const WarehouseIncomingOrdersScreen({super.key});

  @override
  ConsumerState<WarehouseIncomingOrdersScreen> createState() => _WarehouseIncomingOrdersScreenState();
}

class _WarehouseIncomingOrdersScreenState extends ConsumerState<WarehouseIncomingOrdersScreen> {
  static const _pageSize = 10;
  static const _flex = [3, 4, 4, 2, 3, 2];
  static const _statuses = ['pending', 'processing', 'ready', 'dispatched', 'completed', 'cancelled'];

  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _statusFilter;
  int _page = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFilter() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Filter by status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, ''), child: const Text('All statuses')),
          for (final s in _statuses)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(s[0].toUpperCase() + s.substring(1))),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      _statusFilter = picked.isEmpty ? null : picked;
      _page = 0;
    });
  }

  Future<void> _process(Order o) async {
    await ref.read(warehouseActionsProvider).processOrder(o);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${o.orderNumber} moved to Prepare Orders')));
  }

  Future<void> _view(Order o) async {
    final lines = ref.read(orderLinesByOrderProvider)[o.uuid] ?? [];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(o.orderNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 420,
          child: lines.isEmpty
              ? const Text('No order lines recorded for this order.', style: TextStyle(fontSize: 13, color: WhColors.muted))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final l in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text(l.productName, style: const TextStyle(fontSize: 13))),
                          Text('${l.quantity} units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: WhColors.muted)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstLoad(ref.watch(ordersStreamProvider))) return const WhLoadingShell(route: WhRoutes.incoming);
    final all = ref.watch(ordersStreamProvider).value ?? [];
    final q = _search.toLowerCase();
    final filtered = all.where((o) {
      if (_statusFilter != null && whOrderStatus(o) != _statusFilter) return false;
      if (q.isEmpty) return true;
      return o.orderNumber.toLowerCase().contains(q) ||
          (o.storeName ?? '').toLowerCase().contains(q) ||
          (o.routeName ?? '').toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final pages = (filtered.length / _pageSize).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(0, pages - 1);
    final shown = filtered.skip(page * _pageSize).take(_pageSize).toList();
    final pending = shown.where((o) => whOrderStatus(o) == 'pending').length;

    return WarehouseShell(
      route: WhRoutes.incoming,
      child: WhPage(children: [
        const WhPageHeader(title: 'Incoming Orders', subtitle: 'Manage and track incoming orders for delivery'),
        WhCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: WhSearchInput(
                      hint: 'Search orders, stores, routes...',
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() {
                        _search = v;
                        _page = 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  WhFilterButton(onPressed: _pickFilter, active: _statusFilter != null),
                  const SizedBox(width: 14),
                  if (MediaQuery.of(context).size.width > 900)
                    Text('$pending pending on this page', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                ]),
              ),
              if (shown.isEmpty)
                WhEmpty(_search.isEmpty && _statusFilter == null ? 'Orders from sales reps will appear here' : 'Try a different search or status filter', title: _search.isEmpty && _statusFilter == null ? 'No incoming orders' : 'No orders match', icon: Icons.move_to_inbox_outlined)
              else
                WhTableScroll(
                  minWidth: 760,
                  child: Column(children: [
                    const WhTableHeader(columns: ['Order Number', 'Store Name', 'Route', 'Items', 'Status', 'Actions'], flex: _flex, rightAlignLast: true),
                    for (final o in shown) _row(o),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: Text('Showing ${shown.length} of ${filtered.length} orders', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
                  ),
                  WhSecondaryButton(label: 'Previous', height: 32, onPressed: page > 0 ? () => setState(() => _page = page - 1) : null),
                  const SizedBox(width: 8),
                  WhSecondaryButton(label: 'Next', height: 32, onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _row(Order o) {
    final status = whOrderStatus(o);
    final canProcess = status == 'pending';
    final when = isSameDay(o.createdAt, DateTime.now()) ? formatClock(o.createdAt) : '${formatDate(o.createdAt)}, ${formatClock(o.createdAt)}';
    return WhTableRow(
      flex: _flex,
      rightAlignLast: true,
      cells: [
        Text(o.orderNumber, style: whMono),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(o.storeName ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text), overflow: TextOverflow.ellipsis),
          Text('ordered $when', style: const TextStyle(fontSize: 11, color: WhColors.muted)),
        ]),
        Text(o.routeName ?? '—', style: const TextStyle(fontSize: 13, color: WhColors.text), overflow: TextOverflow.ellipsis),
        Text('${o.itemCount} products', style: const TextStyle(fontSize: 13, color: WhColors.text)),
        WhStatusBadge(status),
        canProcess
            ? WhPrimaryButton(label: 'Process', height: 30, onPressed: () => _process(o))
            : WhSecondaryButton(label: 'View', height: 30, onPressed: () => _view(o)),
      ],
    );
  }
}
