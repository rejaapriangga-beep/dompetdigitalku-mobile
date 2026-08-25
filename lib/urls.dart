// lib/urls.dart
// Link publik (Kebijakan Privasi, Syarat & Ketentuan) dan helper untuk
// membukanya di browser eksternal — dipakai dari layar Login dan Bantuan.
import 'package:url_launcher/url_launcher.dart';

const kPrivacyUrl = 'https://dompetdigitalku.my.id/privacy';
const kTermsUrl = 'https://dompetdigitalku.my.id/terms';

Future<void> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
