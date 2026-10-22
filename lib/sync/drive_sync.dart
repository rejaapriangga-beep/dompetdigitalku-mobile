// lib/sync/drive_sync.dart
// Sinkron antar-perangkat lewat Google Drive milik pengguna sendiri.
//
// - Data disimpan sebagai SATU file terenkripsi di appDataFolder (folder
//   tersembunyi khusus aplikasi ini, scope drive.appdata). Server kami tidak
//   terlibat sama sekali.
// - Enkripsinya AES-256-GCM dengan kunci dari "sandi sinkron" buatan
//   pengguna (PBKDF2, sama seperti file backup), jadi Google pun tidak bisa
//   membaca isinya. Sandi disimpan di penyimpanan aman HP ini supaya sinkron
//   bisa berjalan otomatis; HP lain perlu memasukkan sandi yang sama.
// - Penggabungannya per baris, last-write-wins (lihat sync_engine.dart).
// - Sinkron berjalan otomatis: saat aplikasi dibuka/kembali ke depan, dan
//   beberapa detik setelah ada perubahan data.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../backup/backup_crypto.dart';
import '../crypto/aes_gcm_box.dart';
import '../data/local_db.dart';
import '../data/local_store.dart';
import 'drive_client.dart';
import 'sync_engine.dart';

enum SyncProblem { none, wrongPassphrase, needsSignIn, network, unknown }

class SyncState {
  final bool enabled;
  final String? email;
  final bool syncing;
  final DateTime? lastSyncAt;
  final SyncProblem problem;
  const SyncState({
    this.enabled = false,
    this.email,
    this.syncing = false,
    this.lastSyncAt,
    this.problem = SyncProblem.none,
  });

  SyncState copyWith({
    bool? enabled,
    String? email,
    bool? syncing,
    DateTime? lastSyncAt,
    SyncProblem? problem,
  }) => SyncState(
    enabled: enabled ?? this.enabled,
    email: email ?? this.email,
    syncing: syncing ?? this.syncing,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    problem: problem ?? this.problem,
  );
}

class WrongSyncPassphrase implements Exception {}

class DriveSync with WidgetsBindingObserver {
  DriveSync._();
  static final _instance = DriveSync._();

