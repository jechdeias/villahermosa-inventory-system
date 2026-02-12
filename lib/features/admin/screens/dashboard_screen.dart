/// Admin Dashboard Screen
/// 
/// Provides administrative overview and management tools.
library;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../../core/database/app_database.dart';
import 'users_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  
  const AdminDashboardScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: AdminDashboardView(database: database),
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}

class AdminDashboardView extends StatelessWidget {
  
  const AdminDashboardView({super.key, required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Admin Navigation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Loading indicator
            if (adminViewModel.isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUsersScreen(database: database),
                    ),
                  );
                },
                child: const Text('User Management'),
              ),
            
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.customerDashboard);
              },
              child: const Text('Customer Dashboard'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.warehouseDashboard);
              },
              child: const Text('Warehouse Dashboard'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.deliveryDashboard);
              },
              child: const Text('Delivery Dashboard'),
            ),
            
            // Error display
            if (adminViewModel.error != null) ...[
              const SizedBox(height: 20),
              Text(
                'Error: ${adminViewModel.error}',
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: adminViewModel.clearError,
                child: const Text('Clear Error'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}
