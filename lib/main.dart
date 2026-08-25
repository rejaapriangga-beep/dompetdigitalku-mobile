// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'ads/ad_ids.dart';
import 'api/auth_api.dart';
import 'locale_controller.dart';
import 'screens/login_screen.dart';
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
  // Data format tanggal untuk kedua bahasa (nama bulan dsb.) — dipakai lewat
  // DateFormat(..., LocaleController.instance.isEnglish ? 'en_US' : 'id_ID')
  // di layar-layar yang menampilkan tanggal dalam bentuk teks panjang.
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  await ThemeController.instance.load();
  await LocaleController.instance.load();
  // Tidak di-await sengaja — supaya startup aplikasi tidak menunggu SDK
  // iklan siap; permintaan iklan pertama akan otomatis menunggu sendiri
  // kalau inisialisasi belum selesai.
  // Dimatikan sementara lewat kAdsEnabled (lihat ads/ad_ids.dart) selama
  // masa review 14 hari, untuk mengisolasi dugaan bug layar hitam dari
  // AdMob.
  if (kAdsEnabled) MobileAds.instance.initialize();
  runApp(const DompetDigitalKuApp());
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
  late Future<bool> _loggedInFuture;

  @override
  void initState() {
    super.initState();
    _loggedInFuture = AuthApi.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loggedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return (snapshot.data ?? false)
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
