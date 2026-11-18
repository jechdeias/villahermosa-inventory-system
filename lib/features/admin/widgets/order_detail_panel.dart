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
        // _PickerItem.id carries the LOCAL int id as a string (orders.routeId /
        // orders.salesRepId are IntColumns). Local ids are not cross-device
        // stable, but nothing filters on these ids — rep matching is done by
        // salesRepName (watchOrdersBySalesRep). Moving both columns to synced
        // uuids is the documented follow-up in drop_dead_columns.sql.
        items: routes.map((r) => _PickerItem(id: r.id.toString(), name: r.routeName)).toList(),
        currentId: order.routeId?.toString(),
        onSelect: (item) async {
          await service.assignRoute(
            order.uuid,
            routeId: int.parse(item.id),
            routeName: item.name,
            salesRepId: order.salesRepId ?? 0,
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
        // Local int id as string — see the note in _showRoutePicker. The name
        // is what delivery dashboards actually match on, so it must stay the
        // rep's exact display name.
        items: reps.map((u) => _PickerItem(id: u.id.toString(), name: '${u.firstName} ${u.lastName}'.trim())).toList(),
        currentId: order.salesRepId?.toString(),
        onSelect: (item) async {
          await service.assignRoute(
            order.uuid,
            routeId: order.routeId ?? 0,
            routeName: order.routeName ?? '',
            salesRepId: int.parse(item.id),
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

  /// Footer actions. Side by side only when every button gets enough width for
  /// its full label; otherwise stacked vertically at full width (primary action
  /// first). The labels ("Dispatch for Delivery", "Mark as Delivered") are
  /// deliberately explicit about an irreversible status change, so they are never
  /// shortened — and each button's Text is `maxLines: 1`, so if this layout ever
  /// regresses the label clips visibly instead of silently re-wrapping.
  Widget _buildFooter(BuildContext context, WidgetRef ref, Order order, OrdersService service) {
    final itemsAsync = ref.watch(orderItemsProvider(order.uuid));
    final action = _statusAction(context, ref, order, service);

    Widget closeBtn() => OutlinedButton(
          onPressed: onClose,
          style: _outlineStyle,
          child: _label('Close'),
        );

    Widget exportBtn() => OutlinedButton.icon(
          onPressed: () async {
            final lines = itemsAsync.valueOrNull ?? [];
            final doc = await buildOrderPdf(order, lines);
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final path = await exportPdf(doc, 'Order_${order.orderNumber}.pdf');
            if (path != null) {
              messenger.showSnackBar(SnackBar(content: Text('PDF saved to $path')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: _label('Export PDF'),
          style: _outlineStyle,
        );

    Widget actionBtn() => action!.outline
        ? OutlinedButton(onPressed: action.onPressed, style: _outlineStyle, child: _label(action.label))
        : ElevatedButton(
            onPressed: action.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: action.bg ?? AppTheme.primary,
              foregroundColor: Colors.white,
              padding: _buttonPadding,
            ),
            child: _label(action.label),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // Natural width each button needs for its whole label on one line.
        final scaler = MediaQuery.textScalerOf(context);
        // Measure in the font the buttons actually render in: Material buttons
        // take their text style from the theme's labelLarge, then our size applies.
        final style = (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).merge(_labelStyle);
        double need(String label, {double extra = 0}) => _textWidth(label, style, scaler) + _buttonPadding.horizontal + extra;
        final widest = [
          need('Close'),
          need('Export PDF', extra: 16 + 8), // icon + its gap
          if (action != null) need(action.label),
        ].reduce((a, b) => a > b ? a : b);
        final count = action == null ? 2 : 3;
        // The Row gives every button an equal Expanded share.
        final share = (constraints.maxWidth - 8 * (count - 1)) / count;

        if (share >= widest) {
          return Row(children: [
            Expanded(child: closeBtn()),
            const SizedBox(width: 8),
            Expanded(child: exportBtn()),
            if (action != null) ...[const SizedBox(width: 8), Expanded(child: actionBtn())],
          ]);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (action != null) ...[actionBtn(), const SizedBox(height: 8)],
            exportBtn(),
            const SizedBox(height: 8),
            closeBtn(),
          ],
        );
      }),
    );
  }

  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const _labelStyle = TextStyle(fontSize: 13);

  static final _outlineStyle = OutlinedButton.styleFrom(
    side: const BorderSide(color: AppTheme.border),
    foregroundColor: const Color(0xFF374151),
    padding: _buttonPadding,
  );

  /// One-line, centred label: never wraps silently (see [_buildFooter]).
  static Widget _label(String text) => Text(text, style: _labelStyle, maxLines: 1, textAlign: TextAlign.center);

  /// Width of [text] in [style] on one line, honouring the user's text scale.
  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  /// The one status action for this order's state, or null (e.g. completed).
  ({String label, Future<void> Function() onPressed, Color? bg, bool outline})? _statusAction(
      BuildContext context, WidgetRef ref, Order order, OrdersService service) {
    // A failure (e.g. the stock deduction that goes with Dispatch/Cancel throws
    // and rolls the status change back) must be SHOWN: the order is still in its
    // old status, so the panel stays open and selected, and the user is told why.
    // debugPrint alone would be invisible in a release build.
    Future<void> advance(String label, Future<void> Function() fn) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await fn();
      } catch (e) {
        messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
          content: Text("Couldn't $label: ${order.orderNumber} was not changed. $e"),
        ));
        return;
      }
      ref.read(selectedOrderProvider.notifier).state = null;
      onClose();
    }

    ({String label, Future<void> Function() onPressed, Color? bg, bool outline}) primary(
            String label, Future<void> Function() fn, {Color? bg}) =>
        (label: label, onPressed: () => advance(label, fn), bg: bg, outline: false);

    return switch (order.status) {
      'pending'          => primary('Start Processing',     () => service.markProcessing(order.uuid)),
      'processing'       => primary('Dispatch for Delivery', () => service.markOutForDelivery(order.uuid), bg: const Color(0xFF7C3AED)),
      'out_for_delivery' => primary('Mark as Delivered',    () => service.markDelivered(order.uuid), bg: const Color(0xFF059669)),
      'delivered'        => primary('Mark Completed',       () => service.markCompleted(order.uuid), bg: const Color(0xFF16A34A)),
      'cancelled'        => (label: 'Restore Order', onPressed: () => advance('Restore Order', () => service.restoreOrder(order.uuid)), bg: null, outline: true),
      _                  => null,
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
