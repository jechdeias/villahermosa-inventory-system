import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/app_database.dart';
import 'core/auth/auth_service.dart';
import 'core/services/navigation_service.dart';
import 'features/qr/qr_service_locator.dart';
import 'core/business/role_based_access.dart';
import 'core/navigation/role_based_navigation.dart';
import 'core/constants/user_roles.dart';
import 'core/widgets/role_based_widgets.dart';
import 'features/auth/login_screen.dart';
import 'routes/app_routes.dart';

// Feature Screens
import 'features/admin/screens/dashboard_screen.dart';
import 'features/admin/screens/users_screen.dart';
import 'features/customer/screens/dashboard_screen.dart';
import 'features/customer/screens/profile_screen.dart';
import 'features/delivery/screens/dashboard_screen.dart';
import 'features/delivery/screens/route_screen.dart';
import 'features/warehouse/screens/dashboard_screen.dart';
import 'features/warehouse/screens/inventory_screen.dart';

// Legacy Customer Screens (do not extend)
import 'features/customers/customer_form_screen.dart';
import 'features/customers/customer_list_screen_mock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - TODO: Replace with actual credentials
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const VillahermosaInventoryApp());
}

class VillahermosaInventoryApp extends StatelessWidget {
  const VillahermosaInventoryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Villahermosa Inventory System',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: false,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _getRouteWidget(settings.name),
        );
      },
    );

  Widget _getRouteWidget(String? route) {
    switch (route) {
      // Auth Routes
      case AppRoutes.login:
        return LoginScreen(database: AppDatabase());
        
      // Admin Routes
      case AppRoutes.adminDashboard:
        return const AdminDashboardScreen();
      case AppRoutes.adminUsers:
        return const AdminUsersScreen();
        
      // Customer Routes
      case AppRoutes.customerDashboard:
        return const CustomerDashboardScreen();
      case AppRoutes.customerProfile:
        return const CustomerProfileScreen();
        
      // Delivery Routes
      case AppRoutes.deliveryDashboard:
        return const DeliveryDashboardScreen();
      case AppRoutes.deliveryRoute:
        return const DeliveryRouteScreen();
        
      // Warehouse Routes
      case AppRoutes.warehouseDashboard:
        return const WarehouseDashboardScreen();
      case AppRoutes.warehouseInventory:
        return const WarehouseInventoryScreen();
        
      // Legacy Routes (do not extend)
      case AppRoutes.customerList:
        return const CustomerListScreenMock();
      case AppRoutes.customerForm:
        return const CustomerFormScreen();
        
      default:
        return LoginScreen(database: AppDatabase());
    }
  }
}

/// Auth Wrapper
/// Handles authentication state and redirects appropriately
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService(AppDatabase());
  final NavigationService _navigationService = NavigationService(
    AuthService(AppDatabase()),
    RoleBasedAccess(AppDatabase()),
  );

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Brief delay for UI
    
    if (_authService.isAuthenticated) {
      final route = await _navigationService.getInitialRoute();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
}

// Dashboard widgets with logout functionality
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const _AdminHomeScreen(),
    const _OrdersScreen(),
    const _ProductsScreen(),
    const _CustomersScreen(),
    const _DeliveriesScreen(),
    const _WarehouseScreen(),
    const _ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          RoleBasedNavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            userRole: UserRole.admin,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
}

