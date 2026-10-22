// Uji aturan bisnis LocalStore (SQLite lokal) — disamakan dengan perilaku
// API server lama. Jalan di desktop lewat sqflite_common_ffi (in-memory).
import 'package:dompetdigitalku/api/auth_api.dart' show ApiException;
import 'package:dompetdigitalku/data/local_db.dart';
import 'package:dompetdigitalku/data/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _freshDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      singleInstance: false,
      version: 1,
      onCreate: (db, _) => LocalDb.createSchema(db),
    ),
  );
  LocalDb.useForTesting(db);
}

Matcher _throwsMsg(String msg) =>
    throwsA(isA<ApiException>().having((e) => e.message, 'message', msg));

Future<String> _cat(String name, {String type = 'expense'}) async =>
    (await LocalStore.getCategories(
      type: type,
    )).firstWhere((c) => c.name == name).id;

void main() {
  sqfliteFfiInit();
  setUp(_freshDb);

  test('data bawaan pengguna baru', () async {
    final accounts = await LocalStore.getAccounts();
    expect(accounts.single.name, 'Kas Utama');
    expect(accounts.single.type, 'Tunai');
    expect(accounts.single.balance, 0);
    expect((await LocalStore.getCategories(type: 'expense')).length, 8);
    expect(
      (await LocalStore.getCategories(type: 'income')).map((c) => c.name),
      ['Bonus', 'Gaji', 'Lainnya'],
    );
  });

  test('saldo akun = pemasukan − pengeluaran', () async {
    final acc = (await LocalStore.getAccounts()).single.id;
    await LocalStore.createTransaction(
      type: 'income',
      amount: 1000000,
      name: 'Gaji Oktober',
      categoryId: await _cat('Gaji', type: 'income'),
      date: DateTime(2026, 10, 1),
      accountId: acc,
    );
    final txId = await LocalStore.createTransaction(
      type: 'expense',
      amount: 250000,
      name: 'Belanja bulanan',
      categoryId: await _cat('Belanja'),
      date: DateTime(2026, 10, 2),
      accountId: acc,
      note: '  ',
    );
    expect((await LocalStore.getAccounts()).single.balance, 750000);

    final txs = await LocalStore.getTransactions();
    expect(txs.map((t) => t.name), ['Belanja bulanan', 'Gaji Oktober']);
    expect(txs.first.accountName, 'Kas Utama');
    expect(txs.first.category.name, 'Belanja');
    expect(txs.first.note, isNull);
    expect(txs.first.date, DateTime.utc(2026, 10, 2));

    await LocalStore.deleteTransaction(txId);
    expect((await LocalStore.getAccounts()).single.balance, 1000000);
  });

  test('validasi transaksi', () async {
    final acc = (await LocalStore.getAccounts()).single.id;
    final cat = await _cat('Makanan');
    Future<String> create({
      String type = 'expense',
      double amount = 1,
      String name = 'x',
      String? debtId,
      String? accountId,
    }) => LocalStore.createTransaction(
      type: type,
      amount: amount,
      name: name,
      categoryId: cat,
      date: DateTime(2026),
      accountId: accountId ?? acc,
      debtId: debtId,
    );
    expect(create(amount: 0), _throwsMsg('Jumlah harus lebih dari 0.'));
    expect(create(name: ' '), _throwsMsg('Nama transaksi wajib diisi.'));
    expect(
      create(type: 'x'),
      _throwsMsg("Tipe transaksi harus 'income' atau 'expense'."),
    );
    expect(create(accountId: 'nope'), _throwsMsg('Akun tidak ditemukan.'));
    expect(create(debtId: 'nope'), _throwsMsg('Utang tidak ditemukan.'));
    await LocalStore.createDebt(
      name: 'KPR',
      type: 'KPR',
      totalAmount: 100,
      monthlyInstallment: 10,
      startDate: DateTime(2026),
    );
    final debt = (await LocalStore.getDebts()).single.id;
    expect(
      create(type: 'income', debtId: debt),
      _throwsMsg('Pembayaran utang harus berupa pengeluaran.'),
    );
  });

  test('sisa utang: bayar manual, transaksi tertaut, ubah & hapus', () async {
    await LocalStore.createDebt(
      name: 'Motor',
      type: 'Kredit Kendaraan',
      totalAmount: 1000,
      monthlyInstallment: 100,
      startDate: DateTime(2026, 1, 1),
    );
    final debt = (await LocalStore.getDebts()).single;
    expect(debt.remainingAmount, 1000);

    await LocalStore.payDebt(debt.id, 300);
    expect((await LocalStore.getDebts()).single.remainingAmount, 700);

    final acc = (await LocalStore.getAccounts()).single.id;
    final cat = await _cat('Tagihan');
    final txId = await LocalStore.createTransaction(
      type: 'expense',
      amount: 200,
      name: 'Cicilan',
      categoryId: cat,
      date: DateTime(2026, 2, 1),
      accountId: acc,
      debtId: debt.id,
    );
    expect((await LocalStore.getDebts()).single.remainingAmount, 500);
    expect((await LocalStore.getTransactions()).single.debtName, 'Motor');

    // Ubah nominal: 200 → 900, sisa tidak boleh di bawah 0.
    await LocalStore.updateTransaction(
      id: txId,
      type: 'expense',
      amount: 900,
      name: 'Cicilan',
      categoryId: cat,
      date: DateTime(2026, 2, 1),
      accountId: acc,
      debtId: debt.id,
    );
    expect((await LocalStore.getDebts()).single.remainingAmount, 0);
    expect(await LocalStore.getDebts(activeOnly: true), isEmpty);

    // Lepas tautan utang lewat update.
    await LocalStore.updateTransaction(
      id: txId,
      type: 'expense',
      amount: 900,
      name: 'Cicilan',
      categoryId: cat,
      date: DateTime(2026, 2, 1),
      accountId: acc,
    );
    expect((await LocalStore.getDebts()).single.remainingAmount, 700);

    expect(
      LocalStore.payDebt(debt.id, 0),
      _throwsMsg('Jumlah pembayaran tidak valid.'),
    );

    await LocalStore.renameDebt(debt.id, 'Motor Beat');
    expect((await LocalStore.getDebts()).single.name, 'Motor Beat');
    await LocalStore.deleteDebt(debt.id);
    expect(await LocalStore.getDebts(), isEmpty);
  });

  test('hapus akun ditolak kalau masih ada transaksi', () async {
    final acc = (await LocalStore.getAccounts()).single.id;
    final txId = await LocalStore.createTransaction(
      type: 'expense',
      amount: 5,
      name: 'Kopi',
      categoryId: await _cat('Makanan'),
      date: DateTime(2026),
      accountId: acc,
    );
    expect(
      LocalStore.deleteAccount(acc),
      _throwsMsg('Akun ini masih punya 1 transaksi, tidak bisa dihapus.'),
    );
    await LocalStore.deleteTransaction(txId);
    await LocalStore.deleteAccount(acc);
    expect(await LocalStore.getAccounts(), isEmpty);
  });

  test(
    'kategori: duplikat, dipakai transaksi, anggaran ikut terhapus',
    () async {
      expect(
        LocalStore.createCategory('Makanan'),
        _throwsMsg('Kategori dengan nama itu sudah ada.'),
      );
      // Nama sama boleh di tipe berbeda.
      await LocalStore.createCategory('Makanan', type: 'income');
      await LocalStore.createCategory('Donasi');
      final donasi = await _cat('Donasi');
      expect(
        LocalStore.updateCategory(donasi, 'Makanan'),
        _throwsMsg('Kategori dengan nama itu sudah ada.'),
      );

      await LocalStore.saveBudget(donasi, 50000);
      await LocalStore.saveBudget(donasi, 75000);
      expect(await LocalStore.getBudgets(), {donasi: 75000});
      expect(
        LocalStore.saveBudget(await _cat('Gaji', type: 'income'), 1),
        _throwsMsg('Anggaran hanya bisa diatur untuk kategori Pengeluaran.'),
      );

      final acc = (await LocalStore.getAccounts()).single.id;
      final txId = await LocalStore.createTransaction(
        type: 'expense',
        amount: 5,
        name: 'Zakat',
        categoryId: donasi,
        date: DateTime(2026),
        accountId: acc,
      );
      expect(
        LocalStore.deleteCategory(donasi),
        _throwsMsg(
          'Kategori masih dipakai oleh transaksi, tidak bisa dihapus.',
        ),
      );
      await LocalStore.deleteTransaction(txId);
      await LocalStore.deleteCategory(donasi);
      expect(await LocalStore.getBudgets(), isEmpty);

      // Setelah dihapus, nama yang sama boleh dibuat lagi tanpa membawa
      // anggaran lama.
      await LocalStore.createCategory('Donasi');
      expect(await LocalStore.getBudgets(), isEmpty);
    },
  );

  test('aset & investasi', () async {
    await LocalStore.createAsset(
      name: 'Rumah',
      type: 'Properti',
      currentValue: 500,
    );
    final asset = (await LocalStore.getAssets()).single;
    await LocalStore.updateAssetValue(asset.id, 600);
    expect((await LocalStore.getAssets()).single.currentValue, 600);
    expect(
      LocalStore.updateAssetValue(asset.id, 0),
      _throwsMsg('Nilai aset tidak valid.'),
    );
    await LocalStore.deleteAsset(asset.id);
    expect(await LocalStore.getAssets(), isEmpty);

    await LocalStore.createInvestment(
      name: 'Reksadana',
      type: 'Reksa Dana',
      investedAmount: 100,
      currentAmount: 0,
      startDate: DateTime(2026, 3, 1),
    );
    final inv = (await LocalStore.getInvestments()).single;
    await LocalStore.updateInvestmentValue(inv.id, 120);
    await LocalStore.renameInvestment(inv.id, 'RD Pasar Uang');
    final updated = (await LocalStore.getInvestments()).single;
    expect(updated.currentAmount, 120);
    expect(updated.name, 'RD Pasar Uang');
  });

  test('backup: format server dipulihkan, ekspor ulang identik', () async {
    // Bentuk persis keluaran app/api/backup/export (Decimal sebagai string,
    // tanggal ISO lengkap).
    final serverBackup = {
      'version': 1,
      'exportedAt': '2026-10-01T00:00:00.000Z',
      'householdName': 'Rumah',
      'categories': [
        {'id': 'c1', 'name': 'Makan', 'type': 'expense'},
        {'id': 'c2', 'name': 'Gaji'}, // backup lama tanpa type
        {'id': 'c3', 'name': 'Upah', 'type': 'income'},
      ],
      'accounts': [
        {'id': 'a1', 'name': 'BCA', 'type': 'Bank'},
      ],
      'assets': [
        {
          'id': 's1',
          'name': 'Rumah',
          'type': 'Properti',
          'currentValue': '500000000',
          'acquisitionValue': null,
          'acquisitionDate': null,
          'note': null,
        },
      ],
      'debts': [
        {
          'id': 'd1',
          'name': 'KPR',
          'type': 'KPR',
          'totalAmount': '1000',
          'remainingAmount': '600',
          'monthlyInstallment': '50',
          'dueDay': null,
          'startDate': '2025-01-01T00:00:00.000Z',
          'note': null,
        },
      ],
      'investments': [
        {
          'id': 'i1',
          'name': 'Saham',
          'type': 'Saham',
          'ticker': null,
          'lots': null,
          'avgPrice': null,
          'investedAmount': '100',
          'currentAmount': '110',
          'lastPriceUpdatedAt': null,
          'startDate': '2025-06-01T00:00:00.000Z',
        },
      ],
      'budgets': [
        {'categoryId': 'c1', 'monthlyAmount': '2000000'},
      ],
      'goals': [],
      'transactions': [
        {
          'id': 't1',
          'accountId': 'a1',
          'debtId': null,
          'type': 'income',
          'amount': '5000',
          'name': 'Gaji',
          'categoryId': 'c3',
          'date': '2026-09-25T00:00:00.000Z',
          'note': null,
          'invoiceUrl': null,
        },
        {
          'id': 't2',
          'accountId': 'a1',
          'debtId': 'd1',
          'type': 'expense',
          'amount': '150',
          'name': 'Cicilan KPR',
          'categoryId': 'c1',
          'date': '2026-09-26T00:00:00.000Z',
          'note': 'Sept',
          'invoiceUrl': null,
        },
      ],
    };

    final result = await LocalStore.importBackup(serverBackup);
    expect(result['counts']['transactions'], 2);

    // Data bawaan diganti total oleh isi backup.
    final accounts = await LocalStore.getAccounts();
    expect(accounts.single.name, 'BCA');
    expect(accounts.single.balance, 4850);
    expect(
      (await LocalStore.getCategories(type: 'expense')).map((c) => c.name),
      ['Gaji', 'Makan'],
    );
    expect((await LocalStore.getDebts()).single.remainingAmount, 600);
    expect(await LocalStore.getBudgets(), {'c1': 2000000});

    // Hapus transaksi cicilan → sisa utang naik lagi sebesar nominalnya.
    await LocalStore.deleteTransaction('t2');
    expect((await LocalStore.getDebts()).single.remainingAmount, 750);

    final exported = await LocalStore.exportBackup();
    expect(exported['version'], 1);
    expect(exported['debts'][0]['remainingAmount'], 750);
    expect(exported['debts'][0]['startDate'], '2025-01-01');
    expect((exported['transactions'] as List).single['id'], 't1');

    // Pulihkan hasil ekspor sendiri → data sama.
    await LocalStore.importBackup(exported);
    expect((await LocalStore.getDebts()).single.remainingAmount, 750);
    expect((await LocalStore.getAccounts()).single.balance, 5000);
    expect((await LocalStore.getInvestments()).single.currentAmount, 110);
  });

  test('backup versi tidak dikenal ditolak', () async {
    expect(
      LocalStore.importBackup({'version': 2}),
      _throwsMsg('Format file backup tidak dikenali atau tidak kompatibel.'),
    );
  });
}
