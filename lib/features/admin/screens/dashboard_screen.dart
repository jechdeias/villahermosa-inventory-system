/// Admin Dashboard Screen
/// 
/// Placeholder for the main admin dashboard interface.
/// This screen will provide administrative overview and management tools.
/// 
/// TODO: Implement admin dashboard UI with system overview, user management,
/// and administrative controls.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: const AdminDashboardView(),
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

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
        padding: const EdgeInsets.all(16.0),
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
                  Navigator.pushNamed(context, AppRoutes.adminUsers);
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
                onPressed: () => adminViewModel.clearError(),
                child: const Text('Clear Error'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
