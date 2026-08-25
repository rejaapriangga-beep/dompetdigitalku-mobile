// lib/api/data_api.dart
// Semua panggilan API data (bukan auth) — 1:1 dengan endpoint yang sama
// persis dipakai versi web, cuma beda cara autentikasi (Bearer token).
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'auth_api.dart' show ApiException;
import '../models/models.dart';

class DataApi {
  static Future<List<Account>> getAccounts() async {
    final res = await ApiClient.instance.dio.get('/accounts');
    return (res.data['accounts'] as List)
        .map((e) => Account.fromJson(e))
        .toList();
  }

  static Future<List<Debt>> getDebts({bool activeOnly = false}) async {
    final res = await ApiClient.instance.dio.get('/debts');
    final debts = (res.data['debts'] as List)
        .map((e) => Debt.fromJson(e))
        .toList();
    return activeOnly
        ? debts.where((d) => d.remainingAmount > 0).toList()
        : debts;
  }

  static Future<void> createDebt({
    required String name,
    required String type,
    required double totalAmount,
    required double monthlyInstallment,
    required DateTime startDate,
  }) async {
    await ApiClient.instance.dio.post(
      '/debts',
      data: {
        'name': name,
        'type': type,
        'totalAmount': totalAmount,
        'monthlyInstallment': monthlyInstallment,
        'startDate': startDate.toIso8601String().substring(0, 10),
      },
    );
  }

  static Future<void> payDebt(String id, double paymentAmount) async {
    await ApiClient.instance.dio.patch(
      '/debts/$id',
      data: {'paymentAmount': paymentAmount},
    );
  }

  static Future<void> deleteDebt(String id) async {
    await ApiClient.instance.dio.delete('/debts/$id');
  }

  static Future<List<Asset>> getAssets() async {
    final res = await ApiClient.instance.dio.get('/assets');
    return (res.data['assets'] as List).map((e) => Asset.fromJson(e)).toList();
  }

  static Future<void> createAsset({
    required String name,
    required String type,
    required double currentValue,
  }) async {
    await ApiClient.instance.dio.post(
      '/assets',
      data: {'name': name, 'type': type, 'currentValue': currentValue},
    );
  }

  static Future<void> updateAssetValue(String id, double currentValue) async {
    await ApiClient.instance.dio.patch(
      '/assets/$id',
      data: {'currentValue': currentValue},
    );
  }

  static Future<void> deleteAsset(String id) async {
    await ApiClient.instance.dio.delete('/assets/$id');
  }

  static Future<void> createAccount({
    required String name,
    required String type,
  }) async {
    await ApiClient.instance.dio.post(
      '/accounts',
      data: {'name': name, 'type': type},
    );
  }

  static Future<void> deleteAccount(String id) async {
    await ApiClient.instance.dio.delete('/accounts/$id');
  }

  static Future<Map<String, double>> getBudgets() async {
    final res = await ApiClient.instance.dio.get('/budgets');
    final map = <String, double>{};
    for (final b in (res.data['budgets'] as List)) {
      map[b['categoryId']] = double.parse(b['monthlyAmount'].toString());
    }
    return map;
  }

  static Future<void> saveBudget(
    String categoryId,
    double monthlyAmount,
  ) async {
    await ApiClient.instance.dio.put(
      '/budgets',
      data: {'categoryId': categoryId, 'monthlyAmount': monthlyAmount},
    );
  }

