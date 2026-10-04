// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK tidak
// diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa pun).
//
// Riwayat singkat: dimatikan 4 Okt 2026 karena ronde tes ke-2 nemu WHITE
// SCREEN total saat app dibuka di tablet Huawei. Sudah dikonfirmasi lewat
// tes ulang (APK iklan mati di tablet yang sama -- app jalan normal) bahwa
// ini memang gara-gara AdMob, bukan masalah device Huawei secara umum.
// Dugaan: AdMob native ad view bentrok dengan render Flutter di device
// tanpa Google Play Services (umum di Huawei keluaran baru/HMS) --
// RenderMode.texture di MainActivity.kt belum menutup kombinasi ini.
//
// Dinyalakan lagi sekarang (4 Okt 2026) karena sudah ada pengaman baru:
// ads/ads_gate.dart mengecek ketersediaan Google Play Services SEBELUM
// SDK AdMob diinisialisasi (lihat main.dart) dan sebelum setiap banner
// dimuat (lihat bottom_banner_ad.dart). Device tanpa GMS otomatis
// di-skip (tidak ada SDK init, tidak ada ad load sama sekali) -- iklan
// hanya jalan di device yang GMS-nya terkonfirmasi tersedia.
const bool kAdsEnabled = true;
