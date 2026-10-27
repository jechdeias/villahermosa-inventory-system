import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/warehouse_shell.dart';
import '../widgets/wh_widgets.dart';

class WarehousePrepareOrdersScreen extends ConsumerStatefulWidget {
  const WarehousePrepareOrdersScreen({super.key});

  @override
  ConsumerState<WarehousePrepareOrdersScreen> createState() => _WarehousePrepareOrdersScreenState();
}

class _WarehousePrepareOrdersScreenState extends ConsumerState<WarehousePrepareOrdersScreen> {
  String? _selectedUuid;

  Future<void> _complete(Order o, List<OrderItem> lines) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Complete order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Mark ${o.orderNumber} as prepared and ready for loading?', style: const TextStyle(fontSize: 13, color: WhColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: WhColors.muted))),
          WhPrimaryButton(label: 'Complete', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(warehouseActionsProvider).completeOrder(o, lines);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${o.orderNumber} is ready for loading')));
  }

  @override
  Widget build(BuildContext context) {
    final orders = (ref.watch(ordersStreamProvider).value ?? []).where(needsPreparing).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final byOrder = ref.watch(orderLinesByOrderProvider);
    final products = ref.watch(productsStreamProvider).value ?? [];

    Order? selected;
    for (final o in orders) {
      if (o.uuid == _selectedUuid) selected = o;
    }
    selected ??= orders.isEmpty ? null : orders.first;

    return WarehouseShell(
      route: WhRoutes.prepare,
      child: WhPage(children: [
        const WhPageHeader(title: 'Prepare Orders (Picklist)', subtitle: 'Pick and prepare items for delivery'),
        WhTwoColumn(
          sideFirst: true,
          sideWidth: 280,
          side: _queueCard(orders, byOrder, selected),
          main: selected == null
              ? const WhCard(child: WhEmpty('No orders to prepare. Process an incoming order to start a picklist.'))
              : _picklistCard(selected, byOrder[selected.uuid] ?? [], products),
        ),
      ]),
    );
  }

  Widget _queueCard(List<Order> orders, Map<String, List<OrderItem>> byOrder, Order? selected) => WhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WhCardTitle('Orders Queue',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(20)),
                  child: Text('${orders.length} to prepare', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
                )),
            if (orders.isEmpty)
              const WhEmpty('Queue is empty')
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  for (final o in orders)
                    Builder(builder: (_) {
                      final lines = byOrder[o.uuid] ?? [];
                      final done = lines.where(isItemPicked).length;
                      return WhRouteCard(
                        title: o.orderNumber,
                        subtitle: '${o.storeName ?? '—'}\n${lines.isEmpty ? o.itemCount : lines.length} items${(o.routeName ?? '').isEmpty ? '' : ' · ${o.routeName}'}',
                        active: o.uuid == selected?.uuid,
                        trailing: lines.isEmpty ? 'Not started' : (done == 0 ? 'Not started' : '$done/${lines.length} picked'),
                        onTap: () => setState(() => _selectedUuid = o.uuid),
                      );
                    }),
                ]),
              ),
          ],
        ),
      );

  Widget _picklistCard(Order o, List<OrderItem> lines, List<Product> products) {
    final picked = lines.where(isItemPicked).length;
    final short = lines.where((l) {
      final p = productForItem(l, products);
      return p != null && p.currentStock < l.quantity;
    }).length;
    final complete = lines.isNotEmpty && picked == lines.length;
    return WhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WhCardHeader(
            leading: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order ${o.orderNumber}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: WhColors.text)),
              const SizedBox(height: 2),
              Text('${o.storeName ?? '—'}${(o.routeName ?? '').isEmpty ? '' : ' • ${o.routeName}'}', style: const TextStyle(fontSize: 12, color: WhColors.muted)),
            ]),
            actions: [
              WhSecondaryButton(
                label: 'Print Picklist',
                icon: Icons.print_outlined,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Picklist printing is not set up yet'))),
              ),
              WhPrimaryButton(label: 'Complete Order', onPressed: complete ? () => _complete(o, lines) : null),
            ],
          ),
          if (lines.isEmpty)
            const WhEmpty('This order has no line items recorded yet.')
          else
            WhTableScroll(
              minWidth: 620,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  decoration: const BoxDecoration(color: WhColors.chip, border: Border(top: BorderSide(color: WhColors.border), bottom: BorderSide(color: WhColors.border))),
                  child: const Row(children: [
                    SizedBox(width: 48),
                    Expanded(flex: 5, child: _H('Product')),
                    Expanded(flex: 2, child: _H('Location')),
                    Expanded(flex: 2, child: _H('Required')),
                    Expanded(flex: 3, child: _H('Available')),
                  ]),
                ),
                for (final l in lines)
                  Builder(builder: (_) {
                    final p = productForItem(l, products);
                    return WhPicklistItemRow(
                      name: l.productName,
                      sku: l.productSku,
                      location: (p?.location ?? '').isEmpty ? '—' : 'Location: ${p!.location}',
                      required: l.quantity,
                      available: p?.currentStock,
                      picked: isItemPicked(l),
                      onChanged: (v) => ref.read(warehouseActionsProvider).setItemPicked(l, v),
                    );
                  }),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: lines.isEmpty ? 0 : picked / lines.length,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: WhColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('$picked of ${lines.length} items picked', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: WhColors.text)),
                  if (short > 0)
                    Text('$short ${short == 1 ? 'item is' : 'items are'} short on stock', style: const TextStyle(fontSize: 12, color: WhColors.red)),
                  if (picked > 0)
                    TextButton(
                      onPressed: () => ref.read(warehouseActionsProvider).resetPicks(lines),
                      child: const Text('Reset', style: TextStyle(fontSize: 12, color: WhColors.muted)),
                    ),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: WhColors.muted, letterSpacing: 0.44));
}
