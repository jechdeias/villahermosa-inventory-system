import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/pdf_export.dart';
import '../providers/orders_provider.dart';
import '../services/orders_service.dart';
import '../utils/order_pdf_printer.dart';
import 'order_status_badge.dart';
import '../../../core/theme/app_theme.dart';

class OrderDetailPanel extends ConsumerWidget {
  const OrderDetailPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(selectedOrderProvider);
    if (order == null) return const SizedBox.shrink();

    final itemsAsync = ref.watch(orderItemsProvider(order.uuid));
    final service = ref.read(ordersServiceProvider);
    final db = ref.read(databaseProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(order, onClose),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection('ORDER INFO', [
                    _buildInfoRow('Order Number', Text(order.orderNumber,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: AppTheme.monoFamily))),
                    _buildInfoRow('Status', OrderStatusBadge(status: order.status)),
                    _buildInfoRow('Date', Text(_formatDate(order.createdAt),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                  ]),
                  _buildSection('STORE & ROUTE', [
                    _buildInfoRow('Store', Text(order.storeName ?? order.customerId,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                    _buildTappableRow(
                      context: context,
                      label: 'Route',
                      value: order.routeName ?? '—',
                      onTap: () => _showRoutePicker(context, ref, order, service, db),
                    ),
                    _buildTappableRow(
                      context: context,
                      label: 'Sales Rep',
                      value: order.salesRepName ?? '—',
                      onTap: () => _showRepPicker(context, ref, order, service, db),
                    ),
                  ]),
                  _buildItemsSection(order, itemsAsync),
                ],
              ),
            ),
          ),
          _buildFooter(context, ref, order, service),
        ],
      ),
    );
  }

  Widget _buildHeader(Order order, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppTheme.textLight, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildTappableRow({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final assigned = value != '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: assigned ? AppTheme.textPrimary : const Color(0xFF9CA3AF),
                        fontStyle: assigned ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit, size: 14, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoutePicker(
    BuildContext context,
    WidgetRef ref,
    Order order,
    OrdersService service,
    AppDatabase db,
  ) async {
    final routes = await db.watchAllDeliveryRoutes().first;
    if (!context.mounted) return;

    if (routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery routes found. Create routes in the Deliveries screen.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: 'Assign Route',
        items: routes.map((r) => _PickerItem(id: r.uuid, name: r.routeName)).toList(),
        currentId: order.routeId,
        onSelect: (item) async {
          await service.assignRoute(
            order.uuid,
            routeId: item.id,
            routeName: item.name,
            salesRepId: order.salesRepId ?? '',
            salesRepName: order.salesRepName ?? '',
          );
          // Refresh selected order
          ref.read(selectedOrderProvider.notifier).state =
              ref.read(filteredOrdersProvider).where((o) => o.uuid == order.uuid).firstOrNull
              ?? ref.read(selectedOrderProvider);
        },
      ),
    );
  }

  Future<void> _showRepPicker(
    BuildContext context,
    WidgetRef ref,
    Order order,
    OrdersService service,
    AppDatabase db,
  ) async {
    final allUsers = await db.getAllUsers();
    final reps = allUsers.where((u) => u.role == 'delivery' || u.role == 'sales_rep').toList();
    if (!context.mounted) return;

    if (reps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery reps found. Add delivery users in User Accounts.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: 'Assign Sales Rep',
        items: reps.map((u) => _PickerItem(id: u.uuid, name: '${u.firstName} ${u.lastName}'.trim())).toList(),
        currentId: order.salesRepId,
        onSelect: (item) async {
          await service.assignRoute(
            order.uuid,
            routeId: order.routeId ?? '',
            routeName: order.routeName ?? '',
            salesRepId: item.id,
            salesRepName: item.name,
          );
          ref.read(selectedOrderProvider.notifier).state =
              ref.read(filteredOrdersProvider).where((o) => o.uuid == order.uuid).firstOrNull
              ?? ref.read(selectedOrderProvider);
        },
      ),
    );
  }

  Widget _buildItemsSection(Order order, AsyncValue<List<OrderItem>> itemsAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ITEMS (${order.itemCount} TOTAL)',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppTheme.textLight, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: Text('PRODUCT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textLight))),
            SizedBox(width: 36, child: Text('QTY',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textLight))),
            SizedBox(width: 52, child: Text('PRICE',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textLight))),
            SizedBox(width: 60, child: Text('SUB',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textLight))),
          ]),
          const Divider(height: 12),
          itemsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(fontSize: 12, color: AppTheme.error)),
            data: (items) => Column(
              children: items.map((item) => _buildItemRow(item)).toList(),
            ),
          ),
          const Divider(height: 20),
          Row(children: [
            const Expanded(
              child: Text('Total Amount',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            Text('₱${_formatNum(order.totalAmount)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Text(item.productName,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        SizedBox(
          width: 36,
          child: Text('${item.quantity}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
        ),
        SizedBox(
          width: 52,
          child: Text('₱${item.unitPrice.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        SizedBox(
          width: 60,
          child: Text('₱${_formatNum(item.subtotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, Order order, OrdersService service) {
    final itemsAsync = ref.watch(orderItemsProvider(order.uuid));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.border),
                foregroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final lines = itemsAsync.value ?? [];
                final doc = await buildOrderPdf(order, lines);
                if (context.mounted) {
                  await exportPdf(doc, 'Order_${order.orderNumber}.pdf');
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('Export PDF', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.border),
                foregroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          ..._statusActions(context, ref, order, service),
        ],
      ),
    );
  }

  List<Widget> _statusActions(BuildContext context, WidgetRef ref, Order order, OrdersService service) {
    Future<void> advance(Future<void> Function() fn) async {
      await fn();
      ref.read(selectedOrderProvider.notifier).state = null;
      onClose();
    }

    Widget primaryBtn(String label, Future<void> Function() fn, {Color? bg}) => Expanded(
          child: ElevatedButton(
            onPressed: () => advance(fn),
            style: ElevatedButton.styleFrom(
              backgroundColor: bg ?? AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
        );

    Widget outlineBtn(String label, Future<void> Function() fn) => Expanded(
          child: OutlinedButton(
            onPressed: () => advance(fn),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border),
              foregroundColor: const Color(0xFF374151),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
        );

    return switch (order.status) {
      'pending'          => [const SizedBox(width: 8), primaryBtn('Start Processing',     () => service.markProcessing(order.uuid))],
      'processing'       => [const SizedBox(width: 8), primaryBtn('Dispatch for Delivery', () => service.markOutForDelivery(order.uuid), bg: const Color(0xFF7C3AED))],
      'out_for_delivery' => [const SizedBox(width: 8), primaryBtn('Mark as Delivered',    () => service.markDelivered(order.uuid), bg: const Color(0xFF059669))],
      'delivered'        => [const SizedBox(width: 8), primaryBtn('Mark Completed',       () => service.markCompleted(order.uuid), bg: const Color(0xFF16A34A))],
      'cancelled'        => [const SizedBox(width: 8), outlineBtn('Restore Order',        () => service.restoreOrder(order.uuid))],
      _                  => [],
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _formatNum(double v) {
    final n = v.round().toString();
    final buf = StringBuffer();
    final mod = n.length % 3;
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (i - mod) % 3 == 0) buf.write(',');
      buf.write(n[i]);
    }
    return buf.toString();
  }
}

// ── Shared picker helpers ──────────────────────────────────────────────────────

class _PickerItem {
  const _PickerItem({required this.id, required this.name});
  final String id;
  final String name;
}

class _PickerDialog extends StatelessWidget {
  const _PickerDialog({
    required this.title,
    required this.items,
    required this.onSelect,
    this.currentId,
  });

  final String title;
  final List<_PickerItem> items;
  final String? currentId;
  final Future<void> Function(_PickerItem) onSelect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 320,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (ctx, i) {
            final item = items[i];
            final selected = item.id == currentId;
            return ListTile(
              dense: true,
              title: Text(item.name, style: const TextStyle(fontSize: 13)),
              trailing: selected ? const Icon(Icons.check, size: 16, color: AppTheme.success) : null,
              selected: selected,
              selectedColor: AppTheme.success,
              onTap: () async {
                Navigator.pop(ctx);
                await onSelect(item);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
