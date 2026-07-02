import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../providers/customers_provider.dart';
import '../services/customers_service.dart';

class AddCustomerPanel extends ConsumerStatefulWidget {
  const AddCustomerPanel({super.key, required this.onClose, this.editing});
  final VoidCallback onClose;
  final Customer? editing;

  @override
  ConsumerState<AddCustomerPanel> createState() => _AddCustomerPanelState();
}

class _AddCustomerPanelState extends ConsumerState<AddCustomerPanel> {
  late final _nameCtrl = TextEditingController(text: widget.editing?.name ?? '');
  late final _businessNameCtrl = TextEditingController(text: widget.editing?.businessName ?? '');
  late final _contactCtrl = TextEditingController(text: widget.editing?.contactNumber ?? '');
  late final _barangayCtrl = TextEditingController(text: widget.editing?.barangay ?? '');
  late final _creditLimitCtrl = TextEditingController(text: '${widget.editing?.creditLimit ?? 0}');
  String? _town;
  String? _channel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _town = widget.editing?.town;
    _channel = widget.editing?.channel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessNameCtrl.dispose();
    _contactCtrl.dispose();
    _barangayCtrl.dispose();
    _creditLimitCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.editing != null;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snackErr('Store name is required');
      return;
    }
    if (_town == null) {
      _snackErr('Please select a town');
      return;
    }
    if (_channel == null) {
      _snackErr('Please select a channel');
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(customersServiceProvider);
      final companion = CustomersCompanion(
        name: Value(_nameCtrl.text.trim()),
        businessName: Value(_businessNameCtrl.text.trim().isEmpty ? null : _businessNameCtrl.text.trim()),
        contactNumber: Value(_contactCtrl.text.trim()),
        barangay: Value(_barangayCtrl.text.trim().isEmpty ? null : _barangayCtrl.text.trim()),
        town: Value(_town),
        municipality: Value(_town!),
        province: const Value('Marinduque'),
        channel: Value(_channel),
        storeType: Value(_channel!),
        creditLimit: Value(double.tryParse(_creditLimitCtrl.text.trim()) ?? 0),
      );

      if (_isEditing) {
        await service.updateCustomer(widget.editing!.uuid, companion);
      } else {
        await service.createCustomer(companion.copyWith(uuid: Value(const Uuid().v4())));
      }

      widget.onClose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Customer updated' : 'Customer added')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snackErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('STORE INFO'),
                  const SizedBox(height: 10),
                  TextField(controller: _nameCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Store Name')),
                  const SizedBox(height: 10),
                  TextField(controller: _businessNameCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Owner / Business Name')),
                  const SizedBox(height: 10),
                  TextField(controller: _contactCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Contact Number')),
                  const SizedBox(height: 10),
                  TextField(controller: _barangayCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Barangay')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: _dec('Town'),
                    isExpanded: true,
                    initialValue: _town,
                    items: kCustomerTowns.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _town = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: _dec('Channel'),
                    isExpanded: true,
                    initialValue: _channel,
                    items: kCustomerChannels.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _channel = v),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('CREDIT'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _creditLimitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: _dec('Credit Limit').copyWith(prefixText: '₱'),
                  ),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(
        child: Text(_isEditing ? 'Edit Customer' : 'Add Customer',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ),
      GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
    ]),
  );

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _saving ? null : widget.onClose,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            foregroundColor: const Color(0xFF374151),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Customer', style: TextStyle(fontSize: 13)),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6B7280))),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  );
}
