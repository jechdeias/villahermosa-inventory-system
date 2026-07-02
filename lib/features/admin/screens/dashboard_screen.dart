import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) => ResponsiveShell(
        database: database,
        selectedRoute: '/admin/dashboard',
        child: AdminDashboardView(database: database, syncManager: syncManager),
      );
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _totalCustomers = 0;
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  double _totalValue = 0;
  double _collectedValue = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final db = widget.database;
    try {
      final c = await db.getAllCustomers();
      if (mounted) setState(() => _totalCustomers = c.length);
    } catch (_) {}
    try {
      final p = await db.getAllProducts();
      if (mounted) {
        setState(() {
          _totalProducts = p.length;
          _lowStockCount = p.where((x) => x.currentStock <= x.minStock).length;
        });
      }
    } catch (_) {}
    try {
      final o = await db.watchAllOrders().first;
      if (mounted) {
        setState(() {
          _totalOrders = o.length;
          _pendingOrders = o.where((x) => x.status == 'pending').length;
        });
      }
    } catch (_) {}
    try {
      final pay = await db.watchAllPayments().first;
      if (mounted) {
        setState(() {
          _totalValue = pay.fold(0.0, (s, p) => s + p.orderAmount);
          _collectedValue = pay.fold(0.0, (s, p) => s + p.amountPaid);
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshData() => _loadDashboardData();

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    try {
      final db = widget.database;
      final activities = <Map<String, dynamic>>[];

      DateTime parseTimestamp(dynamic value) {
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        if (value is String) return DateTime.parse(value);
        return DateTime.now();
      }

      try {
        final rows = await db.customSelect(
          'SELECT id, first_name, last_name, email, role, created_at, updated_at FROM users WHERE is_deleted = 0 ORDER BY created_at DESC LIMIT 8',
        ).get();
        for (final row in rows) {
          final createdAt = parseTimestamp(row.data['created_at']);
          final updatedAt = row.data['updated_at'] != null ? parseTimestamp(row.data['updated_at']) : null;
          final isUpdate = updatedAt != null && updatedAt.difference(createdAt).inMinutes > 5;
          final name = '${row.read<String>('first_name')} ${row.read<String>('last_name')}'.trim();
          final email = row.read<String>('email');
          activities.add({
            'time': isUpdate ? updatedAt : createdAt,
            'user': 'Admin',
            'action': isUpdate ? 'Updated user' : 'Created user',
            'details': '$name (${email.length > 20 ? '${email.substring(0, 18)}...' : email})',
          });
        }
      } catch (_) {}

      try {
        final rows = await db.customSelect(
          'SELECT o.id, o.order_number, o.total_amount, o.created_at, o.store_name, o.sales_rep_name FROM orders o ORDER BY o.created_at DESC LIMIT 5',
        ).get();
        for (final row in rows) {
          final amount = row.read<double?>('total_amount');
          final orderNum = row.read<String?>('order_number') ?? 'ORD-${row.read<int>('id')}';
          final amountStr = amount != null ? '₱${amount.toStringAsFixed(0)}' : '';
          activities.add({
            'time': parseTimestamp(row.data['created_at']),
            'user': row.read<String?>('sales_rep_name') ?? 'Sales Staff',
            'action': 'Created order',
            'details': '$orderNum · $amountStr',
          });
        }
      } catch (_) {}

      activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
      return activities.take(8).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[time.month - 1]} ${time.day}, ${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildStatCards(isNarrow),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: isNarrow
                  ? Column(children: [
                      _buildActivityPanel(),
                      const SizedBox(height: 14),
                      _buildQuickActionsPanel(),
                    ])
                  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 62, child: _buildActivityPanel()),
                      const SizedBox(width: 14),
                      Expanded(flex: 38, child: _buildQuickActionsPanel()),
                    ]),
            ),
            _buildChartsSection(isNarrow),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  SizedBox(height: 2),
                  Text('System overview and analytics',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Color(0xFF6B7280)),
                      SizedBox(width: 6),
                      Text('Last 30 days',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _refreshData,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.refresh, size: 14, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatCards(bool isNarrow) {
    final totalStr = _totalValue >= 1000
        ? '₱${(_totalValue / 1000).toStringAsFixed(0)}K'
        : '₱${_totalValue.toStringAsFixed(0)}';
    final colStr = _collectedValue >= 1000
        ? '₱${(_collectedValue / 1000).toStringAsFixed(0)}K'
        : '₱${_collectedValue.toStringAsFixed(0)}';

    final cards = [
      _statCard(label: 'Total Customers', value: '$_totalCustomers',
          dotColor: const Color(0xFF059669), sub: 'Active stores'),
      _statCard(label: 'Products', value: '$_totalProducts',
          dotColor: const Color(0xFFD97706), sub: 'Low stock: $_lowStockCount'),
      _statCard(
          label: 'Orders',
          value: '$_totalOrders',
          valueColor: _pendingOrders > 0 ? const Color(0xFFD97706) : null,
          dotColor: const Color(0xFFD97706),
          sub: 'Pending: $_pendingOrders'),
      _statCard(label: 'Total Value', value: totalStr,
          dotColor: const Color(0xFF059669), sub: '$colStr collected'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: isNarrow
          ? Column(children: [
              Row(children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 10),
                Expanded(child: cards[3]),
              ]),
            ])
          : Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
              const SizedBox(width: 10),
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ]),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color dotColor,
    required String sub,
    Color? valueColor,
  }) =>
      Container(
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
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF111827))),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(sub,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        ),
      );

  Widget _buildActivityPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                GestureDetector(
                  onTap: () {},
                  child: const Row(children: [
                    Text('View All',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 14, color: Color(0xFF6B7280)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(children: [
              SizedBox(width: 100, child: _ColHead('TIME')),
              SizedBox(width: 90, child: _ColHead('USER')),
              SizedBox(width: 100, child: _ColHead('ACTION')),
              Expanded(child: _ColHead('DETAILS')),
            ]),
            const Divider(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getRecentActivity(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('No recent activity',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280)))),
                  );
                }
                return Column(
                  children: list
                      .map((a) => _activityRow(
                            time: a['time'] as DateTime,
                            user: a['user'] as String,
                            action: a['action'] as String,
                            details: a['details'] as String,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      );

  Widget _activityRow({
    required DateTime time,
    required String user,
    required String action,
    required String details,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(
            width: 100,
            child: Row(children: [
              const Icon(Icons.access_time_outlined,
                  size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(_formatRelativeTime(time),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          SizedBox(
            width: 90,
            child: Text(user,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 100,
            child: Text(action,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(details,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _buildQuickActionsPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _quickAction(Icons.person_add_outlined, 'Create User', '/admin/users'),
                _quickAction(Icons.inventory_2_outlined, 'Add Product', '/admin/inventory'),
                _quickAction(Icons.bar_chart_outlined, 'Reports', '/admin/reports'),
                _quickAction(Icons.shopping_cart_outlined, 'View Orders', '/admin/orders'),
              ],
            ),
          ],
        ),
      );

  Widget _quickAction(IconData icon, String label, String route) => InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827))),
            ],
          ),
        ),
      );

  Widget _buildChartsSection(bool isNarrow) {
    final charts = [
      _chartCard('Sales Trend', _lineChart()),
      _chartCard('Orders by Status', _donutChart()),
      _chartCard('Stock Levels', _barChart()),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: isNarrow
          ? Column(children: [
              charts[0],
              const SizedBox(height: 14),
              charts[1],
              const SizedBox(height: 14),
              charts[2],
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: charts[0]),
              const SizedBox(width: 14),
              Expanded(child: charts[1]),
              const SizedBox(width: 14),
              Expanded(child: charts[2]),
            ]),
    );
  }

  Widget _chartCard(String title, Widget chart) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
            const SizedBox(height: 10),
            chart,
          ],
        ),
      );

  Widget _lineChart() => SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 45),
                  FlSpot(1, 52),
                  FlSpot(2, 48),
                  FlSpot(3, 61),
                  FlSpot(4, 55),
                  FlSpot(5, 67),
                ],
                isCurved: true,
                color: const Color(0xFF1E1E1E),
                barWidth: 1.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF1E1E1E),
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (val, meta) {
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                    final idx = val.toInt();
                    if (idx < 0 || idx >= months.length) return const SizedBox();
                    return Text(months[idx],
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF6B7280)));
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      );

  Widget _donutChart() {
    const data = [
      ('Delivered', 45, Color(0xFF1E1E1E)),
      ('Processing', 28, Color(0xFF6B7280)),
      ('Pending', 12, Color(0xFFD1D5DB)),
      ('Cancelled', 4, Color(0xFFE5E7EB)),
    ];
    final total = data.fold(0, (s, d) => s + d.$2);

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PieChart(
            PieChartData(
              sections: data
                  .map((d) => PieChartSectionData(
                        value: d.$2.toDouble(),
                        color: d.$3,
                        radius: 20,
                        showTitle: false,
                      ))
                  .toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...data.map((d) {
          final pct = total > 0 ? (d.$2 / total * 100).toStringAsFixed(0) : '0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: d.$3, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('${d.$1} (${d.$2})',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280)))),
              Text('$pct%',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF6B7280))),
            ]),
          );
        }),
      ],
    );
  }

  Widget _barChart() {
    const cats = ['Beverages', 'Snacks', 'Household', 'Personal', 'Frozen'];
    const vals = [450.0, 320.0, 180.0, 210.0, 95.0];
    const opacities = [0.9, 0.6, 0.75, 0.45, 0.3];

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(5, (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: vals[i],
                    color: const Color(0xFF1E1E1E).withValues(alpha: opacities[i]),
                    width: 20,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              )),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= cats.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(cats[idx],
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF6B7280)),
                        textAlign: TextAlign.center),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _ColHead extends StatelessWidget {
  const _ColHead(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3));
}
