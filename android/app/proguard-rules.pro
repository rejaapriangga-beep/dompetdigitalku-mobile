# google_mlkit_text_recognition mereferensikan recognizer bahasa opsional
# (Cina/Devanagari/Jepang/Korea) yang tidak kita pakai (cuma "latin" dipakai
# di lib/ocr/ocr_scan.dart) — R8 perlu diberitahu supaya tidak menganggapnya
# error saat class-nya tidak ditemukan. Ini rekomendasi resmi dari Android
# Gradle plugin sendiri (missing_rules.txt).
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
