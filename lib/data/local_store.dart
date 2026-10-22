// lib/data/local_store.dart
// Implementasi lokal (SQLite) dari seluruh operasi data yang dulu dilayani
// server (app/api/* di repo web). Aturan bisnis & pesan error-nya disamakan
// persis dengan versi server, supaya perilaku layar tidak berubah.
// Signature method-nya sama dengan DataApi, jadi DataApi tinggal
// mendelegasikan ke sini.
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uuid/uuid.dart';
import '../api/auth_api.dart' show ApiException;
import '../models/models.dart';
import 'local_db.dart';

class LocalStore {
  static const backupFormatVersion = 1;
  static const _uuid = Uuid();

  static Future<Database> get _db => LocalDb.instance;

  static int _now() => DateTime.now().millisecondsSinceEpoch;
  static String _newId() => _uuid.v4();
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  // Server dulu mengirim tanggal sebagai tengah malam UTC; disamakan supaya
  // perbandingan tanggal di layar tidak bergeser.
  static DateTime _parseDay(String s) {
    final d = DateTime.parse(s);
    return DateTime.utc(d.year, d.month, d.day);
  }

  static Map<String, Object?> _newRow(Map<String, Object?> values) {
    final now = _now();
    return {
      'id': _newId(),
      ...values,
      'created_at': now,
      'updated_at': now,
      'deleted': 0,
    };
  }

