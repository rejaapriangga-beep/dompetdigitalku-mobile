// lib/crypto/aes_gcm_box.dart
// Primitif enkripsi bersama (dipakai backup_crypto.dart untuk backup data,
// dan local_invoice_store.dart untuk foto invoice lokal) — AES-256-GCM
// tanpa urusan penurunan kunci (itu tanggung jawab pemanggil). Format
// "segel" (sealed box): [nonce 12 byte][ciphertext][MAC 16 byte].
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

const int kGcmNonceLength = 12;
const int kGcmMacLength = 16;

class AesGcmAuthenticationError implements Exception {
  @override
  String toString() => 'Kunci salah, atau data rusak/sudah diubah.';
}

/// Enkripsi [plaintext] dengan [key] (AES-256), hasilnya siap disimpan
/// langsung sebagai bytes.
Future<Uint8List> aesGcmSeal(Uint8List plaintext, SecretKey key) async {
  final algorithm = AesGcm.with256bits();
  final nonce = algorithm.newNonce();
  final box = await algorithm.encrypt(plaintext, secretKey: key, nonce: nonce);
  final out = BytesBuilder();
  out.add(nonce);
  out.add(box.cipherText);
  out.add(box.mac.bytes);
  return out.toBytes();
}

/// Dekripsi hasil [aesGcmSeal]. Melempar [AesGcmAuthenticationError] kalau
/// kunci salah atau datanya rusak/sudah diubah.
Future<Uint8List> aesGcmOpen(Uint8List sealed, SecretKey key) async {
  if (sealed.length < kGcmNonceLength + kGcmMacLength) {
    throw AesGcmAuthenticationError();
  }
  final nonce = sealed.sublist(0, kGcmNonceLength);
  final mac = sealed.sublist(sealed.length - kGcmMacLength);
  final cipherText = sealed.sublist(
    kGcmNonceLength,
    sealed.length - kGcmMacLength,
  );
  final algorithm = AesGcm.with256bits();
  final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
  try {
    final plaintext = await algorithm.decrypt(box, secretKey: key);
    return Uint8List.fromList(plaintext);
  } on SecretBoxAuthenticationError {
    throw AesGcmAuthenticationError();
  }
}

/// Bytes acak aman-kriptografis (dipakai untuk salt PBKDF2, dll).
List<int> secureRandomBytes(int length) {
  final random = SecureRandom.fast;
  return List<int>.generate(length, (_) => random.nextInt(256));
}

/// Kunci AES-256 acak baru (dipakai untuk vault key lokal).
Future<SecretKey> generateAesKey() => AesGcm.with256bits().newSecretKey();
