import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orders_provider.dart';

class OrdersFilterSheet extends ConsumerStatefulWidget {
  const OrdersFilterSheet({super.key});

  @override
  ConsumerState<OrdersFilterSheet> createState() => _OrdersFilterSheetState();
}

class _OrdersFilterSheetState extends ConsumerState<OrdersFilterSheet> {
  static const _routes = [
    'Route 1 - Centro',
    'Route 2 - North',
    'Route 3 - South',
  ];

  String? _selectedRoute;
  String? _selectedRep;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _preset = '';
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = ref.read(ordersFilterProvider);
    _selectedRoute = f.route;
    _selectedRep = f.salesRepName;
    _dateFrom = f.dateFrom;
    _dateTo = f.dateTo;
    if (f.minAmount != null) _minCtrl.text = f.minAmount!.toStringAsFixed(0);
    if (f.maxAmount != null) _maxCtrl.text = f.maxAmount!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _preset = preset;
      switch (preset) {
        case 'today':
          _dateFrom = DateTime(now.year, now.month, now.day);
          _dateTo = DateTime(now.year, now.month, now.day);
        case 'week':
          _dateFrom = now.subtract(Duration(days: now.weekday - 1));
          _dateTo = now;
        case 'month':
          _dateFrom = DateTime(now.year, now.month);
          _dateTo = now;
        default:
          break;
      }
    });
  }

  void _reset() => setState(() {
        _selectedRoute = null;
        _selectedRep = null;
        _dateFrom = null;
        _dateTo = null;
        _preset = '';
        _minCtrl.clear();
        _maxCtrl.clear();
      });

  void _apply() {
    ref.read(ordersFilterProvider.notifier).state = OrderFilters(
      route: _selectedRoute,
      salesRepName: _selectedRep,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      minAmount: double.tryParse(_minCtrl.text),
      maxAmount: double.tryParse(_maxCtrl.text),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).value ?? [];
    final repNames = users
        .where((u) => u.role == 'sales_rep' || u.role == 'admin')
        .map((u) => '${u.firstName} ${u.lastName}'.trim())
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          _header(context),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateSection(context),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _routeDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _repDropdown(repNames)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _amtField(_minCtrl, 'Min Amount (₱)', '0')),
                    const SizedBox(width: 12),
                    Expanded(child: _amtField(_maxCtrl, 'Max Amount (₱)', '100,000')),
                  ]),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(children: [
          const Expanded(
            child: Text('Filter Orders',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
          ),
        ]),
      );

  Widget _dateSection(BuildContext context) {
    const presets = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('custom', 'Custom'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: presets.map<Widget>((preset) {
            final pKey = preset.$1;
            final pLabel = preset.$2;
            final active = _preset == pKey;
            return GestureDetector(
              onTap: () {
                if (pKey == 'custom') {
                  setState(() => _preset = 'custom');
                } else {
                  _applyPreset(pKey);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF1E1E1E)
                      : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFE5E7EB),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: active
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_preset == 'custom') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _datePicker(context, 'From', _dateFrom,
                    (d) => setState(() => _dateFrom = d))),
            const SizedBox(width: 12),
            Expanded(
                child: _datePicker(context, 'To', _dateTo,
                    (d) => setState(() => _dateTo = d))),
          ]),
        ] else if (_preset.isNotEmpty &&
            _dateFrom != null &&
            _dateTo != null) ...[
          const SizedBox(height: 6),
          Text(
            '${_fmtDate(_dateFrom)} — ${_fmtDate(_dateTo)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ],
    );
  }

  Widget _datePicker(BuildContext context, String label, DateTime? value,
      void Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              value != null ? _fmtDate(value) : 'dd/mm/yyyy',
              style: TextStyle(
                fontSize: 13,
                color: value != null
                    ? const Color(0xFF111827)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          const Icon(Icons.calendar_today_outlined,
              size: 14, color: Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  Widget _routeDropdown() => DropdownButtonFormField<String>(
        value: _selectedRoute, // ignore: deprecated_member_use
        decoration: _dec('Route'),
        isExpanded: true,
        items: [
          const DropdownMenuItem(
              value: null,
              child: Text('All Routes',
                  style: TextStyle(fontSize: 13))),
          ..._routes.map((r) => DropdownMenuItem(
              value: r, child: Text(r, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: (v) => setState(() => _selectedRoute = v),
      );

  Widget _repDropdown(List<String> repNames) =>
      DropdownButtonFormField<String>(
        value: _selectedRep, // ignore: deprecated_member_use
        decoration: _dec('Sales Rep'),
        isExpanded: true,
        items: [
          const DropdownMenuItem(
              value: null,
              child:
                  Text('All Reps', style: TextStyle(fontSize: 13))),
          ...repNames.map((r) => DropdownMenuItem(
              value: r, child: Text(r, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: (v) => setState(() => _selectedRep = v),
      );

  Widget _amtField(
          TextEditingController ctrl, String label, String hint) =>
      TextFormField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 13),
        decoration: _dec(label).copyWith(hintText: hint),
      );

  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                foregroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child:
                  const Text('Reset', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Apply Filters',
                  style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ]),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF374151))),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        filled: true,
        fillColor: Colors.white,
      );

  static String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
