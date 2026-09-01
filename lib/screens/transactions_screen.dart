// lib/screens/transactions_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../ads/bottom_banner_ad.dart';
import '../api/auth_api.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../locale_controller.dart';
import '../models/models.dart';
import '../ocr/ocr_scan.dart';
import '../storage/local_invoice_store.dart';
import '../storage/token_storage.dart';
import '../theme.dart';
import '../widgets/currency_field.dart';
import 'login_screen.dart';
import 'accounts_assets_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'invoice_view_screen.dart';
import 'transaction_detail_screen.dart';
import 'categories_screen.dart';

final _rupiah = NumberFormat.decimalPattern('id_ID');
String rp(num value) => 'Rp${_rupiah.format(value)}';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Debt> _debts = [];
  List<Category> _categories = [];
  Set<String> _localInvoiceIds = {};
  bool _loading = true;
  String? _error;

  // Filter sederhana: jenis transaksi (semua/masuk/keluar), kategori, dan
  // pencarian nama — tidak pakai rentang tanggal seperti di halaman
  // Laporan, supaya tampilannya tetap ringkas di sini.
  String _typeFilter = 'all';
  String? _categoryFilter;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Category> get _categoriesForFilter => _typeFilter == 'all'
      ? _categories
      : _categories.where((c) => c.type == _typeFilter).toList();

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      final valid = value == 'all'
          ? _categories
          : _categories.where((c) => c.type == value).toList();
      if (_categoryFilter != null && !valid.any((c) => c.id == _categoryFilter)) {
        _categoryFilter = null;
      }
    });
  }

  List<Transaction> get _filteredTransactions => _transactions.where((t) {
    if (_typeFilter != 'all' && t.type != _typeFilter) return false;
    if (_categoryFilter != null && t.category.id != _categoryFilter) {
      return false;
    }
    if (_searchQuery.isNotEmpty &&
        !t.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.trim()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
        DataApi.getDebts(activeOnly: true),
        DataApi.getCategories(),
      ]);
      final txs = results[0] as List<Transaction>;
      final localIds = await LocalInvoiceStore.getLocalInvoiceIds(
        txs.map((t) => t.id).toList(),
      );
      setState(() {
        _transactions = txs;
        _accounts = results[1] as List<Account>;
        _debts = results[2] as List<Debt>;
        _categories = results[3] as List<Category>;
        _localInvoiceIds = localIds;
      });
    } catch (e) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _income => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);
  double get _expense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteTx(Transaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t.dialogDeleteTransactionTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t.delete, style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DataApi.deleteTransaction(t.id);
      // Selalu coba hapus foto lokal juga (aman & no-op kalau memang tidak ada
      // entri lokal untuk transaksi ini) — jangan gantungkan ke state yang
      // bisa saja belum sinkron.
      try {
        await LocalInvoiceStore.deleteLocalInvoice(t.id);
      } catch (_) {}
      _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.t.deleteTransactionFailed)));
    }
  }

  Future<void> _viewInvoice(Transaction t) async {
    if (_localInvoiceIds.contains(t.id)) {
      final bytes = await LocalInvoiceStore.getLocalInvoiceBytes(t.id);
      if (bytes == null) return;
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => InvoiceViewScreen.local(bytes)));
      return;
    }
    if (t.invoiceUrl != null) {
      final token = await TokenStorage.instance.getAccessToken();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvoiceViewScreen.network(
            DataApi.invoiceViewUrl(t.invoiceUrl!),
            token != null ? {'Authorization': 'Bearer $token'} : null,
          ),
        ),
      );
    }
  }

  void _openAddSheet() {
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
        debts: _debts,
        categories: _categories,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.menuTransactions,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => const AccountsAssetsScreen(),
                  ),
                )
                .then((_) => _load()),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: S.t.assetsDebtTooltip,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            tooltip: S.t.moreMenuTooltip,
            onSelected: (value) {
              final Widget screen = value == 'budgets'
                  ? const BudgetsScreen()
                  : const ReportsScreen();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => screen))
                  .then((_) => _load());
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'budgets', child: Text(S.t.menuBudget)),
              PopupMenuItem(value: 'reports', child: Text(S.t.menuReportsFull)),
            ],
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: S.t.logoutTooltip,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: S.t.statIncome,
                          value: rp(_income),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: S.t.statExpense,
                          value: rp(_expense),
                          color: AppColors.coral,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: S.t.statBalance,
                          value: rp(_income - _expense),
                          color: AppColors.sky,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    S.t.historySectionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: S.t.searchTransactionHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _searchCtrl.clear(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TypeFilterChip(
                        label: S.t.filterAll,
                        selected: _typeFilter == 'all',
                        onTap: () => _setTypeFilter('all'),
                      ),
                      _TypeFilterChip(
                        label: S.t.statIncome,
                        selected: _typeFilter == 'income',
                        onTap: () => _setTypeFilter('income'),
                      ),
                      _TypeFilterChip(
                        label: S.t.statExpense,
                        selected: _typeFilter == 'expense',
                        onTap: () => _setTypeFilter('expense'),
                      ),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _categoryFilter,
                          isDense: true,
                          isExpanded: true,
                          style: TextStyle(fontSize: 12, color: AppColors.ink),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                S.t.filterCategoryAll,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ..._categoriesForFilter.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _categoryFilter = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_filteredTransactions.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          S.t.noTransactionsYet,
                          style: TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                    )
                  else
                    ..._filteredTransactions.map(
                      (t) => _TransactionRow(
                        t: t,
                        hasInvoice:
                            _localInvoiceIds.contains(t.id) ||
                            t.invoiceUrl != null,
                        onDelete: () => _deleteTx(t),
                        onViewInvoice: () => _viewInvoice(t),
                        onTap: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(
                                  transaction: t,
                                  hasLocalInvoice: _localInvoiceIds.contains(
                                    t.id,
                                  ),
                                  accounts: _accounts,
                                  debts: _debts,
                                  categories: _categories,
                                ),
                              ),
                            )
                            .then((_) => _load()),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }
}

