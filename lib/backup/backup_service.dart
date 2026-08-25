// lib/backup/backup_service.dart
// Orkestrasi fitur Backup: ambil data dari server -> (opsional) sertakan
// lampiran foto invoice lokal -> enkripsi jadi SATU file -> simpan ke
// perangkat lewat share sheet Android (dari situ pengguna bisa pilih kirim
// ke Google Drive, email sendiri, dst). Serta alur sebaliknya untuk
// Pulihkan. Logika enkripsi ada di backup_crypto.dart — file ini cuma
// menyambungkannya.
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../api/data_api.dart';
import '../storage/local_invoice_store.dart';
import 'backup_crypto.dart';

class BackupPreview {
  final Map<String, dynamic> data;
  BackupPreview(this.data);

  DateTime? get exportedAt {
    final raw = data['exportedAt'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  int get transactionCount => (data['transactions'] as List?)?.length ?? 0;
  int get accountCount => (data['accounts'] as List?)?.length ?? 0;
  int get categoryCount => (data['categories'] as List?)?.length ?? 0;
  int get attachmentCount => (data['attachments'] as List?)?.length ?? 0;
}

class BackupService {
  static String _fileName() {
    final ts = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    return 'duitkita-backup-$ts.duitkitabackup';
  }

  /// Buat backup (opsional sertakan lampiran foto invoice lokal) lalu buka
  /// share sheet Android (simpan ke folder HP, kirim ke Google Drive/email
  /// sendiri/aplikasi penyimpanan lain, dsb). Return jumlah lampiran yang
  /// ikut disertakan (0 kalau [includeAttachments] false atau memang tidak
  /// ada).
  static Future<int> createAndShareLocal(
    String passphrase, {
    required bool includeAttachments,
  }) async {
    final data = await DataApi.exportBackup();
    var attachmentCount = 0;
    if (includeAttachments) {
      final entries = await LocalInvoiceStore.getAllEntries();
      attachmentCount = entries.length;
      data['attachments'] = entries
          .map(
            (e) => {
              'transactionId': e.transactionId,
              'extension': e.extension,
              'contentBase64': base64Encode(e.bytes),
            },
          )
          .toList();
    }
    final bytes = await encryptBackup(data, passphrase);

    final dir = await getTemporaryDirectory();
    final fileName = _fileName();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([
      XFile(file.path, name: fileName),
    ], text: 'Backup DuitKita');
    return attachmentCount;
  }

  /// Pilih file backup dari penyimpanan HP lalu dekripsi. Return null kalau
  /// pengguna membatalkan pemilihan file.
  static Future<BackupPreview?> pickAndDecryptLocalFile(
    String passphrase,
  ) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) {
      throw Exception('Tidak bisa membaca file yang dipilih.');
    }
    final bytes = await File(path).readAsBytes();
    final data = await decryptBackup(bytes, passphrase);
    return BackupPreview(data);
  }

  /// Kirim data yang sudah didekripsi ke server untuk memulihkan — akan
  /// MENGGANTI TOTAL data rumah tangga saat ini — lalu pulihkan lampiran
  /// (kalau ada) ke penyimpanan lokal perangkat ini, dienkripsi ulang
  /// dengan vault key perangkat saat ini.
  static Future<Map<String, dynamic>> restore(BackupPreview preview) async {
    final result = await DataApi.importBackup(preview.data);
    final attachments = preview.data['attachments'] as List?;
    if (attachments != null) {
      for (final raw in attachments) {
        final m = raw as Map<String, dynamic>;
        await LocalInvoiceStore.restoreEntry(
          LocalInvoiceEntry(
            transactionId: m['transactionId'] as String,
            extension: m['extension'] as String,
            bytes: base64Decode(m['contentBase64'] as String),
          ),
        );
      }
    }
    return result;
  }
}
