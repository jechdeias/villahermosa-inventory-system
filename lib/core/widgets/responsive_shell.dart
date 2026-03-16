import 'package:flutter/material.dart';
import '../theme/villahermosa_theme.dart';

/// Responsive navigation shell for admin interface
/// Adapts between desktop sidebar and mobile bottom navigation
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
  final dynamic database; // AppDatabase
  final List<NavigationItem>? navItems;
  final dynamic syncManager; // SyncManager

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  static bool _sidebarExpandedGlobal = true; // Persist across route changes
  
  bool get _sidebarExpanded => _sidebarExpandedGlobal;
  
  void _toggleSidebar() {
    setState(() {
      _sidebarExpandedGlobal = !_sidebarExpandedGlobal;
    });
  }
  
  // Navigation items configuration - matching Figma design
  List<NavigationItem> get navItems => widget.navItems ?? _getNavItemsForRole();
  
  List<NavigationItem> _getNavItemsForRole() {
    // Default to admin role - in real implementation, get from auth service
    final userRole = 'admin'; // This should come from auth service
    
    switch (userRole) {
      case 'admin':
        return _adminNavItems;
      case 'warehouse':
        return _warehouseNavItems;
      case 'delivery':
        return _deliveryNavItems;
      case 'customer':
        return _customerNavItems;
      default:
        return _pendingNavItems;
    }
  }

  static const List<NavigationItem> _adminNavItems = [
    NavigationItem(
      route: '/admin/dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
    NavigationItem(
      route: '/admin/products',
      icon: Icons.inventory_2_outlined,
      label: 'Products',
    ),
    NavigationItem(
      route: '/admin/customers',
      icon: Icons.storefront_outlined,
      label: 'Customers',
    ),
    NavigationItem(
      route: '/admin/orders',
      icon: Icons.shopping_cart_outlined,
      label: 'Orders',
    ),
    NavigationItem(
      route: '/admin/stock',
      icon: Icons.trending_up,
      label: 'Stock Movement',
    ),
    NavigationItem(
      route: '/admin/deliveries',
      icon: Icons.local_shipping_outlined,
      label: 'Deliveries',
    ),
    NavigationItem(
      route: '/admin/reports',
      icon: Icons.bar_chart_outlined,
      label: 'Reports',
    ),
    NavigationItem(
      route: '/admin/users',
      icon: Icons.shield_outlined,
      label: 'User Accounts',
    ),
    NavigationItem(
      route: '/admin/settings',
      icon: Icons.settings_outlined,
      label: 'Settings',
    ),
  ];

  static const List<NavigationItem> _warehouseNavItems = [
    NavigationItem(
      route: '/warehouse/dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
    NavigationItem(
      route: '/admin/products',
      icon: Icons.inventory_2_outlined,
      label: 'Products',
    ),
    NavigationItem(
      route: '/admin/stock',
      icon: Icons.trending_up,
      label: 'Stock Movement',
    ),
  ];

  static const List<NavigationItem> _deliveryNavItems = [
    NavigationItem(
      route: '/delivery/dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
    NavigationItem(
      route: '/admin/deliveries',
      icon: Icons.local_shipping_outlined,
      label: 'Deliveries',
    ),
  ];

  static const List<NavigationItem> _customerNavItems = [
    NavigationItem(
      route: '/customer/dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
  ];

  static const List<NavigationItem> _pendingNavItems = [
    NavigationItem(
      route: '/admin/dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  void _navigateToRoute(String route) {
    if (_isMobile(context)) {
      Navigator.pop(context); // Close mobile menu
    }
    Navigator.pushReplacementNamed(context, route);
  }

  String _getRoleLabel() {
    // Default to admin role - in real implementation, get from auth service
    final userRole = 'admin'; // This should come from auth service
    
    switch (userRole) {
      case 'admin':
        return 'Marketing Admin';
      case 'warehouse':
        return 'Warehouse Staff';
      case 'delivery':
        return 'Delivery Personnel';
      case 'customer':
        return 'Customer';
      default:
        return 'Pending Approval';
    }
  }

  void _logout() {
    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Collapsible Desktop Sidebar with OverflowBox clipping
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: _sidebarExpanded ? 256 : 64,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: 256,
                child: SizedBox(
                  width: 256,
                  child: _buildExpandedSidebar(context),
                ),
              ),
            ),
          ),
          // Main Content Area (no top bar)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F4), // Light content background
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSidebar(BuildContext context) {
    return Container(
      height: double.infinity,
      color: const Color(0xFF1E1E1E), // #1E1E1E from Figma
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF2A2A2A), // #2A2A2A divider
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Hamburger FIRST (leftmost, always visible)
                IconButton(
                  icon: const Icon(Icons.menu, 
                    color: Colors.white, size: 20),
                  onPressed: _toggleSidebar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40, minHeight: 40,
                  ),
                  tooltip: _sidebarExpanded ? 'Collapse sidebar' : 'Expand sidebar',
                ),
                const SizedBox(width: 8),
                // Logo
                Image.asset(
                  'assets/images/logo/vm_logo.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 8),
                // Text (gets clipped when collapsed)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Villahermosa',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White text
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        _getRoleLabel(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A8A), // #8A8A8A muted gray
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isActive = widget.selectedRoute == item.route;
                
                return _buildDesktopNavItem(item, isActive);
              },
            ),
          ),
          // Divider before logout
          const Divider(
            color: Color(0xFF2A2A2A), // #2A2A2A divider
            height: 1,
            thickness: 1,
          ),
          // Logout Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_outlined,
                      size: 20,
                      color: const Color(0xFF8A8A8A), // #8A8A8A
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8A8A8A), // #8A8A8A
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(NavigationItem item, bool isActive) {
    return Container(
      height: 48, // Fixed item height from Figma
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToRoute(item.route),
          borderRadius: BorderRadius.circular(6),
          hoverColor: const Color(0xFF252525), // #252525 hover color
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20, // 20px icon size from Figma
                  color: isActive 
                      ? Colors.white // #FFFFFF for active
                      : const Color(0xFF8A8A8A), // #8A8A8A for inactive
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15, // 15px label size from Figma
                      color: isActive 
                          ? Colors.white // #FFFFFF for active
                          : const Color(0xFF8A8A8A), // #8A8A8A for inactive
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: VillahermosaColors.contentBg,
      appBar: AppBar(
        backgroundColor: VillahermosaColors.cardBg,
        elevation: 1,
        title: Row(
          children: [
            // Logo
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: VillahermosaColors.sidebarDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: VillahermosaColors.cardBg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Villahermosa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VillahermosaColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: VillahermosaColors.textPrimary),
            onPressed: () {
              _showMobileMenu();
            },
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  Widget _buildMobileBottomNav() {
    // Show first 5 items in bottom nav
    final primaryItems = navItems.take(5).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: VillahermosaColors.cardBg,
        border: Border(
          top: BorderSide(
            color: VillahermosaColors.borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: primaryItems.map((item) {
            final isActive = widget.selectedRoute == item.route;
            return Expanded(
              child: InkWell(
                onTap: () => _navigateToRoute(item.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isActive 
                            ? VillahermosaColors.textPrimary 
                            : VillahermosaColors.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive 
                              ? VillahermosaColors.textPrimary 
                              : VillahermosaColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VillahermosaColors.sidebarDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Container(
        width: 288,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Navigation Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VillahermosaColors.cardBg,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: VillahermosaColors.cardBg),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...navItems.map((item) {
              final isActive = widget.selectedRoute == item.route;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    item.icon,
                    color: isActive ? VillahermosaColors.cardBg : VillahermosaColors.textSecondary,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? VillahermosaColors.cardBg : VillahermosaColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToRoute(item.route);
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: VillahermosaColors.cardBg),
                  backgroundColor: Colors.transparent,
                  foregroundColor: VillahermosaColors.cardBg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
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
