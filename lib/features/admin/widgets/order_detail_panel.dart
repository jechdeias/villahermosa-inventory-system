import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/orders_provider.dart';
import '../services/orders_service.dart';
import 'order_status_badge.dart';

class OrderDetailPanel extends ConsumerWidget {
  const OrderDetailPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(selectedOrderProvider);
    if (order == null) return const SizedBox.shrink();

    final itemsAsync = ref.watch(orderItemsProvider(order.uuid));
    final service = ref.read(ordersServiceProvider);

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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
                    _buildInfoRow('Status', OrderStatusBadge(status: order.status)),
                    _buildInfoRow('Date', Text(_formatDate(order.createdAt),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                  ]),
                  _buildSection('STORE & ROUTE', [
                    _buildInfoRow('Store', Text(order.storeName ?? order.customerId,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _buildInfoRow('Route', Text(order.routeName ?? '—',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                    _buildInfoRow('Sales Rep', Text(order.salesRepName ?? '—',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
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
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildItemsSection(Order order, AsyncValue<List<OrderItem>> itemsAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ITEMS (${order.itemCount} TOTAL)',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          // column headers
          const Row(children: [
            Expanded(child: Text('PRODUCT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)))),
            SizedBox(width: 36, child: Text('QTY',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)))),
            SizedBox(width: 52, child: Text('PRICE',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)))),
            SizedBox(width: 60, child: Text('SUB',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)))),
          ]),
          const Divider(height: 12),
          itemsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
            data: (items) => Column(
              children: items.map((item) => _buildItemRow(item)).toList(),
            ),
          ),
          const Divider(height: 20),
          Row(children: [
            const Expanded(
              child: Text('Total Amount',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            ),
            Text('₱${_formatNum(order.totalAmount)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        SizedBox(
          width: 36,
          child: Text('${item.quantity}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Color(0xFF111827))),
        ),
        SizedBox(
          width: 52,
          child: Text('₱${item.unitPrice.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        SizedBox(
          width: 60,
          child: Text('₱${_formatNum(item.subtotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        ),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, Order order, OrdersService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                foregroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 13)),
            ),
          ),
          if (order.status == 'pending') ...[
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await service.markCompleted(order.uuid);
                  ref.read(selectedOrderProvider.notifier).state = null;
                  onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Mark as Completed', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
          if (order.status == 'cancelled') ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await service.restoreOrder(order.uuid);
                  ref.read(selectedOrderProvider.notifier).state = null;
                  onClose();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  foregroundColor: const Color(0xFF374151),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Restore Order', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
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
