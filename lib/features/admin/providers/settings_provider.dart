import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/settings/app_settings.dart';

final autoSyncOnStartupProvider = StateNotifierProvider<AutoSyncOnStartupNotifier, bool>(
  (ref) => AutoSyncOnStartupNotifier(),
);

class AutoSyncOnStartupNotifier extends StateNotifier<bool> {
  AutoSyncOnStartupNotifier() : super(AppSettings.instance.autoSyncOnStartup);

  Future<void> set(bool value) async {
    await AppSettings.instance.setAutoSyncOnStartup(value);
    state = value;
  }
}

/// Bumped after a manual sync or backup completes to force
/// [lastSyncProvider]/[lastBackupProvider] to re-read from AppSettings.
final settingsRefreshProvider = StateProvider<int>((ref) => 0);

final lastSyncProvider = Provider<DateTime?>((ref) {
  ref.watch(settingsRefreshProvider);
  return AppSettings.instance.lastSyncTimestamp;
});

final lastBackupProvider = Provider<DateTime?>((ref) {
  ref.watch(settingsRefreshProvider);
  return AppSettings.instance.lastBackupTimestamp;
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

final supabaseStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return !results.contains(ConnectivityResult.none);
});
