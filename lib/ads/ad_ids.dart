// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar sementara untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK
// tidak diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa
// pun) — dipakai untuk mengisolasi dugaan bug layar hitam dari AdMob
// selama masa review 14 hari. Set kembali ke `true` kalau mau
// mengaktifkan iklan lagi.
const bool kAdsEnabled = false;
