// lib/api/data_api.dart
// Pintu masuk semua operasi data untuk layar-layar aplikasi. Sejak versi
// local-first, seluruh data keuangan disimpan di database SQLite di HP ini
// (lihat lib/data/local_store.dart) — tidak ada lagi yang dikirim ke server.
// Kelas ini sengaja dipertahankan sebagai fasad tipis supaya layar tidak
// perlu tahu di mana data disimpan.
import 'api_client.dart';
import '../data/local_store.dart';
import '../models/models.dart';
import '../sync/drive_sync.dart';

class DataApi {
  // Setiap perubahan data menjadwalkan sinkron Google Drive (kalau aktif).
  static Future<T> _changed<T>(Future<T> op) async {
    final result = await op;
    DriveSync.scheduleSync();
    return result;
  }

  static Future<List<Account>> getAccounts() => LocalStore.getAccounts();

  static Future<List<Debt>> getDebts({bool activeOnly = false}) =>
      LocalStore.getDebts(activeOnly: activeOnly);

  static Future<void> createDebt({
    required String name,
    required String type,
    required double totalAmount,
    required double monthlyInstallment,
    required DateTime startDate,
  }) => _changed(LocalStore.createDebt(
    name: name,
    type: type,
    totalAmount: totalAmount,
    monthlyInstallment: monthlyInstallment,
    startDate: startDate,
  ));

  static Future<void> payDebt(String id, double paymentAmount) =>
      _changed(LocalStore.payDebt(id, paymentAmount));

  static Future<void> renameDebt(String id, String name) =>
      _changed(LocalStore.renameDebt(id, name));

  static Future<void> deleteDebt(String id) => _changed(LocalStore.deleteDebt(id));

  static Future<List<Asset>> getAssets() => LocalStore.getAssets();

  static Future<void> createAsset({
    required String name,
    required String type,
    required double currentValue,
  }) => _changed(LocalStore.createAsset(
    name: name,
    type: type,
    currentValue: currentValue,
  ));

  static Future<void> updateAssetValue(String id, double currentValue) =>
      _changed(LocalStore.updateAssetValue(id, currentValue));

  static Future<void> renameAsset(String id, String name) =>
      _changed(LocalStore.renameAsset(id, name));

  static Future<void> deleteAsset(String id) => _changed(LocalStore.deleteAsset(id));

  static Future<void> createAccount({
    required String name,
    required String type,
  }) => _changed(LocalStore.createAccount(name: name, type: type));

  static Future<void> renameAccount(String id, String name) =>
      _changed(LocalStore.renameAccount(id, name));

  static Future<void> deleteAccount(String id) => _changed(LocalStore.deleteAccount(id));

  static Future<Map<String, double>> getBudgets() => LocalStore.getBudgets();

  static Future<void> saveBudget(String categoryId, double monthlyAmount) =>
      _changed(LocalStore.saveBudget(categoryId, monthlyAmount));

  static Future<List<Category>> getCategories({String? type}) =>
      LocalStore.getCategories(type: type);

  static Future<void> createCategory(String name, {String type = 'expense'}) =>
      _changed(LocalStore.createCategory(name, type: type));

  static Future<void> updateCategory(String id, String name) =>
      _changed(LocalStore.updateCategory(id, name));

  static Future<void> deleteCategory(String id) =>
      _changed(LocalStore.deleteCategory(id));

  static Future<List<Investment>> getInvestments() =>
      LocalStore.getInvestments();

  static Future<void> createInvestment({
    required String name,
    required String type,
    required double investedAmount,
    required double currentAmount,
    required DateTime startDate,
  }) => _changed(LocalStore.createInvestment(
    name: name,
    type: type,
    investedAmount: investedAmount,
    currentAmount: currentAmount,
    startDate: startDate,
  ));

  static Future<void> updateInvestmentValue(String id, double currentAmount) =>
      _changed(LocalStore.updateInvestmentValue(id, currentAmount));

  static Future<void> renameInvestment(String id, String name) =>
      _changed(LocalStore.renameInvestment(id, name));

  static Future<void> deleteInvestment(String id) =>
      _changed(LocalStore.deleteInvestment(id));

  static Future<List<Transaction>> getTransactions() =>
      LocalStore.getTransactions();

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
  }) => _changed(LocalStore.createTransaction(
    type: type,
    amount: amount,
    name: name,
    categoryId: categoryId,
    date: date,
    accountId: accountId,
    note: note,
    debtId: debtId,
    invoiceUrl: invoiceUrl,
  ));

  static Future<void> deleteTransaction(String id) =>
      _changed(LocalStore.deleteTransaction(id));

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
  }) => _changed(LocalStore.updateTransaction(
    id: id,
    type: type,
    amount: amount,
    name: name,
    categoryId: categoryId,
    date: date,
    accountId: accountId,
    note: note,
    debtId: debtId,
  ));

  /// URL endpoint server lama untuk melihat invoice yang dulu tersimpan di
  /// R2. Saat data dipindah dari server (lib/data/server_migration.dart),
  /// foto-foto itu diunduh ke HP; endpoint ini cuma cadangan untuk foto
  /// yang gagal diunduh, selama server lama masih hidup.
  static String invoiceViewUrl(String key) =>
      '$kApiBaseUrl/uploads/view?key=${Uri.encodeQueryComponent(key)}';

  /// Seluruh data (JSON polos, belum dienkripsi) untuk bahan file backup.
  /// Enkripsinya di lib/backup/backup_crypto.dart.
  static Future<Map<String, dynamic>> exportBackup() =>
      LocalStore.exportBackup();

  /// Pulihkan data dari isi backup yang sudah didekripsi — MENGGANTI TOTAL
  /// data saat ini.
  static Future<Map<String, dynamic>> importBackup(
    Map<String, dynamic> payload,
  ) => _changed(LocalStore.importBackup(payload));
}
