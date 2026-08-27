// lib/screens/help_screen.dart
// Panduan singkat pemakaian aplikasi, dikelompokkan per fitur (accordion
// biar ringkas — tinggal tap judulnya untuk buka/tutup). Isinya statis,
// tidak perlu koneksi internet.
import 'package:flutter/material.dart';
import '../biometric/biometric_prefs.dart';
import '../biometric/biometric_service.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../urls.dart';
import 'delete_account_screen.dart';
import 'onboarding_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  /// Getter (bukan `static final`) supaya isinya ikut mengikuti bahasa yang
  /// sedang dipilih setiap kali dibaca, bukan cuma sekali saat pertama kali
  /// diakses.
  static List<_HelpSection> get _sections => [
    _HelpSection(
      icon: Icons.swap_horiz,
      color: AppColors.primary,
      title: S.t.menuTransactions,
      points: [
        S.t.helpTxPoint1,
        S.t.helpTxPoint2,
        S.t.helpTxPoint3,
        S.t.helpTxPoint4,
      ],
    ),
    _HelpSection(
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.gold,
      title: S.t.menuAssets,
      points: [
        S.t.helpAssetPoint1,
        S.t.helpAssetPoint2,
        S.t.helpAssetPoint3,
        S.t.helpAssetPoint4,
      ],
    ),
    _HelpSection(
      icon: Icons.pie_chart_outline,
      color: AppColors.plum,
      title: S.t.menuBudget,
      points: [
        S.t.helpBudgetPoint1,
        S.t.helpBudgetPoint2,
        S.t.helpBudgetPoint3,
        S.t.helpBudgetPoint4,
      ],
    ),
    _HelpSection(
      icon: Icons.bar_chart,
      color: AppColors.teal,
      title: S.t.menuReportsFull,
      points: [
        S.t.helpReportPoint1,
        S.t.helpReportPoint2,
        S.t.helpReportPoint3,
      ],
    ),
    _HelpSection(
      icon: Icons.dark_mode_outlined,
      color: AppColors.sky,
      title: S.t.helpDarkModeTitle,
      points: [S.t.helpDarkModePoint1, S.t.helpDarkModePoint2],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.helpTooltip,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.t.quickGuideTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.t.quickGuideSubtitle,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.t.viewIntroTutorialAgain,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _BiometricLockTile(),
          const SizedBox(height: 16),
          ..._sections.map((s) => _HelpTile(section: s)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => openExternalUrl(kPrivacyUrl),
                child: Text(
                  S.t.privacyPolicyLink,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
              Text('·', style: TextStyle(color: AppColors.inkSoft)),
              TextButton(
                onPressed: () => openExternalUrl(kTermsUrl),
                child: Text(
                  S.t.termsLink,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              ),
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: AppColors.coral,
              ),
              label: Text(
                S.t.deleteAccountLink,
                style: TextStyle(fontSize: 11.5, color: AppColors.coral),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle "Kunci Sidik Jari" — mengaktifkan lewat sini butuh satu kali
/// verifikasi sidik jari dulu (biar tidak sengaja terkunci di perangkat yang
/// ternyata sensornya bermasalah); mematikan tidak perlu verifikasi ulang.
class _BiometricLockTile extends StatefulWidget {
  const _BiometricLockTile();

  @override
  State<_BiometricLockTile> createState() => _BiometricLockTileState();
}

class _BiometricLockTileState extends State<_BiometricLockTile> {
  bool _enabled = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await BiometricPrefs.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (value) {
        final supported = await BiometricService.isSupported();
        if (!supported) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(S.t.biometricNotAvailable)));
          return;
        }
        final ok = await BiometricService.authenticate(
          S.t.biometricEnableReason,
        );
        if (!ok) return;
      }
      await BiometricPrefs.setEnabled(value);
      if (!mounted) return;
      setState(() => _enabled = value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.fingerprint, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.t.biometricLockTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  S.t.biometricLockSubtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(value: _enabled, onChanged: _toggle),
        ],
      ),
    );
  }
}

class _HelpSection {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> points;
  const _HelpSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.points,
  });
}

class _HelpTile extends StatelessWidget {
  final _HelpSection section;
  const _HelpTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(section.icon, size: 18, color: section.color),
          ),
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: section.points
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: section.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
