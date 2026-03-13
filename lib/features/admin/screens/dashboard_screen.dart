import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/dashboard',
      child: AdminDashboardView(database: database, syncManager: syncManager),
    );
  }
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late Future<int> _totalUsersFuture;
  late Future<int> _activeUsersFuture;
  late Future<int> _totalProductsFuture;
  late Future<int> _lowStockCountFuture;
  late Future<int> _totalOrdersFuture;
  late Future<int> _pendingOrdersCountFuture;
  late Future<int> _totalDeliveriesFuture;
  late Future<int> _inTransitCountFuture;
  late Future<List<Map<String, dynamic>>> _recentActivityFuture;
  late Future<List<Map<String, dynamic>>> _monthlySalesFuture;
  late Future<Map<String, int>> _ordersByStatusFuture;
  late Future<Map<String, int>> _stockByCategoryFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _totalUsersFuture = _getTotalUsers();
      _activeUsersFuture = _getActiveUsers();
      _totalProductsFuture = _getTotalProducts();
      _lowStockCountFuture = _getLowStockCount();
      _totalOrdersFuture = _getTotalOrders();
      _pendingOrdersCountFuture = _getPendingOrdersCount();
      _totalDeliveriesFuture = _getTotalDeliveries();
      _inTransitCountFuture = _getInTransitCount();
      _recentActivityFuture = _getRecentActivity();
      _monthlySalesFuture = _getMonthlySales();
      _ordersByStatusFuture = _getOrdersByStatus();
      _stockByCategoryFuture = _getStockByCategory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4), // #F4F4F4 background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            _buildHeader(),
            const SizedBox(height: 32),
            
            // Stat Cards Row
            _buildStatCardsRow(),
            const SizedBox(height: 32),
            
            // Recent Activity + Quick Actions Row
            SizedBox(
              height: 420,
              child: _buildActivityAndActionsRow(),
            ),
            const SizedBox(height: 32),
            
            // Charts Row
            SizedBox(
              height: 280,
              child: _buildChartsRow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'System overview and analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Last 30 days',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _performRefresh,
              icon: const Icon(Icons.refresh, color: Colors.black87),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCardsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Users', Icons.people_outline, _totalUsersFuture, _activeUsersFuture, 'Active accounts')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Products', Icons.inventory_2_outlined, _totalProductsFuture, _lowStockCountFuture, 'Low stock')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Orders', Icons.shopping_cart_outlined, _totalOrdersFuture, _pendingOrdersCountFuture, 'This month')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Deliveries', Icons.local_shipping_outlined, _totalDeliveriesFuture, _inTransitCountFuture, 'In transit')),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, Future<int> countFuture, Future<int> subCountFuture, String subLabel) {
    return Container(
      height: 140, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 20, color: Colors.grey[700]),
              ),
            ],
          ),
          const Spacer(),
          FutureBuilder<int>(
            future: countFuture,
            builder: (context, snapshot) {
              return Text(
                snapshot.data?.toString() ?? '--',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              FutureBuilder<int>(
                future: subCountFuture,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data?.toString() ?? '--',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityAndActionsRow() {
    return Row(
      children: [
        // Recent Activity Panel (70%)
        Expanded(
          flex: 7,
          child: _buildRecentActivityPanel(),
        ),
        const SizedBox(width: 16),
        // Quick Actions Panel (30%)
        Expanded(
          flex: 3,
          child: _buildQuickActionsPanel(),
        ),
      ],
    );
  }

  Widget _buildRecentActivityPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All >'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _recentActivityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              
              final activities = snapshot.data!;
              return _buildActivityTable(activities);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTable(List<Map<String, dynamic>> activities) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B6B6B)))),
              Expanded(flex: 2, child: Text('USER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B6B6B)))),
              Expanded(flex: 2, child: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B6B6B)))),
              Expanded(flex: 3, child: Text('DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B6B6B)))),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        // Table Rows
        ...activities.map((activity) => _buildActivityRow(activity)).toList(),
      ],
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> activity) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(activity['time'] ?? '', style: const TextStyle(fontSize: 12))),
              Expanded(flex: 2, child: Text(activity['user'] ?? '', style: const TextStyle(fontSize: 12))),
              Expanded(flex: 2, child: Text(activity['action'] ?? '', style: const TextStyle(fontSize: 12))),
              Expanded(flex: 3, child: Text(activity['details'] ?? '', style: const TextStyle(fontSize: 12))),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  Widget _buildQuickActionsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _buildActionButton(Icons.person_add_outlined, 'Create User', () => _navigateTo('/admin/users')),
                _buildActionButton(Icons.add_box_outlined, 'Add Product', () => _navigateTo('/admin/inventory')),
                _buildActionButton(Icons.description_outlined, 'Generate Report', () => _navigateTo('/admin/reports')),
                _buildActionButton(Icons.list_alt_outlined, 'View Orders', () => _navigateTo('/admin/orders')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    return Row(
      children: [
        Expanded(child: _buildSalesTrendChart()),
        const SizedBox(width: 16),
        Expanded(child: _buildOrdersByStatusChart()),
        const SizedBox(width: 16),
        Expanded(child: _buildStockLevelsChart()),
      ],
    );
  }

  Widget _buildSalesTrendChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _monthlySalesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data ?? [];
                return _buildLineChart(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20000,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₱${(value / 1000).toInt()}k',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), (entry.value['sales'] ?? 0).toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.black,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.black,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 80000,
      ),
    );
  }

  Widget _buildOrdersByStatusChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders by Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<Map<String, int>>(
              future: _ordersByStatusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data ?? {};
                return _buildDonutChart(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, int> data) {
    final sections = <PieChartSectionData>[];
    final colors = {
      'Pending': const Color(0xFF9E9E9E),
      'Processing': const Color(0xFF616161),
      'Delivered': const Color(0xFF212121),
      'Cancelled': const Color(0xFFBDBDBD),
    };
    
    data.forEach((status, count) {
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '',
            color: colors[status] ?? Colors.grey,
            radius: 40,
          ),
        );
      }
    });

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Column(
          children: data.entries.map((entry) {
            final color = colors[entry.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key} (${entry.value})',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockLevelsChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Levels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<Map<String, int>>(
              future: _stockByCategoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data ?? {};
                return _buildBarChart(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
              reservedSize: 30,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final categories = data.keys.toList();
                if (value.toInt() >= 0 && value.toInt() < categories.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      categories[value.toInt()],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.entries.map((entry) {
          return BarChartGroupData(
            x: data.keys.toList().indexOf(entry.key),
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: const Color(0xFF212121),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        minY: 0,
        maxY: 600,
      ),
    );
  }

  void _navigateTo(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _performRefresh() async {
    try {
      await widget.syncManager.performFullSync();
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Data Query Methods
  Future<int> _getTotalUsers() async {
    final result = await widget.database.customSelect('SELECT COUNT(*) as count FROM users WHERE is_deleted = 0').getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getActiveUsers() async {
    final result = await widget.database.customSelect('SELECT COUNT(*) as count FROM users WHERE is_deleted = 0 AND is_active = 1').getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getTotalProducts() async {
    final result = await widget.database.customSelect('SELECT COUNT(*) as count FROM products WHERE is_deleted = 0').getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getLowStockCount() async {
    final result = await widget.database.customSelect('SELECT COUNT(*) as count FROM products WHERE is_deleted = 0 AND stock < reorder_level').getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getTotalOrders() async {
    final result = await widget.database.customSelect('SELECT COUNT(*) as count FROM orders WHERE is_deleted = 0').getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getPendingOrdersCount() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final result = await widget.database.customSelect(
      "SELECT COUNT(*) as count FROM orders WHERE status = 'pending' AND is_deleted = 0 AND created_at >= ?",
      variables: [drift.Variable.withDateTime(firstDayOfMonth)],
    ).getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getTotalDeliveries() async {
    final result = await widget.database.customSelect('SELECT COUNT(*) as count FROM deliveries WHERE is_deleted = 0').getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<int> _getInTransitCount() async {
    final result = await widget.database.customSelect("SELECT COUNT(*) as count FROM deliveries WHERE status = 'in_transit' AND is_deleted = 0").getSingle();
    return result.read<int>('count') ?? 0;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    final result = await widget.database.customSelect('''
      SELECT 
        sm.created_at,
        u.first_name || ' ' || u.last_name as user_name,
        sm.movement_type,
        sm.quantity,
        sm.reference
      FROM stock_movements sm
      LEFT JOIN users u ON sm.user_id = u.id
      ORDER BY sm.created_at DESC
      LIMIT 10
    ''').get();
    
    return result.map((row) {
      final createdAt = row.read<DateTime>('created_at') ?? DateTime.now();
      return {
        'time': _formatRelativeTime(createdAt),
        'user': row.read<String>('user_name') ?? 'Unknown',
        'action': row.read<String>('movement_type').toUpperCase(),
        'details': 'Qty: ${row.read<int>('quantity')} | Ref: ${row.read<String>('reference')}',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getMonthlySales() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    
    final result = await widget.database.customSelect('''
      SELECT 
        strftime('%m', created_at) as month,
        COALESCE(SUM(total_amount), 0) as sales
      FROM orders 
      WHERE created_at >= ? AND is_deleted = 0
      GROUP BY strftime('%m', created_at)
      ORDER BY month
    ''', variables: [drift.Variable.withDateTime(sixMonthsAgo)]).get();
    
    // Fill missing months with 0
    final monthlyData = <Map<String, dynamic>>[];
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      final monthStr = month.month.toString().padLeft(2, '0');
      final foundMonth = result.where((row) => row.read<String>('month') == monthStr).toList();
      final sales = foundMonth.isNotEmpty ? foundMonth.first.read<double>('sales') ?? 0 : 0;
      monthlyData.add({'sales': sales});
    }
    
    return monthlyData;
  }

  Future<Map<String, int>> _getOrdersByStatus() async {
    final result = await widget.database.customSelect('''
      SELECT status, COUNT(*) as count
      FROM orders 
      WHERE is_deleted = 0
      GROUP BY status
    ''').get();
    
    return {
      for (final row in result)
        row.read<String>('status'): row.read<int>('count'),
    };
  }

  Future<Map<String, int>> _getStockByCategory() async {
    final result = await widget.database.customSelect('''
      SELECT category, SUM(stock) as total_stock
      FROM products 
      WHERE is_deleted = 0
      GROUP BY category
      ORDER BY total_stock DESC
      LIMIT 5
    ''').get();
    
    return {
      for (final row in result)
        row.read<String>('category'): row.read<int>('total_stock'),
    };
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} sec ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
