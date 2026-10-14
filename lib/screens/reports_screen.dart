// lib/screens/reports_screen.dart
// Dulu berisi 2 tab (Laporan Keuangan + Kesehatan Keuangan). Tab "Laporan
// Keuangan" (filter tanggal/tipe/kategori, ringkasan, rincian per kategori,
// ringkasan utang, rasio keuangan) sudah dihapus atas permintaan — halaman
// ini sekarang cuma menampilkan Kesehatan Keuangan (lihat health_screen.dart
// untuk isinya).
import 'package:flutter/material.dart';
import '../ads/bottom_banner_ad.dart';
import '../l10n/app_strings.dart';
import '../widgets/top_menu_bar.dart';
import 'health_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.menuReportsShort,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: const Column(
        children: [
          TopMenuBar(current: TopMenuDestination.reports),
          Expanded(child: HealthContent()),
        ],
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }
}
