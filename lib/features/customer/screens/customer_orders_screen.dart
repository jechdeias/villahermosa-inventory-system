import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';
import '../widgets/order_progress_stepper.dart';
import 'customer_order_detail_screen.dart';

const ccMono = TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 16, fontWeight: FontWeight.w600, color: CcColors.text);

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  CustomerOrderStatus? _filter; // null = All

  static const _chips = <(String, CustomerOrderStatus?)>[
    ('All', null),
    ('Processing', CustomerOrderStatus.processing),
    ('Out for Delivery', CustomerOrderStatus.outForDelivery),
    ('Delivered', CustomerOrderStatus.delivered),
    ('Cancelled', CustomerOrderStatus.cancelled),
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    final orders = ordersAsync.value ?? [];
    final shown = _filter == null ? orders : orders.where((o) => customerStatusOf(o) == _filter).toList();

    return CustomerShell(
      currentRoute: CustomerRoutes.orders,
      child: Column(children: [
        const CcTitleBar(title: 'My Orders'),
        Container(
          color: Colors.white,
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              for (final (label, status) in _chips)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _filter = status),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _filter == status ? CcColors.primary : Colors.white,
                        border: Border.all(color: _filter == status ? CcColors.primary : CcColors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _filter == status ? Colors.white : CcColors.text)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: CcColors.border),
        Expanded(
          child: isFirstLoad(ordersAsync)
              ? const ShimmerCardList(cardHeight: 120)
              : shown.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: orders.isEmpty ? 'No orders yet' : 'No ${_filter == null ? '' : customerStatusLabel(_filter!).toLowerCase()} orders',
                  message: orders.isEmpty
                      ? 'When your Villahermosa sales rep takes an order at your store, it will show up here'
                      : 'Try another filter to see your other orders',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => _OrderCard(
                    order: shown[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CustomerOrderDetailScreen(orderUuid: shown[i].uuid))),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.onTap});
  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = customerStatusOf(order);
    final active = isActiveCustomerOrder(status);
    final rep = order.salesRepName ?? '';
    String? note;
    if (status == CustomerOrderStatus.processing && order.expectedDeliveryDate != null) {
      note = 'Delivery on ${ccWeekdayShort(order.expectedDeliveryDate!)}';
    } else if (status == CustomerOrderStatus.outForDelivery) {
      note = rep.isEmpty ? 'On the way today' : 'On the way today with $rep';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CcCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: order.orderNumber, style: ccMono),
                  TextSpan(text: ' · ${ccShortDate(order.createdAt)}', style: const TextStyle(fontSize: 15, color: CcColors.muted)),
                ])),
              ),
              CcBadge.status(customerStatusLabel(status)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text('${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}', style: const TextStyle(fontSize: 15, color: CcColors.muted)),
              const Spacer(),
              Text(formatPeso(order.totalAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CcColors.text)),
            ]),
            if (active) ...[
              const SizedBox(height: 12),
              OrderProgressStepper(currentStep: customerStepOf(status)),
              if (note != null) ...[
                const SizedBox(height: 12),
                Text(note, style: const TextStyle(fontSize: 15, color: CcColors.muted)),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}
