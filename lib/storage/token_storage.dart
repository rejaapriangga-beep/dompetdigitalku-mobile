// lib/storage/token_storage.dart
// Access & refresh token disimpan di penyimpanan terenkripsi bawaan Android
// (Keystore-backed EncryptedSharedPreferences), bukan SharedPreferences biasa.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  // Baca token via ini (bukan langsung _storage.read) — beberapa HP Android
  // sempat gagal baca EncryptedSharedPreferences sesaat setelah lama idle
  // atau baru dibuka kuncinya. Coba sekali lagi sebelum menyerah, supaya
  // hiccup sesaat itu tidak dianggap "belum login" padahal sebenarnya masih.
  Future<String?> _readWithRetry(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        return await _storage.read(key: key);
      } catch (_) {
        return null;
      }
    }
  }

  Future<String?> getAccessToken() => _readWithRetry(_accessKey);
  Future<String?> getRefreshToken() => _readWithRetry(_refreshKey);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
