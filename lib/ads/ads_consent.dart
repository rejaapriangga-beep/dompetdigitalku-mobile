// lib/ads/ads_consent.dart
// Persetujuan iklan untuk pengguna di Uni Eropa/EEA/Inggris (GDPR) lewat
// Google User Messaging Platform (UMP). Pesan persetujuannya sendiri dibuat
// di AdMob → Privacy & messaging → European regulations; SDK ini yang
// menampilkannya — hanya kepada pengguna di wilayah yang mewajibkan, di luar
// itu tidak ada pop-up apa pun.
//
// Aturannya: SDK AdMob baru diinisialisasi (dan banner baru dimuat) setelah
// ConsentInformation.canRequestAds() bernilai true. Persetujuan dari sesi
// sebelumnya langsung dipakai, jadi iklan tidak tertunda di pembukaan
// berikutnya.
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'ads_gate.dart';

class AdsConsent {
  AdsConsent._();

  /// true setelah SDK AdMob siap dipakai (persetujuan sudah cukup).
  static final ready = ValueNotifier(false);

  /// Dipanggil sekali setelah runApp (form persetujuan butuh Activity).
  static Future<void> gatherAndInit() async {
    if (!kAdsEnabled || !await AdsGate.adsSupported) return;
    // Persetujuan dari sesi sebelumnya — iklan bisa langsung jalan.
    await _initIfAllowed();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired(
        (FormError? _) => _initIfAllowed(),
      ),
      (FormError _) => _initIfAllowed(),
    );
  }

  static Future<void> _initIfAllowed() async {
    if (ready.value) return;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    // Batasi rating konten iklan ke "General audiences" di level SDK —
    // lapisan tambahan di atas Blocking controls AdMob Console.
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
    );
    ready.value = true;
  }

  /// Pengguna di wilayah GDPR wajib bisa mengubah pilihannya kapan saja —
  /// tombol "Pengaturan Privasi Iklan" hanya tampil kalau ini true.
  static Future<bool> privacyOptionsRequired() async {
    if (!kAdsEnabled) return false;
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm(
      (FormError? _) => _initIfAllowed(),
    );
  }
}
