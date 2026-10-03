// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK tidak
// diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa pun).
//
// Dimatikan lagi (3 Okt 2026) setelah dilaporkan iklan banner AUTO-
// REDIRECT ke Play Store SETIAP KALI app dibuka, TANPA tap sama sekali
// dari user -- indikasi iklan nakal/non-compliant yang ikut mengisi
// slot AdMob (umum terjadi di akun baru, sebelum demand "bersih" mulai
// dominan). Jangan nyalakan lagi sebelum root cause-nya jelas DAN
// Blocking controls di AdMob Console sudah dirapikan -- lihat
// percakapan terkait untuk detail investigasi.
const bool kAdsEnabled = false;
