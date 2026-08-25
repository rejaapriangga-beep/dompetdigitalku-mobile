// lib/screens/accounts_assets_screen.dart
// Mirror dari app/accounts/page.tsx di versi web: Akun Kas & Bank + Aset Tetap,
// plus ringkasan Utang Aktif dengan link ke halaman kelola utang penuh.
import 'package:flutter/material.dart';
import '../ads/bottom_banner_ad.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/currency_field.dart';
import '../widgets/stat_card.dart';
import 'transactions_screen.dart' show rp;
import 'debts_screen.dart';
import 'investments_screen.dart';

const kAccountTypes = ['Bank', 'Tunai', 'E-Wallet', 'Lainnya'];
const kAssetTypes = [
  'Properti',
  'Kendaraan',
  'Elektronik',
  'Perhiasan',
  'Lainnya',
];

class AccountsAssetsScreen extends StatefulWidget {
  /// Tab awal yang dibuka: 0 = Akun Kas, 1 = Aset Tetap, 2 = Investasi,
  /// 3 = Utang. Dipakai supaya tap dari card ringkasan di Beranda bisa
  /// langsung lompat ke sub-menu yang relevan.
  final int initialTabIndex;
  const AccountsAssetsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AccountsAssetsScreen> createState() => _AccountsAssetsScreenState();
}

