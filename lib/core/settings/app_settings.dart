import 'package:shared_preferences/shared_preferences.dart';

/// Local app preferences (auto-sync toggle, last sync/backup timestamps).
/// Singleton, initialized once in main() before first use — mirrors the
/// AppDatabase/SyncManager singleton pattern already used in this app.
class AppSettings {
  AppSettings._(this._prefs);

  static AppSettings? _instance;
  final SharedPreferences _prefs;

  static AppSettings get instance {
    if (_instance == null) {
      throw Exception('AppSettings not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    _instance ??= AppSettings._(await SharedPreferences.getInstance());
  }

  static const _kAutoSyncOnStartup = 'auto_sync_on_startup';
  static const _kLastSyncTimestamp = 'last_sync_timestamp';
  static const _kLastBackupTimestamp = 'last_backup_timestamp';

  bool get autoSyncOnStartup => _prefs.getBool(_kAutoSyncOnStartup) ?? true;
  Future<void> setAutoSyncOnStartup(bool value) => _prefs.setBool(_kAutoSyncOnStartup, value);

  DateTime? get lastSyncTimestamp => _readDateTime(_kLastSyncTimestamp);
  Future<void> setLastSyncTimestamp(DateTime value) => _prefs.setString(_kLastSyncTimestamp, value.toIso8601String());

  DateTime? get lastBackupTimestamp => _readDateTime(_kLastBackupTimestamp);
  Future<void> setLastBackupTimestamp(DateTime value) => _prefs.setString(_kLastBackupTimestamp, value.toIso8601String());

  DateTime? _readDateTime(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
