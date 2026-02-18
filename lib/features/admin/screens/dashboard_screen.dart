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
      create: (_) => AdminViewModel(database),
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
      backgroundColor: AppTheme.dashboardBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGradientStart,
                          AppTheme.primaryGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.dashboard,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: AppTheme.figmaHeading,
                        ),
                        Text(
                          'Welcome to Admin Dashboard',
                          style: AppTheme.figmaSubheading,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Stats Cards Grid
              Expanded(
                child: Row(
                  children: [
                    // Left Column - Stats and Actions
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Stats Cards
                          Expanded(
                            flex: 2,
                            child: GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.4,
                              children: [
                                _buildStatCard('Total Products', Icons.inventory_outlined, AppTheme.statCardPurple, () => _getTotalProducts()),
                                _buildStatCard('Total Customers', Icons.people_outline, AppTheme.statCardBlue, () => _getTotalCustomers()),
                                _buildStatCard('Pending Orders', Icons.shopping_bag_outlined, AppTheme.statCardPink, () => _getPendingOrders()),
                                _buildStatCard('Total Users', Icons.person_outline, AppTheme.statCardGreen, () => _getTotalUsers()),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action Buttons
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: AppTheme.figmaHeading,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 2.5,
                                    children: [
                                      _buildActionButton(
                                        'Manage Users',
                                        Icons.people_outline,
                                        AppTheme.primaryGradientStart,
                                        () => _showComingSoon(context, 'Manage Users'),
                                      ),
                                      _buildActionButton(
                                        'View Inventory',
                                        Icons.inventory_2_outlined,
                                        AppTheme.statCardBlue,
                                        () => _showComingSoon(context, 'View Inventory'),
                                      ),
                                      _buildActionButton(
                                        'View Orders',
                                        Icons.receipt_long_outlined,
                                        AppTheme.statCardPink,
                                        () => _showComingSoon(context, 'View Orders'),
                                      ),
                                      _buildActionButton(
                                        'Sync Now',
                                        Icons.sync_outlined,
                                        AppTheme.statCardGreen,
                                        () => _performSync(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Right Column - Recent Activity
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: AppTheme.figmaHeading,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildRecentActivity(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Error display
              if (adminViewModel.error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    border: Border.all(color: AppTheme.errorColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error: ${adminViewModel.error}',
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                      TextButton(
                        onPressed: adminViewModel.clearError,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, Future<int> Function() countFunction) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.figmaCardTitle,
          ),
          const SizedBox(height: 4),
          FutureBuilder<int>(
            future: countFunction(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Text(
                snapshot.data?.toString() ?? '0',
                style: AppTheme.figmaStatNumber,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.figmaButtonText.copyWith(color: AppTheme.textPrimary),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<List<StockMovement>>(
        future: _getRecentStockMovements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            );
          }
          
          final movements = snapshot.data ?? [];
          
          if (movements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 48,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: AppTheme.figmaSubheading,
                  ),
                ],
              ),
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 5 Stock Movements',
                style: AppTheme.figmaSubheading,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: movements.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getMovementColor(movement.movementType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getMovementIcon(movement.movementType),
                          color: _getMovementColor(movement.movementType),
                          size: 16,
                        ),
                      ),
                      title: Text(
                        movement.movementType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Quantity: ${movement.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      trailing: Text(
                        _formatDate(movement.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
        return AppTheme.statCardGreen;
      case 'out':
        return AppTheme.statCardPink;
      case 'adjustment':
        return AppTheme.statCardPurple;
      case 'return':
        return AppTheme.statCardBlue;
      default:
        return AppTheme.textLight;
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
        backgroundColor: AppTheme.statCardBlue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _performSync(BuildContext context) async {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Starting sync...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
          backgroundColor: AppTheme.statCardGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
