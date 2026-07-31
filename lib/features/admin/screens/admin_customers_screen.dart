import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/customers_provider.dart';
import '../widgets/add_customer_panel.dart';
import '../widgets/customer_channel_badge.dart';
import '../widgets/customer_detail_panel.dart';
import '../widgets/mobile_list_card.dart';
import '../widgets/orders_stat_card.dart';

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  ConsumerState<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final _searchCtrl = TextEditingController();
  bool _showAddPanel = false;
  Customer? _editingCustomer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(customersSearchProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeDetailPanel() {
    ref.read(selectedCustomerProvider.notifier).state = null;
  }

  void _openAddPanel({Customer? editing}) {
    setState(() {
      _showAddPanel = true;
      _editingCustomer = editing;
    });
    ref.read(selectedCustomerProvider.notifier).state = null;
  }

  void _closeAddPanel() => setState(() {
    _showAddPanel = false;
    _editingCustomer = null;
  });

  void _showAddSheet(BuildContext context, {Customer? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: AddCustomerPanel(editing: editing, onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    ref.listen<Customer?>(selectedCustomerProvider, (_, next) {
      if (next != null) {
        if (!isWide) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (_) => UncontrolledProviderScope(
              container: ProviderScope.containerOf(context),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: CustomerDetailPanel(customer: next, onClose: () => Navigator.pop(context)),
              ),
            ),
          ).then((_) => _closeDetailPanel());
        } else if (_showAddPanel) {
          setState(() => _showAddPanel = false);
        }
      }
    });

    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/customers',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CustomersListColumn(
                searchCtrl: _searchCtrl,
                onAddCustomer: isWide ? () => _openAddPanel() : () => _showAddSheet(context),
                onEditCustomer: (c) => isWide ? _openAddPanel(editing: c) : _showAddSheet(context, editing: c),
              ),
            ),
            if (isWide && _showAddPanel)
              SizedBox(
                width: 380,
                child: AddCustomerPanel(editing: _editingCustomer, onClose: _closeAddPanel),
              ),
            if (isWide && !_showAddPanel && selectedCustomer != null)
              SizedBox(
                width: 360,
                child: CustomerDetailPanel(customer: selectedCustomer, onClose: _closeDetailPanel),
              ),
          ],
        ),
      ),
    );
  }
}

// ── List Column ───────────────────────────────────────────────────────────────

class _CustomersListColumn extends ConsumerWidget {
  const _CustomersListColumn({
    required this.searchCtrl,
    required this.onAddCustomer,
    required this.onEditCustomer,
  });
  final TextEditingController searchCtrl;
  final VoidCallback onAddCustomer;
  final void Function(Customer) onEditCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCustomers = ref.watch(customersStreamProvider).value ?? [];

    final totalCount = allCustomers.length;
    final activeCount = allCustomers.where((c) => c.status == 'active').length;
    final townsCovered = allCustomers.map((c) => c.town).whereType<String>().toSet().length;
    final channelsCount = allCustomers.map((c) => c.channel).whereType<String>().toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(totalCount, activeCount, townsCovered, channelsCount),
          const SizedBox(height: 20),
          _buildContentCard(context, ref),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customers & Stores',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        const Text('Manage your customer database',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildStatsRow(int total, int active, int towns, int channels) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      final cards = [
        OrdersStatCard(title: 'Total Stores', value: '$total', subtitle: 'All channels'),
        OrdersStatCard(title: 'Active Stores', value: '$active', subtitle: 'Currently serving', valueColor: const Color(0xFF059669)),
        OrdersStatCard(title: 'Towns Covered', value: '$towns', subtitle: 'Marinduque municipalities'),
        OrdersStatCard(title: 'Store Channels', value: '$channels', subtitle: 'Types of stores'),
      ];
      if (isNarrow) {
        return Column(children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
        ]);
      }
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ]);
    });
  }

  Widget _buildContentCard(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(customersTabProvider);
    final filteredCustomers = ref.watch(filteredCustomersProvider);
    final allCustomers = ref.watch(customersStreamProvider).value ?? [];

    final tabs = [
      _Tab('All', null, allCustomers.length),
      ...kCustomerTowns.map((t) => _Tab(t, t, allCustomers.where((c) => c.town == t).length)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabBar(ref, tab, tabs),
          _buildToolbar(context, ref),
          if (filteredCustomers.isEmpty)
            _buildEmptyState(tab)
          else
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: filteredCustomers.map((c) => _CustomerMobileCard(customer: c, onEdit: () => onEditCustomer(c))).toList(),
                );
              }
              return Column(children: [
                _buildTableHeader(),
                ...filteredCustomers.map((c) => _CustomerRow(customer: c, onEdit: () => onEditCustomer(c))),
              ]);
            }),
        ],
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, String? tab, List<_Tab> tabs) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = tab == t.value;
            return GestureDetector(
              onTap: () => ref.read(customersTabProvider.notifier).state = t.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF111827) : Colors.transparent, width: 2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${t.count}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF6B7280))),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(customersFilterProvider);
    final filterActive = filters.isActive;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6B7280))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => UncontrolledProviderScope(
                  container: ProviderScope.containerOf(context),
                  child: const _CustomersFilterSheet(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: filterActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                backgroundColor: filterActive ? const Color(0xFFEFF6FF) : null,
                side: BorderSide(color: filterActive ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: filterActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text('Filter', style: TextStyle(fontSize: 12, color: filterActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280))),
                  if (filterActive) ...[
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAddCustomer,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB)), bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(children: [
        _HeaderCell('STORE NAME', flex: 2),
        _HeaderCell('OWNER', flex: 2),
        _HeaderCell('BARANGAY', flex: 2),
        _HeaderCell('TOWN', flex: 2),
        _HeaderCell('CHANNEL', flex: 2),
        _HeaderCell('STATUS', flex: 2),
        _HeaderCell('', flex: 2),
      ]),
    );
  }

  Widget _buildEmptyState(String? tab) {
    final label = tab == null ? 'customers' : 'customers in $tab';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.storefront_outlined, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No $label found', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ]),
    );
  }
}

