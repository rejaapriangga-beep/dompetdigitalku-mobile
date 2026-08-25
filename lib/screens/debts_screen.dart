// lib/screens/debts_screen.dart
// Mirror dari app/debts/page.tsx: kelola utang penuh (tambah, bayar cicilan, hapus).
import 'package:flutter/material.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/currency_field.dart';
import '../widgets/stat_card.dart';
import 'transactions_screen.dart' show rp;

const kDebtTypes = [
  'KPR',
  'Kredit Kendaraan',
  'Kartu Kredit',
  'Pinjaman Online',
  'Pinjaman Pribadi',
  'Lainnya',
];

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
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
      final debts = await DataApi.getDebts();
      setState(() => _debts = debts);
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalRemaining => _debts.fold(0, (s, d) => s + d.remainingAmount);
  double get _totalInstallment => _debts
      .where((d) => d.remainingAmount > 0)
      .fold(0, (s, d) => s + d.monthlyInstallment);

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _delete(Debt d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirmDeleteDebtMessage(d.name)),
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
    if (ok != true) return;
    try {
      await DataApi.deleteDebt(d.id);
      _load();
    } catch (_) {
      _snack(S.t.deleteDebtFailed);
    }
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddDebtSheet(onSaved: _load),
    );
  }

  void _openPay(Debt d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PayDebtSheet(debt: d, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.debtsInstallments,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
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
                        child: StatCard(
                          label: S.t.totalRemainingDebt,
                          value: rp(_totalRemaining),
                          color: AppColors.coral,
                          icon: Icons.credit_card,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: S.t.installmentPerMonth,
                          value: rp(_totalInstallment),
                          color: AppColors.amber,
                          icon: Icons.event_repeat,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_debts.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          S.t.noDebtYet,
                          style: TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                    )
                  else
                    ..._debts.map((d) {
                      final paid = d.totalAmount - d.remainingAmount;
                      final pct = d.totalAmount > 0
                          ? (paid / d.totalAmount * 100).clamp(0, 100)
                          : 0.0;
                      final isPaidOff = d.remainingAmount <= 0;
                      return Container(
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
                                    d.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: AppColors.coral,
                                  ),
                                  onPressed: () => _delete(d),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                d.type + (isPaidOff ? S.t.paidOffSuffix : ''),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: AppColors.bg,
                                valueColor: AlwaysStoppedAnimation(
                                  isPaidOff
                                      ? AppColors.primary
                                      : AppColors.gold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              debtRemainingSummary(
                                rp(d.remainingAmount),
                                rp(d.totalAmount),
                                rp(d.monthlyInstallment),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            if (!isPaidOff) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton(
                                  onPressed: () => _openPay(d),
                                  child: Text(S.t.recordPaymentButton),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}

class _AddDebtSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddDebtSheet({required this.onSaved});

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _installmentCtrl = TextEditingController();
  String _type = kDebtTypes.first;
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final total = CurrencyField.rawValue(_totalCtrl);
    final installment = CurrencyField.rawValue(_installmentCtrl);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = S.t.debtNameRequired);
      return;
    }
    if (total == null || total <= 0) {
      setState(() => _error = S.t.principalTotalInvalid);
      return;
    }
    if (installment == null || installment <= 0) {
      setState(() => _error = S.t.monthlyInstallmentInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.createDebt(
        name: _nameCtrl.text.trim(),
        type: _type,
        totalAmount: total,
        monthlyInstallment: installment,
        startDate: _startDate,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.addDebtFailed);
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
              S.t.addDebtTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: S.t.debtNameFieldHint),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(labelText: S.t.debtTypeLabel),
              items: kDebtTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            CurrencyField(
              controller: _totalCtrl,
              labelText: S.t.principalTotalLabel,
            ),
            const SizedBox(height: 12),
            CurrencyField(
              controller: _installmentCtrl,
              labelText: S.t.monthlyInstallmentLabel,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(labelText: S.t.startDateLabel),
                child: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                ),
              ),
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

class _PayDebtSheet extends StatefulWidget {
  final Debt debt;
  final VoidCallback onSaved;
  const _PayDebtSheet({required this.debt, required this.onSaved});

  @override
  State<_PayDebtSheet> createState() => _PayDebtSheetState();
}

class _PayDebtSheetState extends State<_PayDebtSheet> {
  final _amountCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final amount = CurrencyField.rawValue(_amountCtrl);
    if (amount == null || amount <= 0) {
      setState(() => _error = S.t.paymentAmountInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.payDebt(widget.debt.id, amount);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.recordPaymentFailed);
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
              recordPaymentTitle(widget.debt.name),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              '${S.t.currentRemainingPrefix}${rp(widget.debt.remainingAmount)}',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 16),
            CurrencyField(
              controller: _amountCtrl,
              labelText: S.t.paymentAmountLabel,
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
                  : Text(S.t.payButton),
            ),
          ],
        ),
      ),
    );
  }
}
