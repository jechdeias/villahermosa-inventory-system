import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_theme.dart';

class CustomerFormScreen extends StatefulWidget { // null for new customer, ID for editing
  
  const CustomerFormScreen({
    super.key,
    this.customerId,
  });
  final String? customerId;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('customerId', customerId));
  }
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMunicipality = 'Boac';
  String _selectedProvince = 'Marinduque';
  String _selectedStoreType = 'Sari-Sari Store';
  String _selectedCustomerType = 'regular';
  String _selectedStatus = 'active';
  bool _isLoading = false;

  final List<String> _municipalities = [
    'Boac', 'Buenavista', 'Gasan', 'Sta. Cruz', 'Torrijos'
  ];
  
  final List<String> _provinces = [
    'Marinduque'
  ];
  
  final List<String> _storeTypes = [
    'Sari-Sari Store', 'Market Stall', 'Mini Mart', 'Supermarket', 
    'Coffee Shop', 'Pharmacy Store', 'Bakery', 'Grocery Store',
    'Wholesaler', 'Eatery'
  ];
  
  final List<String> _customerTypes = [
    'regular', 'wholesale', 'vip'
  ];
  
  final List<String> _statuses = [
    'active', 'inactive', 'suspended'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomerData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadCustomerData() {
    // TODO: Load actual customer data from database
    // For now, populate with sample data for demo
    _nameController.text = 'Anding Maningas';
    _businessNameController.text = 'ABC Market';
    _contactNumberController.text = '09123456789';
    _creditLimitController.text = '50000.00';
    _selectedMunicipality = 'Boac';
    _selectedProvince = 'Marinduque';
    _selectedStoreType = 'Market Stall';
    _selectedCustomerType = 'regular';
    _selectedStatus = 'active';
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Save to database
      await Future.delayed(const Duration(seconds: 1)); // Simulate save

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customerId == null ? 'Customer added successfully!' : 'Customer updated successfully!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerId != null;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavigation,
        title: Text(
          isEditing ? 'Edit Customer' : 'Add Customer',
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
              tooltip: 'Delete Customer',
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
              
              // Business Information Section
              _buildSectionHeader('Business Information'),
              const SizedBox(height: 16),
              _buildBusinessInfoSection(),
              
              const SizedBox(height: 32),
              
              // Location Section
              _buildSectionHeader('Location'),
              const SizedBox(height: 16),
              _buildLocationSection(),
              
              const SizedBox(height: 32),
              
              // Credit & Status Section
              _buildSectionHeader('Credit & Status'),
              const SizedBox(height: 16),
              _buildCreditStatusSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
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
                      : Text(isEditing ? 'Update Customer' : 'Add Customer'),
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
                Expanded(child: _buildTextField(_nameController, 'Customer Name*', required: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_businessNameController, 'Business Name*', required: true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_contactNumberController, 'Contact Number', keyboardType: TextInputType.phone)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_addressController, 'Address', maxLines: 2),
          ],
        ),
      ),
    );

  Widget _buildBusinessInfoSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdownField('Store Type*', _selectedStoreType, _storeTypes, (value) => setState(() => _selectedStoreType = value))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownField('Customer Type*', _selectedCustomerType, _customerTypes, (value) => setState(() => _selectedCustomerType = value))),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_notesController, 'Notes', maxLines: 3),
          ],
        ),
      ),
    );

  Widget _buildLocationSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdownField('Municipality*', _selectedMunicipality, _municipalities, (value) => setState(() => _selectedMunicipality = value))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownField('Province*', _selectedProvince, _provinces, (value) => setState(() => _selectedProvince = value))),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildCreditStatusSection() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_creditLimitController, 'Credit Limit*', required: true, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownField('Status*', _selectedStatus, _statuses, (value) => setState(() => _selectedStatus = value))),
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
              if (label == 'Email' && value.isNotEmpty) {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
              }
              if (label == 'Contact Number' && value.isNotEmpty) {
                final phoneRegex = RegExp(r'^[0-9]{10,11}$');
                if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
                  return 'Please enter a valid phone number';
                }
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
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCustomer();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Delete from database
      await Future.delayed(const Duration(seconds: 1)); // Simulate delete

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer deleted successfully!'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
