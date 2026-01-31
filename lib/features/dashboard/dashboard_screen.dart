import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../inventory/product_list_screen_mock.dart';
import '../customers/customer_list_screen_mock.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  
  // Mock data for calculations
  late List<MockProduct> _products;
  late List<MockCustomer> _customers;
  
  // Dashboard metrics
  int _totalProducts = 0;
  int _totalCustomers = 0;
  int _lowStockProducts = 0;
  double _totalInventoryValue = 0;
  double _totalCreditExposure = 0;
  int _wholesaleCustomers = 0;
  
  // Municipality distribution
  final Map<String, int> _municipalityDistribution = {};
  final Map<String, int> _storeTypeDistribution = {};
  
  @override
  void initState() {
    super.initState();
    _loadMockData();
    _calculateMetrics();
  }

  void _loadMockData() {
    // Load product data (simplified for demo)
    _products = [
      MockProduct(id: '1', sku: 'BNB', name: 'Beer na Beer 330ml', category: 'Beer', unitPrice: 750, costPrice: 600, unit: 'cs', currentStock: 50, minStock: 20, status: 'active', location: 'Warehouse A'),
      MockProduct(id: '2', sku: 'BNB MACHO', name: 'Beer na Beer 1000ml', category: 'Beer', unitPrice: 555, costPrice: 450, unit: 'cs', currentStock: 30, minStock: 15, status: 'active', location: 'Warehouse A'),
      MockProduct(id: '3', sku: 'C ASTIG-G', name: 'Cobra Astig - Green', category: 'Energy Drink', unitPrice: 208, costPrice: 170, unit: 'cs', currentStock: 100, minStock: 50, status: 'active', location: 'Warehouse B'),
      MockProduct(id: '27', sku: 'AB350', name: 'Absolute Drinking Water 350ml', category: 'Water', unitPrice: 379, costPrice: 300, unit: 'cs', currentStock: 200, minStock: 100, status: 'active', location: 'Warehouse E'),
      MockProduct(id: '64', sku: 'RC COLA', name: 'RC Cola Drink 240ml - Cola Flavor', category: 'Soft Drinks', unitPrice: 180, costPrice: 140, unit: 'cs', currentStock: 300, minStock: 150, status: 'active', location: 'Warehouse G'),
      MockProduct(id: '94', sku: 'J.CONDENSED 1KG', name: 'Jersey Condensed Milk 1KG', category: 'Milk', unitPrice: 108, costPrice: 85, unit: 'cs', currentStock: 20, minStock: 10, status: 'active', location: 'Warehouse F'),
      MockProduct(id: '125', sku: 'POWDET LAVENDER 57G', name: 'Powder Detergent 57g - Lavender', category: 'Detergent', unitPrice: 34.80, costPrice: 27, unit: 'cs', currentStock: 100, minStock: 50, status: 'active', location: 'Warehouse H'),
      MockProduct(id: '186', sku: 'GLUTINOUS', name: 'Kings Glutinous Rice Flour 500g', category: 'Food', unitPrice: 45, costPrice: 35, unit: 'cs', currentStock: 18, minStock: 10, status: 'active', location: 'Warehouse I'),
      MockProduct(id: '216', sku: 'ICEPOPS 90ML', name: 'Snow Time Icepops 90ml x 8 x 15', category: 'Snacks', unitPrice: 23, costPrice: 18, unit: 'cs', currentStock: 12, minStock: 6, status: 'active', location: 'Warehouse J'),
      // Low stock items
      MockProduct(id: '298', sku: 'S TIBAY TRIAL', name: 'Super Tibay Trial Size', category: 'Cleaning', unitPrice: 13, costPrice: 10, unit: 'cs', currentStock: 5, minStock: 20, status: 'active', location: 'Warehouse K'),
      MockProduct(id: '299', sku: 'S TIBAY SCOURING', name: 'Super Tibay Scouring Regular', category: 'Cleaning', unitPrice: 24, costPrice: 19, unit: 'cs', currentStock: 8, minStock: 25, status: 'active', location: 'Warehouse K'),
      MockProduct(id: '300', sku: 'S TIBAY 2IN1', name: 'Super Tibay 2in1 Economy Size', category: 'Cleaning', unitPrice: 32.40, costPrice: 25, unit: 'cs', currentStock: 3, minStock: 15, status: 'active', location: 'Warehouse K'),
    ];

    // Load customer data (simplified for demo)
    _customers = [
      MockCustomer(id: '1', name: 'Anding Maningas', businessName: 'ABC Market', municipality: 'Boac', province: 'Marinduque', storeType: 'Market Stall', contactNumber: '09123456789', creditLimit: 50000, customerType: 'regular', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 365)), updatedAt: DateTime.now().subtract(const Duration(days: 30))),
      MockCustomer(id: '2', name: 'Arnold', businessName: 'ABC Market', municipality: 'Boac', province: 'Marinduque', storeType: 'Market Stall', contactNumber: '09123456790', creditLimit: 45000, customerType: 'regular', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 300)), updatedAt: DateTime.now().subtract(const Duration(days: 15))),
      MockCustomer(id: '11', name: 'GMART', businessName: 'GMART', municipality: 'Balaring', province: 'Boac', storeType: 'Mini Mart', contactNumber: '09123456800', creditLimit: 100000, customerType: 'wholesale', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 150)), updatedAt: DateTime.now().subtract(const Duration(days: 25))),
      MockCustomer(id: '66', name: 'Black Mustache', businessName: 'Black Mustache Coffee', municipality: 'Poblacion', province: 'Boac', storeType: 'Coffee Shop', contactNumber: '09123456855', creditLimit: 75000, customerType: 'regular', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 90)), updatedAt: DateTime.now().subtract(const Duration(days: 12))),
      MockCustomer(id: '84', name: 'Kathlyn Joy Sienna', businessName: 'Kathlyn Store', municipality: 'Bagtingon', province: 'Buenavista', storeType: 'Sari-Sari Store', contactNumber: '09123456873', creditLimit: 30000, customerType: 'regular', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 120)), updatedAt: DateTime.now().subtract(const Duration(days: 8))),
      MockCustomer(id: '153', name: 'Happyroo', businessName: 'Happyroo Supermarket', municipality: 'Bahi', province: 'Gasan', storeType: 'Supermarket', contactNumber: '09123456942', creditLimit: 200000, customerType: 'wholesale', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 85)), updatedAt: DateTime.now().subtract(const Duration(days: 15))),
      MockCustomer(id: '323', name: 'Home Town Drugstore', businessName: 'Home Town Drugstore', municipality: 'Napo', province: 'Sta. Cruz', storeType: 'Pharmacy Store', contactNumber: '09123457012', creditLimit: 150000, customerType: 'wholesale', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 70)), updatedAt: DateTime.now().subtract(const Duration(days: 20))),
      MockCustomer(id: '373', name: 'Sunshine Bakery', businessName: 'Sunshine Bakery', municipality: 'Mabuhay', province: 'Torrijos', storeType: 'Bakery', contactNumber: '09123457062', creditLimit: 55000, customerType: 'regular', status: 'active', createdAt: DateTime.now().subtract(const Duration(days: 40)), updatedAt: DateTime.now().subtract(const Duration(days: 10))),
    ];
  }

  void _calculateMetrics() {
    // Calculate basic metrics
    _totalProducts = _products.length;
    _totalCustomers = _customers.length;
    _lowStockProducts = _products.where((p) => p.currentStock < p.minStock && p.status == 'active').length;
    _totalInventoryValue = _products.fold<double>(0, (sum, p) => sum + (p.currentStock * p.unitPrice));
    _totalCreditExposure = _customers.fold<double>(0, (sum, c) => sum + c.creditLimit);
    _wholesaleCustomers = _customers.where((c) => c.customerType == 'wholesale').length;

    // Calculate municipality distribution
    _municipalityDistribution.clear();
    for (final customer in _customers) {
      _municipalityDistribution[customer.municipality] = (_municipalityDistribution[customer.municipality] ?? 0) + 1;
    }

    // Calculate store type distribution
    _storeTypeDistribution.clear();
    for (final customer in _customers) {
      _storeTypeDistribution[customer.storeType] = (_storeTypeDistribution[customer.storeType] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavigation,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadMockData();
              _calculateMetrics();
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Overview
            _buildKeyMetricsSection(),
            
            const SizedBox(height: 24),
            
            // Charts and Analytics
            Row(
              children: [
                // Municipality Distribution
                Expanded(child: _buildMunicipalityChart()),
                const SizedBox(width: 16),
                // Store Type Distribution
                Expanded(child: _buildStoreTypeChart()),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Low Stock Alert
            _buildLowStockAlert(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActionsSection(),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );

  Widget _buildKeyMetricsSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Overview',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Products', _totalProducts.toString(), Icons.inventory_2, AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Total Customers', _totalCustomers.toString(), Icons.people, AppTheme.accentColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Low Stock', _lowStockProducts.toString(), Icons.warning, AppTheme.warningColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Inventory Value', '₱${_totalInventoryValue.toStringAsFixed(0)}', Icons.account_balance, AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Credit Exposure', '₱${_totalCreditExposure.toStringAsFixed(0)}', Icons.credit_card, AppTheme.warningColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Wholesale', _wholesaleCustomers.toString(), Icons.store, AppTheme.accentColor)),
          ],
        ),
      ],
    );

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );

  Widget _buildMunicipalityChart() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customers by Municipality',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildBarChart(_municipalityDistribution, Colors.blue),
            ),
          ],
        ),
      ),
    );

  Widget _buildStoreTypeChart() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Type Distribution',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildBarChart(_storeTypeDistribution, Colors.green),
            ),
          ],
        ),
      ),
    );

  Widget _buildBarChart(Map<String, int> data, Color color) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: data.entries.map((entry) {
        final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLowStockAlert() {
    if (_lowStockProducts == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  '$_lowStockProducts products need restocking',
                  style: const TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to low stock details
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to low stock details')),
                  );
                },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show top 3 low stock items
            ..._products
                .where((p) => p.currentStock < p.minStock && p.status == 'active')
                .take(3)
                .map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.name} (${product.sku})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${product.currentStock}/${product.minStock}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add Product',
                Icons.add_shopping_cart,
                AppTheme.primaryColor,
                () {
                  // TODO: Navigate to add product
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to add product')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Add Customer',
                Icons.person_add,
                AppTheme.accentColor,
                () {
                  // TODO: Navigate to add customer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to add customer')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View All Products',
                Icons.inventory_2,
                Colors.grey.shade600,
                () {
                  // TODO: Navigate to products list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to products list')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View All Customers',
                Icons.people,
                Colors.grey.shade600,
                () {
                  // TODO: Navigate to customers list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to customers list')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) => ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );

  Widget _buildRecentActivitySection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Mock recent activities
            _buildActivityItem('Product Added', 'Beer na Beer 330ml', '2 hours ago', Icons.add_shopping_cart),
            _buildActivityItem('Customer Added', 'Kathlyn Joy Sienna', '5 hours ago', Icons.person_add),
            _buildActivityItem('Product Updated', 'RC Cola Drink 240ml', '1 day ago', Icons.edit),
            _buildActivityItem('Low Stock Alert', 'Super Tibay 2in1', '2 days ago', Icons.warning),
          ],
        ),
      ),
    );

  Widget _buildActivityItem(String action, String item, String time, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
}
