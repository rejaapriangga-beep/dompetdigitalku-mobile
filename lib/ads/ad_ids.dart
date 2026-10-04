// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
const String kBannerAdUnitId = 'ca-app-pub-6278959551618441/5335778610';

// Saklar untuk MEMATIKAN semua iklan AdMob di seluruh app (SDK tidak
// diinisialisasi, dan BottomBannerAd tidak memuat/menampilkan apa pun).
//
// Dimatikan lagi (4 Okt 2026) -- ronde tes ke-2 (setelah auto-redirect
// ronde 1 nampak teratasi, 100% match rate tanpa iklan nakal) malah
// nemu masalah baru yang lebih parah: WHITE SCREEN total saat app
// dibuka di tablet Huawei (app sama sekali tidak bisa dipakai).
// Dugaan kuat: sama kelas bug dengan "layar hitam" lama (komentar di
// MainActivity.kt soal AdMob hybrid composition bentrok dengan render
// Flutter di GPU/driver tertentu) -- RenderMode.texture ternyata belum
// menutup semua kombinasi device/GPU (kemungkinan device tanpa Google
// Play Services juga berperan, umum di Huawei keluaran baru/HMS).
// JANGAN nyalakan lagi sebelum root cause-nya jelas DAN ada rencana
// penanganan yang aman untuk device tanpa Google Play Services --
// white screen total jauh lebih parah daripada iklan nakal, app jadi
// tidak bisa dipakai sama sekali.
const bool kAdsEnabled = false;
