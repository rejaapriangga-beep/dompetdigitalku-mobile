// lib/ads/ad_ids.dart
// ID iklan AdMob milik akun sendiri.
//
// App ID (dipasang di android/app/src/main/AndroidManifest.xml, meta-data
// "com.google.android.gms.ads.APPLICATION_ID"): ca-app-pub-6278959551618441~6808642386
//
// ADMOB DIAGNOSTIC TEST (4 Okt 2026) -- SEMENTARA diganti ke test ad unit
// resmi Google untuk Anchored Adaptive Banner Android
// (ca-app-pub-3940256099942544/9214589741), iklan sintetis dari Google
// sendiri yang pasti bersih dari creative nakal. Tujuannya mengisolasi
// apakah bug auto-redirect full-screen (lihat riwayat panjang di
// kAdsEnabled di bawah) berasal dari creative/ad-serving live atau dari
// kode app -- investigasi sebelumnya sudah mengonfirmasi tidak ada kode
// InterstitialAd/RewardedAd/AppOpenAd/Timer mencurigakan di app ini sama
// sekali, cuma BannerAd biasa.
// UNTUK KEMBALI KE PRODUCTION: ganti baris di bawah balik ke
// 'ca-app-pub-6278959551618441/5335778610' (satu baris saja).
const String kBannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';

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
// DIMATIKAN (ronde 3, 4 Okt 2026) sampai root cause sebenarnya ketemu --
// GMS check saja TIDAK CUKUP untuk menjamin device ini aman.
//
// Ronde 4 (4 Okt 2026, APK tes): ads_gate.dart diperbaiki jadi HANYA
// deteksi merek device (Huawei/Honor), cek GMS dibuang total (terbukti
// tidak reliable di DUA arah -- lihat riwayat lengkap di ads_gate.dart).
// Tes nyata mengonfirmasi gate ini SUDAH BENAR: di tablet Huawei MatePad
// 10.4 SE tetap tidak white screen & tidak ada iklan, di HP biasa iklan
// berhasil tampil normal (Requests > 0 di AdMob Console).
//
// TAPI begitu iklan tampil di HP biasa itu, muncul masalah LAIN yang
// jauh lebih serius: iklan langsung full-screen SENDIRI tanpa disentuh
// sama sekali (auto-redirect, persis pola bug "Veil Trace Hunt" dulu),
// dan tombol Back malah keluar total dari aplikasi alih-alih menutup
// overlay iklan. Pengiklan kali ini "KreditNavigator-Pinjaman Aman" --
// pengiklan baru, berarti blocking per-advertiser di AdMob Console
// cuma reaktif & tidak pernah benar-benar menutup celahnya (sudah
// terjadi berulang dengan pengiklan berbeda-beda: Veil Trace Hunt,
// 77RTPabu, 55RTVessel, sekarang KreditNavigator).
//
// Keputusan user: TETAP dinyalakan (ronde 5, 4 Okt 2026) meski ada bug
// auto-redirect KreditNavigator di atas -- sambil dicari mitigasi
// tambahan di sisi AdMob Console (bukan cuma blocking reaktif per
// pengiklan). Dugaan kuat dari riset: ini soal pengaturan Mediation/
// Blocking Console, bukan sesuatu yang bisa diperbaiki dari kode app
// (lihat PR yang menyertai perubahan ini untuk detail & langkah yang
// disarankan ke user: cek toggle "Ad filtering" di tiap bidding source,
// dan audit "Manage Ad networks" di Blocking controls).
const bool kAdsEnabled = true;
