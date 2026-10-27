import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/responsive_shell.dart';
import 'wh_widgets.dart';

/// Route names for every warehouse screen.
class WhRoutes {
  static const dashboard = '/warehouse/dashboard';
  static const incoming = '/warehouse/incoming-orders';
  static const prepare = '/warehouse/prepare-orders';
  static const inventory = '/warehouse/inventory';
  static const stockMovement = '/warehouse/stock-movement';
  static const dispatch = '/warehouse/loading-dispatch';
  static const routesToday = '/warehouse/routes-today';
  static const returns = '/warehouse/returns';
  static const reports = '/warehouse/reports';
  static const sync = '/warehouse/sync';
}

const whNavItems = [
  NavigationItem(route: WhRoutes.dashboard, icon: Icons.grid_view_outlined, label: 'Dashboard'),
  NavigationItem(route: WhRoutes.incoming, icon: Icons.inbox_outlined, label: 'Incoming Orders'),
  NavigationItem(route: WhRoutes.prepare, icon: Icons.assignment_turned_in_outlined, label: 'Prepare Orders'),
  NavigationItem(route: WhRoutes.inventory, icon: Icons.inventory_2_outlined, label: 'Inventory Stock'),
  NavigationItem(route: WhRoutes.stockMovement, icon: Icons.swap_vert, label: 'Stock Movement'),
  NavigationItem(route: WhRoutes.dispatch, icon: Icons.local_shipping_outlined, label: 'Loading & Dispatch'),
  NavigationItem(route: WhRoutes.routesToday, icon: Icons.map_outlined, label: 'Routes Today'),
  NavigationItem(route: WhRoutes.returns, icon: Icons.history, label: 'Returns & Damaged'),
  NavigationItem(route: WhRoutes.reports, icon: Icons.bar_chart_outlined, label: 'Reports'),
  NavigationItem(route: WhRoutes.sync, icon: Icons.sync, label: 'Sync & Activity'),
];

/// Sidebar + hamburger chrome shared with admin (ResponsiveShell), configured
/// with the warehouse nav. Every warehouse screen wraps its body in this.
class WarehouseShell extends StatelessWidget {
  const WarehouseShell({super.key, required this.route, required this.child});
  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) => ResponsiveShell(
        database: AuthService.instance.database,
        selectedRoute: route,
        navItems: whNavItems,
        subtitle: 'Marketing Warehouse',
        child: Scaffold(backgroundColor: WhColors.page, body: child),
      );
}

/// Navigate between warehouse screens (sidebar-style replace, like admin).
void whGo(BuildContext context, String route, {Object? args}) =>
    Navigator.pushReplacementNamed(context, route, arguments: args);
