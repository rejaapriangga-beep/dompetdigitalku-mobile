// lib/data/local_db.dart
// Database SQLite lokal di HP: sumber data utama aplikasi (local-first).
// Data keuangan pengguna tidak lagi disimpan di server kita.
//
// Skema sengaja dibuat siap-sinkron (untuk sinkron antar-perangkat lewat
// Google Drive milik pengguna sendiri):
// - id selalu UUID (atau id tetap untuk data bawaan, lihat _seedDefaults),
//   jadi baris dari dua HP tidak akan bentrok;
// - setiap baris punya updated_at (epoch ms) untuk last-write-wins;
// - hapus = tandai deleted = 1 (tombstone), bukan DELETE, supaya
//   penghapusan ikut tersinkron ke perangkat lain;
// - sisa utang TIDAK disimpan sebagai angka yang terus diubah, tapi dihitung
//   dari total − log pembayaran (debt_payments, insert-only) − transaksi
//   pengeluaran yang ditautkan ke utang itu. Dengan begitu dua pembayaran
//   dari dua HP tidak saling menimpa saat digabung.
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static const _fileName = 'dompetdigitalku.db';
  static const _version = 1;

  static Future<Database>? _instance;

  /// Database aplikasi (dibuka sekali, dipakai bersama).
  static Future<Database> get instance => _instance ??= _open();

  /// Untuk unit test: pakai database yang sudah dibuka (mis. in-memory via
  /// sqflite_common_ffi), skemanya dibuat lewat [createSchema].
  static void useForTesting(Database db) => _instance = Future.value(db);

  static Future<String> _path() async =>
      p.join(await getDatabasesPath(), _fileName);

  /// Hapus seluruh isi database (fitur "Hapus Semua Data"). Pembukaan
  /// berikutnya membuat database baru berisi data bawaan lagi.
  static Future<void> reset() async {
    final current = _instance;
    _instance = null;
    if (current != null) await (await current).close();
    await deleteDatabase(await _path());
  }

  static Future<Database> _open() async {
    final path = await _path();
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, _) => createSchema(db),
    );
  }

  static Future<void> createSchema(DatabaseExecutor db) async {
    const sync = '''
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0''';
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        $sync
      )''');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        $sync
      )''');
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        account_id TEXT NOT NULL,
        note TEXT,
        debt_id TEXT,
        invoice_url TEXT,
        $sync
      )''');
    // Satu anggaran per kategori, jadi id-nya = id kategori.
    await db.execute('''
      CREATE TABLE budgets (
        category_id TEXT PRIMARY KEY,
        monthly_amount REAL NOT NULL,
        $sync
      )''');
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        total_amount REAL NOT NULL,
        monthly_installment REAL NOT NULL,
        due_day INTEGER,
        start_date TEXT NOT NULL,
        note TEXT,
        $sync
      )''');
    // Insert-only. amount bisa negatif untuk baris penyesuaian saat data
    // dipulihkan dari backup lama yang cuma menyimpan sisa utang.
    await db.execute('''
      CREATE TABLE debt_payments (
        id TEXT PRIMARY KEY,
        debt_id TEXT NOT NULL,
        amount REAL NOT NULL,
        $sync
      )''');
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        current_value REAL NOT NULL,
        acquisition_value REAL,
        acquisition_date TEXT,
        note TEXT,
        $sync
      )''');
    await db.execute('''
      CREATE TABLE investments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        ticker TEXT,
        lots INTEGER,
        avg_price REAL,
        invested_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        last_price_updated_at TEXT,
        start_date TEXT NOT NULL,
        $sync
      )''');
    // Belum dipakai UI; disimpan supaya isi backup lama tidak hilang.
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL,
        deadline TEXT,
        $sync
      )''');
    await db.execute(
      'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_account ON transactions (account_id, deleted)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_category ON transactions (category_id, deleted)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_debt ON transactions (debt_id, deleted)',
    );
    await db.execute(
      'CREATE INDEX idx_payment_debt ON debt_payments (debt_id, deleted)',
    );
    await _seedDefaults(db);
  }

  // Data bawaan untuk pengguna baru — sama dengan yang dulu dibuat server
  // saat registrasi. Id-nya tetap (bukan UUID acak) supaya dua HP yang sama-
  // sama baru dipasang lalu disinkron tidak menghasilkan "Kas Utama" ganda.
  // updated_at-nya 0 supaya saat sinkron, perubahan nyata dari HP lain
  // (mis. "Kas Utama" sudah diganti nama) selalu menang atas data bawaan HP
  // yang baru dipasang.
  static Future<void> _seedDefaults(DatabaseExecutor db) async {
    const now = 0;
    await db.insert('accounts', {
      'id': 'default-account-kas-utama',
      'name': 'Kas Utama',
      'type': 'Tunai',
      'created_at': now,
      'updated_at': now,
      'deleted': 0,
    });
    const expense = [
      'Makanan',
      'Transport',
      'Belanja',
      'Hiburan',
      'Tagihan',
      'Kesehatan',
      'Pendidikan',
      'Lainnya',
    ];
    const income = ['Gaji', 'Bonus', 'Lainnya'];
    for (final (type, names) in [('expense', expense), ('income', income)]) {
      for (final name in names) {
        await db.insert('categories', {
          'id': 'default-category-$type-${name.toLowerCase()}',
          'name': name,
          'type': type,
          'created_at': now,
          'updated_at': now,
          'deleted': 0,
        });
      }
    }
  }
}
