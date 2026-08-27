package id.dompetdigitalku.dompetdigitalku

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.RenderMode

// FlutterFragmentActivity (bukan FlutterActivity biasa) — dibutuhkan paket
// local_auth supaya BiometricPrompt Android bisa ditampilkan (fitur kunci
// sidik jari, lihat lib/biometric/). FlutterFragmentActivity tetap turunan
// dari FlutterActivity, jadi semua override di bawah ini tetap berlaku sama.
class MainActivity : FlutterFragmentActivity() {
    // Mode render default Flutter ("surface") menggambar ke SurfaceView
    // terpisah yang di-composite langsung oleh hardware compositor, DI LUAR
    // urutan Z normal View Android — sementara banner AdMob (AdWidget dari
    // paket google_mobile_ads) dipasang lewat Hybrid Composition, yaitu
    // View Android asli yang disisipkan langsung ke hierarki. Di sejumlah
    // GPU/driver (termasuk yang dipakai untuk uji coba app ini), kombinasi
    // ini bisa membuat View native banner iklan ter-composite DI ATAS
    // SurfaceView Flutter walau z-index-nya seharusnya di bawah — jadi
    // seluruh konten Flutter (termasuk loading spinner) tertutup total,
    // dan baru "muncul" lagi begitu ada trigger lain yang memaksa
    // compositor menggambar ulang.
    //
    // Ganti ke mode "texture": FlutterView jadi TextureView biasa yang
    // ikut aturan Z normal View Android, jadi tidak bisa lagi tertimpa oleh
    // platform view lain seperti ini. Sedikit lebih berat di rendering,
    // tapi tidak masalah untuk app yang kontennya bukan game/animasi berat.
    override fun getRenderMode(): RenderMode = RenderMode.texture
}
