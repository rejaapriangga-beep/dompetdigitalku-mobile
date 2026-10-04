// lib/ads/ads_gate.dart
// Pengecekan sebelum menyalakan iklan AdMob -- device Huawei/Honor tanpa GMS
// resmi terbukti bikin white screen total saat AdMob native ad view
// dirender (lihat catatan histori di ads/ad_ids.dart). Daripada device
// begini menanggung risiko app tidak bisa dipakai sama sekali, iklan
// di-skip khusus untuk device ini -- device Android lain (mayoritas) dan
// semua iOS tetap dapat iklan seperti biasa.
//
// Sinyal yang dipakai: HANYA merek device (Huawei/Honor) lewat
// device_info_plus. Sempat dicoba cek ketersediaan Google Play Services
// (package google_api_availability) sebagai sinyal tambahan, tapi dibuang
// lagi karena terbukti TIDAK bisa diandalkan di dua arah:
// - Di tablet Huawei MatePad 10.4 SE, cek ini melaporkan "tersedia" padahal
//   device itu pakai software emulasi Play Services pihak ketiga (bukan
//   GMS asli) -- gate jadi salah lolos dan AdMob tetap crash.
// - Di HP Android biasa (bukan Huawei/Honor, GMS asli terpasang), cek ini
//   malah gagal/melaporkan "tidak tersedia" -- AdMob jadi tidak pernah
//   diinisialisasi sama sekali (0 ad request) padahal device ini aman.
// Deteksi merek device jauh lebih sederhana dan deterministik untuk kasus
// yang sudah dikonfirmasi nyata (Huawei/Honor), tanpa efek samping di
// device lain.
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class AdsGate {
  AdsGate._();

  static Future<bool>? _future;

  /// true kalau aman untuk memuat iklan AdMob di device ini. Hasilnya
  /// di-cache (sekali cek per proses app) karena merek device tidak berubah
  /// selama app berjalan.
  static Future<bool> get adsSupported => _future ??= _check();

  static Future<bool> _check() async {
    // Huawei/Honor murni soal merek Android -- di iOS langsung anggap aman.
    if (!Platform.isAndroid) return true;

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return !(manufacturer.contains('huawei') ||
          brand.contains('huawei') ||
          manufacturer.contains('honor') ||
          brand.contains('honor'));
    } catch (_) {
      // Gagal baca info device -- lebih aman anggap tidak didukung
      // daripada memaksa load iklan dan berisiko crash di device yang
      // tidak lazim.
      return false;
    }
  }
}