  static Future<List<Category>> getCategories({String? type}) async {
    final res = await ApiClient.instance.dio.get(
      '/categories',
      queryParameters: type != null ? {'type': type} : null,
    );
    return (res.data['categories'] as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  static Future<void> createCategory(
    String name, {
    String type = 'expense',
  }) async {
    await ApiClient.instance.dio.post(
      '/categories',
      data: {'name': name, 'type': type},
    );
  }

  static Future<void> updateCategory(String id, String name) async {
    await ApiClient.instance.dio.patch('/categories/$id', data: {'name': name});
  }

  static Future<void> deleteCategory(String id) async {
    await ApiClient.instance.dio.delete('/categories/$id');
  }

  static Future<List<Investment>> getInvestments() async {
    final res = await ApiClient.instance.dio.get('/investments');
    return (res.data['investments'] as List)
        .map((e) => Investment.fromJson(e))
        .toList();
  }

  static Future<void> createInvestment({
    required String name,
    required String type,
    required double investedAmount,
    required double currentAmount,
    required DateTime startDate,
  }) async {
    await ApiClient.instance.dio.post(
      '/investments',
      data: {
        'name': name,
        'type': type,
        'investedAmount': investedAmount,
        'currentAmount': currentAmount,
        'startDate': startDate.toIso8601String().substring(0, 10),
      },
    );
  }

  static Future<void> updateInvestmentValue(
    String id,
    double currentAmount,
  ) async {
    await ApiClient.instance.dio.patch(
      '/investments/$id',
      data: {'currentAmount': currentAmount},
    );
  }

  static Future<void> deleteInvestment(String id) async {
    await ApiClient.instance.dio.delete('/investments/$id');
  }

  static Future<List<Transaction>> getTransactions() async {
    final res = await ApiClient.instance.dio.get('/transactions');
    return (res.data['transactions'] as List)
        .map((e) => Transaction.fromJson(e))
        .toList();
  }

  /// Mengembalikan id transaksi yang baru dibuat (dipakai untuk menyimpan
  /// foto invoice lokal setelah transaksinya punya id).
  static Future<String> createTransaction({
    required String type,
    required double amount,
    required String name,
    required String categoryId,
    required DateTime date,
    required String accountId,
    String? note,
    String? debtId,
    String? invoiceUrl,
  }) async {
    final res = await ApiClient.instance.dio.post(
      '/transactions',
      data: {
        'type': type,
        'amount': amount,
        'name': name,
        'categoryId': categoryId,
        'date': date.toIso8601String().substring(0, 10),
        'accountId': accountId,
        'note': note,
        'debtId': debtId,
        'invoiceUrl': invoiceUrl,
      },
    );
    return res.data['transaction']['id'] as String;
  }

  static Future<void> deleteTransaction(String id) async {
    await ApiClient.instance.dio.delete('/transactions/$id');
  }

  static Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String name,
    required String categoryId,
    required DateTime date,
    required String accountId,
    String? note,
    String? debtId,
  }) async {
    await ApiClient.instance.dio.patch(
      '/transactions/$id',
      data: {
        'type': type,
        'amount': amount,
        'name': name,
        'categoryId': categoryId,
        'date': date.toIso8601String().substring(0, 10),
        'accountId': accountId,
        'note': note,
        'debtId': debtId,
      },
    );
  }

  /// URL endpoint kita sendiri untuk melihat invoice lama yang tersimpan di
  /// R2 (server akan redirect ke URL baca sementara setelah verifikasi
  /// kepemilikan). Foto invoice baru sekarang SELALU tersimpan lokal di HP —
  /// endpoint ini dipertahankan hanya supaya invoice lama (dari sebelum
  /// pilihan "Server" dihilangkan) masih bisa dilihat.
  static String invoiceViewUrl(String key) =>
      '$kApiBaseUrl/uploads/view?key=${Uri.encodeQueryComponent(key)}';

  /// Hapus akun pengguna (bukan akun kas/bank — lihat [deleteAccount] di
  /// atas) beserta seluruh data rumah tangga terkait. Tidak bisa dibatalkan.
  static Future<void> deleteUserAccount() async {
    try {
      await ApiClient.instance.dio.delete('/account');
    } on DioException catch (e) {
      throw ApiException(e.response?.data?['error'] ?? 'Gagal menghapus akun.');
    }
  }

  /// Ambil seluruh data finansial rumah tangga (JSON polos, belum
  /// dienkripsi) untuk dijadikan bahan file backup. Enkripsinya dilakukan
  /// di sisi aplikasi (lihat lib/backup/backup_crypto.dart).
  static Future<Map<String, dynamic>> exportBackup() async {
    try {
      final res = await ApiClient.instance.dio.get('/backup/export');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(e.response?.data?['error'] ?? 'Gagal membuat backup.');
    }
  }

  /// Pulihkan (restore) data rumah tangga dari isi backup yang sudah
  /// didekripsi — MENGGANTI TOTAL data rumah tangga saat ini.
  static Future<Map<String, dynamic>> importBackup(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await ApiClient.instance.dio.post(
        '/backup/import',
        data: payload,
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['error'] ?? 'Gagal memulihkan backup.',
      );
    }
  }
}
