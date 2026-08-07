import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/sync/sync_manager.dart';
import '../providers/sales_providers.dart';
import '../widgets/sales_shell.dart';

class SalesProfileScreen extends ConsumerStatefulWidget {
  const SalesProfileScreen({super.key});

  @override
  ConsumerState<SalesProfileScreen> createState() => _SalesProfileScreenState();
}

class _SalesProfileScreenState extends ConsumerState<SalesProfileScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SyncManager.instance.performFullSync();
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Synced successfully')));
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.instance.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rep = ref.watch(currentSalesRepProvider);
    final route = ref.watch(salesRepRouteProvider);
    final pending = ref.watch(salesPendingUploadsProvider);
    final lastSync = AppSettings.instance.lastSyncTimestamp;

    return SalesShell(
      currentRoute: '/sales/profile',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                (rep?.firstName.isNotEmpty ?? false) ? rep!.firstName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${rep?.firstName ?? ''} ${rep?.lastName ?? ''}'.trim(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(rep?.email ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  if (route != null) ...[
                    const SizedBox(height: 4),
                    Text(route.routeName, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Sync Status',
            children: [
              _InfoRow(label: 'Pending Uploads', value: '$pending'),
              _InfoRow(
                label: 'Last Sync',
                value: lastSync == null ? 'Never' : _formatDateTime(lastSync),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _syncing ? null : _syncNow,
                  icon: _syncing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync, size: 18),
                  label: Text(_syncing ? 'Syncing…' : 'Sync Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Account',
            children: [
              _InfoRow(label: 'Role', value: 'Sales Rep / Delivery'),
              _InfoRow(label: 'Phone', value: rep?.phone ?? '—'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_outlined, color: Color(0xFFDC2626), size: 18),
              label: const Text('Logout', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day}/${dt.year} $h:$m $ampm';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
      ]),
    );
  }
}
