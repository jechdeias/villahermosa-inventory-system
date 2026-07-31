import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../theme/villahermosa_theme.dart';

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    required this.database,
    this.selectedRoute = '/',
    this.navItems,
    this.syncManager,
  });

  final Widget child;
  final String selectedRoute;
  final dynamic database;
  final List<NavigationItem>? navItems;
  final dynamic syncManager;

  @override
  State<ResponsiveShell> createState() => 
    _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  static bool _sidebarExpanded = true;

  List<NavigationItem> get _navItems =>
    widget.navItems ?? _adminNavItems;

  static const List<NavigationItem> _adminNavItems = [
    NavigationItem(route: '/admin/dashboard',
      icon: Icons.dashboard_outlined, 
      label: 'Dashboard'),
    NavigationItem(route: '/admin/products',
      icon: Icons.inventory_2_outlined, 
      label: 'Products'),
    NavigationItem(route: '/admin/customers',
      icon: Icons.storefront_outlined, 
      label: 'Customers'),
    NavigationItem(route: '/admin/orders',
      icon: Icons.shopping_cart_outlined,
      label: 'Orders'),
    NavigationItem(route: '/admin/payments',
      icon: Icons.credit_card_outlined,
      label: 'Payments'),
    NavigationItem(route: '/admin/stock',
      icon: Icons.trending_up, 
      label: 'Stock Movement'),
    NavigationItem(route: '/admin/deliveries',
      icon: Icons.local_shipping_outlined, 
      label: 'Deliveries'),
    NavigationItem(route: '/admin/reports',
      icon: Icons.bar_chart_outlined, 
      label: 'Reports'),
    NavigationItem(route: '/admin/users',
      icon: Icons.shield_outlined, 
      label: 'User Accounts'),
    NavigationItem(route: '/admin/settings',
      icon: Icons.settings_outlined, 
      label: 'Settings'),
  ];

  void _toggle() {
    setState(() => _sidebarExpanded = !_sidebarExpanded);
  }

  void _navigate(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Logout',
          style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827))),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 13,
            color: Color(0xFF6B7280))),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.instance.logout();
              if (mounted) {
                Navigator.of(context)
                  .pushNamedAndRemoveUntil(
                    '/login', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                  BorderRadius.circular(8))),
            child: const Text('Logout')),
        ],
      ),
    );
  }

  bool get _isMobile =>
    MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    if (_isMobile) return _buildMobile();
    return _buildDesktop();
  }

  // ─── DESKTOP ───────────────────────────────────

  Widget _buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar + hamburger as a Stack
          SizedBox(
            width: _sidebarExpanded ? 256 : 64,
            child: Stack(
              children: [
                // 1. Sidebar background (bottom)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: _sidebarExpanded ? 256 : 64,
                  color: const Color(0xFF1E1E1E),
                  child: Column(
                    children: [
                      // Header space (72px) - hamburger floats over this
                      const SizedBox(height: 72),
                      const Divider(
                        color: Color(0xFF2A2A2A), height: 1),
                      Expanded(child: _buildNavItems()),
                      const Divider(
                        color: Color(0xFF2A2A2A), height: 1),
                      _buildLogout(),
                    ],
                  ),
                ),
                // 2. Logo/text (middle, only when expanded)
                if (_sidebarExpanded)
                  Positioned(
                    top: 0,
                    left: 52,  // after hamburger
                    right: 0,
                    height: 72,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo/vm_logo.png',
                            width: 28, height: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                                MainAxisAlignment.center,
                              crossAxisAlignment:
                                CrossAxisAlignment.start,
                              children: [
                                const Text('Villahermosa',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                      FontWeight.bold,
                                    color: Colors.white),
                                  overflow:
                                    TextOverflow.ellipsis),
                                const Text('Marketing Admin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                      Color(0xFF8A8A8A)),
                                  overflow:
                                    TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // 3. Hamburger LAST (always on top)
                Positioned(
                  top: 16,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.menu,
                      color: Colors.white, size: 22),
                    onPressed: _toggle,
                    tooltip: _sidebarExpanded
                      ? 'Collapse sidebar'
                      : 'Expand sidebar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF4F4F4),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    return ListView(
      padding: EdgeInsets.zero,
      children: _navItems.map((item) {
        final active = widget.selectedRoute == item.route;
        return _buildNavItem(item, active);
      }).toList(),
    );
  }

  Widget _buildNavItem(NavigationItem item, bool active) {
    final color = active
      ? Colors.white
      : const Color(0xFF8A8A8A);

    if (_sidebarExpanded) {
      return InkWell(
        onTap: () => _navigate(item.route),
        hoverColor: const Color(0xFF252525),
        child: Container(
          height: 48,
          color: active
            ? const Color(0xFF2A2A2A)
            : Colors.transparent,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                  style: TextStyle(
                    fontSize: 14, color: color),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    } else {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: InkWell(
          onTap: () => _navigate(item.route),
          child: Container(
            height: 48,
            color: active
              ? const Color(0xFF2A2A2A)
              : Colors.transparent,
            child: Center(
              child: Icon(item.icon,
                size: 22, color: color),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLogout() {
    if (_sidebarExpanded) {
      return InkWell(
        onTap: _logout,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.logout_outlined,
                size: 20, color: Color(0xFF8A8A8A)),
              const SizedBox(width: 12),
              const Text('Logout',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A8A))),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    } else {
      return Tooltip(
        message: 'Logout',
        child: InkWell(
          onTap: _logout,
          child: const SizedBox(
            height: 56,
            child: Center(
              child: Icon(Icons.logout_outlined,
                size: 22,
                color: Color(0xFF8A8A8A)),
            ),
          ),
        ),
      );
    }
  }

  // ─── MOBILE ────────────────────────────────────

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: VillahermosaColors.contentBg,
      appBar: AppBar(
        backgroundColor: VillahermosaColors.cardBg,
        elevation: 1,
        title: const Text('Villahermosa',
          style: TextStyle(
            fontSize:16,
            fontWeight: FontWeight.w600,
            color: VillahermosaColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu,
              color: VillahermosaColors.textPrimary),
            onPressed: _showMobileMenu,
            tooltip: 'Navigation menu',
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  Widget _buildMobileBottomNav() {
    final items = _navItems.take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: VillahermosaColors.cardBg,
        border: Border(
          top: BorderSide(
            color: VillahermosaColors.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            ...items.map((item) {
              final active =
                widget.selectedRoute == item.route;
              return Expanded(
                child: InkWell(
                  onTap: () => _navigate(item.route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 24,
                          color: active
                            ? VillahermosaColors.textPrimary
                            : VillahermosaColors
                              .textSecondary),
                        const SizedBox(height: 2),
                        Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                              ? VillahermosaColors.textPrimary
                              : VillahermosaColors
                                .textSecondary),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: InkWell(
                onTap: _showMobileMenu,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz, size: 24,
                        color: VillahermosaColors.textSecondary),
                      const SizedBox(height: 2),
                      Text('More',
                        style: TextStyle(
                          fontSize: 10,
                          color: VillahermosaColors.textSecondary),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Navigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            ..._navItems.map((item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                Navigator.pop(context);
                _navigate(item.route);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  const NavigationItem({
    required this.route,
    required this.icon,
    required this.label,
  });
  final String route;
  final IconData icon;
  final String label;
}
