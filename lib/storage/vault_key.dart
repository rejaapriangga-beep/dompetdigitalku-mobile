// lib/storage/vault_key.dart
// Kunci enkripsi lokal (AES-256) untuk dokumen invoice yang tersimpan di
// HP — dibuat sekali secara acak, disimpan di penyimpanan terenkripsi
// bawaan Android (Keystore-backed), sama seperti token login. Kunci ini
// TIDAK PERNAH dikirim ke server dan tidak butuh passphrase untuk dipakai
// sehari-hari (buka dokumen jadi transparan) — passphrase baru diperlukan
// saat mengekspor/mengimpor arsip untuk pindah HP (lihat
// lib/backup/document_archive_service.dart).
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/aes_gcm_box.dart';

class VaultKeyStore {
  VaultKeyStore._();
  static final VaultKeyStore instance = VaultKeyStore._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _storageKey = 'local_invoice_vault_key_v1';

  SecretKey? _cached;

  Future<SecretKey> getOrCreateKey() async {
    if (_cached != null) return _cached!;
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) {
      final bytes = base64Decode(existing);
      _cached = SecretKey(bytes);
      return _cached!;
    }
    final newKey = await generateAesKey();
    final bytes = await newKey.extractBytes();
    await _storage.write(key: _storageKey, value: base64Encode(bytes));
    _cached = newKey;
    return newKey;
  }
}
