import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/settings/app_settings.dart';

/// Copies the live SQLite database file to a timestamped backup in the same
/// documents directory app_database.dart uses to open it.
class BackupService {
  Future<File> backupNow() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final sourceFile = File(p.join(dbFolder.path, 'villahermosa_inventory.db'));
    if (!await sourceFile.exists()) {
      throw StateError('Database file not found at ${sourceFile.path}');
    }

    final now = DateTime.now();
    final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final backupFile = File(p.join(dbFolder.path, 'villahermosa_inventory_backup_$stamp.db'));

    await sourceFile.copy(backupFile.path);
    await AppSettings.instance.setLastBackupTimestamp(now);
    return backupFile;
  }
}
