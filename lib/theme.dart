// lib/theme.dart
// Warna & tema disamakan persis dengan versi web (app/globals.css) supaya
// identitas brand DompetDigitalKu konsisten di semua platform — termasuk
// palet mode gelapnya (lihat @media prefers-color-scheme: dark di globals.css).
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sumber kebenaran tunggal untuk mode gelap/terang — dibaca oleh AppColors
/// (supaya semua `AppColors.xxx` di seluruh app otomatis ikut berubah) dan
/// oleh MaterialApp (untuk themeMode). Preferensi disimpan di HP supaya tidak
/// balik ke default tiap buka app.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);
  static final ThemeController instance = ThemeController._();

  static const _prefKey = 'theme_mode';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_prefKey)) {
        case 'light':
          value = ThemeMode.light;
        case 'dark':
          value = ThemeMode.dark;
        default:
          value = ThemeMode.system;
      }
    } catch (_) {
      // Biarkan default (ikut sistem) kalau gagal baca preferensi.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }

  /// Apakah tampilan SAAT INI seharusnya gelap — mempertimbangkan pengaturan
  /// sistem kalau mode-nya "ikut sistem".
  bool get isDark {
    if (value == ThemeMode.dark) return true;
    if (value == ThemeMode.light) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }
}

/// Satu set warna lengkap untuk salah satu mode (terang ATAU gelap) — dipakai
/// sebagai SATU-SATUNYA sumber nilai hex, supaya AppColors (yang mengikuti
/// mode aktif saat ini) dan _buildTheme (yang butuh warna untuk mode terang
/// & gelap SEKALIGUS, terlepas dari mode aktif saat ini) selalu konsisten.
class _Palette {
  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color ink;
  final Color inkSoft;
  final Color primary;
  final Color primaryLight;
  final Color success;
  final Color gold;
  final Color coral;
  final Color border;
  final Color sky;
  final Color plum;
  final Color teal;
  final Color amber;
  final Color heroGradientEnd;

  const _Palette({
    required this.bg,
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.inkSoft,
    required this.primary,
    required this.primaryLight,
    required this.success,
    required this.gold,
    required this.coral,
    required this.border,
    required this.sky,
    required this.plum,
    required this.teal,
    required this.amber,
    required this.heroGradientEnd,
  });
}

const _lightPalette = _Palette(
  bg: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  surfaceElevated: Color(0xFFFFFFFF),
  ink: Color(0xFF2B1B0F),
  inkSoft: Color(0xFF8A7565),
  primary: Color(0xFFE8631C),
  primaryLight: Color(0xFFF2924D),
  success: Color(0xFF2F7D6B),
  gold: Color(0xFFC89B3C),
  coral: Color(0xFFA83227),
  border: Color(0xFFEDE2D6),
  sky: Color(0xFF3B7FC4),
  plum: Color(0xFF8B5FBF),
  teal: Color(0xFF1E9E8E),
  amber: Color(0xFFE08A3C),
  heroGradientEnd: Color(0xFFC24E12),
);

const _darkPalette = _Palette(
  bg: Color(0xFF000000),
  surface: Color(0xFF1C1C1E),
  surfaceElevated: Color(0xFF262628),
  ink: Color(0xFFF2F2F2),
  inkSoft: Color(0xFFA69C90),
  primary: Color(0xFFFF8A3D),
  primaryLight: Color(0xFFFFB27A),
  success: Color(0xFF4FB89C),
  gold: Color(0xFFE3B65A),
  coral: Color(0xFFE98072),
  border: Color(0xFF313133),
  sky: Color(0xFF5B9FE0),
  plum: Color(0xFFA47FD9),
  teal: Color(0xFF3DBEA9),
  amber: Color(0xFFE8A366),
  heroGradientEnd: Color(0xFFE96A1D),
);

_Palette _paletteFor({required bool dark}) => dark ? _darkPalette : _lightPalette;

class AppColors {
  static bool get _dark => ThemeController.instance.isDark;
  static _Palette get _p => _paletteFor(dark: _dark);

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surfaceElevated => _p.surfaceElevated;
  static Color get ink => _p.ink;
  static Color get inkSoft => _p.inkSoft;
  static Color get primary => _p.primary;
  static Color get primaryLight => _p.primaryLight;

  /// Warna semantik "positif" (pemasukan, lunas, rasio sehat) — dipisah dari
  /// [primary] supaya makna "bagus"-nya tetap jelas walau warna brand
  /// (primary) bukan hijau/teal lagi. Mirror dari --success di web.
  static Color get success => _p.success;
  static Color get gold => _p.gold;
  static Color get coral => _p.coral;
  static Color get border => _p.border;

  // Aksen tambahan (dekoratif saja — bukan warna semantik keuangan) supaya
  // menu/kartu di mobile terasa lebih hidup & berwarna, di luar palet inti
  // yang tetap sama persis dengan web untuk primary/coral/gold.
  static Color get sky => _p.sky;
  static Color get plum => _p.plum;
  static Color get teal => _p.teal;
  static Color get amber => _p.amber;

  /// Gradasi hijau brand — dipakai untuk kartu hero (mis. Total Aset Bersih)
  /// supaya lebih dinamis dibanding warna flat.
  static LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, _p.heroGradientEnd],
  );
}

// Dulu fungsi ini mengambil warna lewat getter AppColors.xxx, yang diam-diam
// mengikuti ThemeController.instance.isDark (variabel GLOBAL) — bukan
// parameter `brightness` di bawah ini. Akibatnya buildAppTheme() (terang)
// dan buildDarkAppTheme() (gelap) bisa jadi punya warna custom yang SAMA
// PERSIS (ikut kondisi global saat itu, bukan mode masing-masing), padahal
// metadata `brightness`-nya beda — kombinasi label/warna yang tidak sinkron
// ini bisa membuat teks jadi senada dengan latar (tidak kelihatan). Sekarang
// warnanya diambil langsung dari _Palette sesuai `brightness` yang dioper ke
// fungsi ini, jadi kedua ThemeData selalu benar terlepas dari mode aktif
// saat ini.
ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final p = _paletteFor(dark: isDark);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary,
      primary: p.primary,
      surface: p.surface,
      error: p.coral,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      foregroundColor: p.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? p.surfaceElevated : p.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    fontFamily: 'Roboto',
  );
}

ThemeData buildAppTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkAppTheme() => _buildTheme(Brightness.dark);
