import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sales_providers.dart';
import '../widgets/customer_detail_sheet.dart';
import '../widgets/sales_shell.dart';
import '../../../core/theme/app_theme.dart';

class SalesCustomersScreen extends ConsumerStatefulWidget {
  const SalesCustomersScreen({super.key});

  @override
  ConsumerState<SalesCustomersScreen> createState() => _SalesCustomersScreenState();
}

class _SalesCustomersScreenState extends ConsumerState<SalesCustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(myCustomersProvider);
    final loading = isFirstLoad(ref.watch(salesRepOrdersProvider));
    final paymentsList = ref.watch(salesRepPaymentsProvider).value ?? [];
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? customers
        : customers.where((c) =>
            salesDisplayStoreName(c).toLowerCase().contains(q) ||
            (c.barangay ?? '').toLowerCase().contains(q)).toList();

    return SalesShell(
      currentRoute: '/sales/customers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Customers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search stores or barangay...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textLight),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const ShimmerCardList(padding: EdgeInsets.fromLTRB(20, 4, 20, 16), cardHeight: 72)
                : filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.store_outlined,
                    title: 'No customers on your route',
                    message: "Customers you've visited will appear here",
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final storeName = salesDisplayStoreName(c);
                      final balance = paymentsList
                          .where((p) => p.storeName == storeName)
                          .fold(0.0, (s, p) => s + p.balance);
                      return InkWell(
                        onTap: () => showCustomerDetailSheet(context, c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(storeName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(c.barangay ?? c.town ?? c.municipality,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            if (balance > 0)
                              Text('₱${balance.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.warning))
                            else
                              const Icon(Icons.chevron_right, color: AppTheme.textLight),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
