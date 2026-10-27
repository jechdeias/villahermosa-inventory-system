import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';

class CustomerCartScreen extends ConsumerStatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  ConsumerState<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends ConsumerState<CustomerCartScreen> {
  static const _methods = ['Cash on Delivery', 'GCash', 'Credit'];
  String _method = _methods.first;
  bool _placing = false;

  Future<void> _confirm(List<CartItem> items, double total) async {
    final profile = ref.read(customerProfileProvider);
    final delivery = nextDeliveryDate(profile.deliveryDays, DateTime.now());
    final units = items.fold<int>(0, (s, i) => s + i.quantity);

    final who = profile.repName.isEmpty ? 'Your sales rep' : 'Your sales rep, ${profile.repName},';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_outlined, color: CcColors.text, size: 22),
            ),
            const SizedBox(height: 16),
            Text('Confirm order of ${formatPeso(total)}?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CcColors.text)),
            const SizedBox(height: 10),
            Text.rich(TextSpan(style: const TextStyle(fontSize: 16, color: CcColors.muted, height: 1.4), children: [
              TextSpan(text: '$who will deliver on '),
              TextSpan(text: ccWeekdayLong(delivery), style: const TextStyle(fontWeight: FontWeight.w700, color: CcColors.text)),
              TextSpan(text: profile.routeName.isEmpty ? '.' : ' (${profile.routeName} route).'),
            ])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: CcColors.border), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text('$units ${units == 1 ? 'item' : 'items'}', style: const TextStyle(fontSize: 15, color: CcColors.muted)),
                const Spacer(),
                Flexible(child: Text(_method, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CcColors.text))),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    foregroundColor: CcColors.text,
                    side: const BorderSide(color: CcColors.border),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: CcPrimaryButton(label: 'Confirm', height: 52, onPressed: () => Navigator.pop(ctx, true))),
            ]),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _placing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await placeCustomerOrder(ref, items: items, paymentMethod: _method, profile: profile);
      navigator.pushReplacementNamed(CustomerRoutes.orders);
      messenger.showSnackBar(const SnackBar(content: Text('Order placed!')));
    } catch (e) {
      if (mounted) setState(() => _placing = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);

    return CustomerShell(
      currentRoute: CustomerRoutes.cart,
      child: Column(children: [
        CcTitleBar(title: 'My Cart', trailing: Text('$count ${count == 1 ? 'item' : 'items'}', style: const TextStyle(fontSize: 16, color: CcColors.muted))),
        if (items.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add products from the shop and they will show up here',
              actionLabel: 'Start Shopping',
              action: () => Navigator.pushReplacementNamed(context, CustomerRoutes.shop),
            ),
          )
        else ...[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                for (final item in items)
                  CartItemCard(
                    key: ValueKey(item.product.uuid),
                    item: item,
                    onQtyChanged: (q) => ref.read(cartProvider.notifier).updateQty(item.product.uuid, q),
                    onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.uuid),
                  ),
                CcCard(
                  child: Column(children: [
                    _sumRow('Subtotal', Text(formatPeso(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CcColors.text))),
                    const SizedBox(height: 10),
                    _sumRow('Delivery', const Text('Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CcColors.green))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: CcColors.border)),
                    Row(children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CcColors.text)),
                      const Spacer(),
                      Text(formatPeso(total), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: CcColors.text)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 8),
                const CcSectionLabel('How will you pay?'),
                Row(children: [
                  for (final (i, m) in _methods.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _methodButton(m)),
                  ],
                ]),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CcColors.border))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total', style: TextStyle(fontSize: 13, color: CcColors.muted)),
                Text(formatPeso(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: CcColors.text)),
              ]),
              const SizedBox(width: 20),
              Expanded(child: CcPrimaryButton(label: 'Place Order', height: 52, onPressed: _placing ? null : () => _confirm(items, total))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _sumRow(String label, Widget value) => Row(children: [
        Text(label, style: const TextStyle(fontSize: 16, color: CcColors.muted)),
        const Spacer(),
        value,
      ]);

  Widget _methodButton(String m) {
    final selected = _method == m;
    return InkWell(
      onTap: () => setState(() => _method = m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CcColors.primary : Colors.white,
          border: Border.all(color: selected ? CcColors.primary : CcColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(m, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : CcColors.body)),
      ),
    );
  }
}
