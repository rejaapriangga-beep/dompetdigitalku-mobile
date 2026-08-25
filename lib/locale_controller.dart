// lib/locale_controller.dart
// Sumber kebenaran tunggal untuk bahasa aplikasi (Indonesia/Inggris) —
// dibaca oleh AppStrings (lib/l10n/app_strings.dart) supaya semua `S.t.xxx`
// di seluruh app otomatis ikut berubah, dan oleh MaterialApp untuk widget
// bawaan Flutter (mis. tombol "OK"/"BATAL" di date picker). Preferensi
// disimpan di HP supaya tidak balik ke default tiap buka app. Pola ini
// sengaja dibuat mirip ThemeController (lib/theme.dart) untuk konsistensi.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ValueNotifier<Locale> {
  LocaleController._() : super(const Locale('id'));
  static final LocaleController instance = LocaleController._();

  static const _prefKey = 'app_locale';
  static const supportedLocales = [Locale('id'), Locale('en')];

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      value = code == 'en' ? const Locale('en') : const Locale('id');
    } catch (_) {
      // Biarkan default (Indonesia) kalau gagal baca preferensi.
    }
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, locale.languageCode);
    } catch (_) {}
  }

  bool get isEnglish => value.languageCode == 'en';

  /// Kode locale untuk `DateFormat(pattern, ...)` milik package `intl` —
  /// dipakai di layar yang menampilkan tanggal sebagai teks panjang
  /// (mis. "19 Agustus 2026" vs "August 19, 2026").
  String get dateLocale => isEnglish ? 'en_US' : 'id_ID';
}