/// Card ringkasan versi ringkas (tanpa badge ikon) supaya Pemasukan,
/// Pengeluaran, dan Saldo bisa muat sejajar dalam 1 baris.
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Pill filter jenis transaksi (Semua/Masuk/Keluar) — single-select,
/// sengaja dibuat sesederhana mungkin (tanpa rentang tanggal/kategori
/// seperti di halaman Laporan).
class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.inkSoft,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.bg,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction t;
  final bool hasInvoice;
  final VoidCallback onDelete;
  final VoidCallback onViewInvoice;
  final VoidCallback onTap;
  const _TransactionRow({
    required this.t,
    required this.hasInvoice,
    required this.onDelete,
    required this.onViewInvoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = t.type == 'expense';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (hasInvoice)
                IconButton(
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppColors.primaryLight,
                  ),
                  onPressed: onViewInvoice,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32),
                  tooltip: S.t.viewInvoiceTooltip,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
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
                    Text(
                      '${DateFormat('d/M/yyyy').format(t.date)}${t.accountName != null ? ' · ${t.accountName}' : ''}${t.debtName != null ? ' · ${S.t.payDebtPrefix}${t.debtName}' : ''}',
                      style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}${rp(t.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isExpense ? AppColors.coral : AppColors.success,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.coral,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final List<Account> accounts;
  final List<Debt> debts;
  final List<Category> categories;
  final VoidCallback onSaved;

  /// Kalau diisi, form ini jadi mode "Ubah Transaksi" (pre-filled, PATCH)
  /// bukan mode tambah baru (POST).
  final Transaction? editing;
  const AddTransactionSheet({
    super.key,
    required this.accounts,
    required this.debts,
    required this.categories,
    required this.onSaved,
    this.editing,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _type = 'expense';
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  late String _accountId;
  late String _categoryId;
  String? _debtId;
  bool _saving = false;
  String? _error;

  // Salinan lokal (bukan widget.accounts/categories langsung) supaya bisa
  // di-refresh sendiri begitu balik dari "Kelola akun"/"Kelola kategori"
  // tanpa perlu menutup dulu form tambah transaksi ini.
  late List<Account> _accountsList;
  late List<Category> _categoriesList;

  File? _invoiceFile;
  bool _scanning = false;
  String _scanNotice = '';

  static const _maxInvoiceBytes = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _accountsList = widget.accounts;
    _categoriesList = widget.categories;
    final editing = widget.editing;
    if (editing != null) {
      _type = editing.type;
      CurrencyField.setValue(_amountCtrl, editing.amount);
      _nameCtrl.text = editing.name;
      _noteCtrl.text = editing.note ?? '';
      _date = editing.date;
      _accountId = _accountsList.any((a) => a.id == editing.accountId)
          ? editing.accountId
          : _accountsList.first.id;
      _categoryId = editing.category.id;
      _debtId = editing.debtId;
    } else {
      _accountId = _accountsList.first.id;
      _categoryId = _categoriesForType.isNotEmpty
          ? _categoriesForType.first.id
          : _categoriesList.first.id;
    }
  }

  /// Kategori yang cocok dengan jenis transaksi (Pengeluaran/Pemasukan) yang
  /// sedang dipilih.
  List<Category> get _categoriesForType =>
      _categoriesList.where((c) => c.type == _type).toList();

  Future<void> _refreshAccounts() async {
    try {
      final accounts = await DataApi.getAccounts();
      if (!mounted || accounts.isEmpty) return;
      setState(() {
        _accountsList = accounts;
        if (!_accountsList.any((a) => a.id == _accountId)) {
          _accountId = _accountsList.first.id;
        }
      });
    } catch (_) {
      // Diamkan — daftar akun lama tetap dipakai.
    }
  }

  Future<void> _refreshCategories() async {
    try {
      final categories = await DataApi.getCategories();
      if (!mounted || categories.isEmpty) return;
      setState(() {
        _categoriesList = categories;
        if (!_categoriesList.any((c) => c.id == _categoryId)) {
          _categoryId = _categoriesForType.isNotEmpty
              ? _categoriesForType.first.id
              : _categoriesList.first.id;
        }
      });
    } catch (_) {
      // Diamkan — daftar kategori lama tetap dipakai.
    }
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    final size = await file.length();
    if (size > _maxInvoiceBytes) {
      setState(() => _error = S.t.invoiceMaxSizeError);
      return;
    }
    setState(() {
      _invoiceFile = file;
      _error = null;
      _scanning = true;
      _scanNotice = '';
    });
    try {
      // Foto ini HANYA diproses di memori HP lewat OCR on-device (Google ML
      // Kit), lalu dibuang — tidak pernah dikirim ke server atau ke Google.
      final result = await scanInvoiceImage(file);
      if (result.amount != null)
        CurrencyField.setValue(_amountCtrl, int.parse(result.amount!));
      if (result.date != null) {
        final parsed = DateTime.tryParse(result.date!);
        if (parsed != null) _date = parsed;
      }
      if (result.vendor != null) _nameCtrl.text = result.vendor!;

      final found = [
        if (result.amount != null) S.t.ocrFoundAmount,
        if (result.date != null) S.t.ocrFoundDate,
        if (result.vendor != null) S.t.ocrFoundVendor,
      ];
      setState(() {
        _scanNotice = found.isNotEmpty
            ? '${S.t.ocrFoundPrefix}${found.join(', ')}${S.t.ocrFoundSuffix}'
            : S.t.ocrNotFound;
      });
    } catch (_) {
      setState(() => _scanNotice = S.t.ocrFailed);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Cek apakah kategori pengeluaran ini sudah melebihi anggaran bulanannya
  /// (kalau anggarannya diatur), lalu tampilkan peringatan ringan lewat
  /// SnackBar — tidak menggagalkan penyimpanan transaksi, cuma info.
  Future<void> _checkBudgetWarning(ScaffoldMessengerState messenger) async {
    if (_type != 'expense') return;
    try {
      final results = await Future.wait([
        DataApi.getBudgets(),
        DataApi.getTransactions(),
      ]);
      final budgets = results[0] as Map<String, double>;
      final budget = budgets[_categoryId];
      if (budget == null || budget <= 0) return;
      final txs = results[1] as List<Transaction>;
      final now = DateTime.now();
      final spent = txs
          .where(
            (t) =>
                t.type == 'expense' &&
                t.category.id == _categoryId &&
                t.date.year == now.year &&
                t.date.month == now.month,
          )
          .fold<double>(0, (s, t) => s + t.amount);
      if (spent > budget) {
        final catName = _categoriesList
            .firstWhere(
              (c) => c.id == _categoryId,
              orElse: () =>
                  Category(id: _categoryId, name: S.t.categoryFallbackName),
            )
            .name;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              budgetExceededMessage(catName, rp(spent), rp(budget)),
            ),
            backgroundColor: AppColors.coral,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      // Diamkan — ini cuma peringatan tambahan, bukan bagian inti simpan.
    }
  }

  Future<void> _submit() async {
    final amount = CurrencyField.rawValue(_amountCtrl);
    if (amount == null || amount <= 0) {
      setState(() => _error = S.t.amountInvalid);
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = S.t.transactionNameRequired);
      return;
    }
    if (_invoiceFile != null &&
        await _invoiceFile!.length() > _maxInvoiceBytes) {
      setState(() => _error = S.t.invoiceMaxSizeError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.editing != null) {
        await DataApi.updateTransaction(
          id: widget.editing!.id,
          type: _type,
          amount: amount,
          name: _nameCtrl.text.trim(),
          categoryId: _categoryId,
          date: _date,
          accountId: _accountId,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          debtId: _debtId,
        );
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        await _checkBudgetWarning(messenger);
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSaved();
        return;
      }

      final txId = await DataApi.createTransaction(
        type: _type,
        amount: amount,
        name: _nameCtrl.text.trim(),
        categoryId: _categoryId,
        date: _date,
        accountId: _accountId,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        debtId: _debtId,
      );

      // Foto invoice SELALU disimpan ke folder privat aplikasi di HP ini
      // saja, setelah transaksi ada id-nya — tidak pernah dikirim ke server.
      if (_invoiceFile != null) {
        try {
          await LocalInvoiceStore.saveLocalInvoice(txId, _invoiceFile!);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.t.invoiceSavedLocallyFailed)),
            );
          }
        }
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await _checkBudgetWarning(messenger);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.saveTransactionFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.editing != null
                  ? S.t.editTransactionTitle
                  : S.t.addTransactionTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 16),

            // --- Scan Invoice (opsional) — cuma buat transaksi baru; kalau
            // sedang mengubah transaksi lama, foto invoice yang sudah ada
            // (kalau ada) tidak ikut diubah lewat form ini.
            if (widget.editing == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.t.scanInvoiceOptional,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanning
                                ? null
                                : () => _pickAndScan(ImageSource.camera),
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                            ),
                            label: Text(S.t.takePhoto),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanning
                                ? null
                                : () => _pickAndScan(ImageSource.gallery),
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(S.t.gallery),
                          ),
                        ),
                      ],
                    ),
                    if (_invoiceFile != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _invoiceFile!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _scanning
                                ? Text(
                                    S.t.readingInvoice,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.inkSoft,
                                    ),
                                  )
                                : Text(
                                    _scanNotice,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _invoiceFile = null;
                              _scanNotice = '';
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        S.t.invoiceLocalDisclosure,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),

            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'expense', label: Text(S.t.statExpense)),
                ButtonSegment(value: 'income', label: Text(S.t.statIncome)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                if (!_categoriesForType.any((c) => c.id == _categoryId)) {
                  _categoryId = _categoriesForType.isNotEmpty
                      ? _categoriesForType.first.id
                      : _categoryId;
                }
              }),
            ),
            const SizedBox(height: 12),
            CurrencyField(
              controller: _amountCtrl,
              labelText: S.t.amountFieldLabel,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: S.t.transactionNameFieldLabel,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.t.categoryLabel,
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                InkWell(
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      )
                      .then((_) => _refreshCategories()),
                  child: Text(
                    S.t.manageCategoryLink,
                    style: TextStyle(fontSize: 11.5, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              items: [
                // Transaksi lama (sebelum kategori dipisah Pengeluaran/
                // Pemasukan) bisa saja menunjuk ke kategori yang tipenya
                // sekarang tidak cocok lagi — tetap ditampilkan saat
                // diedit supaya tidak jadi kosong/rusak.
                if (!_categoriesForType.any((c) => c.id == _categoryId))
                  ..._categoriesList
                      .where((c) => c.id == _categoryId)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.name}${S.t.oldCategorySuffix}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                ..._categoriesForType.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _categoryId = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(labelText: S.t.dateFieldLabel),
                child: Text(
                  DateFormat(
                    'd MMMM yyyy',
                    LocaleController.instance.dateLocale,
                  ).format(_date),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.t.cashAccountLabel,
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                InkWell(
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AccountsAssetsScreen(initialTabIndex: 0),
                        ),
                      )
                      .then((_) => _refreshAccounts()),
                  child: Text(
                    S.t.manageAccountLink,
                    style: TextStyle(fontSize: 11.5, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              isExpanded: true,
              items: _accountsList
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(
                        '${a.name} (${a.type})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v!),
            ),
            if (_type == 'expense' && widget.debts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _debtId,
                isExpanded: true,
                decoration: InputDecoration(labelText: S.t.linkToDebtLabel),
                items: [
                  DropdownMenuItem(value: null, child: Text(S.t.notLinked)),
                  ...widget.debts.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        '${d.name}${S.t.remainingPrefix}${rp(d.remainingAmount)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _debtId = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(labelText: S.t.noteFieldLabel),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: AppColors.coral, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.editing != null ? S.t.saveChanges : S.t.addButton,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