  static Future<Map<String, Object?>?> _find(
    DatabaseExecutor db,
    String table,
    String id,
  ) async {
    final rows = await db.query(
      table,
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> _update(
    DatabaseExecutor db,
    String table,
    String id,
    Map<String, Object?> values,
  ) => db.update(
    table,
    {...values, 'updated_at': _now()},
    where: 'id = ?',
    whereArgs: [id],
  );

  static Future<void> _softDelete(
    DatabaseExecutor db,
    String table,
    String id,
  ) => _update(db, table, id, {'deleted': 1});

  static String _requireName(String name, String message) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ApiException(message);
    return trimmed;
  }

  static double _num(Object? v) =>
      v == null ? 0 : (v is num ? v.toDouble() : double.parse(v.toString()));
  static double? _numOrNull(Object? v) => v == null ? null : _num(v);

  // ---------------------------------------------------------------- Akun

  static Future<List<Account>> getAccounts() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT a.id, a.name, a.type,
        COALESCE((SELECT SUM(CASE WHEN t.type = 'income' THEN t.amount
                                  ELSE -t.amount END)
                  FROM transactions t
                  WHERE t.account_id = a.id AND t.deleted = 0), 0) AS balance
      FROM accounts a
      WHERE a.deleted = 0
      ORDER BY a.created_at ASC''');
    return rows
        .map(
          (r) => Account(
            id: r['id'] as String,
            name: r['name'] as String,
            type: r['type'] as String,
            balance: _num(r['balance']),
          ),
        )
        .toList();
  }

  static Future<void> createAccount({
    required String name,
    required String type,
  }) async {
    final n = _requireName(name, 'Nama akun wajib diisi.');
    if (type.trim().isEmpty) throw ApiException('Jenis akun wajib diisi.');
    final db = await _db;
    await db.insert('accounts', _newRow({'name': n, 'type': type}));
  }

  static Future<void> renameAccount(String id, String name) async {
    final n = _requireName(name, 'Nama akun wajib diisi.');
    final db = await _db;
    if (await _find(db, 'accounts', id) == null) {
      throw ApiException('Akun tidak ditemukan.');
    }
    await _update(db, 'accounts', id, {'name': n});
  }

  static Future<void> deleteAccount(String id) async {
    final db = await _db;
    await db.transaction((tx) async {
      if (await _find(tx, 'accounts', id) == null) {
        throw ApiException('Akun tidak ditemukan.');
      }
      final count = Sqflite.firstIntValue(
        await tx.rawQuery(
          'SELECT COUNT(*) FROM transactions WHERE account_id = ? AND deleted = 0',
          [id],
        ),
      )!;
      if (count > 0) {
        throw ApiException(
          'Akun ini masih punya $count transaksi, tidak bisa dihapus.',
        );
      }
      await _softDelete(tx, 'accounts', id);
    });
  }

  // ---------------------------------------------------------------- Utang

  static const _debtQuery = '''
    SELECT d.*,
      COALESCE((SELECT SUM(p.amount) FROM debt_payments p
                WHERE p.debt_id = d.id AND p.deleted = 0), 0)
      + COALESCE((SELECT SUM(t.amount) FROM transactions t
                  WHERE t.debt_id = d.id AND t.deleted = 0
                    AND t.type = 'expense'), 0) AS paid
    FROM debts d
    WHERE d.deleted = 0''';

  static Debt _debtFromRow(Map<String, Object?> r) {
    final total = _num(r['total_amount']);
    final remaining = (total - _num(r['paid'])).clamp(0, total).toDouble();
    return Debt(
      id: r['id'] as String,
      name: r['name'] as String,
      type: r['type'] as String,
      totalAmount: total,
      remainingAmount: remaining,
      monthlyInstallment: _num(r['monthly_installment']),
    );
  }

  static Future<List<Debt>> getDebts({bool activeOnly = false}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '$_debtQuery ORDER BY d.start_date DESC, d.created_at DESC',
    );
    final debts = rows.map(_debtFromRow).toList();
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
    final n = _requireName(name, 'Nama utang wajib diisi.');
    if (type.trim().isEmpty) throw ApiException('Jenis utang wajib diisi.');
    if (totalAmount <= 0) throw ApiException('Total pokok tidak valid.');
    if (monthlyInstallment <= 0) {
      throw ApiException('Cicilan per bulan tidak valid.');
    }
    final db = await _db;
    await db.insert(
      'debts',
      _newRow({
        'name': n,
        'type': type,
        'total_amount': totalAmount,
        'monthly_installment': monthlyInstallment,
        'start_date': _day(startDate),
      }),
    );
  }

  static Future<void> payDebt(String id, double paymentAmount) async {
    if (paymentAmount <= 0) {
      throw ApiException('Jumlah pembayaran tidak valid.');
    }
    final db = await _db;
    await db.transaction((tx) async {
      if (await _find(tx, 'debts', id) == null) {
        throw ApiException('Utang tidak ditemukan.');
      }
      await tx.insert(
        'debt_payments',
        _newRow({'debt_id': id, 'amount': paymentAmount}),
      );
    });
  }

  static Future<void> renameDebt(String id, String name) async {
    final n = _requireName(name, 'Nama utang wajib diisi.');
    final db = await _db;
    if (await _find(db, 'debts', id) == null) {
      throw ApiException('Utang tidak ditemukan.');
    }
    await _update(db, 'debts', id, {'name': n});
  }

  static Future<void> deleteDebt(String id) async {
    final db = await _db;
    if (await _find(db, 'debts', id) == null) {
      throw ApiException('Utang tidak ditemukan.');
    }
    // Sama seperti server (onDelete: SetNull): transaksi yang tertaut tetap
    // ada, cuma tautan utangnya yang hilang.
    await db.transaction((tx) async {
      await _softDelete(tx, 'debts', id);
      await tx.update(
        'transactions',
        {'debt_id': null, 'updated_at': _now()},
        where: 'debt_id = ? AND deleted = 0',
        whereArgs: [id],
      );
    });
  }

  // ---------------------------------------------------------------- Aset

  static Future<List<Asset>> getAssets() async {
    final db = await _db;
    final rows = await db.query(
      'assets',
      where: 'deleted = 0',
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (r) => Asset(
            id: r['id'] as String,
            name: r['name'] as String,
            type: r['type'] as String,
            currentValue: _num(r['current_value']),
          ),
        )
        .toList();
  }

  static Future<void> createAsset({
    required String name,
    required String type,
    required double currentValue,
  }) async {
    final n = _requireName(name, 'Nama aset wajib diisi.');
    if (type.trim().isEmpty) throw ApiException('Jenis aset wajib diisi.');
    if (currentValue <= 0) throw ApiException('Nilai aset tidak valid.');
    final db = await _db;
    await db.insert(
      'assets',
      _newRow({'name': n, 'type': type, 'current_value': currentValue}),
    );
  }

  static Future<void> updateAssetValue(String id, double currentValue) async {
    if (currentValue <= 0) throw ApiException('Nilai aset tidak valid.');
    final db = await _db;
    if (await _find(db, 'assets', id) == null) {
      throw ApiException('Aset tidak ditemukan.');
    }
    await _update(db, 'assets', id, {'current_value': currentValue});
  }

  static Future<void> renameAsset(String id, String name) async {
    final n = _requireName(name, 'Nama aset wajib diisi.');
    final db = await _db;
    if (await _find(db, 'assets', id) == null) {
      throw ApiException('Aset tidak ditemukan.');
    }
    await _update(db, 'assets', id, {'name': n});
  }

  static Future<void> deleteAsset(String id) async {
    final db = await _db;
    if (await _find(db, 'assets', id) == null) {
      throw ApiException('Aset tidak ditemukan.');
    }
    await _softDelete(db, 'assets', id);
  }

  // ---------------------------------------------------------------- Anggaran

  static Future<Map<String, double>> getBudgets() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT b.category_id, b.monthly_amount FROM budgets b
      JOIN categories c ON c.id = b.category_id AND c.deleted = 0
      WHERE b.deleted = 0''');
    return {
      for (final r in rows)
        r['category_id'] as String: _num(r['monthly_amount']),
    };
  }

  static Future<void> saveBudget(
    String categoryId,
    double monthlyAmount,
  ) async {
    if (categoryId.isEmpty) throw ApiException('Kategori wajib dipilih.');
    if (monthlyAmount < 0) throw ApiException('Jumlah anggaran tidak valid.');
    final db = await _db;
    final category = await _find(db, 'categories', categoryId);
    if (category == null) throw ApiException('Kategori tidak ditemukan.');
    if (category['type'] != 'expense') {
      throw ApiException(
        'Anggaran hanya bisa diatur untuk kategori Pengeluaran.',
      );
    }
    final now = _now();
    await db.rawInsert(
      '''
      INSERT INTO budgets (category_id, monthly_amount, created_at, updated_at, deleted)
      VALUES (?, ?, ?, ?, 0)
      ON CONFLICT(category_id) DO UPDATE SET
        monthly_amount = excluded.monthly_amount,
        updated_at = excluded.updated_at,
        deleted = 0''',
      [categoryId, monthlyAmount, now, now],
    );
  }

  // ---------------------------------------------------------------- Kategori

  static Future<List<Category>> getCategories({String? type}) async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      where: type == null ? 'deleted = 0' : 'deleted = 0 AND type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'name ASC',
    );
    return rows
        .map(
          (r) => Category(
            id: r['id'] as String,
            name: r['name'] as String,
            type: r['type'] as String,
          ),
        )
        .toList();
  }

  static Future<bool> _categoryNameTaken(
    DatabaseExecutor db,
    String name,
    String type, {
    String? exceptId,
  }) async {
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: exceptId == null
          ? 'deleted = 0 AND name = ? AND type = ?'
          : 'deleted = 0 AND name = ? AND type = ? AND id != ?',
      whereArgs: [name, type, ?exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<void> createCategory(
    String name, {
    String type = 'expense',
  }) async {
    final n = _requireName(name, 'Nama kategori wajib diisi.');
    if (type != 'income' && type != 'expense') {
      throw ApiException('Tipe kategori tidak valid.');
    }
    final db = await _db;
    await db.transaction((tx) async {
      if (await _categoryNameTaken(tx, n, type)) {
        throw ApiException('Kategori dengan nama itu sudah ada.');
      }
      await tx.insert('categories', _newRow({'name': n, 'type': type}));
    });
  }

  static Future<void> updateCategory(String id, String name) async {
    final n = _requireName(name, 'Nama kategori wajib diisi.');
    final db = await _db;
    await db.transaction((tx) async {
      final existing = await _find(tx, 'categories', id);
      if (existing == null) throw ApiException('Kategori tidak ditemukan.');
      if (await _categoryNameTaken(
        tx,
        n,
        existing['type'] as String,
        exceptId: id,
      )) {
        throw ApiException('Kategori dengan nama itu sudah ada.');
      }
      await _update(tx, 'categories', id, {'name': n});
    });
  }

  static Future<void> deleteCategory(String id) async {
    final db = await _db;
    await db.transaction((tx) async {
      if (await _find(tx, 'categories', id) == null) {
        throw ApiException('Kategori tidak ditemukan.');
      }
      final used = Sqflite.firstIntValue(
        await tx.rawQuery(
          'SELECT COUNT(*) FROM transactions WHERE category_id = ? AND deleted = 0',
          [id],
        ),
      )!;
      if (used > 0) {
        throw ApiException(
          'Kategori masih dipakai oleh transaksi, tidak bisa dihapus.',
        );
      }
      await _softDelete(tx, 'categories', id);
      await tx.update(
        'budgets',
        {'deleted': 1, 'updated_at': _now()},
        where: 'category_id = ?',
        whereArgs: [id],
      );
    });
  }

  // ---------------------------------------------------------------- Investasi

  static Future<List<Investment>> getInvestments() async {
    final db = await _db;
    final rows = await db.query(
      'investments',
      where: 'deleted = 0',
      orderBy: 'start_date DESC, created_at DESC',
    );
    return rows
        .map(
          (r) => Investment(
            id: r['id'] as String,
            name: r['name'] as String,
            type: r['type'] as String,
            investedAmount: _num(r['invested_amount']),
            currentAmount: _num(r['current_amount']),
          ),
        )
        .toList();
  }

  static Future<void> createInvestment({
    required String name,
    required String type,
    required double investedAmount,
    required double currentAmount,
    required DateTime startDate,
  }) async {
    final n = _requireName(name, 'Nama investasi wajib diisi.');
    if (type.trim().isEmpty) {
      throw ApiException('Jenis investasi wajib diisi.');
    }
    if (investedAmount <= 0) throw ApiException('Modal awal tidak valid.');
    if (currentAmount < 0) throw ApiException('Nilai saat ini tidak valid.');
    final db = await _db;
    await db.insert(
      'investments',
      _newRow({
        'name': n,
        'type': type,
        'invested_amount': investedAmount,
        'current_amount': currentAmount,
        'start_date': _day(startDate),
      }),
    );
  }

  static Future<void> updateInvestmentValue(
    String id,
    double currentAmount,
  ) async {
    if (currentAmount < 0) throw ApiException('Nilai saat ini tidak valid.');
    final db = await _db;
    if (await _find(db, 'investments', id) == null) {
      throw ApiException('Investasi tidak ditemukan.');
    }
    await _update(db, 'investments', id, {
      'current_amount': currentAmount,
      'last_price_updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> renameInvestment(String id, String name) async {
    final n = _requireName(name, 'Nama investasi wajib diisi.');
    final db = await _db;
    if (await _find(db, 'investments', id) == null) {
      throw ApiException('Investasi tidak ditemukan.');
    }
    await _update(db, 'investments', id, {'name': n});
  }

  static Future<void> deleteInvestment(String id) async {
    final db = await _db;
    if (await _find(db, 'investments', id) == null) {
      throw ApiException('Investasi tidak ditemukan.');
    }
    await _softDelete(db, 'investments', id);
  }

  // ---------------------------------------------------------------- Transaksi

  static Future<List<Transaction>> getTransactions() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.*, a.name AS account_name, d.name AS debt_name,
        c.name AS category_name, c.type AS category_type
      FROM transactions t
      LEFT JOIN accounts a ON a.id = t.account_id
      LEFT JOIN debts d ON d.id = t.debt_id AND d.deleted = 0
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.deleted = 0
      ORDER BY t.date DESC, t.created_at DESC''');
    return rows
        .map(
          (r) => Transaction(
            id: r['id'] as String,
            type: r['type'] as String,
            amount: _num(r['amount']),
            name: r['name'] as String,
            category: Category(
              id: r['category_id'] as String,
              name: (r['category_name'] as String?) ?? '',
              type: (r['category_type'] as String?) ?? 'expense',
            ),
            date: _parseDay(r['date'] as String),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              r['created_at'] as int,
              isUtc: true,
            ),
            note: r['note'] as String?,
            accountId: r['account_id'] as String,
            accountName: r['account_name'] as String?,
            debtId: r['debt_id'] as String?,
            debtName: r['debt_name'] as String?,
            invoiceUrl: r['invoice_url'] as String?,
          ),
        )
        .toList();
  }

  // Validasi bersama create & update — sama dengan app/api/transactions.
  static Future<Map<String, Object?>> _validateTransaction(
    DatabaseExecutor db, {
    required String type,
    required double amount,
    required String name,
    required String categoryId,
    required DateTime date,
    required String accountId,
    String? note,
    String? debtId,
  }) async {
    if (type != 'income' && type != 'expense') {
      throw ApiException("Tipe transaksi harus 'income' atau 'expense'.");
    }
    if (amount <= 0) throw ApiException('Jumlah harus lebih dari 0.');
    final n = _requireName(name, 'Nama transaksi wajib diisi.');
    if (categoryId.isEmpty) throw ApiException('Kategori wajib dipilih.');
    if (accountId.isEmpty) throw ApiException('Akun kas/bank wajib dipilih.');
    if (await _find(db, 'accounts', accountId) == null) {
      throw ApiException('Akun tidak ditemukan.');
    }
    if (await _find(db, 'categories', categoryId) == null) {
      throw ApiException('Kategori tidak ditemukan.');
    }
    final debt = (debtId == null || debtId.isEmpty) ? null : debtId;
    if (debt != null) {
      if (type != 'expense') {
        throw ApiException('Pembayaran utang harus berupa pengeluaran.');
      }
      if (await _find(db, 'debts', debt) == null) {
        throw ApiException('Utang tidak ditemukan.');
      }
    }
    final trimmedNote = note?.trim();
    return {
      'type': type,
      'amount': amount,
      'name': n,
      'category_id': categoryId,
      'date': _day(date),
      'account_id': accountId,
      'note': (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      'debt_id': debt,
    };
  }

  /// Mengembalikan id transaksi yang baru dibuat.
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
    final db = await _db;
    return db.transaction((tx) async {
      final values = await _validateTransaction(
        tx,
        type: type,
        amount: amount,
        name: name,
        categoryId: categoryId,
        date: date,
        accountId: accountId,
        note: note,
        debtId: debtId,
      );
      final row = _newRow({...values, 'invoice_url': invoiceUrl});
      await tx.insert('transactions', row);
      return row['id'] as String;
    });
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
    final db = await _db;
    await db.transaction((tx) async {
      if (await _find(tx, 'transactions', id) == null) {
        throw ApiException('Transaksi tidak ditemukan.');
      }
      final values = await _validateTransaction(
        tx,
        type: type,
        amount: amount,
        name: name,
        categoryId: categoryId,
        date: date,
        accountId: accountId,
        note: note,
        debtId: debtId,
      );
      await _update(tx, 'transactions', id, values);
    });
  }

  static Future<void> deleteTransaction(String id) async {
    final db = await _db;
    if (await _find(db, 'transactions', id) == null) {
      throw ApiException('Transaksi tidak ditemukan.');
    }
    await _softDelete(db, 'transactions', id);
  }

  // ---------------------------------------------------------------- Backup

  /// Seluruh data dalam format backup v1 (sama dengan app/api/backup/export
  /// di server, jadi file backup lama & baru saling kompatibel).
  static Future<Map<String, dynamic>> exportBackup() async {
    final db = await _db;
    Future<List<Map<String, Object?>>> live(String table) =>
        db.query(table, where: 'deleted = 0', orderBy: 'created_at ASC');

    final debts = await db.rawQuery('$_debtQuery ORDER BY d.created_at ASC');
    return {
      'version': backupFormatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'householdName': '',
      'categories': [
        for (final c in await live('categories'))
          {'id': c['id'], 'name': c['name'], 'type': c['type']},
      ],
      'accounts': [
        for (final a in await live('accounts'))
          {'id': a['id'], 'name': a['name'], 'type': a['type']},
      ],
      'assets': [
        for (final a in await live('assets'))
          {
            'id': a['id'],
            'name': a['name'],
            'type': a['type'],
            'currentValue': a['current_value'],
            'acquisitionValue': a['acquisition_value'],
            'acquisitionDate': a['acquisition_date'],
            'note': a['note'],
          },
      ],
      'debts': [
        for (final d in debts)
          {
            'id': d['id'],
            'name': d['name'],
            'type': d['type'],
            'totalAmount': d['total_amount'],
            'remainingAmount': _debtFromRow(d).remainingAmount,
            'monthlyInstallment': d['monthly_installment'],
            'dueDay': d['due_day'],
            'startDate': d['start_date'],
            'note': d['note'],
          },
      ],
      'investments': [
        for (final i in await live('investments'))
          {
            'id': i['id'],
            'name': i['name'],
            'type': i['type'],
            'ticker': i['ticker'],
            'lots': i['lots'],
            'avgPrice': i['avg_price'],
            'investedAmount': i['invested_amount'],
            'currentAmount': i['current_amount'],
            'lastPriceUpdatedAt': i['last_price_updated_at'],
            'startDate': i['start_date'],
          },
      ],
      'budgets': [
        for (final e in (await getBudgets()).entries)
          {'categoryId': e.key, 'monthlyAmount': e.value},
      ],
      'goals': [
        for (final g in await live('goals'))
          {
            'id': g['id'],
            'name': g['name'],
            'targetAmount': g['target_amount'],
            'savedAmount': g['saved_amount'],
            'deadline': g['deadline'],
          },
      ],
      'transactions': [
        for (final t in await live('transactions'))
          {
            'id': t['id'],
            'accountId': t['account_id'],
            'debtId': t['debt_id'],
            'type': t['type'],
            'amount': t['amount'],
            'name': t['name'],
            'categoryId': t['category_id'],
            'date': t['date'],
            'note': t['note'],
            'invoiceUrl': t['invoice_url'],
          },
      ],
    };
  }

  /// Pulihkan dari isi backup v1 (buatan server maupun buatan app ini) —
  /// MENGGANTI TOTAL data saat ini. Data lama ditandai terhapus (bukan
  /// dibuang), supaya penghapusannya ikut tersinkron ke perangkat lain.
  static Future<Map<String, dynamic>> importBackup(
    Map<String, dynamic> payload,
  ) async {
    if (payload['version'] != backupFormatVersion) {
      throw ApiException(
        'Format file backup tidak dikenali atau tidak kompatibel.',
      );
    }
    List<Map<String, dynamic>> list(String key) => [
      for (final e in (payload[key] as List?) ?? const [])
        Map<String, dynamic>.from(e as Map),
    ];
    // Tanggal dari server berbentuk ISO lengkap ("2026-01-05T00:00:00.000Z");
    // yang disimpan cukup bagian tanggalnya.
    String? day(Object? v) => v?.toString().substring(0, 10);

    final categories = list('categories');
    final accounts = list('accounts');
    final assets = list('assets');
    final debts = list('debts');
    final investments = list('investments');
    final budgets = list('budgets');
    final goals = list('goals');
    final transactions = list('transactions');

    final db = await _db;
    try {
      await db.transaction((tx) async {
        final now = _now();
        const tables = [
          'accounts',
          'categories',
          'transactions',
          'debts',
          'debt_payments',
          'assets',
          'investments',
          'goals',
        ];
        for (final table in tables) {
          await tx.update(table, {
            'deleted': 1,
            'updated_at': now,
          }, where: 'deleted = 0');
        }
        await tx.update('budgets', {
          'deleted': 1,
          'updated_at': now,
        }, where: 'deleted = 0');

        Future<void> put(String table, Map<String, Object?> values) =>
            tx.insert(table, {
              ...values,
              'created_at': now,
              'updated_at': now,
              'deleted': 0,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final c in categories) {
          await put('categories', {
            'id': c['id'],
            'name': c['name'],
            // Backup lama belum menyimpan `type`.
            'type': c['type'] == 'income' ? 'income' : 'expense',
          });
        }
        for (final a in accounts) {
          await put('accounts', {
            'id': a['id'],
            'name': a['name'],
            'type': a['type'],
          });
        }
        for (final a in assets) {
          await put('assets', {
            'id': a['id'],
            'name': a['name'],
            'type': a['type'],
            'current_value': _num(a['currentValue']),
            'acquisition_value': _numOrNull(a['acquisitionValue']),
            'acquisition_date': day(a['acquisitionDate']),
            'note': a['note'],
          });
        }
        for (final i in investments) {
          await put('investments', {
            'id': i['id'],
            'name': i['name'],
            'type': i['type'],
            'ticker': i['ticker'],
            'lots': i['lots'],
            'avg_price': _numOrNull(i['avgPrice']),
            'invested_amount': _num(i['investedAmount']),
            'current_amount': _num(i['currentAmount']),
            'last_price_updated_at': i['lastPriceUpdatedAt'],
            'start_date': day(i['startDate']),
          });
        }
        for (final g in goals) {
          await put('goals', {
            'id': g['id'],
            'name': g['name'],
            'target_amount': _num(g['targetAmount']),
            'saved_amount': _num(g['savedAmount']),
            'deadline': day(g['deadline']),
          });
        }
        for (final b in budgets) {
          await put('budgets', {
            'category_id': b['categoryId'],
            'monthly_amount': _num(b['monthlyAmount']),
          });
        }
        for (final t in transactions) {
          await put('transactions', {
            'id': t['id'],
            'account_id': t['accountId'],
            'debt_id': t['debtId'],
            'type': t['type'],
            'amount': _num(t['amount']),
            'name': t['name'],
            'category_id': t['categoryId'],
            'date': day(t['date']),
            'note': t['note'],
            'invoice_url': t['invoiceUrl'],
          });
        }
        for (final d in debts) {
          final id = d['id'] as String;
          final total = _num(d['totalAmount']);
          await put('debts', {
            'id': id,
            'name': d['name'],
            'type': d['type'],
            'total_amount': total,
            'monthly_installment': _num(d['monthlyInstallment']),
            'due_day': d['dueDay'],
            'start_date': day(d['startDate']),
            'note': d['note'],
          });
          // Backup cuma menyimpan sisa utang. Selisihnya dengan total yang
          // belum terjelaskan oleh transaksi tertaut dicatat sebagai satu
          // baris pembayaran penyesuaian, supaya sisa hasil hitungan sama
          // persis dengan yang tersimpan di backup.
          final linked = transactions
              .where((t) => t['debtId'] == id && t['type'] == 'expense')
              .fold<double>(0, (sum, t) => sum + _num(t['amount']));
          final adjustment = total - _num(d['remainingAmount']) - linked;
          if (adjustment != 0) {
            await put('debt_payments', {
              'id': _newId(),
              'debt_id': id,
              'amount': adjustment,
            });
          }
        }
      });
    } catch (_) {
      throw ApiException(
        'Gagal memulihkan backup. Pastikan file backup valid dan tidak rusak.',
      );
    }

    return {
      'message': 'Data berhasil dipulihkan dari backup.',
      'counts': {
        'categories': categories.length,
        'accounts': accounts.length,
        'assets': assets.length,
        'debts': debts.length,
        'investments': investments.length,
        'budgets': budgets.length,
        'goals': goals.length,
        'transactions': transactions.length,
      },
    };
  }
}
