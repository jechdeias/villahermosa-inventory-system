import 'package:flutter/material.dart';

import '../../shared/theme/tablet_warehouse_theme.dart';
import '../../shared/theme/warehouse_theme.dart';

class TabletWarehouseDashboard extends StatefulWidget {
  const TabletWarehouseDashboard({super.key});

  @override
  State<TabletWarehouseDashboard> createState() => _TabletWarehouseDashboardState();
}

class _TabletWarehouseDashboardState extends State<TabletWarehouseDashboard> {
  int _selectedIndex = 0;
  
  // Real data from Villahermosa Marketing system
  final int _totalProducts = 325;
  final int _totalCustomers = 405;
  final int _lowStockAlerts = 3;
  final int _activeRoutes = 6;

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Warehouse Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('Manage alert preferences'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                _showNotificationsSheet(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFE94560)),
              title: const Text('Logout',
                  style: TextStyle(color: Color(0xFFE94560))),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _notifTile(Icons.warning_amber_rounded, const Color(0xFFF59E0B),
                'Low stock: $_lowStockAlerts items', 'Super Tibay products below threshold'),
            _notifTile(Icons.local_shipping_outlined, const Color(0xFF3B82F6),
                '$_activeRoutes routes active today', 'All routes dispatched on schedule'),
            _notifTile(Icons.inventory_2_outlined, const Color(0xFF10B981),
                'Inventory count up to date', '$_totalProducts products tracked'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(IconData icon, Color color, String title, String sub) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        )),
      ]),
    );

  @override
  Widget build(BuildContext context) => TabletWarehouseTheme.responsiveLayout(
      context: context,
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );

  Widget _buildMobileLayout() => Scaffold(
      backgroundColor: WarehouseTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Villahermosa Warehouse'),
        backgroundColor: WarehouseTheme.darkSidebar,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: WarehouseTheme.darkSidebar,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Orders',
          ),
        ],
      ),
    );

  Widget _buildTabletLayout() => Scaffold(
      backgroundColor: WarehouseTheme.lightBackground,
      body: Row(
        children: [
          // Tablet Sidebar
          Container(
            width: TabletWarehouseTheme.getSidebarWidth(context),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WarehouseTheme.darkSidebar,
                  WarehouseTheme.darkSidebarVariant,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo/Title
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warehouse,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Warehouse System',
                        style: WarehouseTheme.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Villahermosa Marketing',
                        style: WarehouseTheme.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                      _buildNavItem(Icons.inbox, 'Incoming Orders', 1),
                      _buildNavItem(Icons.inventory, 'Prepare Orders', 2),
                      _buildNavItem(Icons.inventory_2, 'Inventory Stock', 3),
                      _buildNavItem(Icons.swap_vert, 'Stock In/Out', 4),
                      _buildNavItem(Icons.local_shipping, 'Loading & Dispatch', 5),
                      _buildNavItem(Icons.route, 'Routes Today', 6),
                      _buildNavItem(Icons.assignment_return, 'Returns & Damaged', 7),
                      _buildNavItem(Icons.analytics, 'Warehouse Reports', 8),
                      _buildNavItem(Icons.sync, 'Sync Status', 9),
                    ],
                  ),
                ),
                
                // User Profile
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warehouse Staff',
                              style: WarehouseTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Active',
                              style: WarehouseTheme.caption.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(builder: (ctx) => IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => _showSettingsDialog(ctx),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );

  Widget _buildDesktopLayout() {
    return _buildTabletLayout(); // Same as tablet for now
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? WarehouseTheme.darkSidebarVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 20,
        ),
        title: Text(
          label,
          style: WarehouseTheme.bodyMedium.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildMainContent() => Scaffold(
      backgroundColor: WarehouseTheme.lightBackground,
      appBar: TabletWarehouseTheme.tabletAppBar(
        context: context,
        title: 'Villahermosa Marketing Overview',
        actions: [
          Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Refresh',
          )),
          Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationsSheet(ctx),
            tooltip: 'Notifications',
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: TabletWarehouseTheme.getContentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards - Responsive Grid
            _buildSummaryCards(),
            const SizedBox(height: 32),
            
            // Recent Activity
            const Text(
              'Recent Activity',
              style: WarehouseTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );

  Widget _buildSummaryCards() => TabletWarehouseTheme.responsiveGrid(
      context: context,
      children: [
        TabletWarehouseTheme.tabletCard(
          context: context,
          title: 'Total Products',
          value: '$_totalProducts',
          icon: Icons.inventory_2,
          color: WarehouseTheme.info,
          onTap: () => setState(() => _selectedIndex = 3),
          subtitle: 'Active inventory',
        ),
        TabletWarehouseTheme.tabletCard(
          context: context,
          title: 'Total Customers',
          value: '$_totalCustomers',
          icon: Icons.people,
          color: WarehouseTheme.success,
          onTap: () => setState(() => _selectedIndex = 3),
          subtitle: 'Registered accounts',
        ),
        TabletWarehouseTheme.tabletCard(
          context: context,
          title: 'Low Stock Alerts',
          value: '$_lowStockAlerts',
          icon: Icons.warning,
          color: WarehouseTheme.error,
          onTap: () => setState(() => _selectedIndex = 3),
          subtitle: 'Needs restock',
        ),
        TabletWarehouseTheme.tabletCard(
          context: context,
          title: 'Active Routes',
          value: '$_activeRoutes',
          icon: Icons.route,
          color: WarehouseTheme.warning,
          onTap: () => setState(() => _selectedIndex = 6),
          subtitle: 'Delivery routes',
        ),
      ],
    );

  Widget _buildRecentActivity() => Card(
      child: Column(
        children: [
          TabletWarehouseTheme.tabletListTile(
            context: context,
            title: 'Product Added',
            subtitle: 'Super Tibay 2in1 Economy Size',
            leadingIcon: Icons.add_shopping_cart,
            trailingIcon: Icons.arrow_forward_ios,
            onTap: () {},
            iconColor: WarehouseTheme.info,
          ),
          const Divider(),
          TabletWarehouseTheme.tabletListTile(
            context: context,
            title: 'Low Stock Alert',
            subtitle: 'Super Tibay Trial Size - 3 units remaining',
            leadingIcon: Icons.warning,
            trailingIcon: Icons.arrow_forward_ios,
            onTap: () {},
            iconColor: WarehouseTheme.warning,
          ),
          const Divider(),
          TabletWarehouseTheme.tabletListTile(
            context: context,
            title: 'Customer Added',
            subtitle: 'Kathlyn Joy Sienna - Bagtingon',
            leadingIcon: Icons.person_add,
            trailingIcon: Icons.arrow_forward_ios,
            onTap: () {},
            iconColor: WarehouseTheme.success,
          ),
          const Divider(),
          TabletWarehouseTheme.tabletListTile(
            context: context,
            title: 'Product Updated',
            subtitle: 'RC Cola Drink 240ml - Stock adjusted',
            leadingIcon: Icons.edit,
            trailingIcon: Icons.arrow_forward_ios,
            onTap: () {},
            iconColor: WarehouseTheme.success,
          ),
        ],
      ),
    );
}
