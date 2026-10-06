package id.dompetdigitalku.dompetdigitalku

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (bukan FlutterActivity biasa) — dibutuhkan paket
// local_auth supaya BiometricPrompt Android bisa ditampilkan (fitur kunci
// sidik jari, lihat lib/biometric/).
//
// Riwayat: sempat ada override getRenderMode() ke RenderMode.texture untuk
// menangani bug "layar hitam" versi lama (device/GPU lama yang tidak lagi
// jelas konteksnya). Dihapus lagi (6 Okt 2026) setelah terbukti lewat
// eksperimen reproducible justru KOMBINASI RenderMode.texture + AdWidget
// (Platform View dari google_mobile_ads) yang menyebabkan bug baru yang
// lebih parah: konten Flutter jadi putih total begitu AdWidget selesai
// load, dikonfirmasi di Android 16 (OPPO Reno12 F, Snapdragon 685).
// RenderMode.surface (default Flutter) + AdWidget terbukti normal di
// regression test. Flutter sendiri merekomendasikan surface sebagai
// default/preferred kecuali ada kebutuhan khusus ke texture (mis. Flutter
// UI perlu berada di antara Android View lain dalam z-order) -- app ini
// tidak butuh itu. JANGAN tambahkan override RenderMode lagi tanpa
// eksperimen reproducible yang sama kuatnya dengan yang menghapus ini.
class MainActivity : FlutterFragmentActivity()
