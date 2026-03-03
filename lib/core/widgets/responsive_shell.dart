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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation items configuration
  List<NavigationItem> get navItems => widget.navItems ?? _defaultNavItems;
  
  static const List<NavigationItem> _defaultNavItems = [
    NavigationItem(
      route: '/admin/dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
    NavigationItem(
      route: '/admin/orders',
      icon: Icons.shopping_cart_outlined,
      label: 'Orders',
    ),
    NavigationItem(
      route: '/admin/customers',
      icon: Icons.store_outlined,
      label: 'Customers & Stores',
    ),
    NavigationItem(
      route: '/admin/inventory',
      icon: Icons.inventory_2_outlined,
      label: 'Inventory',
    ),
    NavigationItem(
      route: '/admin/payments',
      icon: Icons.credit_card_outlined,
      label: 'Payments',
    ),
    NavigationItem(
      route: '/admin/sales-reps',
      icon: Icons.people_outlined,
      label: 'Sales Representatives',
    ),
    NavigationItem(
      route: '/admin/delivery',
      icon: Icons.local_shipping_outlined,
      label: 'Routes & Delivery',
    ),
    NavigationItem(
      route: '/admin/reports',
      icon: Icons.bar_chart_outlined,
      label: 'Reports & Analytics',
    ),
    NavigationItem(
      route: '/admin/users',
      icon: Icons.shield_outlined,
      label: 'User Accounts',
    ),
    NavigationItem(
      route: '/admin/settings',
      icon: Icons.settings_outlined,
      label: 'System Settings',
    ),
    NavigationItem(
      route: '/admin/sync',
      icon: Icons.sync_outlined,
      label: 'Sync Status',
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

  String _getLastSyncTime() {
    if (widget.syncManager == null) return 'Never';
    
    final lastSync = widget.syncManager.lastSyncTime;
    if (lastSync == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
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
          // Desktop Sidebar
          Container(
            width: 256,
            height: double.infinity,
            decoration: BoxDecoration(
              color: VillahermosaColors.sidebarDark,
              border: Border(
                right: BorderSide(
                  color: VillahermosaColors.sidebarDarkHover,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: VillahermosaColors.sidebarDarkHover,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Logo placeholder
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: VillahermosaColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'V',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: VillahermosaColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Villahermosa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: VillahermosaColors.cardBg,
                              ),
                            ),
                            Text(
                              'Marketing Admin',
                              style: TextStyle(
                                fontSize: 12,
                                color: VillahermosaColors.textSecondary,
                              ),
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
                    padding: EdgeInsets.zero,
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isActive = widget.selectedRoute == item.route;
                      
                      return _buildDesktopNavItem(item, isActive);
                    },
                  ),
                ),
                // Warehouse Footer (only for warehouse nav)
                if (widget.syncManager != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last sync: ${_getLastSyncTime()}',
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Logout Button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
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
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 256),
              decoration: BoxDecoration(
                color: VillahermosaColors.contentBg,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
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

  Widget _buildDesktopNavItem(NavigationItem item, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? VillahermosaColors.sidebarDarkHover : Colors.transparent,
        border: isActive
            ? Border(
                left: BorderSide(
                  color: VillahermosaColors.cardBg,
                  width: 2,
                ),
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          size: 20,
          color: isActive ? VillahermosaColors.cardBg : VillahermosaColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? VillahermosaColors.cardBg : VillahermosaColors.textSecondary,
          ),
        ),
        onTap: () => _navigateToRoute(item.route),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
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
