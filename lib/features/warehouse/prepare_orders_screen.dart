import 'package:flutter/material.dart';

import '../../features/qr/qr_service_locator.dart';
import '../../shared/theme/warehouse_theme.dart';

class PrepareOrdersScreen extends StatefulWidget {
  const PrepareOrdersScreen({super.key});

  @override
  State<PrepareOrdersScreen> createState() => _PrepareOrdersScreenState();
}

class _PrepareOrdersScreenState extends State<PrepareOrdersScreen> {
  String _selectedOrder = 'ORD-2024-001';
  final Map<String, List<Map<String, dynamic>>> _orderItems = {
    'ORD-2024-001': [
      {
        'id': 1,
        'productName': 'Beer na Beer 330ml',
        'sku': 'BNB',
        'required': 5,
        'available': 50,
        'picked': 0,
        'location': 'Warehouse A - Aisle 1',
        'category': 'Beer',
      },
      {
        'id': 2,
        'productName': 'Cobra Energy Drink Green',
        'sku': 'C ASTIG-G',
        'required': 10,
        'available': 100,
        'picked': 0,
        'location': 'Warehouse B - Aisle 3',
        'category': 'Energy Drink',
      },
      {
        'id': 3,
        'productName': 'Absolute Drinking Water 500ml',
        'sku': 'AB500',
        'required': 8,
        'available': 180,
        'picked': 0,
        'location': 'Warehouse E - Aisle 2',
        'category': 'Water',
      },
      {
        'id': 4,
        'productName': 'RC Cola Drink 240ml',
        'sku': 'RC COLA',
        'required': 12,
        'available': 300,
        'picked': 0,
        'location': 'Warehouse G - Aisle 1',
        'category': 'Soft Drinks',
      },
      {
        'id': 5,
        'productName': 'Jersey Condensed Milk 1KG',
        'sku': 'J.CONDENSED 1KG',
        'required': 3,
        'available': 20,
        'picked': 0,
        'location': 'Warehouse F - Aisle 4',
        'category': 'Milk',
      },
    ],
    'ORD-2024-002': [
      {
        'id': 6,
        'productName': 'Colt 45 330ml',
        'sku': 'COLT330',
        'required': 6,
        'available': 40,
        'picked': 0,
        'location': 'Warehouse A - Aisle 2',
        'category': 'Beer',
      },
      {
        'id': 7,
        'productName': 'Vitamilk Soya Drink 300ml',
        'sku': 'VM CHOCO',
        'required': 4,
        'available': 50,
        'picked': 0,
        'location': 'Warehouse F - Aisle 1',
        'category': 'Milk',
      },
    ],
  };

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-2024-001',
      'storeName': 'ABC Market - Boac',
      'route': 'Boac North',
      'status': 'in_progress',
      'totalItems': 38,
      'pickedItems': 0,
      'priority': 'high',
    },
    {
      'id': 'ORD-2024-002',
      'storeName': 'GMART - Balaring',
      'route': 'Boac Central',
      'status': 'pending',
      'totalItems': 10,
      'pickedItems': 0,
      'priority': 'normal',
    },
  ];

  List<Map<String, dynamic>> get _currentOrderItems => _orderItems[_selectedOrder] ?? [];

  int get _totalPicked => _currentOrderItems.fold<int>(0, (sum, item) => sum + (item['picked'] as int));

  int get _totalRequired => _currentOrderItems.fold<int>(0, (sum, item) => sum + (item['required'] as int));

  bool get _isOrderComplete => _currentOrderItems.every((item) => (item['picked'] as int) >= (item['required'] as int));

  @override
  Widget build(BuildContext context) => Theme(
      data: WarehouseTheme.theme,
      child: Scaffold(
        backgroundColor: WarehouseTheme.lightBackground,
        appBar: AppBar(
          title: const Text('Prepare Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {},
              tooltip: 'Print Picklist',
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                await QrServiceLocator.instance.scanQrCode();
              },
              tooltip: 'Scan Items',
            ),
          ],
        ),
        body: Column(
          children: [
            // Order Selection
            Container(
              padding: const EdgeInsets.all(16),
              color: WarehouseTheme.whiteCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Order to Prepare',
                    style: WarehouseTheme.headingSmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrder,
                    decoration: const InputDecoration(
                      labelText: 'Order Number',
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    items: _orders.map((order) => DropdownMenuItem<String>(
                        value: order['id'] as String,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['id'] as String,
                              style: WarehouseTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${order['storeName']} - ${order['route']}',
                              style: WarehouseTheme.bodySmall,
                            ),
                          ],
                        ),
                      )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedOrder = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: WarehouseTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$_totalPicked / $_totalRequired items',
                        style: WarehouseTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _totalRequired > 0 ? _totalPicked / _totalRequired : 0.0,
                    backgroundColor: WarehouseTheme.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isOrderComplete ? WarehouseTheme.success : WarehouseTheme.info,
                    ),
                  ),
                ],
              ),
            ),
            
            // Picklist Items
            Expanded(
              child: _currentOrderItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: WarehouseTheme.textDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items to pick',
                            style: WarehouseTheme.headingMedium.copyWith(
                              color: WarehouseTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _currentOrderItems.length,
                      itemBuilder: (context, index) {
                        final item = _currentOrderItems[index];
                        return _buildPicklistItem(item);
                      },
                    ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              color: WarehouseTheme.whiteCard,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetAllPicks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isOrderComplete
                          ? _completeOrder
                          : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Complete Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOrderComplete ? WarehouseTheme.success : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildPicklistItem(Map<String, dynamic> item) {
    final required = item['required'] as int;
    final available = item['available'] as int;
    final picked = item['picked'] as int;
    final isComplete = picked >= required;
    final hasStockIssue = available < required;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['productName'],
                        style: WarehouseTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'SKU: ${item['sku']} | ${item['category']}',
                        style: WarehouseTheme.bodySmall,
                      ),
                      Text(
                        item['location'],
                        style: WarehouseTheme.bodySmall.copyWith(
                          color: WarehouseTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasStockIssue)
                  WarehouseTheme.statusBadge(
                    text: 'LOW STOCK',
                    color: WarehouseTheme.error,
                  )
                else if (isComplete)
                  WarehouseTheme.statusBadge(
                    text: 'PICKED',
                    color: WarehouseTheme.success,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Quantity Controls
            Row(
              children: [
                // Required Quantity
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Required',
                        style: WarehouseTheme.caption.copyWith(
                          color: WarehouseTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$required',
                        style: WarehouseTheme.headingSmall.copyWith(
                          color: WarehouseTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Available Quantity
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Available',
                        style: WarehouseTheme.caption.copyWith(
                          color: WarehouseTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$available',
                        style: WarehouseTheme.headingSmall.copyWith(
                          color: hasStockIssue ? WarehouseTheme.error : WarehouseTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Picked Quantity
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Picked',
                        style: WarehouseTheme.caption.copyWith(
                          color: WarehouseTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: picked > 0
                                ? () {
                                    _updatePickedQuantity(item['id'], picked - 1);
                                  }
                                : null,
                            icon: const Icon(Icons.remove),
                            iconSize: 20,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: WarehouseTheme.divider),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$picked',
                              textAlign: TextAlign.center,
                              style: WarehouseTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isComplete ? WarehouseTheme.success : WarehouseTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: picked < available
                                ? () {
                                    _updatePickedQuantity(item['id'], picked + 1);
                                  }
                                : null,
                            icon: const Icon(Icons.add),
                            iconSize: 20,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Quick Actions
            if (!isComplete)
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                            onPressed: () {
                              _updatePickedQuantity(item['id'] as int, required);
                            },
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Pick All'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                            onPressed: () {
                              _updatePickedQuantity(item['id'] as int, 0);
                            },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await QrServiceLocator.instance.scanQrCode();
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Quick Scan',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updatePickedQuantity(int itemId, int quantity) {
    setState(() {
      final items = _orderItems[_selectedOrder]!;
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);
      if (itemIndex != -1) {
        items[itemIndex]['picked'] = quantity;
      }
    });
  }

  void _resetAllPicks() {
    setState(() {
      final items = _orderItems[_selectedOrder]!;
      for (final item in items) {
        item['picked'] = 0;
      }
    });
  }

  void _completeOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Order'),
        content: Text('Are you sure you want to complete order $_selectedOrder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Complete order logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order $_selectedOrder completed successfully!'),
                  backgroundColor: WarehouseTheme.success,
                ),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
