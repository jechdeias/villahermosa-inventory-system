import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import 'customer_form_screen.dart';

// Mock Customer class for web testing
class MockCustomer {
  final String id;
  final String name;
  final String businessName;
  final String municipality;
  final String province;
  final String storeType;
  final String? contactNumber;
  final String? email;
  final String? address;
  final double creditLimit;
  final String customerType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MockCustomer({
    required this.id,
    required this.name,
    required this.businessName,
    required this.municipality,
    required this.province,
    required this.storeType,
    this.contactNumber,
    this.email,
    this.address,
    required this.creditLimit,
    required this.customerType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

class CustomerListScreenMock extends StatefulWidget {
  const CustomerListScreenMock({super.key});

  @override
  State<CustomerListScreenMock> createState() => _CustomerListScreenMockState();
}

class _CustomerListScreenMockState extends State<CustomerListScreenMock> {
  List<MockCustomer> _customers = [];
  List<MockCustomer> _filteredCustomers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedMunicipality = 'All';
  String _selectedStoreType = 'All';

  @override
  void initState() {
    super.initState();
    _loadMockCustomers();
  }

  void _loadMockCustomers() {
    setState(() => _isLoading = true);
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final mockCustomers = [
        // Boac Customers
        MockCustomer(
          id: '1',
          name: 'Anding Maningas',
          businessName: 'ABC Market',
          municipality: 'Boac',
          province: 'Marinduque',
          storeType: 'Market Stall',
          contactNumber: '09123456789',
          creditLimit: 50000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        MockCustomer(
          id: '2',
          name: 'Arnold',
          businessName: 'ABC Market',
          municipality: 'Boac',
          province: 'Marinduque',
          storeType: 'Market Stall',
          contactNumber: '09123456790',
          creditLimit: 45000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 300)),
          updatedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        MockCustomer(
          id: '3',
          name: 'Emely Almanza',
          businessName: 'ABC Market',
          municipality: 'Boac',
          province: 'Marinduque',
          storeType: 'Market Stall',
          contactNumber: '09123456791',
          creditLimit: 60000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 280)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        MockCustomer(
          id: '9',
          name: 'Paglinawan Store',
          businessName: 'Paglinawan Store',
          municipality: 'Amoingon',
          province: 'Boac',
          storeType: 'Market Stall',
          contactNumber: '09123456798',
          creditLimit: 35000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        MockCustomer(
          id: '10',
          name: 'Sherly',
          businessName: 'Sherly Store',
          municipality: 'Amoingon',
          province: 'Boac',
          storeType: 'Sari-Sari Store',
          contactNumber: '09123456799',
          creditLimit: 25000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        MockCustomer(
          id: '11',
          name: 'GMART',
          businessName: 'GMART',
          municipality: 'Balaring',
          province: 'Boac',
          storeType: 'Mini Mart',
          contactNumber: '09123456800',
          creditLimit: 100000.00,
          customerType: 'wholesale',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 150)),
          updatedAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        MockCustomer(
          id: '66',
          name: 'Black Mustache',
          businessName: 'Black Mustache Coffee',
          municipality: 'Poblacion',
          province: 'Boac',
          storeType: 'Coffee Shop',
          contactNumber: '09123456855',
          creditLimit: 75000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
        
        // Buenavista Customers
        MockCustomer(
          id: '84',
          name: 'Kathlyn Joy Sienna',
          businessName: 'Kathlyn Store',
          municipality: 'Bagtingon',
          province: 'Buenavista',
          storeType: 'Sari-Sari Store',
          contactNumber: '09123456873',
          creditLimit: 30000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        MockCustomer(
          id: '85',
          name: 'Mayeth',
          businessName: 'Mayeth Store',
          municipality: 'Bagtingon',
          province: 'Buenavista',
          storeType: 'Sari-Sari Store',
          contactNumber: '09123456874',
          creditLimit: 28000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 110)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        
        // Gasan Customers
        MockCustomer(
          id: '144',
          name: 'Apolinario Sapunggan',
          businessName: 'Sapungan Store',
          municipality: 'Antipolo',
          province: 'Gasan',
          storeType: 'Sari-Sari Store',
          contactNumber: '09123456933',
          creditLimit: 32000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 95)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        MockCustomer(
          id: '153',
          name: 'Happyroo',
          businessName: 'Happyroo Supermarket',
          municipality: 'Bahi',
          province: 'Gasan',
          storeType: 'Supermarket',
          contactNumber: '09123456942',
          creditLimit: 200000.00,
          customerType: 'wholesale',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 85)),
          updatedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        
        // Sta. Cruz Customers
        MockCustomer(
          id: '323',
          name: 'Home Town Drugstore',
          businessName: 'Home Town Drugstore',
          municipality: 'Napo',
          province: 'Sta. Cruz',
          storeType: 'Pharmacy Store',
          contactNumber: '09123457012',
          creditLimit: 150000.00,
          customerType: 'wholesale',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 70)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        MockCustomer(
          id: '324',
          name: 'Xpress Mini Mart',
          businessName: 'Xpress Mini Mart',
          municipality: 'Napo',
          province: 'Sta. Cruz',
          storeType: 'Mini Mart',
          contactNumber: '09123457013',
          creditLimit: 80000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now().subtract(const Duration(days: 18)),
        ),
        
        // Torrijos Customers
        MockCustomer(
          id: '357',
          name: 'Lyka Mae Rey',
          businessName: 'Rey Store',
          municipality: 'Basyao',
          province: 'Torrijos',
          storeType: 'Sari-Sari Store',
          contactNumber: '09123457046',
          creditLimit: 25000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
        MockCustomer(
          id: '373',
          name: 'Sunshine Bakery',
          businessName: 'Sunshine Bakery',
          municipality: 'Mabuhay',
          province: 'Torrijos',
          storeType: 'Bakery',
          contactNumber: '09123457062',
          creditLimit: 55000.00,
          customerType: 'regular',
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 40)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        
        // Inactive customer for testing
        MockCustomer(
          id: '999',
          name: 'Test Inactive Customer',
          businessName: 'Test Store',
          municipality: 'Test',
          province: 'Test',
          storeType: 'Sari-Sari Store',
          contactNumber: '09123459999',
          creditLimit: 0.00,
          customerType: 'regular',
          status: 'inactive',
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now().subtract(const Duration(days: 200)),
        ),
      ];
      
      setState(() {
        _customers = mockCustomers;
        _filteredCustomers = mockCustomers;
        _isLoading = false;
      });
    });
  }

  void _filterCustomers() {
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        final matchesSearch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           customer.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           customer.contactNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
        final matchesMunicipality = _selectedMunicipality == 'All' || customer.municipality == _selectedMunicipality;
        final matchesStoreType = _selectedStoreType == 'All' || customer.storeType == _selectedStoreType;
        final matchesStatus = customer.status == 'active'; // Only show active customers by default
        return matchesSearch && matchesMunicipality && matchesStoreType && matchesStatus;
      }).toList();
    });
  }

