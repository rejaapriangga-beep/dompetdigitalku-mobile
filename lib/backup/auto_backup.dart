// lib/backup/auto_backup.dart
// Salinan otomatis harian di HP — jaring pengaman kalau database lokal rusak
// atau data terhapus karena bug/salah pencet, tanpa perlu Google Drive
// maupun file backup manual. Sekali sehari (saat app dibuka), seluruh data
// diekspor dalam format backup v1 ke folder privat aplikasi; 7 salinan
// terbaru disimpan. Pemulihannya lewat layar Backup.
//
// Catatan: salinan ini ikut hilang kalau aplikasi di-uninstall — untuk itu
// tetap perlu backup manual atau sinkron Google Drive.
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/local_db.dart';
import '../data/local_store.dart';

class AutoBackupEntry {
  final File file;
  final DateTime date;
  final int transactionCount;
  AutoBackupEntry(this.file, this.date, this.transactionCount);
}

class AutoBackup {
  static const _keep = 7;
  static const _prefix = 'auto-';
  static const _suffix = '.json';
  static const _dueAfter = Duration(hours: 20);

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/auto_backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  /// Buat salinan hari ini kalau salinan terakhir sudah lebih dari ~sehari.
  /// Tidak pernah melempar error — kegagalan salinan otomatis tidak boleh
  /// mengganggu pemakaian aplikasi.
  static Future<void> runIfDue() async {
    try {
      final entries = await list();
      final now = DateTime.now();
      if (entries.isNotEmpty &&
          now.difference(entries.first.date) < _dueAfter) {
        return;
      }
      final data = await LocalStore.exportBackup();
      // Jangan simpan salinan dari database yang kosong total (mis. baru
      // dipasang) — supaya tidak menggeser salinan lama yang berisi.
      final hasContent = [
        'transactions',
        'assets',
        'debts',
        'investments',
      ].any((k) => (data[k] as List).isNotEmpty);
      if (!hasContent) return;
      final dir = await _dir();
      final file = File('${dir.path}/$_prefix${_stamp(now)}$_suffix');
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(data), flush: true);
      await tmp.rename(file.path);
      final all = await list();
      for (final old in all.skip(_keep)) {
        await old.file.delete();
      }
    } catch (_) {}
  }

  /// Hapus semua salinan otomatis (bagian dari "Hapus Semua Data").
  static Future<void> deleteAll() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Salinan yang ada, terbaru dulu.
  static Future<List<AutoBackupEntry>> list() async {
    final dir = await _dir();
    final entries = <AutoBackupEntry>[];
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith(_prefix) || !name.endsWith(_suffix)) continue;
      try {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final exported = DateTime.tryParse(data['exportedAt'] as String? ?? '');
        entries.add(
          AutoBackupEntry(
            f,
            (exported ?? await f.lastModified()).toLocal(),
            (data['transactions'] as List?)?.length ?? 0,
          ),
        );
      } catch (_) {
        // File rusak dilewati.
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Pulihkan dari satu salinan — MENGGANTI TOTAL data saat ini. Kalau
  /// database sendiri yang rusak sampai tidak bisa ditulisi, database
  /// dibuat ulang dulu lalu pemulihan dicoba sekali lagi.
  static Future<void> restore(AutoBackupEntry entry) async {
    final data =
        jsonDecode(await entry.file.readAsString()) as Map<String, dynamic>;
    try {
      await LocalStore.importBackup(data);
    } catch (_) {
      await LocalDb.reset();
      await LocalStore.importBackup(data);
    }
  }
}
