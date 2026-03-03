import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

/// Warehouse Dashboard Screen
/// 
/// Provides warehouse operations overview and management tools.
class WarehouseDashboardScreen extends StatefulWidget {
  const WarehouseDashboardScreen({
    super.key, 
    required this.database, 
    required this.syncManager
  });
  
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<WarehouseDashboardScreen> createState() => _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState extends State<WarehouseDashboardScreen> {
  int _incomingOrdersCount = 0;
  int _ordersToPrepareCount = 0;
  int _lowStockAlertsCount = 0;
  int _todayRoutesCount = 0;
  List<StockMovement> _recentActivities = [];
  bool _isLoading = true;

  // Warehouse navigation items
  static const List<NavigationItem> _warehouseNavItems = [
    NavigationItem(
      route: '/warehouse/dashboard',
      icon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavigationItem(
      route: '/warehouse/incoming-orders',
      icon: Icons.inventory_2,
      label: 'Incoming Orders',
    ),
    NavigationItem(
      route: '/warehouse/prepare-orders',
      icon: Icons.assignment,
      label: 'Prepare Orders',
    ),
    NavigationItem(
      route: '/warehouse/inventory',
      icon: Icons.storage,
      label: 'Inventory Stock',
    ),
    NavigationItem(
      route: '/warehouse/stock-movement',
      icon: Icons.trending_up,
      label: 'Stock Movement',
    ),
    NavigationItem(
      route: '/warehouse/loading-dispatch',
      icon: Icons.local_shipping,
      label: 'Loading & Dispatch',
    ),
    NavigationItem(
      route: '/warehouse/routes',
      icon: Icons.location_on,
      label: 'Routes Today',
    ),
    NavigationItem(
      route: '/warehouse/returns',
      icon: Icons.refresh,
      label: 'Returns & Damaged',
    ),
    NavigationItem(
      route: '/warehouse/reports',
      icon: Icons.bar_chart,
      label: 'Reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait(<Future<Object>>[
        _getIncomingOrdersCount(),
        _getOrdersToPrepareCount(),
        _getLowStockAlertsCount(),
        _getTodayRoutesCount(),
        _getRecentActivities(),
      ]);

      if (mounted) {
        setState(() {
          _incomingOrdersCount = results[0] as int;
          _ordersToPrepareCount = results[1] as int;
          _lowStockAlertsCount = results[2] as int;
          _todayRoutesCount = results[3] as int;
          _recentActivities = results[4] as List<StockMovement>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<int> _getIncomingOrdersCount() async {
    final result = await widget.database.customSelect(
      "SELECT COUNT(*) as count FROM orders WHERE status = 'incoming' AND is_deleted = 0"
    ).getSingle();
    return result.read<int>('count');
  }

  Future<int> _getOrdersToPrepareCount() async {
    final result = await widget.database.customSelect(
      "SELECT COUNT(*) as count FROM orders WHERE status = 'pending' AND is_deleted = 0"
    ).getSingle();
    return result.read<int>('count');
  }

  Future<int> _getLowStockAlertsCount() async {
    final result = await widget.database.customSelect(
      "SELECT COUNT(*) as count FROM products WHERE current_stock <= min_stock AND is_deleted = 0"
    ).getSingle();
    return result.read<int>('count');
  }

  Future<int> _getTodayRoutesCount() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final result = await widget.database.customSelect(
      "SELECT COUNT(*) as count FROM deliveries WHERE date >= ? AND date < ? AND is_deleted = 0",
      variables: [
        drift.Variable.withString(todayStart.toIso8601String()),
        drift.Variable.withString(todayEnd.toIso8601String()),
      ],
    ).getSingle();
    return result.read<int>('count');
  }

  Future<List<StockMovement>> _getRecentActivities() async {
    return await (widget.database.select(widget.database.stockMovements)
          ..orderBy([(t) => drift.OrderingTerm(
            expression: t.createdAt, 
            mode: drift.OrderingMode.desc
          )])
          ..limit(5))
        .get();
  }

  Future<void> _handleQuickAction(String action) async {
    switch (action) {
      case 'Sync Data':
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Syncing data...')),
          );
          await widget.syncManager.push();
          await widget.syncManager.pull();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sync completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      selectedRoute: '/warehouse/dashboard',
      database: widget.database,
      navItems: _warehouseNavItems,
      syncManager: widget.syncManager,
      child: _buildWarehouseDashboard(),
    );
  }

  Widget _buildWarehouseDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          _buildPageHeader(),
          const SizedBox(height: 24),
          
          // Stats Cards
          _buildStatsCards(),
          const SizedBox(height: 24),
          
          // Activity and Actions Row
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1200) {
                  // Desktop layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildRecentActivity()),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildQuickActions()),
                    ],
                  );
                } else {
                  // Mobile layout
                  return Column(
                    children: [
                      _buildRecentActivity(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warehouse Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Villahermosa Marketing - Warehouse Operations',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF6B6B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Incoming Orders',
              _incomingOrdersCount,
              Icons.inventory_2,
              'Orders to receive',
            ),
            _buildStatCard(
              'Orders to Prepare',
              _ordersToPrepareCount,
              Icons.assignment,
              'Pending picklist',
            ),
            _buildStatCard(
              'Low Stock Alerts',
              _lowStockAlertsCount,
              Icons.warning,
              'Items below threshold',
            ),
            _buildStatCard(
              "Today's Routes",
              _todayRoutesCount,
              Icons.local_shipping,
              'Active delivery routes',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, String description) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              Icon(
                icon,
                color: const Color(0xFF1E1E1E),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Large number
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _recentActivities.isEmpty
                ? const Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Color(0xFF6B6B6B)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _recentActivities.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Color(0xFFE0E0E0),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final activity = _recentActivities[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                activity.reason,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                            ),
                            Text(
                              (() {
                                final now = DateTime.now();
                                final difference = now.difference(activity.createdAt);
                                
                                if (difference.inMinutes < 1) {
                                  return 'Just now';
                                } else if (difference.inMinutes < 60) {
                                  return '${difference.inMinutes} minutes ago';
                                } else if (difference.inHours < 24) {
                                  return '${difference.inHours} hours ago';
                                } else {
                                  return '${difference.inDays} days ago';
                                }
                              })(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton('Stock In'),
                _buildActionButton('Stock Out'),
                _buildActionButton('New Order'),
                _buildActionButton('Print Labels'),
                _buildActionButton('View Routes'),
                _buildActionButton('Sync Data'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label) {
    return ElevatedButton(
      onPressed: () => _handleQuickAction(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
