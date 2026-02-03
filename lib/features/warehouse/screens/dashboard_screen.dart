/// Warehouse Dashboard Screen
/// 
/// Placeholder for warehouse management dashboard interface.
/// This screen will provide inventory overview and warehouse operations.
/// 
/// TODO: Implement warehouse dashboard UI with inventory status and order management.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../viewmodels/warehouse_viewmodel.dart';

class WarehouseDashboardScreen extends StatelessWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WarehouseViewModel(),
      child: const WarehouseDashboardView(),
    );
  }
}

class WarehouseDashboardView extends StatelessWidget {
  const WarehouseDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final warehouseViewModel = context.watch<WarehouseViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Dashboard'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Warehouse Navigation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Loading indicator
            if (warehouseViewModel.isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.warehouseInventory);
                },
                child: const Text('Inventory Management'),
              ),
            
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.deliveryDashboard);
              },
              child: const Text('Delivery Status'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.customerDashboard);
              },
              child: const Text('Customer Orders'),
            ),
            
            // Error display
            if (warehouseViewModel.error != null) ...[
              const SizedBox(height: 20),
              Text(
                'Error: ${warehouseViewModel.error}',
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: () => warehouseViewModel.clearError(),
                child: const Text('Clear Error'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
