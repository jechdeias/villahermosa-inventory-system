/// Delivery Dashboard Screen
/// 
/// Placeholder for delivery operations dashboard interface.
/// This screen will provide delivery overview and route management.
/// 
/// TODO: Implement delivery dashboard UI with route tracking and delivery status.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../viewmodels/delivery_viewmodel.dart';
import 'delivery_confirmation_screen.dart';

class DeliveryDashboardScreen extends StatelessWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => DeliveryViewModel(),
      child: const DeliveryDashboardView(),
    );
}

class DeliveryDashboardView extends StatelessWidget {
  const DeliveryDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveryViewModel = context.watch<DeliveryViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Delivery Navigation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Loading indicator
            if (deliveryViewModel.isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.deliveryRoute);
                    },
                    child: const Text('Manage Routes'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _testDeliveryConfirmation(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Delivery Confirmation'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.warehouseDashboard);
                    },
                    child: const Text('View Warehouse'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.customerDashboard);
                    },
                    child: const Text('Customer Info'),
                  ),
                ],
              ),
            
            // Error display
            if (deliveryViewModel.error != null) ...[
              const SizedBox(height: 20),
              Text(
                'Error: ${deliveryViewModel.error}',
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: deliveryViewModel.clearError,
                child: const Text('Clear Error'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _testDeliveryConfirmation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryConfirmationScreen(
          deliveryId: 'DEL-001',
          customerName: 'John Doe',
          deliveryAddress: '123 Main St, City, State 12345',
        ),
      ),
    );
  }
}
