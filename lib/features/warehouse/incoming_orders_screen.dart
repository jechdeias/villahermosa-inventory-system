import 'package:flutter/material.dart';
import '../../shared/theme/warehouse_theme.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  String _selectedStatus = 'All';
  String _selectedRoute = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-2024-001',
      'storeName': 'ABC Market - Boac',
      'route': 'Boac North',
      'status': 'pending',
      'items': 15,
      'totalAmount': 12500.00,
      'orderTime': '08:30 AM',
      'deliveryDate': 'Today',
      'priority': 'high',
    },
    {
      'id': 'ORD-2024-002',
      'storeName': 'GMART - Balaring',
      'route': 'Boac Central',
      'status': 'processing',
      'items': 8,
      'totalAmount': 8900.00,
      'orderTime': '09:15 AM',
      'deliveryDate': 'Today',
      'priority': 'normal',
    },
    {
      'id': 'ORD-2024-003',
      'storeName': 'Happyroo Supermarket',
      'route': 'Gasan East',
      'status': 'pending',
      'items': 25,
      'totalAmount': 18750.00,
      'orderTime': '09:45 AM',
      'deliveryDate': 'Tomorrow',
      'priority': 'high',
    },
    {
      'id': 'ORD-2024-004',
      'storeName': 'Home Town Drugstore',
      'route': 'Sta. Cruz West',
      'status': 'ready',
      'items': 12,
      'totalAmount': 15600.00,
      'orderTime': '10:20 AM',
      'deliveryDate': 'Today',
      'priority': 'normal',
    },
    {
      'id': 'ORD-2024-005',
      'storeName': 'Sunshine Bakery',
      'route': 'Torrijos South',
      'status': 'pending',
      'items': 6,
      'totalAmount': 4500.00,
      'orderTime': '11:00 AM',
      'deliveryDate': 'Tomorrow',
      'priority': 'low',
    },
    {
      'id': 'ORD-2024-006',
      'storeName': 'Kathlyn Store',
      'route': 'Buenavista North',
      'status': 'processing',
      'items': 10,
      'totalAmount': 7200.00,
      'orderTime': '11:30 AM',
      'deliveryDate': 'Today',
      'priority': 'normal',
    },
  ];

  List<String> get _routes => ['All', 'Boac North', 'Boac Central', 'Gasan East', 'Sta. Cruz West', 'Torrijos South', 'Buenavista North'];
  List<String> get _statuses => ['All', 'pending', 'processing', 'ready'];

  List<Map<String, dynamic>> get _filteredOrders => _orders.where((order) {
      final matchesSearch = order['storeName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           order['id'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || order['status'] == _selectedStatus;
      final matchesRoute = _selectedRoute == 'All' || order['route'] == _selectedRoute;
      return matchesSearch && matchesStatus && matchesRoute;
    }).toList();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return WarehouseTheme.warning;
      case 'processing':
        return WarehouseTheme.info;
      case 'ready':
        return WarehouseTheme.success;
      default:
        return WarehouseTheme.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return WarehouseTheme.error;
      case 'normal':
        return WarehouseTheme.info;
      case 'low':
        return WarehouseTheme.textSecondary;
      default:
        return WarehouseTheme.textSecondary;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: WarehouseTheme.theme,
      child: Scaffold(
        backgroundColor: WarehouseTheme.lightBackground,
        appBar: AppBar(
          title: const Text('Incoming Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              tooltip: 'Filter',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {},
              tooltip: 'Export',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: WarehouseTheme.whiteCard,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by order ID or store name...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag),
                          ),
                          items: _statuses.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRoute,
                          decoration: const InputDecoration(
                            labelText: 'Route',
                            prefixIcon: Icon(Icons.route),
                          ),
                          items: _routes.map((route) => DropdownMenuItem(
                              value: route,
                              child: Text(route),
                            )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRoute = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Orders List
            Expanded(
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: WarehouseTheme.textDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: WarehouseTheme.headingMedium.copyWith(
                              color: WarehouseTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Try adjusting your filters',
                            style: WarehouseTheme.bodyMedium.copyWith(
                              color: WarehouseTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ],
        ),
      ),
    );

  Widget _buildOrderCard(Map<String, dynamic> order) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to order details
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['id'],
                          style: WarehouseTheme.headingSmall,
                        ),
                        Text(
                          order['storeName'],
                          style: WarehouseTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      WarehouseTheme.statusBadge(
                        text: order['status'].toString().toUpperCase(),
                        color: _getStatusColor(order['status']),
                      ),
                      const SizedBox(height: 4),
                      WarehouseTheme.statusBadge(
                        text: order['priority'].toString().toUpperCase(),
                        color: _getPriorityColor(order['priority']),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Route',
                      order['route'],
                      Icons.route,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Items',
                      '${order['items']}',
                      Icons.inventory_2,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Amount',
                      '₱${order['totalAmount'].toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Time and Delivery Info
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: WarehouseTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Order: ${order['orderTime']}',
                    style: WarehouseTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.local_shipping,
                    size: 16,
                    color: WarehouseTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery: ${order['deliveryDate']}',
                    style: WarehouseTheme.bodySmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Start processing order
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Process'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildDetailItem(String label, String value, IconData icon) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: WarehouseTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: WarehouseTheme.caption.copyWith(
                color: WarehouseTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: WarehouseTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
}
