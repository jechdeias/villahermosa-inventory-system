/// Admin Dashboard Screen
/// 
/// Provides administrative overview and management tools.
library;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/theme/app_theme.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminDashboardScreen extends StatelessWidget {
  
  const AdminDashboardScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: AdminDashboardView(database: database, syncManager: syncManager),
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
    properties.add(DiagnosticsProperty<SyncManager>('syncManager', syncManager));
  }
}

class AdminDashboardView extends StatelessWidget {
  
  const AdminDashboardView({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();
    
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.darkNavigation,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Dashboard Overview',
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: 24),
            
            // Stats Cards Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Products', Icons.inventory, context, () => _getTotalProducts())),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Total Customers', Icons.people, context, () => _getTotalCustomers())),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Pending Orders', Icons.pending, context, () => _getPendingOrders())),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Total Users', Icons.person, context, () => _getTotalUsers())),
              ],
            ),
            const SizedBox(height: 24),
            
            // Quick Actions Grid
            Text(
              'Quick Actions',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionButton(
                  'Manage Users',
                  Icons.people,
                  AppTheme.accentColor,
                  () => _showComingSoon(context, 'Manage Users'),
                ),
                _buildActionButton(
                  'View Inventory',
                  Icons.inventory,
                  AppTheme.primaryColor,
                  () => _showComingSoon(context, 'View Inventory'),
                ),
                _buildActionButton(
                  'View Orders',
                  Icons.shopping_cart,
                  AppTheme.warningColor,
                  () => _showComingSoon(context, 'View Orders'),
                ),
                _buildActionButton(
                  'Sync Now',
                  Icons.sync,
                  AppTheme.successColor,
                  () => _performSync(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Recent Activity
            Text(
              'Recent Activity',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
            
            // Error display
            if (adminViewModel.error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.errorColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error: ${adminViewModel.error}',
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: adminViewModel.clearError,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear Error'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, BuildContext context, Future<int> Function() countFunction) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            FutureBuilder<int>(
              future: countFunction(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return Text(
                  snapshot.data?.toString() ?? '0',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<StockMovement>>(
          future: _getRecentStockMovements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorColor));
            }
            
            final movements = snapshot.data ?? [];
            
            if (movements.isEmpty) {
              return const Text('No recent activity', style: TextStyle(color: Colors.grey));
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last 5 Stock Movements:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                ...movements.map((movement) => ListTile(
                  dense: true,
                  leading: Icon(
                    _getMovementIcon(movement.movementType),
                    color: _getMovementColor(movement.movementType),
                    size: 20,
                  ),
                  title: Text(
                    movement.movementType.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Qty: ${movement.quantity}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    _formatDate(movement.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<int> _getTotalProducts() async {
    final result = await database.customSelect('SELECT COUNT(*) as count FROM products WHERE is_deleted = 0').getSingle();
    return result.read<int>('count');
  }

  Future<int> _getTotalCustomers() async {
    final result = await database.customSelect('SELECT COUNT(*) as count FROM customers WHERE is_deleted = 0').getSingle();
    return result.read<int>('count');
  }

  Future<int> _getPendingOrders() async {
    final result = await database.customSelect("SELECT COUNT(*) as count FROM orders WHERE status = 'pending' AND is_deleted = 0").getSingle();
    return result.read<int>('count');
  }

  Future<int> _getTotalUsers() async {
    final result = await database.customSelect('SELECT COUNT(*) as count FROM users WHERE is_deleted = 0').getSingle();
    return result.read<int>('count');
  }

  Future<List<StockMovement>> _getRecentStockMovements() async {
    return await (database.select(database.stockMovements)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)])
          ..limit(5))
        .get();
  }

  IconData _getMovementIcon(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'in':
        return Icons.arrow_downward;
      case 'out':
        return Icons.arrow_upward;
      case 'adjustment':
        return Icons.tune;
      case 'return':
        return Icons.undo;
      default:
        return Icons.swap_vert;
    }
  }

  Color _getMovementColor(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'in':
        return AppTheme.successColor;
      case 'out':
        return AppTheme.warningColor;
      case 'adjustment':
        return AppTheme.primaryColor;
      case 'return':
        return AppTheme.accentColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        backgroundColor: AppTheme.warningColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _performSync(BuildContext context) async {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting sync...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Push changes
      final pushResult = await syncManager.push();
      
      // Pull changes
      final pullResult = await syncManager.pull();
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync complete!\n'
            'Pushed: ${pushResult['recordsPushed']} records\n'
            'Pulled: ${pullResult['recordsPulled']} records',
          ),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
    properties.add(DiagnosticsProperty<SyncManager>('syncManager', syncManager));
  }
}
