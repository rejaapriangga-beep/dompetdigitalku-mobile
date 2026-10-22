// Uji penggabungan sinkron antar-perangkat (SyncEngine) dengan dua database
// in-memory yang berperan sebagai dua HP berbeda.
import 'dart:convert';
import 'package:dompetdigitalku/data/local_db.dart';
import 'package:dompetdigitalku/data/local_store.dart';
import 'package:dompetdigitalku/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(
    singleInstance: false,
    version: 1,
    onCreate: (db, _) => LocalDb.createSchema(db),
  ),
);

// Simulasi "Drive": snapshot di-JSON-kan bolak-balik seperti aslinya.
Map<String, dynamic>? drive;

Future<MergeResult> _sync(Database db) async {
  final result = await SyncEngine.merge(db, drive);
  if (drive == null || result.remoteOutdated) {
    drive = jsonDecode(jsonEncode(await SyncEngine.exportSnapshot(db)));
  }
  return result;
}

void main() {
  sqfliteFfiInit();
  late Database phoneA;
  late Database phoneB;

  setUp(() async {
    drive = null;
    phoneA = await _openDb();
    phoneB = await _openDb();
  });

  // LocalStore selalu bekerja pada "HP yang sedang dipegang".
  void use(Database db) => LocalDb.useForTesting(db);

  test('data dari dua HP tergabung, tanpa duplikat data bawaan', () async {
    use(phoneA);
    final kas = (await LocalStore.getAccounts()).single.id;
    final makan = (await LocalStore.getCategories(
      type: 'expense',
    )).firstWhere((c) => c.name == 'Makanan').id;
    await LocalStore.createTransaction(
      type: 'expense',
      amount: 20000,
      name: 'Nasi padang',
      categoryId: makan,
      date: DateTime(2026, 10, 1),
      accountId: kas,
    );
    await LocalStore.renameAccount(kas, 'Dompet');
    await _sync(phoneA);

    // HP B baru dipasang: data bawaannya (updated_at 0) tidak boleh
    // menimpa nama "Dompet" dari HP A.
    use(phoneB);
    await LocalStore.createTransaction(
      type: 'income',
      amount: 50000,
      name: 'Jual barang',
      categoryId: (await LocalStore.getCategories(type: 'income')).first.id,
      date: DateTime(2026, 10, 2),
      accountId: kas,
    );
    final r = await _sync(phoneB);
    expect(r.localChanged, isTrue);
    expect(r.remoteOutdated, isTrue);
    final accountsB = await LocalStore.getAccounts();
    expect(accountsB.single.name, 'Dompet');
    expect(accountsB.single.balance, 30000);
    expect((await LocalStore.getCategories()).length, 11);

    use(phoneA);
    await _sync(phoneA);
    expect((await LocalStore.getTransactions()).length, 2);
    expect((await LocalStore.getAccounts()).single.balance, 30000);

    // Sudah sama persis → sinkron berikutnya tidak mengubah apa pun.
    final again = await _sync(phoneA);
    expect(again.localChanged, isFalse);
    expect(again.remoteOutdated, isFalse);
  });

  test('hapus & pembayaran utang dari dua HP tidak saling menimpa', () async {
    use(phoneA);
    await LocalStore.createDebt(
      name: 'Motor',
      type: 'Kredit Kendaraan',
      totalAmount: 1000,
      monthlyInstallment: 100,
      startDate: DateTime(2026),
    );
    await LocalStore.createAsset(
      name: 'TV',
      type: 'Elektronik',
      currentValue: 5,
    );
    await _sync(phoneA);
    use(phoneB);
    await _sync(phoneB);

    // Keduanya membayar utang yang sama secara terpisah (offline).
    final debtId = (await LocalStore.getDebts()).single.id;
    await LocalStore.payDebt(debtId, 200);
    use(phoneA);
    await LocalStore.payDebt(debtId, 300);
    await LocalStore.deleteAsset((await LocalStore.getAssets()).single.id);

    await _sync(phoneA);
    use(phoneB);
    await _sync(phoneB);
    expect((await LocalStore.getDebts()).single.remainingAmount, 500);
    expect(await LocalStore.getAssets(), isEmpty);
    use(phoneA);
    await _sync(phoneA);
    expect((await LocalStore.getDebts()).single.remainingAmount, 500);
  });

  test('perubahan terbaru yang menang', () async {
    use(phoneA);
    await LocalStore.createAsset(
      name: 'Rumah',
      type: 'Properti',
      currentValue: 100,
    );
    await _sync(phoneA);
    use(phoneB);
    await _sync(phoneB);
    final id = (await LocalStore.getAssets()).single.id;

    use(phoneA);
    await LocalStore.updateAssetValue(id, 200);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    use(phoneB);
    await LocalStore.updateAssetValue(id, 300);

    use(phoneA);
    await _sync(phoneA);
    use(phoneB);
    await _sync(phoneB);
    use(phoneA);
    await _sync(phoneA);
    expect((await LocalStore.getAssets()).single.currentValue, 300);
    use(phoneB);
    expect((await LocalStore.getAssets()).single.currentValue, 300);
  });

  test('format snapshot tidak dikenal ditolak', () async {
    expect(
      SyncEngine.merge(phoneA, {'format': 99}),
      throwsA(isA<FormatException>()),
    );
  });
}
