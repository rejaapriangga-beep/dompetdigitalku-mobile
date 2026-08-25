// lib/screens/onboarding_screen.dart
// Tutorial perkenalan singkat yang muncul otomatis sekali saja saat
// pertama kali masuk ke Beranda (ditandai lewat shared_preferences), berupa
// beberapa slide yang bisa digeser. Bisa dibuka ulang kapan saja lewat
// halaman Bantuan & Panduan (menu "Lihat tutorial lagi").
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';

const _kOnboardingSeenKey = 'onboarding_seen_v1';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// true kalau tutorial ini belum pernah ditandai selesai sebelumnya.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kOnboardingSeenKey) ?? false);
  }

  static Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Getter (bukan `static final`) supaya isinya ikut mengikuti bahasa yang
  // sedang dipilih setiap kali dibaca.
  static List<_Slide> get _slides => [
    _Slide(
      icon: Icons.waving_hand_rounded,
      color: AppColors.primary,
      title: S.t.onboardWelcomeTitle,
      desc: S.t.onboardWelcomeDesc,
    ),
    _Slide(
      icon: Icons.swap_horiz,
      color: AppColors.primary,
      title: S.t.onboardTxTitle,
      desc: S.t.onboardTxDesc,
    ),
    _Slide(
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.gold,
      title: S.t.menuAssets,
      desc: S.t.onboardAssetsDesc,
    ),
    _Slide(
      icon: Icons.pie_chart_outline,
      color: AppColors.plum,
      title: S.t.onboardBudgetTitle,
      desc: S.t.onboardBudgetDesc,
    ),
    _Slide(
      icon: Icons.favorite_border,
      color: AppColors.teal,
      title: S.t.onboardHealthTitle,
      desc: S.t.onboardHealthDesc,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingScreen._markSeen();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) OnboardingScreen._markSeen();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      S.t.skipButton,
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? _slides[_page].color
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_page].color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _next,
                        child: Text(
                          isLast ? S.t.startNowButton : S.t.nextButton,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 52, color: slide.color),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
