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

class AppColors {
  static bool get _dark => ThemeController.instance.isDark;

  static Color get bg =>
      _dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get surface =>
      _dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated =>
      _dark ? const Color(0xFF262628) : const Color(0xFFFFFFFF);
  static Color get ink =>
      _dark ? const Color(0xFFF2F2F2) : const Color(0xFF1B2E28);
  static Color get inkSoft =>
      _dark ? const Color(0xFF98989D) : const Color(0xFF5B6B63);
  static Color get primary =>
      _dark ? const Color(0xFF34C98E) : const Color(0xFF0F6650);
  static Color get primaryLight =>
      _dark ? const Color(0xFF5FD1A6) : const Color(0xFF3E9C82);
  static Color get gold =>
      _dark ? const Color(0xFFE3B65A) : const Color(0xFFC89B3C);
  static Color get coral =>
      _dark ? const Color(0xFFE37268) : const Color(0xFFC4534A);
  static Color get border =>
      _dark ? const Color(0xFF313133) : const Color(0xFFE4DFD3);

  // Aksen tambahan (dekoratif saja — bukan warna semantik keuangan) supaya
  // menu/kartu di mobile terasa lebih hidup & berwarna, di luar palet inti
  // yang tetap sama persis dengan web untuk primary/coral/gold.
  static Color get sky =>
      _dark ? const Color(0xFF5B9FE0) : const Color(0xFF3B7FC4);
  static Color get plum =>
      _dark ? const Color(0xFFA47FD9) : const Color(0xFF8B5FBF);
  static Color get teal =>
      _dark ? const Color(0xFF3DBEA9) : const Color(0xFF1E9E8E);
  static Color get amber =>
      _dark ? const Color(0xFFE8A366) : const Color(0xFFE08A3C);

  /// Gradasi hijau brand — dipakai untuk kartu hero (mis. Total Aset Bersih)
  /// supaya lebih dinamis dibanding warna flat.
  static LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      _dark ? const Color(0xFF1B5B44) : const Color(0xFF0B4E3D),
    ],
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.coral,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.surfaceElevated : AppColors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
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
