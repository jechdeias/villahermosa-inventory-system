import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/sales_providers.dart';
import '../widgets/new_order_flow.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/sales_shell.dart';

class SalesHomeScreen extends ConsumerWidget {
  const SalesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SalesShell(
      currentRoute: '/sales/home',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(),
            const _RouteSummaryCard(),
            const _TodayProgress(),
            const _QuickActions(),
            const _RecentActivity(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rep = ref.watch(currentSalesRepProvider);
    final online = ref.watch(salesConnectivityProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_greeting()}, ${rep?.firstName ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          online.when(
            data: (isOnline) => _SyncChip(isOnline: isOnline),
            loading: () => const _SyncChip(isOnline: false, label: 'Checking…'),
            error: (_, _) => const _SyncChip(isOnline: false),
          ),
        ],
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.isOnline, this.label});
  final bool isOnline;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? const Color(0xFF059669) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label ?? (isOnline ? 'Synced' : 'Offline'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

class _RouteSummaryCard extends ConsumerWidget {
  const _RouteSummaryCard();

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(salesRepRouteProvider);
    final progress = ref.watch(todayProgressProvider);
    final now = DateTime.now();
    final dateStr = '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(route?.routeName ?? 'No route assigned',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 2),
          Text('Today: $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _RouteStat(label: 'Stores', value: progress['total']!, color: const Color(0xFF111827))),
            const _VDivider(),
            Expanded(child: _RouteStat(label: 'Visited', value: progress['visited']!, color: const Color(0xFF059669))),
            const _VDivider(),
            Expanded(child: _RouteStat(label: 'Remaining', value: progress['remaining']!, color: const Color(0xFFD97706))),
          ]),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: const Color(0xFFE5E7EB));
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
    ]);
  }
}

class _TodayProgress extends ConsumerWidget {
  const _TodayProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(todayProgressProvider);
    final total = progress['total']!;
    final visited = progress['visited']!;
    final value = total == 0 ? 0.0 : visited / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Progress", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: const Color(0xFF059669),
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 6),
          Text('$visited of $total stores visited', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _QuickActionCard(
            icon: Icons.shopping_cart_outlined,
            label: 'New Order',
            onTap: () => showNewOrderFlow(context),
          ),
          _QuickActionCard(
            icon: Icons.payments_outlined,
            label: 'Record Payment',
            onTap: () => showRecordPaymentSheet(context),
          ),
          _QuickActionCard(
            icon: Icons.store_outlined,
            label: 'My Customers',
            onTap: () => Navigator.of(context).pushReplacementNamed('/sales/customers'),
          ),
          _QuickActionCard(
            icon: Icons.sync_outlined,
            label: 'Sync Data',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await SyncManager.instance.performFullSync();
                messenger.showSnackBar(const SnackBar(content: Text('Synced successfully')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF1E1E1E)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(salesRecentActivityProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 10),
          if (activity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No activity yet today', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            )
          else
            ...activity.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                          children: [
                            TextSpan(text: '${a.storeName} ', style: const TextStyle(fontWeight: FontWeight.w500)),
                            TextSpan(text: '— ${a.action}', style: TextStyle(color: a.color)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_relativeTime(a.time), style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ]),
                )),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
