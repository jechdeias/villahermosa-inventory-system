import 'package:flutter/material.dart';
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
    Navigator.pushReplacementNamed(context, '/login');
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
          _buildSidebar(),
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

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 256 : 64,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const Divider(
            color: Color(0xFF2A2A2A), height: 1),
          Expanded(child: _buildNavItems()),
          const Divider(
            color: Color(0xFF2A2A2A), height: 1),
          _buildLogout(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return SizedBox(
      height: 72,
      child: _sidebarExpanded
        ? Padding(
            padding: const EdgeInsets.only(
              left: 12, right: 4),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo/vm_logo.png',
                  width: 32, height: 32),
                const SizedBox(width: 10),
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
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                      const Text('Marketing Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A8A)),
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu,
                    color: Colors.white, size: 20),
                  onPressed: _toggle,
                  tooltip: 'Collapse',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          )
        : Center(
            child: IconButton(
              icon: const Icon(Icons.menu,
                color: Colors.white, size: 22),
              onPressed: _toggle,
              tooltip: 'Expand',
            ),
          ),
    );
  }

  Widget _buildNavItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                  style: TextStyle(
                    fontSize: 14, color: color),
                  overflow: TextOverflow.ellipsis),
              ),
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
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: 12),
          child: Row(
            children: const [
              Icon(Icons.logout_outlined,
                size: 20, color: Color(0xFF8A8A8A)),
              SizedBox(width: 12),
              Text('Logout',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A8A))),
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
      ),
      body: widget.child,
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  Widget _buildMobileBottomNav() {
    final items = _navItems.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: VillahermosaColors.cardBg,
        border: Border(
          top: BorderSide(
            color: VillahermosaColors.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: items.map((item) {
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
          }).toList(),
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
