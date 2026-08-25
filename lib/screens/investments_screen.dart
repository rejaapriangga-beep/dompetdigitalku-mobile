// lib/screens/investments_screen.dart
// Dulunya layar sendiri (mirror app/investments/page.tsx); sekarang isinya
// jadi bagian dari halaman Aset & Utang (accounts_assets_screen.dart) supaya
// tidak perlu ikon menu terpisah di Beranda. File ini menyisakan konstanta
// jenis investasi + form tambah/perbarui nilai yang dipakai di sana.
import 'package:flutter/material.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/currency_field.dart';
import 'transactions_screen.dart' show rp;

const kInvestmentTypes = [
  'Saham',
  'Reksadana',
  'Obligasi',
  'Emas',
  'Kripto',
  'Deposito',
  'Properti',
  'Lainnya',
];

class AddInvestmentSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const AddInvestmentSheet({super.key, required this.onSaved});

  @override
  State<AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<AddInvestmentSheet> {
  final _nameCtrl = TextEditingController();
  final _investedCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  String _type = kInvestmentTypes.first;
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final invested = CurrencyField.rawValue(_investedCtrl);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = S.t.investmentNameRequired);
      return;
    }
    if (invested == null || invested <= 0) {
      setState(() => _error = S.t.initialCapitalInvalid);
      return;
    }
    final current = CurrencyField.rawValue(_currentCtrl) ?? invested;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.createInvestment(
        name: _nameCtrl.text.trim(),
        type: _type,
        investedAmount: invested,
        currentAmount: current,
        startDate: _startDate,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      setState(() => _error = S.t.addInvestmentFailed);
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
              S.t.addInvestmentTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: S.t.investmentNameLabel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(labelText: S.t.investmentTypeLabel),
              items: kInvestmentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            CurrencyField(
              controller: _investedCtrl,
              labelText: S.t.initialCapitalLabel,
            ),
            const SizedBox(height: 12),
            CurrencyField(
              controller: _currentCtrl,
              labelText: S.t.currentValueEmptyLabel,
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

class UpdateInvestmentSheet extends StatefulWidget {
  final Investment investment;
  final VoidCallback onSaved;
  const UpdateInvestmentSheet({
    super.key,
    required this.investment,
    required this.onSaved,
  });

  @override
  State<UpdateInvestmentSheet> createState() => _UpdateInvestmentSheetState();
}

class _UpdateInvestmentSheetState extends State<UpdateInvestmentSheet> {
  final _valueCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final value = CurrencyField.rawValue(_valueCtrl);
    if (value == null || value < 0) {
      setState(() => _error = S.t.valueInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DataApi.updateInvestmentValue(widget.investment.id, value);
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
              updateAssetValueTitle(widget.investment.name),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              '${S.t.currentlyPrefix}${rp(widget.investment.currentAmount)}',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 16),
            CurrencyField(
              controller: _valueCtrl,
              labelText: S.t.currentValueLabel,
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
