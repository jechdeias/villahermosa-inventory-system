import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common.dart';
import '../widgets/customer_shell.dart';
import '../widgets/product_grid_card.dart';
import 'customer_product_detail_screen.dart';

class CustomerShopScreen extends ConsumerStatefulWidget {
  const CustomerShopScreen({super.key});

  @override
  ConsumerState<CustomerShopScreen> createState() => _CustomerShopScreenState();
}

class _CustomerShopScreenState extends ConsumerState<CustomerShopScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(customerProfileProvider);
    final balance = ref.watch(customerBalanceProvider);
    final suppliers = ref.watch(supplierNamesProvider);
    final all = ref.watch(shopProductsProvider);
    final loading = isFirstLoad(ref.watch(productsStreamProvider));
    final q = _search.trim().toLowerCase();
    final products = q.isEmpty
        ? all
        : all.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
    final subtitle = [profile.storeName, if (profile.routeName.isNotEmpty) profile.routeName].join(' · ');

    return CustomerShell(
      currentRoute: CustomerRoutes.shop,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: CcColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Text('V', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                const Text('Villahermosa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CcColors.text)),
                const Spacer(),
                IconButton(
                  tooltip: 'Cart',
                  onPressed: () => Navigator.pushReplacementNamed(context, CustomerRoutes.cart),
                  icon: const CartBadgeIcon(size: 28),
                ),
              ]),
              const SizedBox(height: 14),
              Text('Hello, ${profile.firstName.isEmpty ? 'there' : profile.firstName} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CcColors.text)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: CcColors.muted)),
            ]),
          ),
          const Divider(height: 1, color: CcColors.border),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (balance > 0) ...[_BalanceAlert(balance: balance), const SizedBox(height: 14)],
                      SizedBox(
                        height: 44,
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search products',
                            hintStyle: const TextStyle(fontSize: 15, color: CcColors.light),
                            prefixIcon: const Icon(Icons.search, color: CcColors.muted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: CcColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: CcColors.primary)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Expanded(child: Text('All Products', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CcColors.text))),
                        const SizedBox(width: 8),
                        Text('${products.length} products', style: const TextStyle(fontSize: 14, color: CcColors.muted)),
                      ]),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
                if (loading)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Row(children: [
                        Expanded(child: ShimmerBox(width: double.infinity, height: 280, borderRadius: 12)),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerBox(width: double.infinity, height: 280, borderRadius: 12)),
                      ]),
                    ),
                  )
                else if (products.isEmpty)
                  SliverToBoxAdapter(
                    child: all.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No products available',
                            message: 'Products will appear here when the catalog is loaded',
                          )
                        : const EmptyState(
                            icon: Icons.search_off_outlined,
                            title: 'No products found',
                            message: 'Try a different search',
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 296,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        childCount: products.length,
                        (context, i) {
                          final p = products[i];
                          return ProductGridCard(
                            product: p,
                            supplierName: suppliers[p.supplierId] ?? '',
                            inCart: ref.watch(cartQtyProvider(p.uuid)),
                            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CustomerProductDetailScreen(productUuid: p.uuid))),
                            onAdd: () => ref.read(cartProvider.notifier).addItem(p, 1),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceAlert extends StatelessWidget {
  const _BalanceAlert({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9E7),
          border: Border.all(color: const Color(0xFFFCD34D)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Color(0xFFFDEFB5), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, color: CcColors.amber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(style: const TextStyle(fontSize: 18, color: CcColors.amber), children: [
                const TextSpan(text: 'You have '),
                TextSpan(text: formatPeso(balance), style: const TextStyle(fontWeight: FontWeight.w800, color: CcColors.red)),
                const TextSpan(text: ' outstanding'),
              ])),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, CustomerRoutes.payments),
                child: const Text('View Payments →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CcColors.amber, decoration: TextDecoration.underline)),
              ),
            ]),
          ),
        ]),
      );
}
