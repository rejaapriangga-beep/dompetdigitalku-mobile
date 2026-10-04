// lib/ads/ads_gate.dart
// Pengecekan sebelum menyalakan iklan AdMob -- device Huawei/Honor tanpa GMS
// resmi terbukti bikin white screen total saat AdMob native ad view
// dirender (lihat catatan histori di ads/ad_ids.dart). Daripada device
// begini menanggung risiko app tidak bisa dipakai sama sekali, iklan
// di-skip khusus untuk device ini -- device Android lain (mayoritas) dan
// semua iOS tetap dapat iklan seperti biasa.
//
// Dua lapisan cek:
// 1. Merek device (Huawei/Honor) -- sinyal UTAMA. Cek GMS murni (lapisan 2)
//    pernah terbukti "ditipu": device tester-nya (Huawei MatePad 10.4 SE)
//    pakai software emulasi Play Services pihak ketiga yang bikin cek GMS
//    melaporkan "tersedia" padahal bukan GMS asli -- gate lama jadi salah
//    lolos dan AdMob tetap crash. Deteksi merek jauh lebih sulit dipalsukan.
// 2. Ketersediaan Google Play Services -- lapisan tambahan untuk device
//    non-Huawei yang kebetulan juga tidak punya GMS asli.
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_api_availability/google_api_availability.dart';

class AdsGate {
  AdsGate._();

  static Future<bool>? _future;

  /// true kalau aman untuk memuat iklan AdMob di device ini. Hasilnya
  /// di-cache (sekali cek per proses app) karena merek/status GMS tidak
  /// berubah selama app berjalan.
  static Future<bool> get adsSupported => _future ??= _check();

  static Future<bool> _check() async {
    // GMS/HMS murni konsep Android -- di iOS langsung anggap aman.
    if (!Platform.isAndroid) return true;

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      if (manufacturer.contains('huawei') ||
          brand.contains('huawei') ||
          manufacturer.contains('honor') ||
          brand.contains('honor')) {
        return false;
      }
    } catch (_) {
      // Gagal baca info device -- lanjut ke cek GMS, jangan langsung
      // anggap gagal total hanya karena lapisan pertama ini error.
    }

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
