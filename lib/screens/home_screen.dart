// lib/screens/home_screen.dart
// Mirror dari app/page.tsx (Beranda web): ringkasan kekayaan bersih,
// komposisi aset, rasio keuangan, transaksi terakhir, dan menu utama.
import 'package:flutter/material.dart';
import '../ads/bottom_banner_ad.dart';
import '../api/auth_api.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../locale_controller.dart';
import '../models/models.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'transactions_screen.dart';
import 'accounts_assets_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'backup_screen.dart';
import 'help_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String _monthKey(DateTime d) => '${d.year}-${d.month}';

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Investment> _investments = [];
  List<Asset> _assets = [];
  List<Debt> _debts = [];
  List<Category> _categories = [];
  Map<String, double> _budgets = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _maybeShowOnboarding();
  }

  Future<void> _maybeShowOnboarding() async {
    if (!await OnboardingScreen.shouldShow()) return;
    if (!mounted) return;
    // Ditunda 1 frame supaya Beranda sudah ter-render dulu di belakangnya
    // sebelum tutorial muncul di atasnya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        DataApi.getTransactions(),
        DataApi.getAccounts(),
        DataApi.getInvestments(),
        DataApi.getAssets(),
        DataApi.getDebts(),
        DataApi.getCategories(),
        DataApi.getBudgets(),
      ]);
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _accounts = results[1] as List<Account>;
        _investments = results[2] as List<Investment>;
        _assets = results[3] as List<Asset>;
        _debts = results[4] as List<Debt>;
        _categories = results[5] as List<Category>;
        _budgets = results[6] as Map<String, double>;
      });
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _kas => _accounts.fold(0, (s, a) => s + a.balance);
  double get _totalInvestasi =>
      _investments.fold(0, (s, i) => s + i.currentAmount);
  double get _totalAsetTetap => _assets.fold(0, (s, a) => s + a.currentValue);
  double get _totalUtang => _debts.fold(
    0.0,
    (s, d) => s + (d.remainingAmount > 0 ? d.remainingAmount : 0),
  );
  double get _totalAsetLikuid => (_kas > 0 ? _kas : 0) + _totalInvestasi;
  double get _totalAsetKeseluruhan => _totalAsetLikuid + _totalAsetTetap;
  double get _asetBersihTotal =>
      _kas + _totalInvestasi + _totalAsetTetap - _totalUtang;

  double get _kasPct => _totalAsetKeseluruhan > 0
      ? ((_kas > 0 ? _kas : 0) / _totalAsetKeseluruhan) * 100
      : 0;
  double get _investasiPct => _totalAsetKeseluruhan > 0
      ? (_totalInvestasi / _totalAsetKeseluruhan) * 100
      : 0;
  double get _asetTetapPct => _totalAsetKeseluruhan > 0
      ? (_totalAsetTetap / _totalAsetKeseluruhan) * 100
      : 0;

  String _formatRatio(double numerator, double denominator) => denominator > 0
      ? '${(numerator / denominator).toStringAsFixed(2)} : 1'
      : S.t.noDebt;

  double get _totalBudgetSet =>
      _budgets.values.fold(0, (s, v) => s + (v > 0 ? v : 0));
  double get _totalSpentBudgeted {
    final thisMonth = _monthKey(DateTime.now());
    final budgetedCatIds = _budgets.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toSet();
    return _transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              _monthKey(t.date) == thisMonth &&
              budgetedCatIds.contains(t.category.id),
        )
        .fold(0.0, (s, t) => s + t.amount);
  }

  double? get _debtToAssetPct {
    if (_totalAsetKeseluruhan > 0)
      return (_totalUtang / _totalAsetKeseluruhan) * 100;
    if (_totalUtang > 0) return 100;
    return null;
  }

  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openMenu(Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _load());
  }

  void _openAddTransaction() {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t.noCashAccountYet)));
      return;
    }
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t.noCategoryYet)));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddTransactionSheet(
        accounts: _accounts,
        debts: _debts.where((d) => d.remainingAmount > 0).toList(),
        categories: _categories,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        backgroundColor: AppColors.primary,
        tooltip: S.t.addTransactionTooltip,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text(
          S.t.home,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          const _LanguageSwitch(),
          IconButton(
            onPressed: () => ThemeController.instance.setMode(
              ThemeController.instance.isDark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: Icon(
              ThemeController.instance.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: ThemeController.instance.isDark
                ? S.t.lightMode
                : S.t.darkMode,
          ),
          IconButton(
            onPressed: () => _openMenu(const BackupScreen()),
            icon: const Icon(Icons.backup_outlined),
            tooltip: S.t.backupRestoreTooltip,
          ),
          IconButton(
            onPressed: () => _openMenu(const HelpScreen()),
            icon: const Icon(Icons.help_outline),
            tooltip: S.t.helpTooltip,
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: S.t.logoutTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          _TopMenuBar(
            items: [
              _MenuItem(
                icon: Icons.swap_horiz,
                color: AppColors.primary,
                label: S.t.menuTransactions,
                shortLabel: S.t.menuTransactions,
                onTap: () => _openMenu(const TransactionsScreen()),
              ),
              _MenuItem(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.gold,
                label: S.t.menuAssets,
                shortLabel: S.t.menuAssets,
                onTap: () => _openMenu(const AccountsAssetsScreen()),
              ),
              _MenuItem(
                icon: Icons.pie_chart_outline,
                color: AppColors.plum,
                label: S.t.menuBudget,
                shortLabel: S.t.menuBudget,
                onTap: () => _openMenu(const BudgetsScreen()),
              ),
              _MenuItem(
                icon: Icons.bar_chart,
                color: AppColors.teal,
                label: S.t.menuReportsFull,
                shortLabel: S.t.menuReportsShort,
                onTap: () => _openMenu(const ReportsScreen()),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }

  Widget _buildBody() {
    final recent = _transactions.take(3).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // SingleChildScrollView (bukan Column kaku) sengaja dipakai
              // supaya tetap aman (tidak overflow merah) di HP layar kecil
              // atau setting font besar — tapi kontennya dirancang pas untuk
              // 1 layar penuh di HP pada umumnya, jadi biasanya tidak perlu
              // discroll sama sekali.
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ),

                  // --- Hero: Total Aset Bersih ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            S.t.totalNetAssets,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Text(
                          rp(_asetBersihTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // --- Stat list (1 card per baris, persentase komposisi
                  // aset ikut di sini) — urutan: Kas, Aset Tetap, Investasi,
                  // Utang, supaya nilai rupiah tidak terpotong. Tiap card
                  // bisa di-tap untuk lompat ke sub-tab terkait di halaman
                  // Aset & Utang.
                  _StatTile(
                    label: S.t.statCash,
                    value: rp(_kas),
                    color: _kas < 0 ? AppColors.coral : AppColors.primary,
                    icon: Icons.account_balance_wallet,
                    pct: _totalAsetKeseluruhan > 0 ? _kasPct : null,
                    onTap: () => _openMenu(
                      const AccountsAssetsScreen(initialTabIndex: 0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatTile(
                    label: S.t.statFixedAssets,
                    value: rp(_totalAsetTetap),
                    color: AppColors.sky,
                    icon: Icons.home_work_outlined,
                    pct: _totalAsetKeseluruhan > 0 ? _asetTetapPct : null,
                    onTap: () => _openMenu(
                      const AccountsAssetsScreen(initialTabIndex: 1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatTile(
                    label: S.t.statInvestments,
                    value: rp(_totalInvestasi),
                    color: AppColors.gold,
                    icon: Icons.trending_up,
                    pct: _totalAsetKeseluruhan > 0 ? _investasiPct : null,
                    onTap: () => _openMenu(
                      const AccountsAssetsScreen(initialTabIndex: 2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatTile(
                    label: S.t.statActiveDebt,
                    value: rp(_totalUtang),
                    color: AppColors.coral,
                    icon: Icons.credit_card,
                    onTap: () => _openMenu(
                      const AccountsAssetsScreen(initialTabIndex: 3),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    S.t.financialRatios,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _RatioCard(
                          icon: Icons.compare_arrows,
                          color: AppColors.teal,
                          label: S.t.ratioCashInvestToDebt,
                          value: _formatRatio(_totalAsetLikuid, _totalUtang),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RatioCard(
                          icon: Icons.account_balance,
                          color: AppColors.plum,
                          label: S.t.ratioTotalAssetsToDebt,
                          value: _formatRatio(
                            _totalAsetKeseluruhan,
                            _totalUtang,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RatioCard(
                          icon: Icons.health_and_safety_outlined,
                          color: _debtToAssetPct == null
                              ? AppColors.primary
                              : (_debtToAssetPct! <= 30
                                    ? AppColors.primary
                                    : (_debtToAssetPct! <= 50
                                          ? AppColors.gold
                                          : AppColors.coral)),
                          label: S.t.ratioDebtToAsset,
                          value: _debtToAssetPct == null
                              ? '0%'
                              : '${_debtToAssetPct!.toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _BudgetHomeSummary(
                    totalBudget: _totalBudgetSet,
                    totalSpent: _totalSpentBudgeted,
                    onTap: () => _openMenu(const BudgetsScreen()),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.t.recentTransactions,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _openMenu(const TransactionsScreen()),
                        child: Text(
                          S.t.viewAll,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        S.t.noTransactionsYet,
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    )
                  else
                    ...recent.map(
                      (t) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      t.category.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${t.type == 'expense' ? '-' : '+'}${rp(t.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: t.type == 'expense'
                                    ? AppColors.coral
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Tombol ganti bahasa (Indonesia/Inggris) di AppBar Beranda — pilihan
/// tersimpan permanen di HP lewat LocaleController, langsung berlaku ke
/// seluruh app begitu dipilih (lihat main.dart untuk rebuild-nya).
class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context) {
    final current = LocaleController.instance.value.languageCode;
    return PopupMenuButton<Locale>(
      tooltip: S.t.languageSwitchTooltip,
      icon: const Icon(Icons.language),
      onSelected: (locale) => LocaleController.instance.setLocale(locale),
      itemBuilder: (context) => [
        _item(const Locale('id'), S.t.languageIndonesian, current),
        _item(const Locale('en'), S.t.languageEnglish, current),
      ],
    );
  }

  PopupMenuItem<Locale> _item(Locale locale, String label, String current) {
    final active = locale.languageCode == current;
    return PopupMenuItem(
      value: locale,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: active
                ? Icon(Icons.check, size: 16, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final double? pct;
  final VoidCallback? onTap;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.pct,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (pct != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct!.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kartu rasio keuangan yang ringkas & berwarna — 3 dijejer sejajar
/// (menggantikan panel putih polos bergaris pemisah yang lama).
class _RatioCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _RatioCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              color: AppColors.inkSoft,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Ringkasan Anggaran Bulan Ini yang ringkas untuk Beranda — hanya
/// menghitung kategori yang anggarannya sudah diatur (>0). Tap untuk buka
/// halaman Anggaran lengkap.
class _BudgetHomeSummary extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final VoidCallback onTap;
  const _BudgetHomeSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBudget = totalBudget > 0;
    final pct = hasBudget ? (totalSpent / totalBudget * 100) : 0.0;
    final color = !hasBudget
        ? AppColors.inkSoft
        : (pct >= 100
              ? AppColors.coral
              : (pct >= 80 ? AppColors.gold : AppColors.primary));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.pie_chart_outline, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.t.budgetThisMonth,
                    style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 3),
                  hasBudget
                      ? Text(
                          '${rp(totalSpent)} / ${rp(totalBudget)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          S.t.budgetNotSetYet,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                  if (hasBudget) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 5,
                        color: color.withValues(alpha: 0.16),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (pct / 100).clamp(0.0, 1.0),
                          child: Container(color: color),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasBudget) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ] else
              Icon(Icons.chevron_right, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String label;
  final String shortLabel;
  final VoidCallback onTap;
  _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.shortLabel,
    required this.onTap,
  });
}

/// Menu utama, sekarang berupa baris ikon statis di atas (tidak ikut
/// scroll) — beda dari sebelumnya yang berupa grid di bagian bawah halaman.
/// Tiap ikon punya label singkat yang selalu terlihat di dalam kartunya
/// (bukan cuma muncul saat ditekan-tahan) supaya langsung jelas menu apa.
/// Baris menu di atas, sekarang selalu muat 1 baris tanpa perlu digeser ke
/// samping (jumlah menunya sudah dikurangi jadi 4 saja — Investasi ikut
/// masuk ke halaman Aset & Utang, Kesehatan Keuangan jadi tab di Laporan,
/// Utang & Kategori sudah bisa diakses dari halaman lain).
class _TopMenuBar extends StatelessWidget {
  final List<_MenuItem> items;
  const _TopMenuBar({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Tooltip(
                  message: item.label,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 22, color: item.color),
                          const SizedBox(height: 4),
                          Text(
                            item.shortLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: item.color,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
