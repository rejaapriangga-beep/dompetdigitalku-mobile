// lib/screens/budgets_screen.dart
// Mirror dari app/budgets/page.tsx, plus penambahan realisasi: daftar
// kategori diambil dari menu Kategori (bukan daftar tetap lagi), tiap
// kategori bisa diisi/diubah jumlah anggaran bulanan (tersimpan otomatis
// saat selesai edit), dan sekarang menampilkan progress realisasi
// pengeluaran bulan berjalan per kategori + ringkasan total di atas.
// Halaman ini punya 2 tab: "Set Anggaran" (form di atas) dan "Historis"
// (rekap pencapaian anggaran per bulan, dihitung dari histori transaksi —
// budget tidak diversi per bulan di backend, jadi rekap historis memakai
// pengaturan anggaran yang aktif SAAT INI sebagai acuan tiap bulannya).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ads/bottom_banner_ad.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../locale_controller.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/currency_field.dart';
import 'categories_screen.dart';
import 'transactions_screen.dart' show rp;

String _monthKey(DateTime d) => '${d.year}-${d.month}';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  List<Category> _categories = [];
  Map<String, double> _budgets = {};
  Map<String, double> _spent = {};
  List<Transaction> _transactions = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  String? _error;
  String? _savingCat;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalBudget =>
      _budgets.values.fold(0, (s, v) => s + (v > 0 ? v : 0));
  double get _totalSpent => _budgets.entries
      .where((e) => e.value > 0)
      .fold(0, (s, e) => s + (_spent[e.key] ?? 0));

  /// Rekap pencapaian anggaran per bulan, dari histori transaksi. Budget
  /// tidak disimpan per bulan di backend (cuma satu nilai "anggaran
  /// bulanan" aktif) — jadi tiap bulan lampau dibandingkan terhadap
  /// pengaturan anggaran yang aktif SAAT INI, bukan anggaran yang berlaku
  /// waktu itu.
  List<_MonthRecap> get _monthlyRecaps {
    if (_totalBudget <= 0) return [];
    final spentByMonth = <String, double>{};
    final monthOf = <String, DateTime>{};
    final txByMonth = <String, List<Transaction>>{};
    for (final t in _transactions) {
      if (t.type != 'expense' || (_budgets[t.category.id] ?? 0) <= 0) {
        continue;
      }
      final key = _monthKey(t.date);
      spentByMonth[key] = (spentByMonth[key] ?? 0) + t.amount;
      monthOf[key] = DateTime(t.date.year, t.date.month);
      txByMonth.putIfAbsent(key, () => []).add(t);
    }
    final list = monthOf.entries
        .map(
          (e) => _MonthRecap(
            month: e.value,
            totalBudget: _totalBudget,
            totalSpent: spentByMonth[e.key] ?? 0,
            transactions: txByMonth[e.key]!
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),
        )
        .toList();
    list.sort((a, b) => b.month.compareTo(a.month));
    return list;
  }

  /// Transaksi pengeluaran kategori [categoryId] bulan berjalan — sumber
  /// data yang sama dengan yang dipakai menghitung [_spent], jadi konsisten
  /// dengan angka realisasi yang ditampilkan di card kategori.
  List<Transaction> _transactionsForCategoryThisMonth(String categoryId) {
    final thisMonth = _monthKey(DateTime.now());
    final list = _transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.category.id == categoryId &&
              _monthKey(t.date) == thisMonth,
        )
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        DataApi.getCategories(type: 'expense'),
        DataApi.getBudgets(),
        DataApi.getTransactions(),
      ]);
      final cats = results[0] as List<Category>;
      final budgets = results[1] as Map<String, double>;
      final txs = results[2] as List<Transaction>;
      final thisMonth = _monthKey(DateTime.now());
      final spent = <String, double>{};
      for (final t in txs) {
        if (t.type != 'expense' || _monthKey(t.date) != thisMonth) continue;
        spent[t.category.id] = (spent[t.category.id] ?? 0) + t.amount;
      }
      for (final c in cats) {
        _controllers.putIfAbsent(c.id, () => TextEditingController());
        if (budgets[c.id] != null) {
          CurrencyField.setValue(_controllers[c.id]!, budgets[c.id]!);
        } else {
          _controllers[c.id]!.text = '';
        }
      }
      setState(() {
        _categories = cats;
        _budgets = budgets;
        _spent = spent;
        _transactions = txs;
      });
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String categoryId) async {
    final value = CurrencyField.rawValue(_controllers[categoryId]!) ?? 0;
    setState(() => _savingCat = categoryId);
    try {
      await DataApi.saveBudget(categoryId, value);
      if (mounted) setState(() => _budgets[categoryId] = value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.t.saveBudgetFailed)));
      }
    } finally {
      if (mounted) setState(() => _savingCat = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.budgetScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                )
                .then((_) => _load()),
            child: Text(S.t.manageCategoryLink),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: S.t.budgetTabSet),
            Tab(text: S.t.budgetTabHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSetTab(), _buildHistoryTab()],
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }

  Widget _buildSetTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ),
                  if (_categories.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        S.t.noCategoryYetBudget,
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    )
                  else ...[
                    if (_totalBudget > 0) ...[
                      _BudgetSummaryCard(
                        totalBudget: _totalBudget,
                        totalSpent: _totalSpent,
                      ),
                      const SizedBox(height: 12),
                    ],
                    ..._categories.map((c) {
                      final budget = _budgets[c.id] ?? 0;
                      final spent = _spent[c.id] ?? 0;
                      void openCategoryTransactions() =>
                          _showTransactionListSheet(
                            context,
                            title: c.name,
                            transactions: _transactionsForCategoryThisMonth(
                              c.id,
                            ),
                          );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: openCategoryTransactions,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          c.name,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.inkSoft,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_savingCat == c.id)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: SizedBox(
                                      width: 11,
                                      height: 11,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  width: 118,
                                  child: TextField(
                                    controller: _controllers[c.id],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 13),
                                    inputFormatters: [
                                      ThousandsInputFormatter(),
                                    ],
                                    decoration: const InputDecoration(
                                      prefixText: 'Rp ',
                                      prefixStyle: TextStyle(fontSize: 13),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 8,
                                      ),
                                    ),
                                    onTapOutside: (_) => _save(c.id),
                                    onSubmitted: (_) => _save(c.id),
                                  ),
                                ),
                              ],
                            ),
                            if (budget > 0) ...[
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: openCategoryTransactions,
                                child: _BudgetProgressBar(
                                  spent: spent,
                                  budget: budget,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final recaps = _monthlyRecaps;
    return RefreshIndicator(
      onRefresh: _load,
      child: recaps.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    S.t.budgetHistoryEmpty,
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recaps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _MonthRecapCard(recap: recaps[i]),
            ),
    );
  }
}