class _AccountsAssetsScreenState extends State<AccountsAssetsScreen> {
  List<Account> _accounts = [];
  List<Asset> _assets = [];
  List<Debt> _debts = [];
  List<Investment> _investments = [];
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
        DataApi.getAccounts(),
        DataApi.getAssets(),
        DataApi.getDebts(),
        DataApi.getInvestments(),
      ]);
      setState(() {
        _accounts = results[0] as List<Account>;
        _assets = results[1] as List<Asset>;
        _debts = results[2] as List<Debt>;
        _investments = results[3] as List<Investment>;
      });
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalKas => _accounts.fold(0, (s, a) => s + a.balance);
  double get _totalAsetTetap => _assets.fold(0, (s, a) => s + a.currentValue);
  List<Debt> get _activeDebts =>
      _debts.where((d) => d.remainingAmount > 0).toList();
  double get _totalUtang =>
      _activeDebts.fold(0, (s, d) => s + d.remainingAmount);
  double get _totalInvested =>
      _investments.fold(0, (s, i) => s + i.investedAmount);
  double get _totalInvestasi =>
      _investments.fold(0, (s, i) => s + i.currentAmount);
  double get _investGain => _totalInvestasi - _totalInvested;
  double get _investPct =>
      _totalInvested > 0 ? (_investGain / _totalInvested * 100) : 0;

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message),
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
    return ok == true;
  }

  Future<void> _deleteAccount(Account a) async {
    if (!await _confirm(confirmDeleteAccountMessage(a.name))) return;
    try {
      await DataApi.deleteAccount(a.id);
      _load();
    } catch (_) {
      _snack(S.t.deleteAccountFailed);
    }
  }

  Future<void> _deleteAsset(Asset a) async {
    if (!await _confirm(confirmDeleteAssetMessage(a.name))) return;
    try {
      await DataApi.deleteAsset(a.id);
      _load();
    } catch (_) {
      _snack(S.t.deleteAssetFailed);
    }
  }

  Future<void> _deleteInvestment(Investment inv) async {
    if (!await _confirm(confirmDeleteInvestmentMessage(inv.name))) return;
    try {
      await DataApi.deleteInvestment(inv.id);
      _load();
    } catch (_) {
      _snack(S.t.deleteInvestmentFailed);
    }
  }

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openAddAccount() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddAccountSheet(onSaved: _load),
    );
  }

  void _openAddAsset() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddAssetSheet(onSaved: _load),
    );
  }

  void _openUpdateAssetValue(Asset a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _UpdateAssetValueSheet(asset: a, onSaved: _load),
    );
  }

  void _openAddInvestment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddInvestmentSheet(onSaved: _load),
    );
  }

  void _openUpdateInvestment(Investment inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => UpdateInvestmentSheet(investment: inv, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            S.t.assetsDebtScreenTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            isScrollable: false,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12.5),
            tabs: [
              Tab(text: S.t.tabCashAccounts),
              Tab(text: S.t.statFixedAssets),
              Tab(text: S.t.statInvestments),
              Tab(text: S.t.tabDebts),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAkunKasTab(),
                        _buildAsetTetapTab(),
                        _buildInvestasiTab(),
                        _buildUtangTab(),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: const BottomBannerAd(),
      ),
    );
  }

  Widget _buildAkunKasTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCard(
            label: S.t.totalCash,
            value: rp(_totalKas),
            color: _totalKas < 0 ? AppColors.coral : AppColors.primary,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: S.t.sectionCashBank, onAdd: _openAddAccount),
          const SizedBox(height: 8),
          if (_accounts.isEmpty)
            _EmptyNote(S.t.noCashAccountYet)
          else
            ..._accounts.map(
              (a) => _RowCard(
                badge: a.type,
                title: a.name,
                trailing: Text(
                  rp(a.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: a.balance < 0 ? AppColors.coral : AppColors.ink,
                  ),
                ),
                onDelete: () => _deleteAccount(a),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAsetTetapTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCard(
            label: S.t.totalFixedAssets,
            value: rp(_totalAsetTetap),
            color: AppColors.sky,
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: S.t.statFixedAssets, onAdd: _openAddAsset),
          const SizedBox(height: 8),
          if (_assets.isEmpty)
            _EmptyNote(S.t.noFixedAssetsYet)
          else
            ..._assets.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                          child: Row(
                            children: [
                              _Badge(a.type),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  a.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.coral,
                          ),
                          onPressed: () => _deleteAsset(a),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rp(a.currentValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () => _openUpdateAssetValue(a),
                        child: Text(S.t.updateValueButton),
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

  Widget _buildInvestasiTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCard(
            label: S.t.totalInvestments,
            value: rp(_totalInvestasi),
            color: AppColors.gold,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: S.t.statInvestments, onAdd: _openAddInvestment),
          const SizedBox(height: 8),
          if (_investments.isEmpty)
            _EmptyNote(S.t.noInvestmentsYet)
          else ...[
            Row(
              children: [
                Text(
                  '${rp(_totalInvested)} → ${rp(_totalInvestasi)} ',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                Text(
                  '(${_investGain >= 0 ? '+' : ''}${_investPct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _investGain >= 0
                        ? AppColors.primary
                        : AppColors.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._investments.map((inv) {
              final g = inv.currentAmount - inv.investedAmount;
              final p = inv.investedAmount > 0
                  ? (g / inv.investedAmount * 100)
                  : 0;
              final positive = g >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                          child: Row(
                            children: [
                              _Badge(inv.type),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  inv.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.coral,
                          ),
                          onPressed: () => _deleteInvestment(inv),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${rp(inv.investedAmount)} → ${rp(inv.currentAmount)} (${positive ? '+' : ''}${p.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: positive ? AppColors.primary : AppColors.coral,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () => _openUpdateInvestment(inv),
                        child: Text(S.t.updateValueButton),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildUtangTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCard(
            label: S.t.totalActiveDebt,
            value: rp(_totalUtang),
            color: AppColors.coral,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.t.debtsInstallments,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (_) => const DebtsScreen()),
                    )
                    .then((_) => _load()),
                child: Text(S.t.manageDebtLink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_activeDebts.isEmpty)
            _EmptyNote(S.t.noActiveDebtYet)
          else
            ..._activeDebts.map(
              (d) => _RowCard(
                badge: d.type,
                title: d.name,
                trailing: Text(
                  '${rp(d.remainingAmount)} · ${rp(d.monthlyInstallment)}${S.t.perMonthSuffix}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.coral,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(S.t.addButton),
        ),
      ],
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

class _RowCard extends StatelessWidget {
  final String badge;
  final String title;
  final Widget trailing;
  final VoidCallback? onDelete;
  const _RowCard({
    required this.badge,
    required this.title,
    required this.trailing,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Badge(badge),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          trailing,
          if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.coral,
              ),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddAccountSheet({required this.onSaved});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  String _type = kAccountTypes.first;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = S.t.accountNameRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.createAccount(name: _nameCtrl.text.trim(), type: _type);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.addAccountFailed);
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
            Text(
              S.t.addAccountTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: S.t.accountNameFieldHint),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(labelText: S.t.accountTypeLabel),
              items: kAccountTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
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
                  : Text(S.t.addButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAssetSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddAssetSheet({required this.onSaved});

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _type = kAssetTypes.first;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final value = CurrencyField.rawValue(_valueCtrl);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = S.t.assetNameRequired);
      return;
    }
    if (value == null || value <= 0) {
      setState(() => _error = S.t.assetValueInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.createAsset(
        name: _nameCtrl.text.trim(),
        type: _type,
        currentValue: value,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.addAssetFailed);
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
            Text(
              S.t.addAssetTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: S.t.assetNameFieldHint),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(labelText: S.t.assetTypeLabel),
              items: kAssetTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            CurrencyField(
              controller: _valueCtrl,
              labelText: S.t.currentValueEstimateLabel,
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
                  : Text(S.t.addButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateAssetValueSheet extends StatefulWidget {
  final Asset asset;
  final VoidCallback onSaved;
  const _UpdateAssetValueSheet({required this.asset, required this.onSaved});

  @override
  State<_UpdateAssetValueSheet> createState() => _UpdateAssetValueSheetState();
}

class _UpdateAssetValueSheetState extends State<_UpdateAssetValueSheet> {
  final _valueCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final value = CurrencyField.rawValue(_valueCtrl);
    if (value == null || value <= 0) {
      setState(() => _error = S.t.valueInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.updateAssetValue(widget.asset.id, value);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.updateValueFailed);
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
            Text(
              updateAssetValueTitle(widget.asset.name),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              '${S.t.currentlyPrefix}${rp(widget.asset.currentValue)}',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 16),
            CurrencyField(
              controller: _valueCtrl,
              labelText: S.t.newValueEstimateLabel,
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
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
