// lib/data/server_migration.dart
// Pindahan satu kali untuk pengguna lama: data yang dulu tersimpan di server
// DompetDigitalKu diunduh ke database lokal HP ini, termasuk foto invoice
// lama yang tersimpan di R2. Setelah itu pengguna bisa menghapus data
// tersebut dari server. Semua ini memakai sesi login lama (token yang sudah
// tersimpan, atau login ulang dari layar Backup).
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/data_api.dart';
import '../storage/local_invoice_store.dart';
import 'local_store.dart';

class MigrationResult {
  final int transactionCount;
  final int invoiceCount;
  final int invoiceFailedCount;
  MigrationResult({
    required this.transactionCount,
    required this.invoiceCount,
    required this.invoiceFailedCount,
  });
}

class ServerMigration {
  static const _migratedKey = 'server_migrated_at';

  /// Ada sesi login lama yang datanya belum dipindah ke HP ini.
  static Future<bool> isPending() async =>
      await AuthApi.isLoggedIn() &&
      await LocalStore.getMeta(_migratedKey) == null;

  static Future<bool> hasServerSession() => AuthApi.isLoggedIn();

  /// Unduh seluruh data dari server lalu ganti data lokal dengannya.
  static Future<MigrationResult> run() async {
    final Map<String, dynamic> data;
    try {
      final res = await ApiClient.instance.dio.get('/backup/export');
      data = Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data is Map
            ? (e.response!.data['error'] ?? 'Gagal mengambil data dari server.')
            : 'Gagal mengambil data dari server. Periksa koneksi internet Anda.',
      );
    }
    await LocalStore.importBackup(data);

    var invoices = 0;
    var failed = 0;
    final transactions = (data['transactions'] as List?) ?? const [];
    for (final raw in transactions) {
      final t = raw as Map;
      final key = t['invoiceUrl'] as String?;
      if (key == null || key.isEmpty) continue;
      final id = t['id'] as String;
      try {
        final bytes = await _downloadInvoice(key);
        final dot = key.lastIndexOf('.');
        final ext = dot >= 0 ? key.substring(dot + 1).toLowerCase() : 'jpg';
        await LocalInvoiceStore.restoreEntry(
          LocalInvoiceEntry(
            transactionId: id,
            extension: ext,
            bytes: Uint8List.fromList(bytes),
          ),
        );
        await LocalStore.clearInvoiceUrl(id);
        invoices++;
      } catch (_) {
        failed++;
      }
    }

    await LocalStore.setMeta(
      _migratedKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    return MigrationResult(
      transactionCount: transactions.length,
      invoiceCount: invoices,
      invoiceFailedCount: failed,
    );
  }

  // Endpoint server membalas redirect ke URL R2 bertanda tangan. Redirect-nya
  // diikuti manual dengan klien tanpa header Authorization, karena R2 menolak
  // permintaan yang membawa dua cara autentikasi sekaligus.
  static Future<List<int>> _downloadInvoice(String key) async {
    final res = await ApiClient.instance.dio.get<List<int>>(
      DataApi.invoiceViewUrl(key),
      options: Options(
        followRedirects: false,
        responseType: ResponseType.bytes,
        validateStatus: (s) => s != null && s < 400,
      ),
    );
    final location = res.headers.value('location');
    if (location == null) return res.data!;
    final file = await Dio().get<List<int>>(
      location,
      options: Options(responseType: ResponseType.bytes),
    );
    return file.data!;
  }

  /// Hapus akun & seluruh data di server, lalu keluar dari sesi lama.
  /// Data lokal di HP tidak disentuh.
  static Future<void> deleteServerData() async {
    try {
      await ApiClient.instance.dio.delete('/account');
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data is Map
            ? (e.response!.data['error'] ?? 'Gagal menghapus data di server.')
            : 'Gagal menghapus data di server. Periksa koneksi internet Anda.',
      );
    }
    await AuthApi.logout();
  }
}
