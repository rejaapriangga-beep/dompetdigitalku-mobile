// lib/biometric/biometric_service.dart
// Pembungkus tipis di atas package local_auth — supaya seluruh app cuma
// perlu tahu 2 hal: apakah perangkat ini bisa dipakai kunci sidik jari, dan
// hasil satu kali verifikasi (berhasil/tidak). Semua PlatformException dari
// plugin (dibatalkan user, sidik jari terkunci sementara, dll) ditelan di
// sini dan dianggap "gagal" biasa — pemanggil tidak perlu peduli detailnya.
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final _auth = LocalAuthentication();

  /// Perangkat punya sensor sidik jari/Face ID YANG SUDAH didaftarkan di
  /// pengaturan Android (bukan cuma hardware-nya ada).
  static Future<bool> isSupported() async {
    try {
      final deviceSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return deviceSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Tampilkan prompt sidik jari/Face ID bawaan OS. `reason` muncul sebagai
  /// teks di dalam prompt-nya. Balikin `false` untuk apa pun yang bukan
  /// sukses (dibatalkan, gagal cocok, sensor error, dll) — tidak pernah
  /// melempar exception ke pemanggil.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
