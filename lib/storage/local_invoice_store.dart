// lib/storage/local_invoice_store.dart
// Mode "Lokal" untuk foto invoice: disimpan di folder privat aplikasi di HP
// ini saja (setara IndexedDB di versi web) — TIDAK PERNAH dikirim ke
// server, dan sekarang dienkripsi di penyimpanan (AES-256, kunci lokal
// perangkat — lihat vault_key.dart). Bisa dibawa pindah HP lewat arsip
// terenkripsi-passphrase (lihat document_archive_service.dart).
//
// Trade-off yang tetap berlaku: hilang kalau aplikasi di-uninstall atau
// storage dibersihkan tanpa pernah diekspor dulu.
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../crypto/aes_gcm_box.dart';
import 'vault_key.dart';

class LocalInvoiceEntry {
  final String transactionId;
  final String extension;
  final Uint8List bytes;
  LocalInvoiceEntry({
    required this.transactionId,
    required this.extension,
    required this.bytes,
  });
}

class LocalInvoiceStore {
  static const _encSuffix = '.enc';

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/local_invoices');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> saveLocalInvoice(
    String transactionId,
    File source,
  ) async {
    final dir = await _dir();
    final ext = source.path.split('.').last;
    final bytes = await source.readAsBytes();
    await _writeEncrypted(dir, transactionId, ext, bytes);
    // Bersihkan file lama tanpa ekstensi terenkripsi kalau ada (jaga-jaga
    // ganti tipe file untuk transaksi yang sama).
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith('$transactionId.') &&
          name != '$transactionId.$ext$_encSuffix') {
        await f.delete();
      }
    }
  }

  static Future<void> _writeEncrypted(
    Directory dir,
    String transactionId,
    String ext,
    Uint8List bytes,
  ) async {
    final key = await VaultKeyStore.instance.getOrCreateKey();
    final sealed = await aesGcmSeal(bytes, key);
    final dest = File('${dir.path}/$transactionId.$ext$_encSuffix');
    await dest.writeAsBytes(sealed);
  }

  /// Cari file untuk [transactionId] — mendukung migrasi otomatis dari
  /// format lama (foto tersimpan polos, sebelum fitur enkripsi ini ada):
  /// kalau ketemu file lama, langsung dienkripsi di tempat lalu file lama
  /// dihapus, supaya semua foto lokal pelan-pelan ikut ter-upgrade.
  static Future<File?> _findEncryptedFile(
    Directory dir,
    String transactionId,
  ) async {
    if (!await dir.exists()) return null;
    final files = dir.listSync().whereType<File>().toList();

    final encMatch = files.where(
      (f) =>
          f.uri.pathSegments.last.startsWith('$transactionId.') &&
          f.path.endsWith(_encSuffix),
    );
    if (encMatch.isNotEmpty) return encMatch.first;

    // Migrasi dari format lama (belum ada akhiran .enc -> belum terenkripsi).
    final legacyMatch = files.where(
      (f) => f.uri.pathSegments.last.startsWith('$transactionId.'),
    );
    if (legacyMatch.isEmpty) return null;
    final legacy = legacyMatch.first;
    final ext = legacy.path.split('.').last;
    final bytes = await legacy.readAsBytes();
    await _writeEncrypted(dir, transactionId, ext, bytes);
    await legacy.delete();
    return File('${dir.path}/$transactionId.$ext$_encSuffix');
  }

  /// Baca & dekripsi foto invoice lokal untuk [transactionId]. Return null
  /// kalau tidak ada.
  static Future<Uint8List?> getLocalInvoiceBytes(String transactionId) async {
    final dir = await _dir();
    final file = await _findEncryptedFile(dir, transactionId);
    if (file == null) return null;
    final key = await VaultKeyStore.instance.getOrCreateKey();
    try {
      final sealed = await file.readAsBytes();
      return await aesGcmOpen(sealed, key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteLocalInvoice(String transactionId) async {
    final dir = await _dir();
    final file = await _findEncryptedFile(dir, transactionId);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  /// Cek beberapa id transaksi sekaligus, kembalikan set id yang punya foto lokal.
  static Future<Set<String>> getLocalInvoiceIds(
    List<String> transactionIds,
  ) async {
    final dir = await _dir();
    if (!await dir.exists()) return {};
    final files = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
    final result = <String>{};
    for (final id in transactionIds) {
      if (files.any((name) => name.startsWith('$id.'))) result.add(id);
    }
    return result;
  }

  /// Semua foto invoice lokal, sudah didekripsi — dipakai saat membuat
  /// arsip ekspor. Bisa cukup besar di memori kalau foto banyak; wajar
  /// untuk skala pemakaian rumah tangga.
  static Future<List<LocalInvoiceEntry>> getAllEntries() async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final key = await VaultKeyStore.instance.getOrCreateKey();
    final entries = <LocalInvoiceEntry>[];
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.endsWith(_encSuffix)) continue;
      final withoutSuffix = name.substring(0, name.length - _encSuffix.length);
      final dot = withoutSuffix.lastIndexOf('.');
      if (dot < 0) continue;
      final transactionId = withoutSuffix.substring(0, dot);
      final ext = withoutSuffix.substring(dot + 1);
      try {
        final sealed = await f.readAsBytes();
        final bytes = await aesGcmOpen(sealed, key);
        entries.add(
          LocalInvoiceEntry(
            transactionId: transactionId,
            extension: ext,
            bytes: bytes,
          ),
        );
      } catch (_) {
        // Lewati file yang gagal dibaca/didekripsi, jangan gagalkan semua.
      }
    }
    return entries;
  }

  /// Simpan ulang satu entri dari arsip yang diimpor — dienkripsi ulang
  /// dengan vault key perangkat SAAT INI (bisa beda dari perangkat asal).
  static Future<void> restoreEntry(LocalInvoiceEntry entry) async {
    final dir = await _dir();
    await _writeEncrypted(
      dir,
      entry.transactionId,
      entry.extension,
      entry.bytes,
    );
  }
}