  void _showAddCustomerDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerFormScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadMockCustomers(); // Refresh the list
      }
    });
  }

  void _showCustomerDetails(MockCustomer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customerId: customer.id),
      ),
    ).then((result) {
      if (result == true) {
        _loadMockCustomers(); // Refresh the list
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavigation,
        title: const Text(
          'Customers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCustomerDialog,
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterCustomers();
                  },
                ),
                const SizedBox(height: 12),
                // Municipality Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Boac', 'Buenavista', 'Gasan', 'Sta. Cruz', 'Torrijos'].map((municipality) {
                      final isSelected = municipality == _selectedMunicipality;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(municipality),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMunicipality = municipality;
                            });
                            _filterCustomers();
                          },
                          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Store Type Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Sari-Sari Store', 'Market Stall', 'Mini Mart', 'Supermarket', 'Coffee Shop', 'Pharmacy Store', 'Bakery'].map((storeType) {
                      final isSelected = storeType == _selectedStoreType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(storeType),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStoreType = storeType;
                            });
                            _filterCustomers();
                          },
                          backgroundColor: isSelected ? AppTheme.accentColor : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Customer Statistics
          _buildCustomerStats(),
          // Customers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStats() {
    final totalCustomers = _customers.where((c) => c.status == 'active').length;
    final wholesaleCustomers = _customers.where((c) => c.status == 'active' && c.customerType == 'wholesale').length;
    final totalCreditLimit = _customers.where((c) => c.status == 'active').fold<double>(0, (sum, c) => sum + c.creditLimit);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total Customers', totalCustomers.toString(), Icons.people),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Wholesale', wholesaleCustomers.toString(), Icons.store),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Total Credit', '₱${totalCreditLimit.toStringAsFixed(0)}', Icons.account_balance),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first customer to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddCustomerDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return CustomerCard(
          customer: customer,
          onTap: () => _showCustomerDetails(customer),
        );
      },
    );
  }
}

class CustomerCard extends StatelessWidget {
  final MockCustomer customer;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customerTypeColor = customer.customerType == 'wholesale' ? AppTheme.accentColor : AppTheme.primaryColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.businessName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customer.municipality}, ${customer.province}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (customer.contactNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            customer.contactNumber!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customerTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          customer.customerType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: customerTypeColor,
                          ),
                        ),
                        Text(
                          customer.storeType,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: customerTypeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credit Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.storeType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
