/// Customer Dashboard Screen
/// 
/// Placeholder for the main customer dashboard interface.
/// This screen will provide customer-specific overview and self-service tools.
/// 
/// TODO: Implement customer dashboard UI with order history, profile management,
/// and customer-specific features.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../viewmodels/customer_viewmodel.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => CustomerViewModel(),
      child: const CustomerDashboardView(),
    );
}

class CustomerDashboardView extends StatelessWidget {
  const CustomerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final customerViewModel = context.watch<CustomerViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customer Navigation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Loading indicator
            if (customerViewModel.isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.customerProfile);
                },
                child: const Text('My Profile'),
              ),
            
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.warehouseDashboard);
              },
              child: const Text('View Products'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.deliveryDashboard);
              },
              child: const Text('Track Deliveries'),
            ),
            
            // Error display
            if (customerViewModel.error != null) ...[
              const SizedBox(height: 20),
              Text(
                'Error: ${customerViewModel.error}',
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: customerViewModel.clearError,
                child: const Text('Clear Error'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
