import 'package:flutter/material.dart';
import 'features/warehouse/simple_warehouse_dashboard.dart';

void main() {
  runApp(const VillahermosaInventoryApp());
}

class VillahermosaInventoryApp extends StatelessWidget {
  const VillahermosaInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Villahermosa Warehouse System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const SimpleWarehouseDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
