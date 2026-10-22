// lib/backup/backup_reminder.dart
// Kapan Beranda perlu menampilkan pengingat backup: data hanya ada di HP
// ini (sinkron Google Drive tidak aktif), sudah ada cukup banyak data, dan
// backup manual terakhir belum pernah dibuat atau sudah lebih dari 30 hari.
// "Nanti" menunda pengingat 7 hari.
import '../data/local_store.dart';
import '../sync/drive_sync.dart';

class BackupReminder {
  static const _lastBackupKey = 'last_backup_at';
  static const _snoozedKey = 'backup_reminder_snoozed_at';
  static const _minTransactions = 10;
  static const _staleAfter = Duration(days: 30);
  static const _snoozeFor = Duration(days: 7);

  static Future<bool> shouldShow(int transactionCount) async {
    if (transactionCount < _minTransactions) return false;
    if (await DriveSync.isEnabled()) return false;
    final now = DateTime.now();
    final snoozed = DateTime.tryParse(
      await LocalStore.getMeta(_snoozedKey) ?? '',
    );
    if (snoozed != null && now.difference(snoozed) < _snoozeFor) return false;
    final last = await lastBackupAt();
    return last == null || now.difference(last) > _staleAfter;
  }

  static Future<DateTime?> lastBackupAt() async =>
      DateTime.tryParse(await LocalStore.getMeta(_lastBackupKey) ?? '');

  static Future<void> markBackedUp() => LocalStore.setMeta(
    _lastBackupKey,
    DateTime.now().toUtc().toIso8601String(),
  );

  static Future<void> snooze() =>
      LocalStore.setMeta(_snoozedKey, DateTime.now().toUtc().toIso8601String());
}