// Admin Home Screen with action cards
class _AdminHomeScreen extends StatelessWidget {
  const _AdminHomeScreen();

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/villahermosa_logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.admin_panel_settings, size: 32);
              },
            ),
            const SizedBox(width: 12),
            const Text('Admin Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 40, color: Colors.grey[800]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Administrator',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage the entire inventory system',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Actions Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    // Example of using RoleGuard - only show for admin users
                    RoleGuard(
                      allowedRoles: [UserRole.admin],
                      child: _buildActionCard(
                        icon: Icons.people,
                        title: 'Users',
                        subtitle: 'Manage user accounts',
                        color: Colors.blue,
                        onTap: () {
                          // TODO: Navigate to users management
                        },
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.inventory,
                      title: 'Products',
                      subtitle: 'Manage products',
                      color: Colors.green,
                      onTap: () {
                        // TODO: Navigate to products management
                      },
                    ),
                    // Example of using PermissionButton
                    PermissionButton(
                      screen: 'orders',
                      action: UserAction.view,
                      onPressed: () {
                        // TODO: Navigate to orders management
                      },
                      child: _buildActionCard(
                        icon: Icons.shopping_cart,
                        title: 'Orders',
                        subtitle: 'View all orders',
                        color: Colors.orange,
                        onTap: () {
                          // TODO: Navigate to orders management
                        },
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.business,
                      title: 'Customers',
                      subtitle: 'Manage customers',
                      color: Colors.purple,
                      onTap: () {
                        // TODO: Navigate to customers management
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.local_shipping,
                      title: 'Deliveries',
                      subtitle: 'Manage deliveries',
                      color: Colors.red,
                      onTap: () {
                        // TODO: Navigate to deliveries management
                      },
                    ),
                    // Example of hiding content from specific roles
                    RoleHide(
                      hiddenRoles: [UserRole.customer],
                      child: _buildActionCard(
                        icon: Icons.assessment,
                        title: 'Reports',
                        subtitle: 'View reports',
                        color: Colors.teal,
                        onTap: () {
                          // TODO: Navigate to reports
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

// Placeholder screens for navigation
class _OrdersScreen extends StatelessWidget {
  const _OrdersScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Orders Screen - Coming Soon')),
    );
}

class _ProductsScreen extends StatelessWidget {
  const _ProductsScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Products Screen - Coming Soon')),
    );
}

class _CustomersScreen extends StatelessWidget {
  const _CustomersScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Customers Screen - Coming Soon')),
    );
}

class _DeliveriesScreen extends StatelessWidget {
  const _DeliveriesScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Deliveries Screen - Coming Soon')),
    );
}

class _WarehouseScreen extends StatelessWidget {
  const _WarehouseScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Warehouse Screen - Coming Soon')),
    );
}

class _ReportsScreen extends StatelessWidget {
  const _ReportsScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Reports Screen - Coming Soon')),
    );
}

class WarehouseDashboard extends StatelessWidget {
  const WarehouseDashboard({super.key});

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/villahermosa_logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.inventory, size: 32);
              },
            ),
            const SizedBox(width: 12),
            const Text('Warehouse Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory, size: 40, color: Colors.grey[800]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Warehouse Staff',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage inventory and stock movements',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Actions Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      icon: Icons.inventory,
                      title: 'Products',
                      subtitle: 'View and manage products',
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Navigate to products
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.swap_vert,
                      title: 'Stock Movements',
                      subtitle: 'Track stock changes',
                      color: Colors.green,
                      onTap: () {
                        // TODO: Navigate to stock movements
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.shopping_cart,
                      title: 'Orders',
                      subtitle: 'Process orders',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Navigate to orders
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.add_circle,
                      title: 'Stock In',
                      subtitle: 'Add new stock',
                      color: Colors.purple,
                      onTap: () {
                        // TODO: Navigate to stock in
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.remove_circle,
                      title: 'Stock Out',
                      subtitle: 'Remove stock',
                      color: Colors.red,
                      onTap: () {
                        // TODO: Navigate to stock out
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.assessment,
                      title: 'Reports',
                      subtitle: 'View inventory reports',
                      color: Colors.teal,
                      onTap: () {
                        // TODO: Navigate to reports
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({super.key});

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/villahermosa_logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.local_shipping, size: 32);
              },
            ),
            const SizedBox(width: 12),
            const Text('Delivery Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, size: 40, color: Colors.grey[800]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Delivery Personnel',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your deliveries and routes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Actions Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      icon: Icons.delivery_dining,
                      title: 'Active Deliveries',
                      subtitle: 'View current deliveries',
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Navigate to active deliveries
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.history,
                      title: 'Delivery History',
                      subtitle: 'View past deliveries',
                      color: Colors.green,
                      onTap: () {
                        // TODO: Navigate to delivery history
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.map,
                      title: 'Routes',
                      subtitle: 'View delivery routes',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Navigate to routes
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan QR',
                      subtitle: 'Scan delivery QR codes',
                      color: Colors.purple,
                      onTap: () async {
                        await QrServiceLocator.instance.scanQrCode(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/villahermosa_logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, size: 32);
              },
            ),
            const SizedBox(width: 12),
            const Text('Customer Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService(AppDatabase()).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 40, color: Colors.grey[800]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Customer',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View your orders and inventory',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Actions Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      icon: Icons.shopping_cart,
                      title: 'My Orders',
                      subtitle: 'View your orders',
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Navigate to orders
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.inventory,
                      title: 'Products',
                      subtitle: 'Browse products',
                      color: Colors.green,
                      onTap: () {
                        // TODO: Navigate to products
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.history,
                      title: 'Order History',
                      subtitle: 'View past orders',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Navigate to order history
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.account_circle,
                      title: 'Profile',
                      subtitle: 'Manage your profile',
                      color: Colors.purple,
                      onTap: () {
                        // TODO: Navigate to profile
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
