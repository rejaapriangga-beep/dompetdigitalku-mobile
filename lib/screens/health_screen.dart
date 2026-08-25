// lib/screens/health_screen.dart
// Mirror dari app/health/page.tsx: 4 indikator kesehatan keuangan (rasio
// menabung, cakupan dana darurat, kedisiplinan anggaran, rasio utang
// terhadap pemasukan) — formula & threshold disalin persis dari versi web.
import 'package:flutter/material.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme.dart';

enum Tier { good, warn, bad }

Color _tierColor(Tier t) {
  switch (t) {
    case Tier.good:
      return AppColors.primary;
    case Tier.warn:
      return AppColors.gold;
    case Tier.bad:
      return AppColors.coral;
  }
}

Tier _tierOf(double score) {
  if (score >= 70) return Tier.good;
  if (score >= 40) return Tier.warn;
  return Tier.bad;
}

double _clamp01(double x) => x.clamp(0, 1);

String _monthKey(DateTime d) => '${d.year}-${d.month}';

class Indicator {
  final String label;
  final double? score;
  final String detail;
  final String advice;
  Indicator({
    required this.label,
    required this.score,
    required this.detail,
    required this.advice,
  });
}

/// Konten Kesehatan Keuangan — dulunya layar sendiri, sekarang jadi salah
/// satu tab di halaman Laporan (lihat reports_screen.dart) supaya tidak
/// perlu ikon menu terpisah di Beranda.
class HealthContent extends StatefulWidget {
  const HealthContent({super.key});

  @override
  State<HealthContent> createState() => _HealthContentState();
}

