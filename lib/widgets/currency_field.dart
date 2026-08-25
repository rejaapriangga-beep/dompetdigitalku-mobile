// lib/widgets/currency_field.dart
// Input angka dengan pemisah ribuan otomatis ala Indonesia (mis. "5.000.000")
// selagi mengetik — setara CurrencyInput di versi web (app/currency-input.tsx).
// Controller menyimpan teks yang SUDAH diformat; ambil nilai mentahnya lewat
// CurrencyField.rawValue(controller).
//
// Ada 2 mode, bisa dipilih lewat ikon di kanan field:
// - Numerik (default): ketik angka biasa lewat keyboard sistem, langsung
//   diformat pemisah ribuan.
// - Kalkulator: ketik ekspresi (mis. "15000+25000+8000") untuk menjumlahkan
//   beberapa struk/pos sekaligus — berguna waktu input belanja pasar yang
//   itemnya banyak. Field jadi read-only dan dipakaikan KEYPAD SENDIRI di
//   bawahnya (bukan keyboard numerik bawaan Android/iOS, yang biasanya tidak
//   punya tombol operator + − × ÷). Hasilnya otomatis dihitung saat tombol
//   "Hitung & Selesai" ditekan atau field kehilangan fokus, lalu field
//   kembali ke tampilan angka biasa.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../utils/calc_eval.dart';

final _thousands = NumberFormat.decimalPattern('id_ID');

class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final formatted = _thousands.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  const CurrencyField({
    super.key,
    required this.controller,
    required this.labelText,
  });

  /// Ambil nilai mentah (tanpa titik pemisah) dari controller yang dipakai CurrencyField.
  static double? rawValue(TextEditingController controller) {
    final digits = controller.text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : double.tryParse(digits);
  }

  /// Isi controller dengan nilai yang sudah diformat pemisah ribuan (mis. buat prefill).
  static void setValue(TextEditingController controller, num value) {
    controller.text = _thousands.format(value);
  }

  @override
  State<CurrencyField> createState() => _CurrencyFieldState();
}

class _CurrencyFieldState extends State<CurrencyField> {
  bool _calcMode = false;
  final _calcController = TextEditingController();
  final _calcFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _calcFocusNode.addListener(() {
      if (!_calcFocusNode.hasFocus) _commitCalc();
    });
  }

  @override
  void dispose() {
    _calcController.dispose();
    _calcFocusNode.dispose();
    super.dispose();
  }

  double? get _calcResult => evaluateExpression(_calcController.text);

  void _commitCalc() {
    final result = _calcResult;
    if (result != null && result >= 0) {
      CurrencyField.setValue(widget.controller, result.round());
    }
    setState(() {
      _calcMode = false;
      _calcController.clear();
    });
  }

  void _enterCalcMode() {
    setState(() {
      _calcController.text = widget.controller.text;
      _calcMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calcFocusNode.requestFocus();
    });
  }

  /// Sisipkan [s] di posisi kursor saat ini pada _calcController (bukan
  /// selalu di akhir teks) — supaya tombol keypad terasa seperti kalkulator
  /// sungguhan, bukan cuma "tempel di belakang".
  void _insertAtCursor(String s) {
    final text = _calcController.text;
    final sel = _calcController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, s);
    setState(() {
      _calcController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + s.length),
      );
    });
  }

  void _backspace() {
    final text = _calcController.text;
    if (text.isEmpty) return;
    final sel = _calcController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    if (start == end) {
      if (start == 0) return;
      setState(() {
        _calcController.value = TextEditingValue(
          text: text.replaceRange(start - 1, start, ''),
          selection: TextSelection.collapsed(offset: start - 1),
        );
      });
    } else {
      setState(() {
        _calcController.value = TextEditingValue(
          text: text.replaceRange(start, end, ''),
          selection: TextSelection.collapsed(offset: start),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_calcMode) {
      final result = _calcResult;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _calcController,
            focusNode: _calcFocusNode,
            readOnly: true,
            showCursor: true,
            decoration: InputDecoration(
              labelText: widget.labelText,
              prefixText: 'Rp ',
              hintText: 'mis. 15000+25000+8000',
              suffixIcon: IconButton(
                icon: const Icon(Icons.tag, size: 26),
                tooltip: 'Ganti ke input angka biasa',
                onPressed: _commitCalc,
              ),
              helperText: _calcController.text.trim().isEmpty
                  ? 'Pakai keypad di bawah untuk ketik penjumlahan.'
                  : (result != null && result >= 0
                        ? '= Rp${result.round().toLocaleId()}'
                        : 'Ekspresi belum lengkap/valid.'),
            ),
          ),
          const SizedBox(height: 8),
          _CalcKeypad(
            onDigit: _insertAtCursor,
            onBackspace: _backspace,
            onCommit: _commitCalc,
          ),
        ],
      );
    }
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsInputFormatter()],
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixText: 'Rp ',
        suffixIcon: IconButton(
          icon: const Icon(Icons.calculate_outlined, size: 26),
          tooltip: 'Ganti ke mode kalkulator (jumlahkan beberapa angka)',
          onPressed: _enterCalcMode,
        ),
      ),
    );
  }
}

/// Keypad kalkulator sendiri (bukan keyboard sistem) — dipakai saat mode
/// kalkulator aktif, supaya tombol operator + − × ÷ selalu ada (keyboard
/// numerik bawaan Android/iOS umumnya tidak menyediakan itu).
class _CalcKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onCommit;
  const _CalcKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _CalcKey('7', () => onDigit('7')),
            _CalcKey('8', () => onDigit('8')),
            _CalcKey('9', () => onDigit('9')),
            _CalcKey('÷', () => onDigit('÷'), isOperator: true),
          ],
        ),
        Row(
          children: [
            _CalcKey('4', () => onDigit('4')),
            _CalcKey('5', () => onDigit('5')),
            _CalcKey('6', () => onDigit('6')),
            _CalcKey('×', () => onDigit('×'), isOperator: true),
          ],
        ),
        Row(
          children: [
            _CalcKey('1', () => onDigit('1')),
            _CalcKey('2', () => onDigit('2')),
            _CalcKey('3', () => onDigit('3')),
            _CalcKey('−', () => onDigit('-'), isOperator: true),
          ],
        ),
        Row(
          children: [
            _CalcKey('.', () => onDigit('.')),
            _CalcKey('0', () => onDigit('0')),
            _CalcKey('⌫', onBackspace),
            _CalcKey('+', () => onDigit('+'), isOperator: true),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: onCommit,
            child: const Text('= Hitung & Selesai'),
          ),
        ),
      ],
    );
  }
}

class _CalcKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  const _CalcKey(this.label, this.onTap, {this.isOperator = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: isOperator
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              height: 62,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isOperator ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _IdFormat on int {
  String toLocaleId() => _thousands.format(this);
}
