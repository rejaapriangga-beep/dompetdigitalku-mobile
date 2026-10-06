package id.dompetdigitalku.dompetdigitalku

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (bukan FlutterActivity biasa) — dibutuhkan paket
// local_auth supaya BiometricPrompt Android bisa ditampilkan (fitur kunci
// sidik jari, lihat lib/biometric/).
//
// ADMOB DIAGNOSTIC TEST -- override getRenderMode() ke RenderMode.texture
// SEMENTARA DIHAPUS (bukan dihapus permanen) untuk menguji apakah
// kombinasi RenderMode.texture + AdWidget (Android Platform View dari
// google_mobile_ads) di device Android 16 (OPPO Reno12 F, Snapdragon 685)
// justru yang menyebabkan bug "konten Flutter jadi putih total begitu
// AdWidget selesai load" -- sudah dikonfirmasi lewat test sebelumnya
// bahwa AdWidget/Platform View adalah pemicunya; sekarang diuji apakah
// RenderMode.texture ikut berkontribusi pada device spesifik ini.
// UNTUK KEMBALI: tambahkan lagi
// `import io.flutter.embedding.android.RenderMode` dan
// `override fun getRenderMode(): RenderMode = RenderMode.texture`.
class MainActivity : FlutterFragmentActivity()