// ── Customer Row ─────────────────────────────────────────────────────────────

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({required this.customer, required this.onEdit});
  final Customer customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCustomerProvider);
    final isSelected = selected?.uuid == customer.uuid;

    return InkWell(
      onTap: () => ref.read(selectedCustomerProvider.notifier).state = customer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9FAFB) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(customer.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(customer.businessName ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(customer.barangay ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(customer.town ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: customer.channel != null
                  ? CustomerChannelBadge(channel: customer.channel!)
                  : const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
                decoration: BoxDecoration(
                  color: customer.status == 'active' ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  customer.status[0].toUpperCase() + customer.status.substring(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: customer.status == 'active' ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: onEdit),
                  _ActionIconButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View',
                    onTap: () => ref.read(selectedCustomerProvider.notifier).state = customer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer Mobile Card ──────────────────────────────────────────────────────

class _CustomerMobileCard extends ConsumerWidget {
  const _CustomerMobileCard({required this.customer, required this.onEdit});
  final Customer customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = customer.status == 'active';
    return MobileListCard(
      onTap: () => ref.read(selectedCustomerProvider.notifier).state = customer,
      primary: Text(customer.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      badge: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          customer.status[0].toUpperCase() + customer.status.substring(1),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
        ),
      ),
      secondary: MobileCardMuted(
          '${customer.barangay ?? '—'}, ${customer.town ?? '—'}${customer.businessName != null ? ' · ${customer.businessName}' : ''}'),
      valueLeft: customer.channel != null
          ? CustomerChannelBadge(channel: customer.channel!)
          : const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      valueRight: MobileCardMuted(customer.contactNumber),
      actions: [
        MobileCardAction(label: 'Edit', onPressed: onEdit),
        MobileCardAction(
          label: 'View',
          onPressed: () => ref.read(selectedCustomerProvider.notifier).state = customer,
        ),
      ],
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _CustomersFilterSheet extends ConsumerStatefulWidget {
  const _CustomersFilterSheet();

  @override
  ConsumerState<_CustomersFilterSheet> createState() => _CustomersFilterSheetState();
}

class _CustomersFilterSheetState extends ConsumerState<_CustomersFilterSheet> {
  late String? _channel = ref.read(customersFilterProvider).channel;
  late String? _status = ref.read(customersFilterProvider).status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          ),
          const Text('Filter Customers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _channel,
            decoration: InputDecoration(hintText: 'Channel', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
            items: [
              const DropdownMenuItem(value: null, child: Text('All channels', style: TextStyle(fontSize: 13))),
              ...kCustomerChannels.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))),
            ],
            onChanged: (v) => setState(() => _channel = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _status,
            decoration: InputDecoration(hintText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
            items: const [
              DropdownMenuItem(value: null, child: Text('All statuses', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'active', child: Text('Active', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(customersFilterProvider.notifier).state = const CustomerFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(customersFilterProvider.notifier).state = CustomerFilters(channel: _channel, status: _status);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
                child: const Text('Apply', style: TextStyle(fontSize: 13)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _Tab {
  const _Tab(this.label, this.value, this.count);
  final String label;
  final String? value;
  final int count;
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({required this.icon, required this.onTap, this.tooltip = ''});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFF3F4F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(widget.icon, size: 15, color: _hovered ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
          ),
        ),
      ),
    );
  }
}
