import 'package:flutter/material.dart';

/// Shared mobile shell for the sales rep role: a bottom nav bar wrapping
/// whichever /sales/* screen is current. Each screen builds its own top
/// bar (they're all different — see each screen's design), so this only
/// owns the Scaffold + bottom nav, matching how ResponsiveShell separates
/// "chrome" from screen content on the admin side. Sales screens are
/// mobile-only by design — no desktop/tablet variant.
class SalesShell extends StatelessWidget {
  const SalesShell({super.key, required this.currentRoute, required this.child});

  final String currentRoute;
  final Widget child;

  static const _items = [
    (route: '/sales/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (route: '/sales/customers', icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Customers'),
    (route: '/sales/orders', icon: Icons.receipt_outlined, activeIcon: Icons.receipt, label: 'Orders'),
    (route: '/sales/payments', icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Payments'),
    (route: '/sales/profile', icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: _items.map((item) {
              final active = currentRoute == item.route;
              final color = active ? const Color(0xFF1E1E1E) : const Color(0xFF9CA3AF);
              return Expanded(
                child: InkWell(
                  onTap: active
                      ? null
                      : () => Navigator.of(context).pushReplacementNamed(item.route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(active ? item.activeIcon : item.icon, size: 24, color: color),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