/// Rekap pencapaian anggaran untuk satu bulan (tab Historis).
class _MonthRecap {
  final DateTime month;
  final double totalBudget;
  final double totalSpent;
  final List<Transaction> transactions;
  const _MonthRecap({
    required this.month,
    required this.totalBudget,
    required this.totalSpent,
    required this.transactions,
  });
}

/// Card rekap 1 bulan di tab Historis — tampilannya sama dengan
/// _BudgetSummaryCard, ditambah label nama bulan di atasnya. Bisa di-tap
/// untuk melihat daftar transaksi bulan tersebut.
class _MonthRecapCard extends StatelessWidget {
  final _MonthRecap recap;
  const _MonthRecapCard({required this.recap});

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat(
      'MMMM yyyy',
      LocaleController.instance.dateLocale,
    ).format(recap.month);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            monthLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showTransactionListSheet(
            context,
            title: monthLabel,
            transactions: recap.transactions,
          ),
          child: _BudgetSummaryCard(
            totalBudget: recap.totalBudget,
            totalSpent: recap.totalSpent,
          ),
        ),
      ],
    );
  }
}

/// Menampilkan daftar transaksi (kategori tertentu bulan ini, atau semua
/// transaksi realisasi anggaran 1 bulan) dalam sebuah popup — dipakai dari
/// tab Set Anggaran maupun tab Historis.
void _showTransactionListSheet(
  BuildContext context, {
  required String title,
  required List<Transaction> transactions,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      S.t.noTransactionsYet,
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (_, i) =>
                        _SimpleTransactionRow(t: transactions[i]),
                  ),
          ),
        ],
      ),
    ),
  );
}

/// Baris transaksi versi ringkas (read-only, tanpa aksi hapus/lihat invoice)
/// dipakai di dalam popup daftar transaksi.
class _SimpleTransactionRow extends StatelessWidget {
  final Transaction t;
  const _SimpleTransactionRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final isExpense = t.type == 'expense';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat(
                    'd MMMM yyyy',
                    LocaleController.instance.dateLocale,
                  ).format(t.date),
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isExpense ? '-' : '+'}${rp(t.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isExpense ? AppColors.coral : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan total anggaran vs realisasi bulan berjalan, dihitung dari
/// kategori yang anggarannya sudah diatur (>0) saja.
class _BudgetSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    final color = pct >= 100
        ? AppColors.coral
        : (pct >= 80 ? AppColors.gold : AppColors.success);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.t.totalRealizationThisMonth,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            spentOfBudgetLabel(rp(totalSpent), rp(totalBudget)),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          _ProgressTrack(pct: pct, color: color, height: 7),
        ],
      ),
    );
  }
}

/// Progress bar realisasi per kategori: teks "Terpakai Rp X dari Rp Y (Z%)"
/// + bar tipis berwarna hijau/kuning/merah sesuai persentase.
class _BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;
  const _BudgetProgressBar({required this.spent, required this.budget});

  @override
  Widget build(BuildContext context) {
    final pct = budget > 0 ? (spent / budget * 100) : 0.0;
    final color = pct >= 100
        ? AppColors.coral
        : (pct >= 80 ? AppColors.gold : AppColors.success);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                usedOfBudgetLabel(rp(spent), rp(budget)),
                style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _ProgressTrack(pct: pct, color: color, height: 6),
      ],
    );
  }
}

/// Track progress bar generik (dipakai ringkasan total & per kategori).
class _ProgressTrack extends StatelessWidget {
  final double pct;
  final Color color;
  final double height;
  const _ProgressTrack({
    required this.pct,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: color.withValues(alpha: 0.16),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (pct / 100).clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}
