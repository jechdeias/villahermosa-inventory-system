import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _totalDeliveries = 0;
  int _inTransitDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final users = await widget.database.getAllUsers();
      final activeUsers = users.where((u) => u.isActive && !u.isDeleted).toList();
      
      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _activeUsers = activeUsers.length;
          // For now, set others to 0 until tables exist
          _totalProducts = 0;
          _lowStockCount = 0;
          _totalOrders = 0;
          _pendingOrders = 0;
          _totalDeliveries = 0;
          _inTransitDeliveries = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    try {
      final db = widget.database;
      final activities = <Map<String, dynamic>>[];
      
      // 1. Recent user changes (created or updated in last 7 days)
      final recentUsers = await db.customSelect(
        '''SELECT id, first_name, last_name, created_at, 
           updated_at, 'user_created' as activity_type
           FROM users 
           WHERE created_at >= datetime('now', '-7 days')
           ORDER BY created_at DESC
           LIMIT 5''',
      ).get();
      
      for (final row in recentUsers) {
        activities.add({
          'time': DateTime.parse(row.read<String>('created_at')),
          'user': '${row.read<String>('first_name')} ${row.read<String>('last_name')}',
          'action': 'User Created',
          'details': 'New user account',
          'icon': Icons.person_add_outlined,
          'color': const Color(0xFF065F46), // Success green
        });
      }
      
      // 2. Recent product changes
      final recentProducts = await db.customSelect(
        '''SELECT id, name, created_at, 
           'product_created' as activity_type
           FROM products 
           WHERE created_at >= datetime('now', '-7 days')
           ORDER BY created_at DESC
           LIMIT 5''',
      ).get();
      
      for (final row in recentProducts) {
        activities.add({
          'time': DateTime.parse(row.read<String>('created_at')),
          'user': 'System',
          'action': 'Product Added',
          'details': row.read<String>('name'),
          'icon': Icons.inventory_2_outlined,
          'color': const Color(0xFF1E40AF), // Info blue
        });
      }
      
      // 3. Stock movements (existing)
      final stockMovements = await db.customSelect(
        '''SELECT sm.id, sm.movement_type, sm.quantity, 
           sm.created_at, sm.product_id,
           p.name as product_name,
           u.first_name, u.last_name
           FROM stock_movements sm
           LEFT JOIN products p ON sm.product_id = p.id
           LEFT JOIN users u ON sm.created_by = u.id
           WHERE sm.created_at >= datetime('now', '-7 days')
           ORDER BY sm.created_at DESC
           LIMIT 5''',
      ).get();
      
      for (final row in stockMovements) {
        final movementType = row.read<String>('movement_type');
        final quantity = row.read<int>('quantity');
        final productName = row.read<String?>('product_name') ?? 'Unknown';
        final firstName = row.read<String?>('first_name') ?? 'Unknown';
        final lastName = row.read<String?>('last_name') ?? '';
        
        activities.add({
          'time': DateTime.parse(row.read<String>('created_at')),
          'user': '$firstName $lastName'.trim(),
          'action': movementType,
          'details': '$productName (${quantity.abs()} units)',
          'icon': quantity > 0 
            ? Icons.trending_up 
            : Icons.trending_down,
          'color': quantity > 0 
            ? const Color(0xFF065F46) 
            : const Color(0xFF991B1B),
        });
      }
      
      // 4. Recent orders (if orders table exists)
      try {
        final recentOrders = await db.customSelect(
          '''SELECT id, status, created_at, total_amount
             FROM orders 
             WHERE created_at >= datetime('now', '-7 days')
             ORDER BY created_at DESC
             LIMIT 5''',
        ).get();
        
        for (final row in recentOrders) {
          activities.add({
            'time': DateTime.parse(row.read<String>('created_at')),
            'user': 'System',
            'action': 'Order ${row.read<String>('status')}',
            'details': 'Order #${row.read<int>('id')}',
            'icon': Icons.shopping_cart_outlined,
            'color': const Color(0xFF92400E), // Warning orange
          });
        }
      } catch (e) {
        // Orders table might not exist yet, skip
        debugPrint('Orders query failed: $e');
      }
      
      // Sort all activities by time (most recent first)
      activities.sort((a, b) => 
        b['time'].compareTo(a['time']));
      
      // Return top 10 most recent
      return activities.take(10).toList();
      
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
      return [];
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildActivityAndActions(),
            const SizedBox(height: 24),
            _buildCharts(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    try {
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
                onPressed: _refreshData,
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
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Header Error: $e'),
      );
    }
  }

  Widget _buildStatCards() {
    try {
      return Row(
        children: [
          Expanded(child: _statCard('Users', Icons.people_outline, _totalUsers, '$_activeUsers active')),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Products', Icons.inventory_2_outlined, _totalProducts, 'Low: $_lowStockCount')),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Orders', Icons.shopping_cart_outlined, _totalOrders, 'Pending: $_pendingOrders')),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Deliveries', Icons.local_shipping_outlined, _totalDeliveries, 'Transit: $_inTransitDeliveries')),
        ],
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Stat Cards Error: $e'),
      );
    }
  }

  Widget _statCard(String title, IconData icon, int count, String subLabel) {
    try {
      return Container(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
            Text(
              subLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Stat Card Error: $e'),
      );
    }
  }

  Widget _buildActivityAndActions() {
    try {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Activity Panel (65% width)
          Expanded(
            flex: 65,
            child: _buildRecentActivityPanel(),
          ),
          const SizedBox(width: 16),
          // Quick Actions Panel (35% width)
          Expanded(
            flex: 35,
            child: _buildQuickActionsPanel(),
          ),
        ],
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Activity & Actions Error: $e'),
      );
    }
  }

  Widget _buildRecentActivityPanel() {
    return Container(
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full activity log
                },
                child: const Text('View All >'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRecentActivity(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              
              final activities = snapshot.data!;
              
              return Column(
                children: activities.map((activity) {
                  return _buildActivityRow(
                    time: activity['time'] as DateTime,
                    user: activity['user'] as String,
                    action: activity['action'] as String,
                    details: activity['details'] as String,
                    icon: activity['icon'] as IconData,
                    color: activity['color'] as Color,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({
    required DateTime time,
    required String user,
    required String action,
    required String details,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      action,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Time
          Text(
            _formatRelativeTime(time),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildQuickActionsPanel() {
    try {
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
          mainAxisSize: MainAxisSize.min,
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
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuickActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'Create User',
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
                _buildQuickActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'Add Product',
                  onTap: () => Navigator.pushNamed(context, '/admin/inventory'),
                ),
                _buildQuickActionButton(
                  icon: Icons.description_outlined,
                  label: 'Reports',
                  onTap: () => Navigator.pushNamed(context, '/admin/reports'),
                ),
                _buildQuickActionButton(
                  icon: Icons.list_alt_outlined,
                  label: 'View Orders',
                  onTap: () => Navigator.pushNamed(context, '/admin/orders'),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Quick Actions Error: $e'),
      );
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E1E1E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    try {
      return Row(
        children: [
          Expanded(child: _buildSalesTrendChart()),
          const SizedBox(width: 16),
          Expanded(child: _buildOrdersByStatusChart()),
          const SizedBox(width: 16),
          Expanded(child: _buildStockLevelsChart()),
        ],
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Charts Error: $e'),
      );
    }
  }

  Widget _buildSalesTrendChart() {
    return Container(
      height: 340,
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
        mainAxisSize: MainAxisSize.min,
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
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
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
                final idx = value.toInt();
                if (idx < 0 || idx >= months.length) {
                  return const SizedBox();
                }
                return Text(
                  months[idx],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
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
            spots: [
              const FlSpot(0, 45000),
              FlSpot(1, 52000),
              FlSpot(2, 48000),
              FlSpot(3, 61000),
              FlSpot(4, 55000),
              FlSpot(5, 67000),
            ],
            isCurved: false,
            color: const Color(0xFF212121),
            barWidth: 2,
            dotData: FlDotData(show: true),
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
      height: 340,
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
        mainAxisSize: MainAxisSize.min,
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
            child: _buildDonutChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart() {
    final sections = [
      PieChartSectionData(
        value: 12,
        title: '',
        showTitle: false,
        color: const Color(0xFF9E9E9E),
        radius: 40,
      ),
      PieChartSectionData(
        value: 28,
        title: '',
        showTitle: false,
        color: const Color(0xFF616161),
        radius: 40,
      ),
      PieChartSectionData(
        value: 45,
        title: '',
        showTitle: false,
        color: const Color(0xFF212121),
        radius: 40,
      ),
      PieChartSectionData(
        value: 4,
        title: '',
        showTitle: false,
        color: const Color(0xFFBDBDBD),
        radius: 40,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildLegendItem('Pending', const Color(0xFF9E9E9E), 12)),
            Expanded(child: _buildLegendItem('Processing', const Color(0xFF616161), 28)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildLegendItem('Delivered', const Color(0xFF212121), 45)),
            Expanded(child: _buildLegendItem('Cancelled', const Color(0xFFBDBDBD), 4)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
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
            '$label ($count)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLevelsChart() {
    return Container(
      height: 340,
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
        mainAxisSize: MainAxisSize.min,
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
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final categories = ['Beverages', 'Snacks', 'Household', 'Personal Care', 'Frozen'];
    final stocks = [450, 320, 180, 210, 95];
    final colors = [
      const Color(0xFF212121),
      const Color(0xFF212121),
      const Color(0xFF212121),
      const Color(0xFF212121),
      const Color(0xFF212121),
    ];

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= categories.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Text(
                      categories[idx],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(5, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stocks[index].toDouble(),
                color: colors[index],
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
        minY: 0,
        maxY: 600,
      ),
    );
  }
}