class _HealthContentState extends State<HealthContent> {
  List<Transaction> _transactions = [];
  Map<String, double> _budgets = {};
  List<Debt> _debts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        DataApi.getTransactions(),
        DataApi.getBudgets(),
        DataApi.getDebts(),
      ]);
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _budgets = results[1] as Map<String, double>;
        _debts = results[2] as List<Debt>;
      });
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Indicator> get _indicators {
    final now = DateTime.now();
    final thisMonthKey = _monthKey(now);

    final incomeThisMonth = _transactions
        .where((t) => t.type == 'income' && _monthKey(t.date) == thisMonthKey)
        .fold(0.0, (s, t) => s + t.amount);
    final expenseThisMonth = _transactions
        .where((t) => t.type == 'expense' && _monthKey(t.date) == thisMonthKey)
        .fold(0.0, (s, t) => s + t.amount);
    final currentBalance = _transactions.fold(
      0.0,
      (s, t) => s + (t.type == 'income' ? t.amount : -t.amount),
    );

    // a. Rasio Menabung
    Indicator savings;
    if (incomeThisMonth > 0) {
      final ratio = (incomeThisMonth - expenseThisMonth) / incomeThisMonth;
      final score = _clamp01(ratio / 0.2) * 100;
      savings = Indicator(
        label: S.t.savingsRatioLabel,
        score: score,
        detail: savingsDetail((ratio * 100).toStringAsFixed(1)),
        advice: score >= 70
            ? S.t.savingsAdviceGood
            : score >= 40
            ? S.t.savingsAdviceWarn
            : S.t.savingsAdviceBad,
      );
    } else {
      savings = Indicator(
        label: S.t.savingsRatioLabel,
        score: null,
        detail: S.t.noIncomeDataThisMonth,
        advice: '',
      );
    }

    // b. Cakupan Dana Darurat
    double expenseSum3 = 0;
    for (var i = 0; i < 3; i++) {
      final key = _monthKey(DateTime(now.year, now.month - i, 1));
      expenseSum3 += _transactions
          .where((t) => t.type == 'expense' && _monthKey(t.date) == key)
          .fold(0.0, (s, t) => s + t.amount);
    }
    final avgExpense3 = expenseSum3 / 3;
    Indicator emergency;
    if (avgExpense3 > 0) {
      final coverage = currentBalance / avgExpense3;
      final score = _clamp01(coverage / 6) * 100;
      emergency = Indicator(
        label: S.t.emergencyFundLabel,
        score: score,
        detail: emergencyDetail(coverage.toStringAsFixed(1)),
        advice: score >= 70
            ? S.t.emergencyAdviceGood
            : score >= 40
            ? S.t.emergencyAdviceWarn
            : S.t.emergencyAdviceBad,
      );
    } else {
      emergency = Indicator(
        label: S.t.emergencyFundLabel,
        score: null,
        detail: S.t.notEnoughExpenseData3Months,
        advice: '',
      );
    }

    // c. Kedisiplinan Anggaran
    final budgeted = _budgets.entries.where((e) => e.value > 0).toList();
    Indicator discipline;
    if (budgeted.isNotEmpty) {
      final underCount = budgeted.where((b) {
        final spent = _transactions
            .where(
              (t) =>
                  t.type == 'expense' &&
                  t.category.id == b.key &&
                  _monthKey(t.date) == thisMonthKey,
            )
            .fold(0.0, (s, t) => s + t.amount);
        return spent < b.value;
      }).length;
      final pct = underCount / budgeted.length;
      final score = pct * 100;
      discipline = Indicator(
        label: S.t.budgetDisciplineLabel,
        score: score,
        detail: disciplineDetail(underCount, budgeted.length),
        advice: score >= 70
            ? S.t.disciplineAdviceGood
            : score >= 40
            ? S.t.disciplineAdviceWarn
            : S.t.disciplineAdviceBad,
      );
    } else {
      discipline = Indicator(
        label: S.t.budgetDisciplineLabel,
        score: null,
        detail: S.t.noBudgetSetYet,
        advice: '',
      );
    }

    // d. Rasio Utang terhadap Pemasukan
    final totalInstallment = _debts
        .where((d) => d.remainingAmount > 0)
        .fold(0.0, (s, d) => s + d.monthlyInstallment);
    Indicator debtRatioInd;
    if (incomeThisMonth > 0) {
      final ratio = totalInstallment / incomeThisMonth;
      final score = _clamp01(1 - ratio / 0.4) * 100;
      debtRatioInd = Indicator(
        label: S.t.debtToIncomeLabel,
        score: score,
        detail: debtRatioDetail((ratio * 100).toStringAsFixed(1)),
        advice: score >= 70
            ? S.t.debtRatioAdviceGood
            : score >= 40
            ? S.t.debtRatioAdviceWarn
            : S.t.debtRatioAdviceBad,
      );
    } else {
      debtRatioInd = Indicator(
        label: S.t.debtToIncomeLabel,
        score: null,
        detail: S.t.noIncomeDataThisMonth,
        advice: '',
      );
    }

    return [savings, emergency, discipline, debtRatioInd];
  }

  @override
  Widget build(BuildContext context) {
    final indicators = _indicators;
    final validScores = indicators
        .where((i) => i.score != null)
        .map((i) => i.score!)
        .toList();
    final overall = validScores.isNotEmpty
        ? (validScores.reduce((a, b) => a + b) / validScores.length).round()
        : null;
    final overallTier = overall != null ? _tierOf(overall.toDouble()) : null;
    final overallLabel = overallTier == Tier.good
        ? S.t.healthy
        : overallTier == Tier.warn
        ? S.t.fairlyHealthy
        : overallTier == Tier.bad
        ? S.t.needsAttention
        : '';

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: overall == null
                      ? Text(
                          S.t.notEnoughDataForScore,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.inkSoft),
                        )
                      : Column(
                          children: [
                            Text(
                              S.t.healthScoreTitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            Text(
                              '$overall',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w600,
                                color: _tierColor(overallTier!),
                                height: 1.1,
                              ),
                            ),
                            Text(
                              outOfScoreLabel(overallLabel),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            if (validScores.length < indicators.length)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  basedOnIndicators(
                                    validScores.length,
                                    indicators.length,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.inkSoft,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: overall / 100,
                                minHeight: 8,
                                backgroundColor: AppColors.bg,
                                valueColor: AlwaysStoppedAnimation(
                                  _tierColor(overallTier),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                ...indicators.map(
                  (ind) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ind.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (ind.score != null)
                              Text(
                                '${ind.score!.round()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _tierColor(_tierOf(ind.score!)),
                                ),
                              ),
                          ],
                        ),
                        if (ind.score != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ind.score! / 100,
                              minHeight: 7,
                              backgroundColor: AppColors.bg,
                              valueColor: AlwaysStoppedAnimation(
                                _tierColor(_tierOf(ind.score!)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          ind.detail,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        if (ind.advice.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              ind.advice,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
