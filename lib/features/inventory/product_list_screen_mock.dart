import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import 'product_form_screen.dart';

// Mock Product class for web testing
class MockProduct {

  MockProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.costPrice,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.status,
    this.location,
  });
  final String id;
  final String sku;
  final String name;
  final String category;
  final double unitPrice;
  final double costPrice;
  final String unit;
  final int currentStock;
  final int minStock;
  final String status;
  final String? location;
}

class ProductListScreenMock extends StatefulWidget {
  const ProductListScreenMock({super.key});

  @override
  State<ProductListScreenMock> createState() => _ProductListScreenMockState();
}

class _ProductListScreenMockState extends State<ProductListScreenMock> {
  List<MockProduct> _products = [];
  List<MockProduct> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMockProducts();
  }

  void _loadMockProducts() {
    setState(() => _isLoading = true);
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final realProducts = [
        // Beer & Alcoholic Beverages
        MockProduct(id: '1', sku: 'BNB', name: 'Beer na Beer 330ml', category: 'Beer', unitPrice: 750, costPrice: 600, unit: 'cs', currentStock: 50, minStock: 20, status: 'active', location: 'Warehouse A'),
        MockProduct(id: '2', sku: 'BNB MACHO', name: 'Beer na Beer 1000ml', category: 'Beer', unitPrice: 555, costPrice: 450, unit: 'cs', currentStock: 30, minStock: 15, status: 'active', location: 'Warehouse A'),
        MockProduct(id: '3', sku: 'C ASTIG-G', name: 'Cobra Astig - Green', category: 'Energy Drink', unitPrice: 208, costPrice: 170, unit: 'cs', currentStock: 100, minStock: 50, status: 'active', location: 'Warehouse B'),
        MockProduct(id: '4', sku: 'C ASTIG-R', name: 'Cobra Astig - Red', category: 'Energy Drink', unitPrice: 208, costPrice: 170, unit: 'cs', currentStock: 95, minStock: 50, status: 'active', location: 'Warehouse B'),
        MockProduct(id: '5', sku: 'C ASTIG-Y', name: 'Cobra Astig - Yellow', category: 'Energy Drink', unitPrice: 208, costPrice: 170, unit: 'cs', currentStock: 90, minStock: 50, status: 'active', location: 'Warehouse B'),
        
        // Energy Drinks
        MockProduct(id: '6', sku: 'CED-ASSTD', name: 'Cobra Energy Drink Assorted', category: 'Energy Drink', unitPrice: 306, costPrice: 250, unit: 'cs', currentStock: 60, minStock: 30, status: 'active', location: 'Warehouse B'),
        MockProduct(id: '7', sku: 'CED-G', name: 'Cobra Energy Drink Green', category: 'Energy Drink', unitPrice: 306, costPrice: 250, unit: 'cs', currentStock: 45, minStock: 30, status: 'active', location: 'Warehouse B'),
        MockProduct(id: '8', sku: 'CED-R', name: 'Cobra Energy Drink Red', category: 'Energy Drink', unitPrice: 306, costPrice: 250, unit: 'cs', currentStock: 50, minStock: 30, status: 'active', location: 'Warehouse B'),
        MockProduct(id: '9', sku: 'CED-Y', name: 'Cobra Energy Drink Yellow', category: 'Energy Drink', unitPrice: 306, costPrice: 250, unit: 'cs', currentStock: 55, minStock: 30, status: 'active', location: 'Warehouse B'),
        
        // Premium Beer
        MockProduct(id: '10', sku: 'COLT330', name: 'Colt 45 330ml', category: 'Beer', unitPrice: 740, costPrice: 600, unit: 'cs', currentStock: 40, minStock: 20, status: 'active', location: 'Warehouse A'),
        MockProduct(id: '11', sku: 'COLT500', name: 'Colt 45 500ml', category: 'Beer', unitPrice: 500, costPrice: 400, unit: 'cs', currentStock: 35, minStock: 20, status: 'active', location: 'Warehouse A'),
        
        // Spirits
        MockProduct(id: '15', sku: 'GIN', name: 'Gin Kapitan 200ml', category: 'Liquor', unitPrice: 1199, costPrice: 950, unit: 'cs', currentStock: 25, minStock: 10, status: 'active', location: 'Warehouse C'),
        MockProduct(id: '22', sku: 'TIGER 300ML', name: 'TIGER LIGHT 300ML', category: 'Beer', unitPrice: 1287, costPrice: 1000, unit: 'cs', currentStock: 30, minStock: 15, status: 'active', location: 'Warehouse A'),
        MockProduct(id: '23', sku: 'TIGER 500ML', name: 'TIGER IN CAN 500ML', category: 'Beer', unitPrice: 1513, costPrice: 1200, unit: 'cs', currentStock: 20, minStock: 10, status: 'active', location: 'Warehouse A'),
        MockProduct(id: '24', sku: 'HEINEKEN 330ML', name: 'Heineken 330ml', category: 'Beer', unitPrice: 1488, costPrice: 1200, unit: 'cs', currentStock: 28, minStock: 15, status: 'active', location: 'Warehouse A'),
        
        // Juice Drinks
        MockProduct(id: '25', sku: 'NESTEA-A 350ML', name: 'Nestea 350ml - Apple', category: 'Juice', unitPrice: 493, costPrice: 400, unit: 'cs', currentStock: 80, minStock: 40, status: 'active', location: 'Warehouse D'),
        MockProduct(id: '26', sku: 'NESTEA-L 350ML', name: 'Nestea 350ml - Lemon', category: 'Juice', unitPrice: 493, costPrice: 400, unit: 'cs', currentStock: 75, minStock: 40, status: 'active', location: 'Warehouse D'),
        
        // Water
        MockProduct(id: '27', sku: 'AB350', name: 'Absolute Drinking Water 350ml', category: 'Water', unitPrice: 379, costPrice: 300, unit: 'cs', currentStock: 200, minStock: 100, status: 'active', location: 'Warehouse E'),
        MockProduct(id: '28', sku: 'AB500', name: 'Absolute Drinking Water 500ml', category: 'Water', unitPrice: 359, costPrice: 280, unit: 'cs', currentStock: 180, minStock: 100, status: 'active', location: 'Warehouse E'),
        MockProduct(id: '29', sku: 'AB1000', name: 'Absolute Drinking Water 1000ml', category: 'Water', unitPrice: 281, costPrice: 220, unit: 'cs', currentStock: 150, minStock: 80, status: 'active', location: 'Warehouse E'),
        MockProduct(id: '30', sku: 'AB1500', name: 'Absolute Drinking Water 1500ml', category: 'Water', unitPrice: 382, costPrice: 300, unit: 'cs', currentStock: 120, minStock: 60, status: 'active', location: 'Warehouse E'),
        
        // Summit Water
        MockProduct(id: '36', sku: 'SU1000', name: 'Summit Purified Drinking Water 1000ml', category: 'Water', unitPrice: 195, costPrice: 150, unit: 'cs', currentStock: 140, minStock: 70, status: 'active', location: 'Warehouse E'),
        MockProduct(id: '37', sku: 'SU1500', name: 'Summit Purified Drinking Water 1500ml', category: 'Water', unitPrice: 272, costPrice: 210, unit: 'cs', currentStock: 110, minStock: 55, status: 'active', location: 'Warehouse E'),
        MockProduct(id: '38', sku: 'SU350', name: 'Summit Purified Drinking Water 350ml', category: 'Water', unitPrice: 250, costPrice: 190, unit: 'cs', currentStock: 160, minStock: 80, status: 'active', location: 'Warehouse E'),
        MockProduct(id: '39', sku: 'SU500', name: 'Summit Purified Drinking Water 500ml', category: 'Water', unitPrice: 217, costPrice: 165, unit: 'cs', currentStock: 145, minStock: 72, status: 'active', location: 'Warehouse E'),
        
        // Milk Products
        MockProduct(id: '41', sku: 'VM 110ML', name: 'Vitamilk Soya Drink 110ml - Double Choco', category: 'Milk', unitPrice: 540, costPrice: 420, unit: 'cs', currentStock: 60, minStock: 30, status: 'active', location: 'Warehouse F'),
        MockProduct(id: '42', sku: 'VM BANANA', name: 'Vitamilk Soya Drink 300ml - Banana', category: 'Milk', unitPrice: 700, costPrice: 550, unit: 'cs', currentStock: 45, minStock: 25, status: 'active', location: 'Warehouse F'),
        MockProduct(id: '43', sku: 'VM CHOCO', name: 'Vitamilk Soya Drink 300ml - Choco', category: 'Milk', unitPrice: 700, costPrice: 550, unit: 'cs', currentStock: 50, minStock: 25, status: 'active', location: 'Warehouse F'),
        
        // RC Cola Products
        MockProduct(id: '64', sku: 'RC COLA', name: 'RC Cola Drink 240ml - Cola Flavor', category: 'Soft Drinks', unitPrice: 180, costPrice: 140, unit: 'cs', currentStock: 300, minStock: 150, status: 'active', location: 'Warehouse G'),
        MockProduct(id: '65', sku: 'RC LEMON', name: 'RC Cola Drink 240ml - Lemon Flavor', category: 'Soft Drinks', unitPrice: 180, costPrice: 140, unit: 'cs', currentStock: 280, minStock: 140, status: 'active', location: 'Warehouse G'),
        MockProduct(id: '66', sku: 'RC SODA', name: 'RC Cola Drink 240ml - Soda Flavor', category: 'Soft Drinks', unitPrice: 180, costPrice: 140, unit: 'cs', currentStock: 290, minStock: 145, status: 'active', location: 'Warehouse G'),
        
        // Jersey Products
        MockProduct(id: '94', sku: 'J.CONDENSED 1KG', name: 'Jersey Condensed Milk 1KG', category: 'Milk', unitPrice: 108, costPrice: 85, unit: 'cs', currentStock: 20, minStock: 10, status: 'active', location: 'Warehouse F'),
        MockProduct(id: '95', sku: 'J.CONDENSED 390G', name: 'Jersey Condensed Milk 390g - Plain Flavor', category: 'Milk', unitPrice: 47, costPrice: 37, unit: 'cs', currentStock: 40, minStock: 20, status: 'active', location: 'Warehouse F'),
        MockProduct(id: '101', sku: 'J.ALL PURPOSE', name: 'Jersey All Purpose Cream 250ml', category: 'Milk', unitPrice: 61, costPrice: 48, unit: 'cs', currentStock: 15, minStock: 8, status: 'active', location: 'Warehouse F'),
        
        // Detergent Products
        MockProduct(id: '125', sku: 'POWDET LAVENDER 57G', name: 'Powder Detergent 57g - Lavender', category: 'Detergent', unitPrice: 34.80, costPrice: 27, unit: 'cs', currentStock: 100, minStock: 50, status: 'active', location: 'Warehouse H'),
        MockProduct(id: '126', sku: 'POWDET BLOOMING 57G', name: 'Powder Detergent 57g - Blooming', category: 'Detergent', unitPrice: 34.80, costPrice: 27, unit: 'cs', currentStock: 95, minStock: 48, status: 'active', location: 'Warehouse H'),
        MockProduct(id: '127', sku: 'POWDET POWER 57G', name: 'Powder Detergent 57g - Power', category: 'Detergent', unitPrice: 34.80, costPrice: 27, unit: 'cs', currentStock: 90, minStock: 45, status: 'active', location: 'Warehouse H'),
        
        // Food Products
        MockProduct(id: '186', sku: 'GLUTINOUS', name: 'Kings Glutinous Rice Flour 500g', category: 'Food', unitPrice: 45, costPrice: 35, unit: 'cs', currentStock: 18, minStock: 10, status: 'active', location: 'Warehouse I'),
        MockProduct(id: '187', sku: 'HFBC 150G', name: 'Happy Fiesta Bread Crumbs 150g', category: 'Food', unitPrice: 21, costPrice: 16, unit: 'cs', currentStock: 45, minStock: 25, status: 'active', location: 'Warehouse I'),
        MockProduct(id: '205', sku: 'VERMICELLI 1.59OZ', name: 'Vermicelli Sotanghon 1.59oz', category: 'Food', unitPrice: 6, costPrice: 4.50, unit: 'cs', currentStock: 480, minStock: 240, status: 'active', location: 'Warehouse I'),
        
        // Snack Products
        MockProduct(id: '216', sku: 'ICEPOPS 90ML', name: 'Snow Time Icepops 90ml x 8 x 15', category: 'Snacks', unitPrice: 23, costPrice: 18, unit: 'cs', currentStock: 12, minStock: 6, status: 'active', location: 'Warehouse J'),
        MockProduct(id: '217', sku: 'CHOCO CRUNCH', name: 'Sweet Station Choco Crunch 45\'s x 24', category: 'Snacks', unitPrice: 46, costPrice: 36, unit: 'cs', currentStock: 20, minStock: 10, status: 'active', location: 'Warehouse J'),
        MockProduct(id: '222', sku: 'KOOLERS220ML-A', name: 'Koolers Juice Drink 220ml - Apple', category: 'Juice', unitPrice: 76, costPrice: 60, unit: 'cs', currentStock: 35, minStock: 18, status: 'active', location: 'Warehouse D'),
        
        // Low Stock Items (for testing alerts)
        MockProduct(id: '298', sku: 'S TIBAY TRIAL', name: 'Super Tibay Trial Size', category: 'Cleaning', unitPrice: 13, costPrice: 10, unit: 'cs', currentStock: 5, minStock: 20, status: 'active', location: 'Warehouse K'),
        MockProduct(id: '299', sku: 'S TIBAY SCOURING', name: 'Super Tibay Scouring Regular', category: 'Cleaning', unitPrice: 24, costPrice: 19, unit: 'cs', currentStock: 8, minStock: 25, status: 'active', location: 'Warehouse K'),
        MockProduct(id: '300', sku: 'S TIBAY 2IN1', name: 'Super Tibay 2in1 Economy Size', category: 'Cleaning', unitPrice: 32.40, costPrice: 25, unit: 'cs', currentStock: 3, minStock: 15, status: 'active', location: 'Warehouse K'),
      ];
      
      setState(() {
        _products = realProducts;
        _filteredProducts = realProducts;
        _isLoading = false;
      });
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           product.sku.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showAddProductDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadMockProducts(); // Refresh the list
      }
    });
  }

  void _showProductDetails(MockProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(productId: product.id),
      ),
    ).then((result) {
      if (result == true) {
        _loadMockProducts(); // Refresh the list
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavigation,
        title: const Text(
          'Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddProductDialog,
            tooltip: 'Add Product',
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
                    hintText: 'Search products...',
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
                    _filterProducts();
                  },
                ),
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Beer', 'Energy Drink', 'Liquor', 'Juice', 'Water', 'Milk', 'Soft Drinks', 'Detergent', 'Food', 'Snacks', 'Cleaning'].map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _filterProducts();
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
              ],
            ),
          ),
          // Low Stock Alert
          _buildLowStockAlert(),
          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductsList(),
          ),
        ],
      ),
    );

  Widget _buildLowStockAlert() {
    final lowStockProducts = _products.where((p) => 
      p.currentStock < p.minStock && p.status == 'active'
    ).toList();

    if (lowStockProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${lowStockProducts.length} products need restocking',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Low stock details coming soon!')),
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first product to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddProductDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );

  Widget _buildProductsList() => ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () => _showProductDetails(product),
        );
      },
    );
}

class ProductCard extends StatelessWidget {

  const ProductCard({
    required this.product, required this.onTap, super.key,
  });
  final MockProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.currentStock < product.minStock;
    final stockStatus = isLowStock ? 'Low Stock' : 'In Stock';
    final stockColor = isLowStock ? Colors.red : Colors.green;

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
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          stockStatus,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: stockColor,
                          ),
                        ),
                        Text(
                          '${product.currentStock} / ${product.minStock}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: stockColor,
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
                    '₱${product.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${product.currentStock}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (product.location != null) ...[
                const SizedBox(height: 8),
                Text(
                  '📍 ${product.location}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MockProduct>('product', product));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}
