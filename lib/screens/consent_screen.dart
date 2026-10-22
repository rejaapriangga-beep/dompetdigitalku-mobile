// lib/screens/consent_screen.dart
// Layar persetujuan satu kali saat aplikasi pertama dibuka (atau saat
// dokumen hukum berubah signifikan — naikkan [ConsentScreen.version]).
// Sejak tidak ada lagi pendaftaran/login, inilah titik pengguna menyetujui
// Kebijakan Privasi & Syarat Ketentuan (UU PDP: persetujuan yang jelas).
// Waktu & versi persetujuan disimpan di HP sebagai bukti.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../urls.dart';

class ConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  const ConsentScreen({super.key, required this.onAccepted});

  /// Versi dokumen yang disetujui. Naikkan kalau Kebijakan Privasi/Syarat
  /// Ketentuan berubah signifikan, supaya semua pengguna diminta setuju lagi.
  static const version = 1;
  static const _versionKey = 'consent_version';
  static const _atKey = 'consent_accepted_at';

  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_versionKey) ?? 0) >= version;
  }

  static Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, version);
    await prefs.setString(_atKey, DateTime.now().toUtc().toIso8601String());
  }

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;

  Future<void> _accept() async {
    await ConsentScreen._accept();
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final points = [
      (Icons.phone_android, S.t.consentPointLocal),
      (Icons.cloud_sync_outlined, S.t.consentPointSync),
      (Icons.backup_outlined, S.t.consentPointBackup),
      (Icons.campaign_outlined, S.t.consentPointAds),
    ];
    final linkStyle = TextStyle(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              S.t.consentTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            for (final (icon, text) in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _checked = !_checked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _checked,
                    onChanged: (v) => setState(() => _checked = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.inkSoft,
                          ),
                          children: [
                            TextSpan(text: S.t.consentAgreePrefix),
                            TextSpan(
                              text: S.t.privacyPolicyLink,
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => openExternalUrl(kPrivacyUrl),
                            ),
                            TextSpan(text: S.t.consentAgreeMiddle),
                            TextSpan(
                              text: S.t.termsLink,
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => openExternalUrl(kTermsUrl),
                            ),
                            TextSpan(text: S.t.consentAgreeSuffix),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checked ? _accept : null,
              child: Text(S.t.consentAcceptButton),
            ),
          ],
        ),
      ),
    );
  }
}
