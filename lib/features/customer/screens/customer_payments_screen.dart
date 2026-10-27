import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';
import 'customer_orders_screen.dart' show ccMono;

class CustomerPaymentsScreen extends ConsumerWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = [...(ref.watch(customerPaymentsProvider).value ?? [])]..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final balance = ref.watch(customerBalanceProvider);
    final paid = payments.fold<double>(0, (s, p) => s + p.amountPaid);

    return CustomerShell(
      currentRoute: CustomerRoutes.payments,
      child: Column(children: [
        const CcTitleBar(title: 'Payments'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CcCard(
                padding: EdgeInsets.zero,
                child: IntrinsicHeight(
                  child: Row(children: [
                    Expanded(child: _summary('Total paid', formatPeso(paid), CcColors.green)),
                    const VerticalDivider(width: 1, color: CcColors.border),
                    Expanded(child: _summary('Outstanding', formatPeso(balance), balance > 0 ? CcColors.red : CcColors.green)),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Payment History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CcColors.text)),
              const SizedBox(height: 10),
              if (payments.isEmpty)
                const CcCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No payments recorded yet', style: TextStyle(fontSize: 14, color: CcColors.muted)))))
              else
                CcCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final (i, p) in payments.indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: CcColors.border))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.orderCode, style: ccMono.copyWith(fontSize: 15, color: CcColors.muted)),
                              const SizedBox(height: 8),
                              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 4, children: [
                                if ((p.paymentMethod ?? '').isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: CcColors.border), borderRadius: BorderRadius.circular(20)),
                                    child: Text(p.paymentMethod!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CcColors.body)),
                                  ),
                                Text(ccFullDate(p.paymentDate), style: const TextStyle(fontSize: 15, color: CcColors.muted)),
                              ]),
                            ]),
                          ),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(formatPeso(p.amountPaid), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CcColors.text)),
                            const SizedBox(height: 8),
                            CcBadge.status(paymentBadgeOf(p)),
                          ]),
                        ]),
                      ),
                  ]),
                ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Payments are recorded by your sales rep when they collect. See something wrong? Tell your rep on the next visit.',
                  style: TextStyle(fontSize: 13, color: CcColors.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _summary(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CcColors.muted, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color))),
        ]),
      );
}
