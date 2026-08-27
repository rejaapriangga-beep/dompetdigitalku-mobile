// lib/biometric/biometric_prefs.dart
// Simpan preferensi "kunci sidik jari aktif?" di HP — hanya ON/OFF, bukan
// data sensitif, jadi cukup shared_preferences biasa (sama seperti
// ThemeController/LocaleController), bukan flutter_secure_storage.
import 'package:shared_preferences/shared_preferences.dart';

class BiometricPrefs {
  BiometricPrefs._();

  static const _enabledKey = 'biometric_lock_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
