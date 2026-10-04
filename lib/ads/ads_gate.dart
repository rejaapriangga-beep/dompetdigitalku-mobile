// lib/ads/ads_gate.dart
// Pengecekan Google Play Services (GMS) sebelum menyalakan iklan AdMob --
// device tanpa GMS (umum di Huawei keluaran baru yang pakai HMS, bukan GMS)
// terbukti bikin white screen total saat AdMob native ad view dirender
// (lihat catatan histori di ads/ad_ids.dart). Daripada device begini
// menanggung risiko app tidak bisa dipakai sama sekali, iklan di-skip khusus
// untuk device ini -- device Android lain (mayoritas) dan semua iOS tetap
// dapat iklan seperti biasa.
import 'dart:io';
import 'package:google_api_availability/google_api_availability.dart';

class AdsGate {
  AdsGate._();

  static Future<bool>? _future;

  /// true kalau aman untuk memuat iklan AdMob di device ini. Hasilnya
  /// di-cache (sekali cek per proses app) karena status GMS tidak berubah
  /// selama app berjalan.
  static Future<bool> get adsSupported => _future ??= _check();

  static Future<bool> _check() async {
    // GMS murni konsep Android -- di iOS plugin ini selalu balas
    // notAvailableOnPlatform, jadi langsung anggap aman di sana.
    if (!Platform.isAndroid) return true;
    try {
      final availability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      return availability == GooglePlayServicesAvailability.success;
    } catch (_) {
      // Gagal cek (device tidak lazim/error plugin) -- lebih aman anggap
      // tidak didukung daripada memaksa load iklan dan berisiko crash lagi.
      return false;
    }
  }
}
