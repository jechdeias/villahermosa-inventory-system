/// Delivery Confirmation Screen
/// 
/// UI for confirming deliveries using multiple methods:
/// - Manual button confirmation
/// - One-time delivery code entry
/// - QR scanning (future implementation)
/// 
/// This screen provides an extensible confirmation flow that works
/// without camera access or QR dependencies.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/delivery_viewmodel.dart';

class DeliveryConfirmationScreen extends StatelessWidget {
  const DeliveryConfirmationScreen({
    required this.deliveryId, required this.customerName, required this.deliveryAddress, super.key,
  });

  final String deliveryId;
  final String customerName;
  final String deliveryAddress;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => DeliveryViewModel(),
      child: DeliveryConfirmationView(
        deliveryId: deliveryId,
        customerName: customerName,
        deliveryAddress: deliveryAddress,
      ),
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('deliveryId', deliveryId));
    properties.add(StringProperty('customerName', customerName));
    properties.add(StringProperty('deliveryAddress', deliveryAddress));
  }
}

class DeliveryConfirmationView extends StatefulWidget {
  const DeliveryConfirmationView({
    required this.deliveryId, required this.customerName, required this.deliveryAddress, super.key,
  });

  final String deliveryId;
  final String customerName;
  final String deliveryAddress;

  @override
  State<DeliveryConfirmationView> createState() => _DeliveryConfirmationViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('deliveryId', deliveryId));
    properties.add(StringProperty('customerName', customerName));
    properties.add(StringProperty('deliveryAddress', deliveryAddress));
  }
}

class _DeliveryConfirmationViewState extends State<DeliveryConfirmationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  bool _codeGenerated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Generate delivery code on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateDeliveryCode();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateDeliveryCode() async {
    final deliveryViewModel = context.read<DeliveryViewModel>();
    await deliveryViewModel.generateDeliveryCode(widget.deliveryId);
    setState(() {
      _codeGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryViewModel = context.watch<DeliveryViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: 'Manual'),
            Tab(icon: Icon(Icons.code), text: 'Code'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR (Future)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualConfirmation(deliveryViewModel),
          _buildCodeConfirmation(deliveryViewModel),
          _buildQRConfirmation(deliveryViewModel),
        ],
      ),
    );
  }

  Widget _buildManualConfirmation(DeliveryViewModel viewModel) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Delivery Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Delivery ID', widget.deliveryId),
                  _buildInfoRow('Customer', widget.customerName),
                  _buildInfoRow('Address', widget.deliveryAddress),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Manual Confirmation Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Confirmation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Confirm this delivery has been successfully completed and delivered to the customer.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _confirmManually(viewModel),
                      icon: viewModel.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(viewModel.isLoading
                          ? 'Confirming...'
                          : 'Confirm Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildCodeConfirmation(DeliveryViewModel viewModel) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Delivery Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Delivery ID', widget.deliveryId),
                  _buildInfoRow('Customer', widget.customerName),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Code Confirmation Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Code Confirmation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  
                  // Generated Code Display
                  if (_codeGenerated && viewModel.generatedDeliveryCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Share this code with customer:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            viewModel.generatedDeliveryCode!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          TextButton(
                            onPressed: _generateDeliveryCode,
                            child: const Text('Generate New Code'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (viewModel.isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    const Text('Generating delivery code...'),
                  ],
                  
                  const Divider(),
                  
                  const Text(
                    'Enter confirmation code provided by customer:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmation Code',
                      border: OutlineInputBorder(),
                      hintText: 'Enter 6-digit code',
                    ),
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.length == 6) {
                        _validateCode(viewModel, value);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_codeController.text.length == 6 && !viewModel.isLoading)
                          ? () => _confirmByCode(viewModel)
                          : null,
                      icon: viewModel.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified),
                      label: Text(viewModel.isLoading
                          ? 'Validating...'
                          : 'Confirm with Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildQRConfirmation(DeliveryViewModel viewModel) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QR Code Scanning',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'QR code scanning will be available in a future update.\n\n'
                    'For now, please use Manual Confirmation or Delivery Code methods.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TODO: QR scanning will be integrated when qr_code_scanner dependency is restored',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildInfoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );

  Future<void> _confirmManually(DeliveryViewModel viewModel) async {
    await viewModel.confirmDeliveryByButton(widget.deliveryId);
    
    if (viewModel.error == null) {
      _showSuccessDialog('Manual Confirmation', 'Delivery confirmed successfully!');
    }
  }

  Future<void> _confirmByCode(DeliveryViewModel viewModel) async {
    await viewModel.confirmDeliveryByCode(widget.deliveryId, _codeController.text);
    
    if (viewModel.error == null) {
      _showSuccessDialog('Code Confirmation', 'Delivery confirmed with code successfully!');
    }
  }

  Future<void> _validateCode(DeliveryViewModel viewModel, String code) async {
    await viewModel.validateDeliveryCode(widget.deliveryId, code);
  }

  void _showSuccessDialog(String method, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
