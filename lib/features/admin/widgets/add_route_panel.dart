import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../providers/customers_provider.dart';
import '../providers/orders_provider.dart' show usersProvider;
import '../services/delivery_routes_service.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class AddRoutePanel extends ConsumerStatefulWidget {
  const AddRoutePanel({super.key, required this.onClose, this.editing});
  final VoidCallback onClose;
  final DeliveryRoute? editing;

  @override
  ConsumerState<AddRoutePanel> createState() => _AddRoutePanelState();
}

class _AddRoutePanelState extends ConsumerState<AddRoutePanel> {
  late final _routeNameCtrl = TextEditingController(text: widget.editing?.routeName ?? '');
  late final _customerCountCtrl = TextEditingController(text: '${widget.editing?.customerCount ?? 0}');
  String? _municipality;
  String? _assignedRepName;
  late Set<String> _selectedDays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _municipality = widget.editing?.municipality;
    _assignedRepName = widget.editing?.assignedRepName;
    _selectedDays = (widget.editing?.deliveryDays.split(',') ?? [])
        .where((d) => d.isNotEmpty)
        .toSet();
  }

  @override
  void dispose() {
    _routeNameCtrl.dispose();
    _customerCountCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.editing != null;

  Future<void> _save() async {
    if (_routeNameCtrl.text.trim().isEmpty) {
      _snackErr('Route name is required');
      return;
    }
    if (_municipality == null) {
      _snackErr('Please select a municipality');
      return;
    }
    if (_selectedDays.isEmpty) {
      _snackErr('Please select at least one delivery day');
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(deliveryRoutesServiceProvider);
      final orderedDays = _days.where(_selectedDays.contains).join(',');
      final companion = DeliveryRoutesCompanion(
        routeName: Value(_routeNameCtrl.text.trim()),
        municipality: Value(_municipality!),
        assignedRepName: Value(_assignedRepName),
        deliveryDays: Value(orderedDays),
        customerCount: Value(int.tryParse(_customerCountCtrl.text.trim()) ?? 0),
      );

      if (_isEditing) {
        await service.updateRoute(widget.editing!.uuid, companion);
      } else {
        await service.createRoute(companion.copyWith(uuid: Value(const Uuid().v4())));
      }

      widget.onClose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Route updated' : 'Route added')),
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
    final reps = (ref.watch(usersProvider).value ?? [])
        .where((u) => u.role == 'sales_rep' || u.role == 'admin')
        .toList();

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
                  _sectionLabel('ROUTE INFO'),
                  const SizedBox(height: 10),
                  TextField(controller: _routeNameCtrl, style: const TextStyle(fontSize: 13), decoration: _dec('Route Name')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: _dec('Municipality'),
                    isExpanded: true,
                    initialValue: _municipality,
                    items: kCustomerTowns.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _municipality = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: _dec('Assigned Rep (optional)'),
                    isExpanded: true,
                    initialValue: _assignedRepName,
                    items: reps.map((u) {
                      final name = '${u.firstName} ${u.lastName}'.trim();
                      return DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() => _assignedRepName = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customerCountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: _dec('Customer Count'),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('DELIVERY DAYS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _days.map((d) {
                      final selected = _selectedDays.contains(d);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedDays.remove(d);
                          } else {
                            _selectedDays.add(d);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF1E1E1E) : Colors.white,
                            border: Border.all(color: selected ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(d,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF374151))),
                        ),
                      );
                    }).toList(),
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
        child: Text(_isEditing ? 'Edit Route' : 'Add Route',
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
              : const Text('Save Route', style: TextStyle(fontSize: 13)),
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
