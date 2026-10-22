// lib/sync/sync_engine.dart
// Inti sinkron antar-perangkat: database lokal ⇄ satu "snapshot" (seluruh
// baris semua tabel, termasuk yang sudah ditandai terhapus). Penggabungan
// dilakukan per baris dengan aturan last-write-wins berdasarkan updated_at.
// Tidak tahu apa-apa soal Google Drive/enkripsi — lihat drive_sync.dart.
import 'dart:convert';
import 'package:sqflite/sqflite.dart' hide Transaction;

class SyncEngine {
  static const snapshotFormat = 1;

  /// Tabel yang ikut disinkron beserta kolom kuncinya. Tabel meta (status
  /// lokal perangkat) sengaja tidak ikut.
  static const tables = {
    'accounts': 'id',
    'categories': 'id',
    'transactions': 'id',
    'budgets': 'category_id',
    'debts': 'id',
    'debt_payments': 'id',
    'assets': 'id',
    'investments': 'id',
    'goals': 'id',
  };

  static Future<Map<String, dynamic>> exportSnapshot(
    DatabaseExecutor db,
  ) async {
    return {
      'format': snapshotFormat,
      'tables': {for (final table in tables.keys) table: await db.query(table)},
    };
  }

  /// Gabungkan [remote] ke database lokal. Mengembalikan hasil berisi
  /// apakah data lokal berubah (layar perlu dimuat ulang) dan apakah
  /// snapshot remote perlu ditimpa (ada baris lokal yang lebih baru atau
  /// belum ada di remote).
  static Future<MergeResult> merge(
    Database db,
    Map<String, dynamic>? remote,
  ) async {
    if (remote != null && remote['format'] != snapshotFormat) {
      throw const FormatException('Format data sinkron tidak dikenali.');
    }
    final remoteTables = (remote?['tables'] as Map?) ?? const {};
    var localChanged = false;
    var remoteOutdated = false;

    await db.transaction((tx) async {
      for (final MapEntry(key: table, value: keyCol) in tables.entries) {
        final columns = {
          for (final c in await tx.rawQuery('PRAGMA table_info($table)'))
            c['name'] as String,
        };
        final local = {
          for (final r in await tx.query(table)) r[keyCol] as String: r,
        };
        final seen = <String>{};
        for (final raw in (remoteTables[table] as List?) ?? const []) {
          // Kolom yang belum dikenal versi aplikasi ini (dari HP dengan
          // versi lebih baru) diabaikan, bukan bikin gagal.
          final row = <String, Object?>{
            for (final e in (raw as Map).entries)
              if (columns.contains(e.key)) e.key as String: e.value,
          };
          final key = row[keyCol] as String;
          seen.add(key);
          final mine = local[key];
          final cmp = mine == null ? 1 : _compare(row, mine);
          if (cmp > 0) {
            await tx.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            localChanged = true;
          } else if (cmp < 0) {
            remoteOutdated = true;
          }
        }
        if (local.keys.any((k) => !seen.contains(k))) remoteOutdated = true;
      }
    });
    return MergeResult(
      localChanged: localChanged,
      remoteOutdated: remoteOutdated,
    );
  }

  // > 0 kalau [a] yang menang. updated_at sama tapi isi beda (jarang sekali)
  // diputus dengan membandingkan isi, supaya semua perangkat memilih
  // pemenang yang sama.
  static int _compare(Map<String, Object?> a, Map<String, Object?> b) {
    final ta = (a['updated_at'] as num?) ?? 0;
    final tb = (b['updated_at'] as num?) ?? 0;
    if (ta != tb) return ta.compareTo(tb);
    return _canonical(a).compareTo(_canonical(b));
  }

  static String _canonical(Map<String, Object?> row) {
    final keys = row.keys.toList()..sort();
    return jsonEncode([
      for (final k in keys) [k, row[k]],
    ]);
  }
}

class MergeResult {
  final bool localChanged;
  final bool remoteOutdated;
  const MergeResult({required this.localChanged, required this.remoteOutdated});
}