  static const _fileName = 'dompetdigitalku-sync.bin';
  static const _magic = [0x44, 0x4B, 0x53, 0x31]; // "DKS1"
  static const _saltLength = 16;
  static const _passKey = 'sync_passphrase';
  static const _emailKey = 'sync_email';
  static const _lastSyncMeta = 'sync_last_at';

  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final _google = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/drive.appdata'],
  );

  /// Status untuk ditampilkan di layar Sinkron.
  static final state = ValueNotifier(const SyncState());

  /// Bertambah setiap kali sinkron membawa masuk data dari HP lain — layar
  /// yang sedang tampil (mis. Beranda) mendengarkan ini untuk memuat ulang.
  static final dataRevision = ValueNotifier(0);

  static Timer? _debounce;
  static Future<void>? _running;
  static bool _again = false;
  // Kunci hasil PBKDF2 di-cache per (sandi, salt) — menurunkannya berat.
  static String? _cachedPass;
  static String? _cachedSalt;
  static SecretKey? _cachedKey;

  /// Sinkron aktif di HP ini (dibaca langsung dari penyimpanan, tidak
  /// menunggu [init] selesai).
  static Future<bool> isEnabled() async => await _read(_passKey) != null;

  /// Dipanggil sekali dari main(): muat status & sinkron saat app dibuka.
  static Future<void> init() async {
    WidgetsBinding.instance.addObserver(_instance);
    final pass = await _read(_passKey);
    if (pass == null) return;
    final last = await LocalStore.getMeta(_lastSyncMeta);
    state.value = SyncState(
      enabled: true,
      email: await _read(_emailKey),
      lastSyncAt: last == null ? null : DateTime.tryParse(last),
    );
    unawaited(syncNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncNow());
  }

  /// Panggil setelah setiap perubahan data; sinkron dijalankan beberapa
  /// detik kemudian (beberapa perubahan beruntun digabung jadi satu).
  static void scheduleSync() {
    if (!state.value.enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 4), () => syncNow());
  }

  // ------------------------------------------------------------ Pengaturan

  /// Langkah 1 mengaktifkan: pilih akun Google & beri izin Drive.
  /// Mengembalikan true kalau di Drive sudah ada data sinkron (dari HP lain)
  /// — artinya pengguna perlu memasukkan sandi yang sudah ada, bukan
  /// membuat baru. Null kalau pengguna membatalkan.
  static Future<bool?> connect() async {
    await _google.signOut();
    final account = await _google.signIn();
    if (account == null) return null;
    final client = DriveClient(await account.authHeaders);
    return await client.find(_fileName) != null;
  }

  /// Langkah 2: simpan sandi sinkron lalu sinkron pertama kali. Kalau data
  /// di Drive sudah ada, sandinya dicek dulu dengan membukanya.
  static Future<void> enable(String passphrase) async {
    final account = _google.currentUser ?? await _google.signInSilently();
    if (account == null) throw StateError('Belum masuk ke Google.');
    final client = DriveClient(await account.authHeaders);
    final file = await client.find(_fileName);
    if (file != null) {
      await _decrypt(await client.download(file.id), passphrase);
    }
    await _storage.write(key: _passKey, value: passphrase);
    await _storage.write(key: _emailKey, value: account.email);
    state.value = SyncState(enabled: true, email: account.email);
    await syncNow();
  }

  /// Matikan sinkron di HP ini. Data lokal tetap ada. Dengan
  /// [deleteRemote], file sinkron di Drive juga dihapus (HP lain yang masih
  /// tersambung akan membuat ulang dari datanya sendiri).
  static Future<void> disable({bool deleteRemote = false}) async {
    _debounce?.cancel();
    if (deleteRemote) {
      final account = _google.currentUser ?? await _google.signInSilently();
      if (account != null) {
        final client = DriveClient(await account.authHeaders);
        final file = await client.find(_fileName);
        if (file != null) await client.delete(file.id);
      }
    }
    try {
      await _google.signOut();
    } catch (_) {}
    await _storage.delete(key: _passKey);
    await _storage.delete(key: _emailKey);
    _cachedPass = null;
    _cachedSalt = null;
    _cachedKey = null;
    state.value = const SyncState();
  }

  // ------------------------------------------------------------ Sinkron

  /// Jalankan sinkron sekarang. Aman dipanggil berkali-kali: kalau sedang
  /// berjalan, satu putaran lagi dijadwalkan setelahnya.
  static Future<void> syncNow() async {
    if (!state.value.enabled) return;
    if (_running != null) {
      _again = true;
      return _running;
    }
    _running = _loop();
    try {
      await _running;
    } finally {
      _running = null;
    }
  }

  static Future<void> _loop() async {
    do {
      _again = false;
      await _syncOnce();
    } while (_again && state.value.enabled);
  }

  static Future<void> _syncOnce() async {
    final pass = await _read(_passKey);
    if (pass == null) return;
    state.value = state.value.copyWith(syncing: true);
    try {
      final account = await _google.signInSilently();
      if (account == null) {
        state.value = state.value.copyWith(
          syncing: false,
          problem: SyncProblem.needsSignIn,
        );
        return;
      }
      final client = DriveClient(await account.authHeaders);
      final file = await client.find(_fileName);
      Map<String, dynamic>? remote;
      String? salt;
      if (file != null) {
        final bytes = await client.download(file.id);
        salt = _saltOf(bytes);
        remote = await _decrypt(bytes, pass);
      }
      final db = await LocalDb.instance;
      final result = await SyncEngine.merge(db, remote);
      if (file == null || result.remoteOutdated) {
        final snapshot = await SyncEngine.exportSnapshot(db);
        final bytes = await _encrypt(snapshot, pass, salt);
        if (file == null) {
          await client.create(_fileName, bytes);
        } else {
          await client.update(file.id, bytes);
        }
      }
      final now = DateTime.now();
      await LocalStore.setMeta(_lastSyncMeta, now.toUtc().toIso8601String());
      state.value = state.value.copyWith(
        syncing: false,
        lastSyncAt: now,
        problem: SyncProblem.none,
      );
      if (result.localChanged) dataRevision.value++;
    } on WrongSyncPassphrase {
      state.value = state.value.copyWith(
        syncing: false,
        problem: SyncProblem.wrongPassphrase,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      state.value = state.value.copyWith(
        syncing: false,
        problem: (code == 401 || code == 403)
            ? SyncProblem.needsSignIn
            : SyncProblem.network,
      );
    } catch (_) {
      state.value = state.value.copyWith(
        syncing: false,
        problem: SyncProblem.unknown,
      );
    }
  }

  /// Masuk ulang ke Google secara interaktif (kalau sesi silent gagal),
  /// lalu sinkron.
  static Future<void> reconnect() async {
    final account = await _google.signIn();
    if (account == null) return;
    await syncNow();
  }

  // ------------------------------------------------------------ Enkripsi
  // Format file: [4 byte "DKS1"][16 byte salt][nonce+ciphertext+MAC]

  static String? _saltOf(Uint8List bytes) => bytes.length < 4 + _saltLength
      ? null
      : base64Encode(bytes.sublist(4, 4 + _saltLength));

  static Future<SecretKey> _key(String pass, String saltB64) async {
    if (_cachedKey != null && _cachedSalt == saltB64 && _cachedPass == pass) {
      return _cachedKey!;
    }
    final key = await deriveKeyFromPassphrase(pass, base64Decode(saltB64));
    _cachedPass = pass;
    _cachedSalt = saltB64;
    _cachedKey = key;
    return key;
  }

  static Future<Uint8List> _encrypt(
    Map<String, dynamic> snapshot,
    String pass,
    String? saltB64,
  ) async {
    final salt =
        saltB64 ?? _cachedSalt ?? base64Encode(secureRandomBytes(_saltLength));
    final key = await _key(pass, salt);
    final sealed = await aesGcmSeal(
      Uint8List.fromList(utf8.encode(jsonEncode(snapshot))),
      key,
    );
    return (BytesBuilder()
          ..add(_magic)
          ..add(base64Decode(salt))
          ..add(sealed))
        .toBytes();
  }

  static Future<Map<String, dynamic>> _decrypt(
    Uint8List bytes,
    String pass,
  ) async {
    final salt = _saltOf(bytes);
    if (salt == null) throw WrongSyncPassphrase();
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != _magic[i]) throw WrongSyncPassphrase();
    }
    final sealed = bytes.sublist(4 + _saltLength);
    try {
      final key = await _key(pass, salt);
      final plain = await aesGcmOpen(sealed, key);
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    } on AesGcmAuthenticationError {
      throw WrongSyncPassphrase();
    }
  }

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}
