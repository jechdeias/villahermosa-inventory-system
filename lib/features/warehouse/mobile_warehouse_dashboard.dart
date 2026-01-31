import 'package:flutter/material.dart';

class MobileWarehouseDashboard extends StatefulWidget {
  const MobileWarehouseDashboard({super.key});

  @override
  State<MobileWarehouseDashboard> createState() => _MobileWarehouseDashboardState();
}

class _MobileWarehouseDashboardState extends State<MobileWarehouseDashboard> {
  int _selectedIndex = 0;
  
  // Real data from Villahermosa Marketing system
  final int _totalProducts = 325;
  final int _totalCustomers = 405;
  final int _lowStockAlerts = 3;
  final int _activeRoutes = 6;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Villahermosa Warehouse'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Villahermosa Marketing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Warehouse Overview',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Summary Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildMetricCard(
                  'Total Products',
                  '$_totalProducts',
                  Icons.inventory_2,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Total Customers',
                  '$_totalCustomers',
                  Icons.people,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Low Stock',
                  '$_lowStockAlerts',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Active Routes',
                  '$_activeRoutes',
                  Icons.route,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildActivityItem(
                    'Product Added',
                    'Super Tibay 2in1 Economy Size',
                    '2 minutes ago',
                    Icons.add_shopping_cart,
                    Colors.blue,
                  ),
                  const Divider(height: 1),
                  _buildActivityItem(
                    'Low Stock Alert',
                    'Super Tibay Trial Size - 3 units remaining',
                    '15 minutes ago',
                    Icons.warning,
                    Colors.orange,
                  ),
                  const Divider(height: 1),
                  _buildActivityItem(
                    'Customer Added',
                    'Kathlyn Joy Sienna - Bagtingon',
                    '1 hour ago',
                    Icons.person_add,
                    Colors.green,
                  ),
                  const Divider(height: 1),
                  _buildActivityItem(
                    'Product Updated',
                    'RC Cola Drink 240ml - Stock adjusted',
                    '2 hours ago',
                    Icons.edit,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) => Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
}
