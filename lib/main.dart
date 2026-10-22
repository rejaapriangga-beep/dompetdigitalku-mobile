// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'ads/ad_ids.dart';
import 'ads/ads_gate.dart';
import 'backup/auto_backup.dart';
import 'biometric/biometric_prefs.dart';
import 'data/server_migration.dart';
import 'locale_controller.dart';
import 'route_observer.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/migration_screen.dart';
import 'sync/drive_sync.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kunci ke mode potret saja. UI aplikasi ini sama sekali tidak didesain
  // untuk lanskap (tidak ada satu layar pun yang menanganinya), dan dari
  // logcat perangkat asli terlihat layar hitam (konten Flutter tidak
  // tergambar, hanya banner iklan native yang tetap tampil) selalu terjadi
  // tepat setelah event rotasi layar — kemungkinan besar ada race saat
  // engine Flutter/Skia harus menggambar ulang ke surface Android yang
  // baru saja di-resize akibat rotasi. Mengunci orientasi menghilangkan
  // seluruh kelas bug ini alih-alih menambal gejalanya satu per satu.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Edge-to-edge eksplisit (wajib di Android 15+/API 35 — status & navigation
  // bar jadi transparan dan konten menggambar sampai ke tepi layar sendiri,
  // bukan lewat API Window.setStatusBarColor/setNavigationBarColor yang sudah
  // di-deprecate Android untuk tujuan ini). Warna status/nav bar per-tema
  // diatur lewat AppBarTheme.systemOverlayStyle di theme.dart.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Data format tanggal untuk kedua bahasa (nama bulan dsb.) — dipakai lewat
  // DateFormat(..., LocaleController.instance.isEnglish ? 'en_US' : 'id_ID')
  // di layar-layar yang menampilkan tanggal dalam bentuk teks panjang.
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  await ThemeController.instance.load();
  await LocaleController.instance.load();
  // kAdsEnabled (lihat ads/ad_ids.dart) mematikan iklan total di seluruh
  // app. AdsGate.adsSupported mengecek Google Play Services -- device tanpa
  // GMS (mis. Huawei ber-HMS) pernah bikin white screen total saat AdMob
  // native ad view dirender, jadi iklan di-skip khusus untuk device itu.
  // Ini satu-satunya await di main() yang menyangkut iklan; sengaja ditunggu
  // karena cuma cek lokal (bukan network) dan harus selesai SEBELUM SDK
  // AdMob diinisialisasi sama sekali, bukan cuma sebelum ad pertama dimuat.
  if (kAdsEnabled && await AdsGate.adsSupported) {
    MobileAds.instance.initialize();
    // Batasi rating konten iklan ke "General audiences" di level SDK —
    // beda dari Blocking controls di AdMob Console (yang kategorinya bisa
    // salah klasifikasi/butuh waktu propagasi), ini filter yang Google
    // terapkan di setiap permintaan iklan berdasarkan rating resmi
    // advertiser-nya. Lapisan tambahan, bukan pengganti Blocking controls.
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
    );
  }
  runApp(const DompetDigitalKuApp());
  // Sinkron Google Drive (kalau diaktifkan) — tidak ditunggu, berjalan di
  // belakang setelah UI tampil.
  DriveSync.init();
  // Salinan otomatis harian di HP (lihat backup/auto_backup.dart).
  AutoBackup.runIfDue();
}

class DompetDigitalKuApp extends StatelessWidget {
  const DompetDigitalKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.instance,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'DompetDigitalKu',
              debugShowCheckedModeBanner: false,
              navigatorObservers: [routeObserver],
              themeMode: mode,
              theme: buildAppTheme(),
              darkTheme: buildDarkAppTheme(),
              locale: locale,
              supportedLocales: LocaleController.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Key ini sengaja diikat ke isDark & bahasa aktif: AppColors.xxx
              // dan S.t.xxx yang dipakai di seluruh app itu getter statis
              // biasa (bukan lewat Theme.of/context), jadi Flutter tidak tahu
              // perlu rebuild widget yang sudah ter-mount saat mode
              // gelap/terang atau bahasa berganti — cuma MaterialApp-nya
              // sendiri yang otomatis rebuild. Ganti key di sini memaksa
              // seluruh isi app (mulai dari _AuthGate ke bawah) dibangun
              // ulang total begitu salah satunya berganti, jadi warna/teksnya
              // langsung berubah tanpa perlu refresh manual.
              home: _AuthGate(
                key: ValueKey(
                  '${ThemeController.instance.isDark}_${locale.languageCode}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({super.key});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // (ada data lama di server yang belum dipindah?, kunci sidik jari aktif?)
  // — dicek bareng sekali di awal. Tidak ada lagi layar login: data
  // tersimpan di HP, jadi aplikasi langsung terbuka. Pengguna lama yang
  // masih punya sesi login diarahkan dulu ke layar pindahan data.
  late Future<(bool, bool)> _stateFuture;

  @override
  void initState() {
    super.initState();
    _stateFuture = Future.wait([
      ServerMigration.isPending(),
      BiometricPrefs.isEnabled(),
    ]).then((r) => (r[0], r[1]));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(bool, bool)>(
      future: _stateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final (migrationPending, biometricLockOn) =
            snapshot.data ?? (false, false);
        if (migrationPending) return const MigrationScreen();
        return biometricLockOn
            ? const BiometricLockScreen()
            : const HomeScreen();
      },
    );
  }
}
