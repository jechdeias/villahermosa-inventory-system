import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/inventory',
      child: _PlaceholderContent(
        icon: Icons.inventory_2_outlined,
        title: 'Inventory',
        subtitle: 'Product management coming soon',
      ),
    );
  }
}

class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/customers',
      child: _PlaceholderContent(
        icon: Icons.storefront_outlined,
        title: 'Customers',
        subtitle: 'Customer management coming soon',
      ),
    );
  }
}

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/orders',
      child: _PlaceholderContent(
        icon: Icons.shopping_cart_outlined,
        title: 'Orders',
        subtitle: 'Order management coming soon',
      ),
    );
  }
}

class AdminStockScreen extends StatelessWidget {
  const AdminStockScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/stock',
      child: _PlaceholderContent(
        icon: Icons.trending_up,
        title: 'Stock',
        subtitle: 'Stock tracking coming soon',
      ),
    );
  }
}

class AdminDeliveriesScreen extends StatelessWidget {
  const AdminDeliveriesScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/deliveries',
      child: _PlaceholderContent(
        icon: Icons.local_shipping_outlined,
        title: 'Deliveries',
        subtitle: 'Delivery management coming soon',
      ),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/reports',
      child: _PlaceholderContent(
        icon: Icons.bar_chart_outlined,
        title: 'Reports',
        subtitle: 'Reports and analytics coming soon',
      ),
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({
    super.key, 
    required this.database, 
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/settings',
      child: _PlaceholderContent(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'System settings coming soon',
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 36, 
                color: const Color(0xFF1E1E1E)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
