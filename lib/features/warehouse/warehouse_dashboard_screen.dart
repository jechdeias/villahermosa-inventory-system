import 'package:flutter/material.dart';
import '../../shared/theme/warehouse_theme.dart';

class WarehouseDashboardScreen extends StatefulWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  State<WarehouseDashboardScreen> createState() => _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState extends State<WarehouseDashboardScreen> {
  int _selectedIndex = 0;
  
  // Real data from Villahermosa Marketing system
  final int _totalProducts = 325; // From our product list
  final int _totalCustomers = 405; // From our customer list  
  final int _lowStockAlerts = 3; // Super Tibay products
  final int _activeRoutes = 6; // Boac, Buenavista, Gasan, Sta. Cruz, Torrijos + Central
  
  @override
  Widget build(BuildContext context) => Theme(
      data: WarehouseTheme.theme,
      child: Scaffold(
        backgroundColor: WarehouseTheme.lightBackground,
        body: Row(
          children: [
            // Dark Sidebar Navigation
            Container(
              width: 280,
              height: double.infinity,
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
                    padding: const EdgeInsets.all(24),
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
                        WarehouseTheme.sidebarItem(
                          icon: Icons.dashboard,
                          label: 'Dashboard',
                          isSelected: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.inbox,
                          label: 'Incoming Orders',
                          isSelected: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.inventory,
                          label: 'Prepare Orders',
                          isSelected: _selectedIndex == 2,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.inventory_2,
                          label: 'Inventory Stock',
                          isSelected: _selectedIndex == 3,
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.swap_vert,
                          label: 'Stock In/Out',
                          isSelected: _selectedIndex == 4,
                          onTap: () => setState(() => _selectedIndex = 4),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.local_shipping,
                          label: 'Loading & Dispatch',
                          isSelected: _selectedIndex == 5,
                          onTap: () => setState(() => _selectedIndex = 5),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.route,
                          label: 'Routes Today',
                          isSelected: _selectedIndex == 6,
                          onTap: () => setState(() => _selectedIndex = 6),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.assignment_return,
                          label: 'Returns & Damaged',
                          isSelected: _selectedIndex == 7,
                          onTap: () => setState(() => _selectedIndex = 7),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.analytics,
                          label: 'Warehouse Reports',
                          isSelected: _selectedIndex == 8,
                          onTap: () => setState(() => _selectedIndex = 8),
                        ),
                        WarehouseTheme.sidebarItem(
                          icon: Icons.sync,
                          label: 'Sync Status',
                          isSelected: _selectedIndex == 9,
                          onTap: () => setState(() => _selectedIndex = 9),
                        ),
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
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
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
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: SizedBox(
                height: double.infinity,
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildIncomingOrdersContent();
      case 2:
        return _buildPrepareOrdersContent();
      case 3:
        return _buildInventoryStockContent();
      case 4:
        return _buildStockInOutContent();
      case 5:
        return _buildLoadingDispatchContent();
      case 6:
        return _buildRoutesTodayContent();
      case 7:
        return _buildReturnsDamagedContent();
      case 8:
        return _buildReportsContent();
      case 9:
        return _buildSyncStatusContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() => Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            const Text(
              'Villahermosa Marketing Overview',
              style: WarehouseTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                WarehouseTheme.summaryCard(
                  title: 'Total Products',
                  value: '$_totalProducts',
                  icon: Icons.inventory_2,
                  color: WarehouseTheme.info,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                WarehouseTheme.summaryCard(
                  title: 'Total Customers',
                  value: '$_totalCustomers',
                  icon: Icons.people,
                  color: WarehouseTheme.success,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                WarehouseTheme.summaryCard(
                  title: 'Low Stock Alerts',
                  value: '$_lowStockAlerts',
                  icon: Icons.warning,
                  color: WarehouseTheme.error,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                WarehouseTheme.summaryCard(
                  title: 'Active Routes',
                  value: '$_activeRoutes',
                  icon: Icons.route,
                  color: WarehouseTheme.warning,
                  onTap: () => setState(() => _selectedIndex = 6),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Recent Activity
            const Text(
              'Recent Activity',
              style: WarehouseTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildActivityItem(
                    'Product Added',
                    'Super Tibay 2in1 Economy Size',
                    '2 minutes ago',
                    Icons.add_shopping_cart,
                    WarehouseTheme.info,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    'Low Stock Alert',
                    'Super Tibay Trial Size - 3 units remaining',
                    '15 minutes ago',
                    Icons.warning,
                    WarehouseTheme.warning,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    'Customer Added',
                    'Kathlyn Joy Sienna - Bagtingon',
                    '1 hour ago',
                    Icons.person_add,
                    WarehouseTheme.success,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    'Product Updated',
                    'RC Cola Drink 240ml - Stock adjusted',
                    '2 hours ago',
                    Icons.edit,
                    WarehouseTheme.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) => ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: WarehouseTheme.bodyMedium),
      subtitle: Text(description, style: WarehouseTheme.bodySmall),
      trailing: Text(time, style: WarehouseTheme.caption),
      contentPadding: const EdgeInsets.all(16),
    );

  // Placeholder content for other screens
  Widget _buildIncomingOrdersContent() => Scaffold(
      appBar: AppBar(title: const Text('Incoming Orders')),
      body: const Center(
        child: Text(
          'Incoming Orders Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildPrepareOrdersContent() => Scaffold(
      appBar: AppBar(title: const Text('Prepare Orders')),
      body: const Center(
        child: Text(
          'Prepare Orders Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildInventoryStockContent() => Scaffold(
      appBar: AppBar(title: const Text('Inventory Stock')),
      body: const Center(
        child: Text(
          'Inventory Stock Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildStockInOutContent() => Scaffold(
      appBar: AppBar(title: const Text('Stock In/Out')),
      body: const Center(
        child: Text(
          'Stock In/Out Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildLoadingDispatchContent() => Scaffold(
      appBar: AppBar(title: const Text('Loading & Dispatch')),
      body: const Center(
        child: Text(
          'Loading & Dispatch Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildRoutesTodayContent() => Scaffold(
      appBar: AppBar(title: const Text('Routes Today')),
      body: const Center(
        child: Text(
          'Routes Today Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildReturnsDamagedContent() => Scaffold(
      appBar: AppBar(title: const Text('Returns & Damaged Goods')),
      body: const Center(
        child: Text(
          'Returns & Damaged Goods Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildReportsContent() => Scaffold(
      appBar: AppBar(title: const Text('Warehouse Reports')),
      body: const Center(
        child: Text(
          'Warehouse Reports Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );

  Widget _buildSyncStatusContent() => Scaffold(
      appBar: AppBar(title: const Text('Sync Status & Activity Logs')),
      body: const Center(
        child: Text(
          'Sync Status & Activity Logs Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
}
