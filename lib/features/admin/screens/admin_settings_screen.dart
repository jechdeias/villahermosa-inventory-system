import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key, required this.database, required this.syncManager});
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveShell(
      database: database,
      selectedRoute: '/admin/settings',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 20),
              _SyncSettingsCard(syncManager: syncManager),
              const SizedBox(height: 16),
              const _BackupCard(),
              const SizedBox(height: 16),
              _AboutCard(database: database),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        SizedBox(height: 4),
        Text('Configure system preferences and sync', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ],
    );
  }
}

// ── Shared section/row building blocks ─────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.rows});
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: const Color(0xFF374151)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ]),
          ),
          for (final row in rows) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            row,
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.subtitle, required this.trailing});
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ]),
    );
  }
}

class _BlackSwitch extends StatelessWidget {
  const _BlackSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF1E1E1E),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFD1D5DB),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF9CA3AF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: loading
          ? const SizedBox(
              width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label),
    );
  }
}

String _formatTimestamp(DateTime? dt) {
  if (dt == null) return 'Never';
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
}

// ── Sync Settings ────────────────────────────────────────────────────────────

class _SyncSettingsCard extends ConsumerStatefulWidget {
  const _SyncSettingsCard({required this.syncManager});
  final SyncManager syncManager;

  @override
  ConsumerState<_SyncSettingsCard> createState() => _SyncSettingsCardState();
}

class _SyncSettingsCardState extends ConsumerState<_SyncSettingsCard> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await widget.syncManager.performFullSync();
      ref.read(settingsRefreshProvider.notifier).state++;
      final success = result['success'] == true;
      messenger.showSnackBar(SnackBar(
        content: Text(success
            ? 'Sync complete — pushed ${result['recordsPushed']}, pulled ${result['recordsPulled']}'
            : 'Sync failed: ${result['error']}'),
      ));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoSync = ref.watch(autoSyncOnStartupProvider);
    return _SectionCard(
      icon: Icons.sync,
      title: 'Sync Settings',
      subtitle: 'Configure data synchronization',
      rows: [
        _SettingRow(
          title: 'Auto-sync on startup',
          subtitle: 'Sync pending data when the app starts',
          trailing: _BlackSwitch(
            value: autoSync,
            onChanged: (v) => ref.read(autoSyncOnStartupProvider.notifier).set(v),
          ),
        ),
        _SettingRow(
          title: 'Sync Now',
          subtitle: 'Push and pull pending changes immediately',
          trailing: _PrimaryButton(label: 'Sync Now', onPressed: _syncNow, loading: _syncing),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Text(
            'Sync also runs automatically on login and right after every change you make — this only covers app startup.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }
}

// ── Database Backup ──────────────────────────────────────────────────────────

class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard();

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  final _backupService = BackupService();
  bool _backingUp = false;

  Future<void> _backupNow() async {
    setState(() => _backingUp = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _backupService.backupNow();
      ref.read(settingsRefreshProvider.notifier).state++;
      messenger.showSnackBar(SnackBar(content: Text('Backup saved to ${file.path}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastBackup = ref.watch(lastBackupProvider);
    return _SectionCard(
      icon: Icons.backup_outlined,
      title: 'Database Backup',
      subtitle: 'Save a local copy of the database',
      rows: [
        _SettingRow(
          title: 'Last Backup',
          subtitle: _formatTimestamp(lastBackup),
          trailing: _PrimaryButton(label: 'Backup Now', onPressed: _backupNow, loading: _backingUp),
        ),
      ],
    );
  }
}

// ── About ────────────────────────────────────────────────────────────────────

class _AboutCard extends ConsumerWidget {
  const _AboutCard({required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSync = ref.watch(lastSyncProvider);
    final appVersion = ref.watch(appVersionProvider);
    final online = ref.watch(supabaseStatusProvider);

    return _SectionCard(
      icon: Icons.info_outline,
      title: 'About',
      subtitle: 'System information',
      rows: [
        _InfoRow(label: 'App Version', value: appVersion.when(
          data: (v) => v,
          loading: () => '…',
          error: (_, _) => 'Unknown',
        )),
        _InfoRow(label: 'Database Version', value: 'v${database.schemaVersion}'),
        _InfoRow(label: 'Last Sync', value: _formatTimestamp(lastSync)),
        _InfoRow(
          label: 'Supabase Status',
          value: online.when(
            data: (isOnline) => isOnline ? 'Connected' : 'Offline',
            loading: () => 'Checking…',
            error: (_, _) => 'Unknown',
          ),
          dotColor: online.when(
            data: (isOnline) => isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
            loading: () => const Color(0xFF9CA3AF),
            error: (_, _) => const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.dotColor});
  final String label;
  final String value;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (dotColor != null) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ]),
      ]),
    );
  }
}
