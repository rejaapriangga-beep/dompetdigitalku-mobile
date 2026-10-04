// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK tidak
// diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa pun).
//
// Dimatikan lagi (3 Okt 2026) -- percobaan nyalakan ulang setelah upgrade
// Adaptive Banner + blokir Gambling/Mature/Adult masih kena advertiser
// auto-redirect (Veil Trace Hunt, 77RTPabu 2x, 55RTVessel berturut-turut
// dalam waktu singkat), bahkan "77RTPabu" yang SUDAH diblokir tetap
// muncul lagi -- indikasi blocking controls AdMob belum/butuh waktu
// propagasi (Google: bisa beberapa jam) sebelum benar-benar efektif.
// Jangan nyalakan lagi sebelum menunggu blocking (termasuk kategori
// Games yang baru diblokir) benar-benar berlaku -- verifikasi dulu
// lewat tes singkat sebelum mengandalkan app ini untuk user asli.
const bool kAdsEnabled = true;
