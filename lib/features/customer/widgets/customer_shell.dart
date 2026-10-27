import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import 'customer_common.dart';

/// Route names for the customer app's tabs.
class CustomerRoutes {
  static const shop = '/customer/dashboard';
  static const orders = '/customer/orders';
  static const cart = '/customer/cart';
  static const payments = '/customer/payments';
  static const profile = '/customer/profile';
}

/// Cart icon with the red count badge (hidden when the cart is empty).
class CartBadgeIcon extends ConsumerWidget {
  const CartBadgeIcon({super.key, this.icon = Icons.shopping_cart_outlined, this.size = 24, this.color = CcColors.text});
  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
      backgroundColor: CcColors.red,
      child: Icon(icon, size: size, color: color),
    );
  }
}

/// Bottom-nav chrome wrapping each tab screen. Content is capped at a phone-ish
/// width and centred, so the app also looks right on tablets / desktop windows.
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.currentRoute, required this.child});
  final String currentRoute;
  final Widget child;

  static const _tabs = [
    (route: CustomerRoutes.shop, icon: Icons.storefront_outlined, label: 'Shop'),
    (route: CustomerRoutes.orders, icon: Icons.receipt_long_outlined, label: 'Orders'),
    (route: CustomerRoutes.cart, icon: Icons.shopping_cart_outlined, label: 'Cart'),
    (route: CustomerRoutes.payments, icon: Icons.payments_outlined, label: 'Payments'),
    (route: CustomerRoutes.profile, icon: Icons.person_outlined, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _tabs.indexWhere((t) => t.route == currentRoute);
    return Scaffold(
      backgroundColor: CcColors.page,
      body: SafeArea(
        bottom: false,
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child)),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CcColors.border))),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: BottomNavigationBar(
                currentIndex: index < 0 ? 0 : index,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: CcColors.text,
                unselectedItemColor: CcColors.light,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                onTap: (i) {
                  if (_tabs[i].route != currentRoute) Navigator.pushReplacementNamed(context, _tabs[i].route);
                },
                items: [
                  for (final t in _tabs)
                    BottomNavigationBarItem(
                      icon: t.route == CustomerRoutes.cart ? CartBadgeIcon(icon: t.icon) : Icon(t.icon),
                      activeIcon: t.route == CustomerRoutes.cart
                          ? CartBadgeIcon(icon: Icons.shopping_cart, color: CcColors.text)
                          : Icon(switch (t.route) {
                              CustomerRoutes.shop => Icons.storefront,
                              CustomerRoutes.orders => Icons.receipt_long,
                              CustomerRoutes.payments => Icons.payments,
                              _ => Icons.person,
                            }),
                      label: t.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
