import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/payments_provider.dart';
import '../widgets/payment_status_badge.dart';
import '../widgets/payment_detail_panel.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({
    super.key,
    required this.database,
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.database.seedPaymentsForDemo();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPaymentProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/payments',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    _statsRow(),
                    _contentCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (isWide && selected != null)
              Container(
                width: 360,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: PaymentDetailPanel(payment: selected),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() => const Padding(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payments',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            SizedBox(height: 2),
            Text('Track and manage all customer payments',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      );

  Widget _statsRow() {
    final stats = ref.watch(paymentStatsProvider);
    final collected  = stats['collected']  as double;
    final outstanding = stats['outstanding'] as double;
    final paidCount  = stats['paidCount']   as int;
    final creditCount = stats['creditCount'] as int;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: LayoutBuilder(builder: (context, constraints) {
        final cards = [
          _StatCard(
            label: 'Total Collected',
            value: '₱${_fmt(collected)}',
            sub: 'This period',
          ),
          _StatCard(
            label: 'Outstanding',
            value: '₱${_fmt(outstanding)}',
            valueColor: const Color(0xFFDC2626),
            sub: '● Unpaid + Partial',
          ),
          _StatCard(
            label: 'Paid',
            value: '$paidCount',
            valueColor: const Color(0xFF059669),
            sub: '● Fully settled',
          ),
          _StatCard(
            label: 'On Credit',
            value: '$creditCount',
            valueColor: const Color(0xFF2563EB),
            sub: '● Credit term orders',
          ),
        ];

        if (constraints.maxWidth >= 600) {
          return Row(
            children: cards
                .map((c) => Expanded(child: Padding(
                    padding: EdgeInsets.only(
                        right: cards.indexOf(c) < cards.length - 1 ? 12 : 0),
                    child: c)))
                .toList(),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: cards,
        );
      }),
    );
  }

  Widget _contentCard(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _tabs(),
            const Divider(height: 1),
            _toolbar(context),
            const Divider(height: 1),
            _tableHeader(),
            const Divider(height: 1),
            _tableBody(context),
          ],
        ),
      );

  Widget _tabs() {
    final tab = ref.watch(paymentsTabProvider);
    const tabs = [
      ('all', 'All'),
      ('unpaid', 'Unpaid'),
      ('partial', 'Partial'),
      ('paid', 'Paid'),
      ('credit', 'On Credit'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((t) {
          final key = t.$1;
          final label = t.$2;
          final active = tab == key;
          return GestureDetector(
            onTap: () => ref.read(paymentsTabProvider.notifier).state = key,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? const Color(0xFF1E1E1E) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? const Color(0xFF111827) : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _toolbar(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) =>
                      ref.read(paymentsSearchProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search by order #, store, or rep...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: Color(0xFF9CA3AF)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune, size: 14),
              label: const Text('Filter', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                foregroundColor: const Color(0xFF374151),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showRecordPaymentSheet(context),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Record Payment', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      );

  Widget _tableHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: const [
            SizedBox(width: 90,  child: _ColHead('ORDER #')),
            Expanded(            child: _ColHead('STORE')),
            SizedBox(width: 120, child: _ColHead('SALES REP')),
            SizedBox(width: 85,  child: _ColHead('ORDER AMT')),
            SizedBox(width: 80,  child: _ColHead('PAID')),
            SizedBox(width: 80,  child: _ColHead('BALANCE')),
            SizedBox(width: 80,  child: _ColHead('METHOD')),
            SizedBox(width: 90,  child: _ColHead('DATE')),
            SizedBox(width: 110, child: _ColHead('STATUS')),
            SizedBox(width: 80,  child: _ColHead('ACTIONS')),
          ],
        ),
      );

  Widget _tableBody(BuildContext context) {
    final list = ref.watch(filteredPaymentsProvider);
    if (ref.watch(paymentsStreamProvider).isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No payments found',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ),
      );
    }
    return Column(
      children: list.map((p) => _PaymentRow(
        payment: p,
        onTap: () => _selectPayment(context, p),
        onRecord: () => _selectPayment(context, p),
      )).toList(),
    );
  }

  void _selectPayment(BuildContext context, Payment p) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    ref.read(selectedPaymentProvider.notifier).state = p;
    if (!isWide) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => UncontrolledProviderScope(
          container: ProviderScope.containerOf(context),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: PaymentDetailPanel(payment: p),
          ),
        ),
      );
    }
  }

  void _showRecordPaymentSheet(BuildContext context) {
    // Opens a quick sheet to pick a payment row to record
    // For now open the detail panel of the first unpaid/partial
    final list = ref.read(filteredPaymentsProvider);
    final target = list.firstWhere(
      (p) => p.status != 'paid',
      orElse: () => list.first,
    );
    _selectPayment(context, target);
  }

  static String _fmt(double v) => v == 0
      ? '0'
      : v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

// ── Column header ──────────────────────────────────────────────────────────────

class _ColHead extends StatelessWidget {
  const _ColHead(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      );
}

// ── Payment row ────────────────────────────────────────────────────────────────

class _PaymentRow extends StatefulWidget {
  const _PaymentRow({
    required this.payment,
    required this.onTap,
    required this.onRecord,
  });
  final Payment payment;
  final VoidCallback onTap;
  final VoidCallback onRecord;

  @override
  State<_PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends State<_PaymentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? const Color(0xFFFAFAFA) : Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(p.orderCode,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace')),
                    ),
                    Expanded(
                      child: Text(p.storeName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(p.salesRepName,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                      width: 85,
                      child: Text('₱${_fmt(p.orderAmount)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text('₱${_fmt(p.amountPaid)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF059669))),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                          p.balance > 0 ? '₱${_fmt(p.balance)}' : '₱0',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: p.balance > 0
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: p.balance > 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF6B7280))),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(p.paymentMethod ?? '—',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(_fmtDate(p.paymentDate),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ),
                    SizedBox(
                      width: 110,
                      child: PaymentStatusBadge(status: p.status),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            color: const Color(0xFF6B7280),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            onPressed: widget.onTap,
                          ),
                          IconButton(
                            icon: const Icon(Icons.receipt_outlined, size: 16),
                            color: const Color(0xFF6B7280),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            onPressed: widget.onRecord,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) => v == 0
      ? '0'
      : v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
