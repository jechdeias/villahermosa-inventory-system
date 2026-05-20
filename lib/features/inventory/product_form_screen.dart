import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth/auth_service.dart';
import '../../core/database/app_database.dart';
import '../../shared/theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget { // null for new product, ID for editing
  
  const ProductFormScreen({
    super.key,
    this.productId,
  });
  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('productId', productId));
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _unitPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _currentStockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');
  final _maxStockController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _locationController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _tagsController = TextEditingController();
  final _supplierController = TextEditingController();
  final _supplierSkuController = TextEditingController();
  final _leadTimeController = TextEditingController();

  String _selectedStatus = 'active';
  String _selectedCurrency = 'PHP';
  bool _isLoading = false;

  final List<String> _statuses = ['active', 'inactive', 'discontinued'];
  final List<String> _currencies = ['PHP', 'USD', 'EUR'];
  final List<String> _categories = [
    'Electronics', 'Furniture', 'Office Supplies', 'Computer Accessories',
    'Appliances', 'Stationery', 'Storage', 'Lighting', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData(); // async — setState called inside when ready
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    _costPriceController.dispose();
    _wholesalePriceController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _locationController.dispose();
    _barcodeController.dispose();
    _tagsController.dispose();
    _supplierController.dispose();
    _supplierSkuController.dispose();
    _leadTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    final db = AuthService.instance.database;
    final product = await db.getProductById(int.tryParse(widget.productId ?? '') ?? 0);
    if (product == null || !mounted) return;
    setState(() {
      _skuController.text = product.sku;
      _nameController.text = product.name;
      _categoryController.text = product.category;
      _unitPriceController.text = product.unitPrice.toString();
      _costPriceController.text = product.costPrice.toString();
      _currentStockController.text = product.currentStock.toString();
      _minStockController.text = product.minStock.toString();
      _locationController.text = product.location ?? '';
      _selectedStatus = product.status;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = AuthService.instance.database;
      final isNew = widget.productId == null;
      final companion = ProductsCompanion(
        sku: Value(_skuController.text.trim()),
        name: Value(_nameController.text.trim()),
        category: Value(_categoryController.text.trim().isEmpty ? 'Other' : _categoryController.text.trim()),
        unitPrice: Value(double.tryParse(_unitPriceController.text) ?? 0),
        costPrice: Value(double.tryParse(_costPriceController.text) ?? 0),
        unit: Value(_unitController.text.trim().isEmpty ? 'pcs' : _unitController.text.trim()),
        currentStock: Value(int.tryParse(_currentStockController.text) ?? 0),
        minStock: Value(int.tryParse(_minStockController.text) ?? 0),
        status: Value(_selectedStatus),
        location: Value(_locationController.text.trim().isEmpty ? null : _locationController.text.trim()),
        syncStatus: const Value('pending'),
        uuid: Value(const Uuid().v4()),
      );

      if (isNew) {
        await db.createProduct(companion);
      } else {
        final id = int.tryParse(widget.productId!);
        final existing = id != null ? await db.getProductById(id) : null;
        if (existing != null) {
          await db.updateProduct(existing.uuid, companion);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? 'Product added successfully!' : 'Product updated successfully!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavigation,
        title: Text(
          isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _showDeleteConfirmDialog,
              tooltip: 'Delete Product',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              _buildBasicInfoSection(),
              
              const SizedBox(height: 32),
              
              // Pricing Section
              _buildSectionHeader('Pricing'),
              const SizedBox(height: 16),
              _buildPricingSection(),
              
              const SizedBox(height: 32),
              
              // Inventory Section
              _buildSectionHeader('Inventory'),
              const SizedBox(height: 16),
              _buildInventorySection(),
              
              const SizedBox(height: 32),
              
              // Physical Properties Section
              _buildSectionHeader('Physical Properties'),
              const SizedBox(height: 16),
              _buildPhysicalPropertiesSection(),
              
              const SizedBox(height: 32),
              
              // Supplier Section
              _buildSectionHeader('Supplier Information'),
              const SizedBox(height: 16),
              _buildSupplierSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isEditing ? 'Update Product' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
      title,
      style: AppTheme.headingMedium.copyWith(
        color: AppTheme.primaryColor,
      ),
    );

  Widget _buildBasicInfoSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_skuController, 'SKU*', required: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownField('Status*', _selectedStatus, _statuses, (value) => setState(() => _selectedStatus = value))),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Product Name*', required: true),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description', maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdownField('Category*', _categoryController.text.isEmpty ? 'Electronics' : _categoryController.text, _categories, (value) => _categoryController.text = value)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_brandController, 'Brand')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_unitController, 'Unit')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_locationController, 'Location')),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_barcodeController, 'Barcode'),
            const SizedBox(height: 16),
            _buildTextField(_tagsController, 'Tags (comma-separated)'),
          ],
        ),
      ),
    );

  Widget _buildPricingSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdownField('Currency', _selectedCurrency, _currencies, (value) => setState(() => _selectedCurrency = value))),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_unitPriceController, 'Unit Price*', required: true, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_costPriceController, 'Cost Price*', required: true, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_wholesalePriceController, 'Wholesale Price', keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildInventorySection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_currentStockController, 'Current Stock*', required: true, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_minStockController, 'Min Stock*', required: true, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_maxStockController, 'Max Stock', keyboardType: TextInputType.number),
          ],
        ),
      ),
    );

  Widget _buildPhysicalPropertiesSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_weightController, 'Weight (kg)', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_lengthController, 'Length (cm)', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_widthController, 'Width (cm)', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_heightController, 'Height (cm)', keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildSupplierSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_supplierController, 'Supplier Name'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_supplierSkuController, 'Supplier SKU')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_leadTimeController, 'Lead Time (days)', keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              if (keyboardType == TextInputType.number && value.isNotEmpty) {
                final number = double.tryParse(value);
                if (number == null) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            }
          : null,
    );

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) => DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    setState(() => _isLoading = true);

    try {
      final db = AuthService.instance.database;
      final id = int.tryParse(widget.productId ?? '');
      final existing = id != null ? await db.getProductById(id) : null;
      if (existing != null) {
        await db.softDeleteProduct(existing.uuid);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!'), backgroundColor: AppTheme.errorColor),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
