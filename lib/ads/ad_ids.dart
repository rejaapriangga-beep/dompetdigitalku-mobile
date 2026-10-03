// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK tidak
// diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa pun).
//
// Dinyalakan lagi (3 Okt 2026) untuk tes ulang setelah: (1) upgrade ke
// Adaptive Banner, dan (2) kategori Gambling + Mature/Adult diblokir
// lewat Blocking controls di AdMob Console -- sebagai respons atas
// laporan iklan banner yang AUTO-REDIRECT ke Play Store tanpa tap user
// (creative dari advertiser "Veil Trace Hunt" dan "77RTPabu", keduanya
// sudah diblokir juga lewat App install ads). Kalau masalah serupa
// muncul lagi, matikan lagi switch ini dan tinjau Blocking controls.
const bool kAdsEnabled = true;
