// lib/utils/calc_eval.dart
// Evaluator ekspresi aritmatika sederhana & aman (recursive-descent parser
// tulisan sendiri — Dart memang tidak punya eval() bawaan) untuk mode
// "Kalkulator" pada CurrencyField. Mendukung + - * / (dan alias × ÷ x)
// serta tanda kurung. Setara app/calc-eval.ts di versi web.
//
// PENTING soal tanda titik: di sini "." dianggap PEMISAH RIBUAN ala id-ID
// (mis. "100.000" = seratus ribu), BUKAN titik desimal ala pemrograman —
// karena app ini cuma pakai Rupiah bulat, tidak ada kebutuhan desimal sama
// sekali di tempat lain. Titik cuma dibuang saat parsing, tidak
// memengaruhi nilainya (beda dari double.parse biasa yang akan membaca
// "100.000" sebagai 100).

class _Token {
  final bool isNum;
  final double numValue;
  final String opValue;
  _Token.num(this.numValue) : isNum = true, opValue = '';
  _Token.op(this.opValue) : isNum = false, numValue = 0;
}

List<_Token>? _tokenize(String expr) {
  final normalized = expr.replaceAll(RegExp('[×xX]'), '*').replaceAll('÷', '/');
  final tokens = <_Token>[];
  var i = 0;
  while (i < normalized.length) {
    final ch = normalized[i];
    if (ch == ' ') {
      i++;
      continue;
    }
    if ('+-*/()'.contains(ch)) {
      tokens.add(_Token.op(ch));
      i++;
      continue;
    }
    if (RegExp(r'[0-9.]').hasMatch(ch)) {
      var j = i;
      while (j < normalized.length &&
          RegExp(r'[0-9.]').hasMatch(normalized[j])) {
        j++;
      }
      final raw = normalized.substring(i, j);
      // Buang titik (pemisah ribuan), bukan diperlakukan sebagai desimal.
      final withoutSeparators = raw.replaceAll('.', '');
      final num = double.tryParse(withoutSeparators);
      if (num == null) return null;
      tokens.add(_Token.num(num));
      i = j;
      continue;
    }
    return null; // karakter tidak dikenal
  }
  return tokens;
}

/// expr -> term (('+'|'-') term)*   |  term -> factor (('*'|'/') factor)*
/// factor -> NUM | '(' expr ')' | '-' factor
class _Parser {
  final List<_Token> tokens;
  int pos = 0;
  _Parser(this.tokens);

  _Token? get _peek => pos < tokens.length ? tokens[pos] : null;
  _Token _next() => tokens[pos++];

  double? parseExpr() {
    var value = _parseTerm();
    if (value == null) return null;
    while (_peek != null &&
        !_peek!.isNum &&
        (_peek!.opValue == '+' || _peek!.opValue == '-')) {
      final op = _next();
      final rhs = _parseTerm();
      if (rhs == null) return null;
      value = op.opValue == '+' ? value! + rhs : value! - rhs;
    }
    return value;
  }

  double? _parseTerm() {
    var value = _parseFactor();
    if (value == null) return null;
    while (_peek != null &&
        !_peek!.isNum &&
        (_peek!.opValue == '*' || _peek!.opValue == '/')) {
      final op = _next();
      final rhs = _parseFactor();
      if (rhs == null) return null;
      if (op.opValue == '/' && rhs == 0) return null; // hindari bagi nol
      value = op.opValue == '*' ? value! * rhs : value! / rhs;
    }
    return value;
  }

  double? _parseFactor() {
    final tok = _peek;
    if (tok == null) return null;
    if (!tok.isNum && tok.opValue == '-') {
      _next();
      final inner = _parseFactor();
      return inner == null ? null : -inner;
    }
    if (!tok.isNum && tok.opValue == '(') {
      _next();
      final inner = parseExpr();
      if (inner == null) return null;
      final close = _peek;
      if (close == null || close.isNum || close.opValue != ')') return null;
      _next();
      return inner;
    }
    if (tok.isNum) {
      _next();
      return tok.numValue;
    }
    return null;
  }

  bool get isAtEnd => pos >= tokens.length;
}

/// Evaluasi ekspresi aritmatika sederhana (mis. "15000+25000+8000").
/// Return null kalau kosong/tidak lengkap/tidak valid.
double? evaluateExpression(String expr) {
  final trimmed = expr.trim();
  if (trimmed.isEmpty) return null;
  final tokens = _tokenize(trimmed);
  if (tokens == null || tokens.isEmpty) return null;
  final parser = _Parser(tokens);
  final result = parser.parseExpr();
  if (result == null || !parser.isAtEnd || !result.isFinite) return null;
  return result;
}
