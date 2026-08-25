// lib/ads/bottom_banner_ad.dart
// Widget banner iklan yang ditempel di bagian bawah layar (dipasang lewat
// Scaffold.bottomNavigationBar di tiap halaman utama, bukan ikut discroll
// bersama konten). Kalau iklan gagal dimuat (mis. tidak ada koneksi),
// widget ini tidak menampilkan apa pun — tidak ada ruang kosong yang aneh.
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme.dart';
import 'ad_ids.dart';

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
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: kBannerAdUnitId,
      size: AdSize.banner,
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
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
