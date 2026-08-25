// lib/backup/backup_crypto.dart
// Enkripsi/dekripsi file backup data keuangan — AES-256-GCM dengan kunci
// diturunkan dari passphrase pengguna lewat PBKDF2 (100.000 iterasi,
// HMAC-SHA256). Kuncinya TIDAK PERNAH disimpan di mana pun (bukan di HP,
// bukan di server) — kalau passphrase-nya lupa, backup tidak bisa
// didekripsi lagi. Itu memang cara kerja enkripsi yang sebenarnya aman,
// bukan kekurangan. Primitif AES-GCM level rendahnya dipakai bersama dengan
// arsip dokumen invoice lokal — lihat lib/crypto/aes_gcm_box.dart.
//
// Format file (semua angka big-endian):
// [4 byte magic "DKB1"] [16 byte salt] [nonce+ciphertext+MAC AES-GCM]
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../crypto/aes_gcm_box.dart';

const List<int> _kMagic = [0x44, 0x4B, 0x42, 0x31]; // "DKB1"
const int _kSaltLength = 16;
const int _kPbkdf2Iterations = 100000;

class BackupDecryptException implements Exception {
  final String message;
  BackupDecryptException(this.message);
  @override
  String toString() => message;
}

Future<SecretKey> deriveKeyFromPassphrase(
  String passphrase,
  List<int> salt,
) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _kPbkdf2Iterations,
    bits: 256,
  );
  return pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(passphrase)),
    nonce: salt,
  );
}

/// Enkripsi [plaintext] mentah dengan [passphrase] — dipakai bersama oleh
/// backup data keuangan (JSON) dan arsip dokumen invoice (biner kustom).
Future<Uint8List> encryptBytesWithPassphrase(
  Uint8List plaintext,
  String passphrase,
) async {
  final salt = secureRandomBytes(_kSaltLength);
  final key = await deriveKeyFromPassphrase(passphrase, salt);
  final sealed = await aesGcmSeal(plaintext, key);
  final out = BytesBuilder();
  out.add(_kMagic);
  out.add(salt);
  out.add(sealed);
  return out.toBytes();
}

/// Dekripsi hasil [encryptBytesWithPassphrase]. Melempar
/// [BackupDecryptException] kalau passphrase salah atau file rusak.
Future<Uint8List> decryptBytesWithPassphrase(
  Uint8List fileBytes,
  String passphrase,
) async {
  if (fileBytes.length < 4 + _kSaltLength) {
    throw BackupDecryptException('File tidak valid atau rusak.');
  }
  final magic = fileBytes.sublist(0, 4);
  if (!_listEquals(magic, _kMagic)) {
    throw BackupDecryptException('File ini bukan file DuitKita yang valid.');
  }
  final salt = fileBytes.sublist(4, 4 + _kSaltLength);
  final sealed = fileBytes.sublist(4 + _kSaltLength);
  final key = await deriveKeyFromPassphrase(passphrase, salt);
  try {
    return await aesGcmOpen(sealed, key);
  } on AesGcmAuthenticationError {
    throw BackupDecryptException(
      'Passphrase salah, atau file rusak/sudah diubah.',
    );
  } catch (_) {
    throw BackupDecryptException('Gagal membaca isi file.');
  }
}

/// Enkripsi [data] (di-JSON-encode dulu) dengan [passphrase], hasilnya siap
/// ditulis langsung sebagai file `.duitkitabackup`.
Future<Uint8List> encryptBackup(
  Map<String, dynamic> data,
  String passphrase,
) async {
  final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  return encryptBytesWithPassphrase(plaintext, passphrase);
}

/// Dekripsi file backup. Melempar [BackupDecryptException] kalau
/// passphrase-nya salah atau file-nya rusak/bukan file backup DuitKita.
Future<Map<String, dynamic>> decryptBackup(
  Uint8List fileBytes,
  String passphrase,
) async {
  final plaintext = await decryptBytesWithPassphrase(fileBytes, passphrase);
  try {
    final jsonStr = utf8.decode(plaintext);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (_) {
    throw BackupDecryptException('Gagal membaca isi file backup.');
  }
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
