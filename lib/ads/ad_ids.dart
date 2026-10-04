// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK tidak
// diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa pun).
//
// Riwayat singkat: dimatikan 4 Okt 2026 (ronde 1) karena WHITE SCREEN total
// di tablet Huawei. Tes ulang (APK iklan mati, device sama) mengonfirmasi
// app jalan normal -- jadi memang gara-gara AdMob.
//
// Dinyalakan lagi (ronde 2, 4 Okt 2026) dengan ads/ads_gate.dart: cek
// ketersediaan Google Play Services dulu, device tanpa GMS di-skip dari
// iklan. Hipotesisnya SALAH atau TIDAK CUKUP -- white screen MASIH muncul
// di tablet Huawei yang sama setelah ronde 2 ini. Artinya salah satu:
// (a) tablet ini sebenarnya lolos cek GMS (jadi gate tidak men-skip apa
// pun, dan bug asli -- AdMob native ad view bentrok dengan render Flutter
// di GPU/driver tertentu, kelas bug "layar hitam" lama -- muncul lagi
// walau RenderMode.texture sudah dipasang), atau (b) ada masalah lain di
// implementasi gate-nya sendiri. Belum dikonfirmasi mana yang benar.
//
// DIMATIKAN LAGI (ronde 3, 4 Okt 2026) sampai root cause sebenarnya
// ketemu -- GMS check saja TIDAK CUKUP untuk menjamin device ini aman.
// Prioritas: konsumen tidak boleh terganggu white screen, iklan nomor dua.
const bool kAdsEnabled = false;
