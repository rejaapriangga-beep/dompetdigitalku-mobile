// lib/ads/bottom_banner_ad.dart
// Widget banner iklan yang ditempel di bagian bawah layar (dipasang lewat
// Scaffold.bottomNavigationBar di tiap halaman utama, bukan ikut discroll
// bersama konten). Kalau iklan gagal dimuat (mis. tidak ada koneksi),
// widget ini tidak menampilkan apa pun — tidak ada ruang kosong yang aneh.
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'ads_gate.dart';

class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Ukuran adaptive banner butuh lebar layar (MediaQuery), yang baru aman
    // diakses setelah frame pertama selesai di-layout -- makanya ditunda
    // lewat addPostFrameCallback, bukan dipanggil langsung di sini.
    if (kAdsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadAd());
    }
  }

  // Dicek lagi di sini (selain di main.dart sebelum SDK diinisialisasi)
  // sebagai lapisan aman tambahan -- kalau sampai lolos, widget ini tetap
  // tidak akan pernah memanggil BannerAd.load() di device tanpa GMS.
  Future<void> _maybeLoadAd() async {
    if (!mounted) return;
    if (!await AdsGate.adsSupported) return;
    if (!mounted) return;
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!mounted) return;
    // ADMOB DIAGNOSTIC TEST -- SEMENTARA balik ke ukuran banner TETAP
    // (AdSize.banner, 320x50) alih-alih Adaptive Banner. Adaptive banner
    // butuh 1 round-trip platform-channel async tambahan
    // (AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize) SEBELUM
    // BannerAd dibuat -- dicoba dihilangkan untuk lihat apakah round-trip
    // ekstra ini ikut berkontribusi ke race condition "layar putih total,
    // cuma banner yang tetap tampil" yang masih terjadi walau
    // RenderMode.texture dan EnableImpeller=false sudah dipasang.
    // UNTUK KEMBALI: ganti balik ke
    // `final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);`
    const size = AdSize.banner;
    if (!mounted) return;

    final ad = BannerAd(
      adUnitId: kBannerAdUnitId,
      size: size,
      // Non-personalized ads dulu (belum ada alur consent untuk iklan
      // personalisasi) — lebih sederhana dari sisi kepatuhan privasi.
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();
    // ADMOB DIAGNOSTIC TEST -- BannerAd.load() dan onAdLoaded/_isLoaded
    // TETAP jalan seperti biasa (round-trip ke server AdMob tetap terjadi),
    // tapi AdWidget (native Android Platform View) SENGAJA TIDAK dirender
    // sama sekali -- diganti placeholder Flutter murni (Container merah).
    // Tujuan: isolasi apakah "Home jadi putih total" dipicu oleh AdWidget/
    // Platform View-nya sendiri, atau oleh sesuatu lain yang kebetulan
    // terjadi bersamaan dengan callback onAdLoaded.
    // - Kalau Home TETAP NORMAL saat placeholder merah muncul -> AdWidget/
    //   Platform View native terbukti jadi penyebabnya.
    // - Kalau Home TETAP JADI PUTIH walau cuma placeholder Flutter biasa
    //   (bukan AdWidget) -> penyebabnya bukan AdWidget, kemungkinan di
    //   lifecycle/state lain yang kebetulan trigger bareng onAdLoaded.
    // UNTUK KEMBALI: hapus blok placeholder di bawah, pakai lagi
    // SafeArea(top:false) -> SizedBox(width/height ad.size) -> AdWidget(ad).
    return const SafeArea(
      top: false,
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: ColoredBox(
          color: Colors.red,
          child: Center(
            child: Text(
              'AD TEST PLACEHOLDER',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
