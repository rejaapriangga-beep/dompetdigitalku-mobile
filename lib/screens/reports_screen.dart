// lib/screens/reports_screen.dart
// Mirror dari app/reports/page.tsx: filter tanggal/tipe/kategori, ringkasan,
// rincian per kategori, daftar transaksi, ringkasan utang, dan rasio keuangan.
// Catatan: unduh CSV di versi web belum diporting ke mobile (perlu paket
// share/file tambahan) — bisa ditambahkan nanti kalau dibutuhkan.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ads/bottom_banner_ad.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';
import 'health_screen.dart';
import 'transactions_screen.dart' show rp;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Transaction> _transactions = [];
  List<Debt> _debts = [];
  List<Account> _accounts = [];
  List<Investment> _investments = [];
  List<Asset> _assets = [];
  bool _loading = true;
  String? _error;

  late DateTime _from;
  late DateTime _to;
  String _typeFilter = 'all';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // "Dari" selalu mulai dari 1 Januari tahun yang dipilih (lihat dropdown
    // tahun di filter) — bukan tanggal bebas seperti "Sampai".
    _from = DateTime(now.year, 1, 1);
    _to = _dateOnly(now);
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
        DataApi.getDebts(),
        DataApi.getAccounts(),
        DataApi.getInvestments(),
        DataApi.getAssets(),
      ]);
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _debts = results[1] as List<Debt>;
        _accounts = results[2] as List<Account>;
        _investments = results[3] as List<Investment>;
        _assets = results[4] as List<Asset>;
      });
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pilihan tahun untuk dropdown "Dari" — dari tahun transaksi tertua
  /// sampai tahun berjalan (turun), minimal berisi tahun berjalan saja
  /// kalau belum ada transaksi sama sekali.
  List<int> get _availableYears {
    final thisYear = DateTime.now().year;
    var earliest = thisYear;
    for (final t in _transactions) {
      if (t.date.year < earliest) earliest = t.date.year;
    }
    return [for (var y = thisYear; y >= earliest; y--) y];
  }

  List<Category> get _allCategories {
    final map = <String, Category>{};
    for (final t in _transactions) {
      map[t.category.id] = t.category;
    }
    final list = map.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<Transaction> get _filtered {
    final list = _transactions.where((t) {
      final d = _dateOnly(t.date);
      if (d.isBefore(_from)) return false;
      if (d.isAfter(_to)) return false;
      if (_typeFilter != 'all' && t.type != _typeFilter) return false;
      if (_categoryFilter != null && t.category.id != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  double get _sumIncome => _filtered
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);
  double get _sumExpense => _filtered
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  List<_CategoryRow> get _byCategory {
    final map = <String, _CategoryRow>{};
    for (final t in _filtered) {
      final row = map.putIfAbsent(
        t.category.id,
        () => _CategoryRow(t.category.id, t.category.name, 0, 0),
      );
      if (t.type == 'income') {
        row.income += t.amount;
      } else {
        row.expense += t.amount;
      }
    }
    final list = map.values.toList();
    list.sort(
      (a, b) =>
          (b.income - b.expense).abs().compareTo((a.income - a.expense).abs()),
    );
    return list;
  }

  List<Debt> get _activeDebts =>
      _debts.where((d) => d.remainingAmount > 0).toList();
  double get _debtRemaining =>
      _activeDebts.fold(0, (s, d) => s + d.remainingAmount);
  double get _debtInstallment =>
      _activeDebts.fold(0, (s, d) => s + d.monthlyInstallment);

  double get _totalKas => _accounts.fold(0, (s, a) => s + a.balance);
  double get _totalInvestasi =>
      _investments.fold(0, (s, i) => s + i.currentAmount);
  double get _totalAsetTetap => _assets.fold(0, (s, a) => s + a.currentValue);
  double get _totalAsetLikuid =>
      (_totalKas > 0 ? _totalKas : 0) + _totalInvestasi;
  double get _totalAsetKeseluruhan => _totalAsetLikuid + _totalAsetTetap;

  String _formatRatio(double numerator, double denominator) => denominator > 0
      ? '${(numerator / denominator).toStringAsFixed(2)} : 1'
      : S.t.noDebt;

  double? get _debtToAssetPct {
    if (_totalAsetKeseluruhan > 0)
      return (_debtRemaining / _totalAsetKeseluruhan) * 100;
    if (_debtRemaining > 0) return 100;
    return null;
  }

  /// "Sampai" tetap tanggal bebas (beda dengan "Dari" yang sekarang
  /// dropdown tahun, selalu 1 Januari).
  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _to = _dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d/M/yyyy');
    // Kesehatan Keuangan dulunya ikon menu terpisah di Beranda — sekarang
    // jadi tab kedua di sini, jadi cukup 1 pintu masuk untuk "analisis
    // keuangan" (Laporan + Kesehatan) daripada 2 ikon terpisah.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            S.t.menuReportsShort,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: S.t.tabFinancialReport),
              Tab(text: S.t.tabFinancialHealth),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
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

                        // Filter — Dari/Sampai/Tipe/Kategori dijejer 1
                        // baris supaya ringkas; masing-masing dropdown
                        // (kecuali Sampai, yang tetap tanggal bebas lewat
                        // date picker) memakai isExpanded+ellipsis supaya
                        // tidak overflow walau kolomnya sempit.
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _from.year,
                                  isDense: true,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: _availableYears
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (y) => setState(
                                    () => _from = DateTime(y!, 1, 1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickToDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 10,
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat('d/M/yy').format(_to),
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _typeFilter,
                                  isDense: true,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(S.t.filterAll),
                                    ),
                                    DropdownMenuItem(
                                      value: 'income',
                                      child: Text(S.t.statIncome),
                                    ),
                                    DropdownMenuItem(
                                      value: 'expense',
                                      child: Text(S.t.statExpense),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _typeFilter = v!),
                                ),
                              ),
                              if (_allCategories.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _categoryFilter,
                                    isDense: true,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ink,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(S.t.filterCategoryAll),
                                      ),
                                      ..._allCategories.map(
                                        (cat) => DropdownMenuItem(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _categoryFilter = v),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Summary
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: S.t.statIncome,
                                value: rp(_sumIncome),
                                color: AppColors.success,
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatCard(
                                label: S.t.statExpense,
                                value: rp(_sumExpense),
                                color: AppColors.coral,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StatCard(
                          label: S.t.statBalanceNet,
                          value: rp(_sumIncome - _sumExpense),
                          color: AppColors.sky,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          S.t.categoryBreakdownTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_byCategory.isEmpty)
                          _EmptyNote(S.t.noDataInRange)
                        else
                          ..._byCategory.map(
                            (c) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  _Badge(c.name),
                                  const Spacer(),
                                  if (c.income > 0)
                                    Text(
                                      '+${rp(c.income)} ',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  if (c.expense > 0)
                                    Text(
                                      '-${rp(c.expense)}',
                                      style: TextStyle(
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                        Text(
                          transactionListTitle(_filtered.length),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_filtered.isEmpty)
                          _EmptyNote(S.t.noTransactionInRange)
                        else
                          ..._filtered.map(
                            (t) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _Badge(t.category.name),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                t.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 3,
                                          ),
                                          child: Text(
                                            df.format(t.date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.inkSoft,
                                            ),
                                          ),
                                        ),
                                        if (t.note != null &&
                                            t.note!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 3,
                                            ),
                                            child: Text(
                                              t.note!,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.inkSoft,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${t.type == 'expense' ? '-' : '+'}${rp(t.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: t.type == 'expense'
                                          ? AppColors.coral
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                        Text(
                          S.t.debtInstallmentSummaryTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_activeDebts.isEmpty)
                          _EmptyNote(S.t.noActiveDebtYet)
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  label: S.t.remainingDebt,
                                  value: rp(_debtRemaining),
                                  color: AppColors.coral,
                                  icon: Icons.credit_card,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  label: S.t.installmentPerMonth,
                                  value: rp(_debtInstallment),
                                  color: AppColors.amber,
                                  icon: Icons.event_repeat,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._activeDebts.map(
                            (d) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  _Badge(d.type),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      d.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${rp(d.remainingAmount)} · ${rp(d.monthlyInstallment)}${S.t.perMonthSuffix}',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        Text(
                          S.t.financialRatiosCurrentTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RatioRow(
                                S.t.ratioCashInvestDebtFull,
                                _formatRatio(_totalAsetLikuid, _debtRemaining),
                              ),
                              const Divider(height: 20),
                              _RatioRow(
                                S.t.ratioCashInvestAssetDebtFull,
                                _formatRatio(
                                  _totalAsetKeseluruhan,
                                  _debtRemaining,
                                ),
                              ),
                              const Divider(height: 20),
                              _RatioRow(
                                S.t.ratioDebtToAssetFull,
                                _debtToAssetPct == null
                                    ? '0%'
                                    : '${_debtToAssetPct!.toStringAsFixed(1)}%',
                                valueColor: _debtToAssetPct == null
                                    ? AppColors.success
                                    : (_debtToAssetPct! <= 30
                                          ? AppColors.success
                                          : (_debtToAssetPct! <= 50
                                                ? AppColors.gold
                                                : AppColors.coral)),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                S.t.debtToAssetExplanation,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
            const HealthContent(),
          ],
        ),
        bottomNavigationBar: const BottomBannerAd(),
      ),
    );
  }
}

class _CategoryRow {
  final String categoryId;
  final String name;
  double income;
  double expense;
  _CategoryRow(this.categoryId, this.name, this.income, this.expense);
}

class _RatioRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _RatioRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: TextStyle(color: AppColors.inkSoft)),
    );
  }
}
