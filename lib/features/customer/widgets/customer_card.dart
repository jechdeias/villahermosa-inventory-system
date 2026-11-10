/// CustomerCard
///
/// Reusable summary card shown in the customer dashboard. Displays the store
/// name, outstanding balance, active order count, and next delivery info.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import 'customer_common.dart';

class CustomerCard extends ConsumerWidget {
  const CustomerCard({super.key, this.onOrdersTap, this.onPaymentsTap});

  final VoidCallback? onOrdersTap;
  final VoidCallback? onPaymentsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(customerProfileProvider);
    final balance = ref.watch(customerBalanceProvider);
    final orders = ref.watch(customerOrdersProvider).value ?? [];
    final activeOrders = orders.where((o) => isActiveCustomerOrder(customerStatusOf(o))).length;
    final nextDelivery = profile.deliveryDays.isNotEmpty
        ? nextDeliveryDate(profile.deliveryDays, DateTime.now())
        : null;

    return CcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header
          Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: CcColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Text(
                profile.storeName.isEmpty ? 'V' : profile.storeName[0].toUpperCase(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CcColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (profile.routeName.isNotEmpty)
                  Text(profile.routeName, style: const TextStyle(fontSize: 12, color: CcColors.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          const Divider(color: CcColors.border, height: 1),
          const SizedBox(height: 18),
          // Stats row
          IntrinsicHeight(
            child: Row(children: [
              _stat(
                label: 'Outstanding',
                value: formatPeso(balance),
                valueColor: balance > 0 ? CcColors.red : CcColors.green,
                onTap: onPaymentsTap,
              ),
              const VerticalDivider(width: 1, color: CcColors.border),
              _stat(
                label: 'Active orders',
                value: '$activeOrders',
                onTap: onOrdersTap,
              ),
              const VerticalDivider(width: 1, color: CcColors.border),
              _stat(
                label: 'Next delivery',
                value: nextDelivery != null ? ccDeliveryDay(nextDelivery) : '—',
              ),
            ]),
          ),
          // Rep info
          if (profile.repName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: CcColors.muted),
              const SizedBox(width: 6),
              Text('Sales rep: ${profile.repName}', style: const TextStyle(fontSize: 12, color: CcColors.muted)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _stat({required String label, required String value, Color? valueColor, VoidCallback? onTap}) {
    final content = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor ?? CcColors.text)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: CcColors.muted), textAlign: TextAlign.center),
        ]),
      ),
    );
    if (onTap == null) return content;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor ?? CcColors.text)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: CcColors.muted), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
