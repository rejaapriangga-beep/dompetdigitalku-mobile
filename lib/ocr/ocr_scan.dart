// lib/ocr/ocr_scan.dart
// OCR invoice 100% di HP (Google ML Kit, on-device) — foto TIDAK PERNAH
// dikirim ke server kita atau ke Google untuk fitur ini; semuanya diproses
// lokal di HP. Cuma teks hasil baca yang diproses sebentar di memori untuk
// mengisi form, lalu dibuang.
// Prinsip: hasil OCR TIDAK PERNAH dipakai otomatis tanpa user memeriksa &
// mengonfirmasi — cuma untuk PRE-FILL form, bukan auto-submit.
// Logika ekstraksi (amount/date/vendor) porting persis dari app/ocr-scan.ts
// di versi web supaya perilakunya konsisten di kedua platform.
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanResult {
  final String rawText;
  final String? amount; // digit mentah, siap dipakai sebagai input jumlah
  final String? date; // format YYYY-MM-DD
  final String? vendor;
  ScanResult({
    required this.rawText,
    required this.amount,
    required this.date,
    required this.vendor,
  });
}

const Map<String, String> _kMonths = {
  'januari': '01',
  'februari': '02',
  'maret': '03',
  'april': '04',
  'mei': '05',
  'juni': '06',
  'juli': '07',
  'agustus': '08',
  'september': '09',
  'oktober': '10',
  'november': '11',
  'desember': '12',
};

String _toDigits(String numStr) {
  final cleaned = numStr.replaceAll(RegExp(r'\s'), '');
  final lastDot = cleaned.lastIndexOf('.');
  final lastComma = cleaned.lastIndexOf(',');
  final decimalSepIdx = lastDot > lastComma ? lastDot : lastComma;
  var integerPart = cleaned;
  if (decimalSepIdx > -1 && cleaned.length - decimalSepIdx <= 3) {
    integerPart = cleaned.substring(0, decimalSepIdx);
  }
  return integerPart.replaceAll(RegExp(r'\D'), '');
}

// Batas nilai wajar untuk transaksi ritel (di bawah Rp1 miliar) — dipakai
// untuk menyaring nomor invoice/barcode/HP yang salah tertangkap sebagai
// "jumlah" (deretan digit panjang biasanya JAUH di atas nilai transaksi wajar).
const int _kMaxPlausibleAmount = 999999999;

String? _extractAmount(String text) {
  final lines = text.split('\n');
  final numberPattern = RegExp(
    r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,})',
  );
  final groupedPattern = RegExp(
    r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?',
  ); // angka berpemisah ribuan, mis. "150.000"
  final keywordPattern = RegExp(
    r'\b(grand\s*total|total\s*tagihan|total\s*bayar|total\s*belanja|total|jumlah\s*bayar|jumlah)\b',
    caseSensitive: false,
  );
  // Baris-baris ini SERING mengandung kata "total"/"jumlah" tapi bukan total
  // akhir invoice — melainkan subtotal per-item, ongkos kirim, potongan, dsb.
  // yang bisa lebih besar dari total akhir setelah diskon/voucher.
  final excludePattern = RegExp(
    r'\b(subtotal|sub\s*total|total\s*harga|harga\s*satuan|ongkos\s*kirim|ongkir|voucher|diskon|discount|asuransi|biaya|kembali|change|tunai|cash)\b',
    caseSensitive: false,
  );

  final candidates = <int>[];
  for (final line in lines) {
    if (!keywordPattern.hasMatch(line) || excludePattern.hasMatch(line))
      continue;
    final matches = numberPattern.allMatches(line);
    for (final m in matches) {
      final digits = _toDigits(m.group(0)!);
      if (digits.isNotEmpty && digits.length >= 3) {
        final n = int.parse(digits);
        if (n <= _kMaxPlausibleAmount) candidates.add(n);
      }
    }
  }
  // Total akhir biasanya dicetak PALING TERAKHIR di struk/invoice (setelah
  // rincian subtotal/ongkir/diskon dihitung) — ambil kandidat paling akhir,
  // BUKAN yang terbesar, supaya subtotal sebelum diskon tidak salah terpilih.
  if (candidates.isNotEmpty) return candidates.last.toString();

  // Fallback: prioritaskan angka berpemisah ribuan (cara umum harga dicetak)
  // supaya nomor invoice/HP/barcode (biasanya deretan digit TANPA pemisah)
  // tidak ikut kena.
  final groupedNums = groupedPattern
      .allMatches(text)
      .map((m) => int.tryParse(_toDigits(m.group(0)!)) ?? 0)
      .where((n) => n >= 100 && n <= _kMaxPlausibleAmount)
      .toList();
  if (groupedNums.isNotEmpty) return groupedNums.last.toString();

  // Fallback terakhir: angka mentah tanpa pemisah, tetap dibatasi nilai wajar.
  final allNums = numberPattern
      .allMatches(text)
      .map((m) => int.tryParse(_toDigits(m.group(0)!)) ?? 0)
      .where((n) => n >= 100 && n <= _kMaxPlausibleAmount)
      .toList();
  if (allNums.isEmpty) return null;
  return allNums.last.toString();
}

String? _extractDate(String text) {
  final slashMatch = RegExp(
    r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})',
  ).firstMatch(text);
  if (slashMatch != null) {
    final d = slashMatch.group(1)!;
    final m = slashMatch.group(2)!;
    var y = slashMatch.group(3)!;
    if (y.length == 2) y = '20$y';
    final dd = d.padLeft(2, '0');
    final mm = m.padLeft(2, '0');
    final mmInt = int.parse(mm);
    final ddInt = int.parse(dd);
    if (mmInt >= 1 && mmInt <= 12 && ddInt >= 1 && ddInt <= 31) {
      return '$y-$mm-$dd';
    }
  }

  final namedMatch = RegExp(
    r'(\d{1,2})\s+(januari|februari|maret|april|mei|juni|juli|agustus|september|oktober|november|desember)\s+(\d{4})',
    caseSensitive: false,
  ).firstMatch(text);
  if (namedMatch != null) {
    final d = namedMatch.group(1)!;
    final monthName = namedMatch.group(2)!.toLowerCase();
    final y = namedMatch.group(3)!;
    final mm = _kMonths[monthName];
    if (mm != null) return '$y-$mm-${d.padLeft(2, '0')}';
  }

  return null;
}

String? _extractVendor(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.length >= 3 && RegExp(r'[a-zA-Z]').hasMatch(l))
      .toList();
  return lines.isNotEmpty ? lines.first : null;
}

Future<ScanResult> scanInvoiceImage(File imageFile) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await recognizer.processImage(inputImage);
    final rawText = result.text;
    return ScanResult(
      rawText: rawText,
      amount: _extractAmount(rawText),
      date: _extractDate(rawText),
      vendor: _extractVendor(rawText),
    );
  } finally {
    await recognizer.close();
  }
}
