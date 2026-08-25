// lib/models/models.dart

class Account {
  final String id;
  final String name;
  final String type;
  final double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    balance: (json['balance'] as num).toDouble(),
  );
}

class Debt {
  final String id;
  final String name;
  final String type;
  final double totalAmount;
  final double remainingAmount;
  final double monthlyInstallment;

  Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.remainingAmount,
    required this.monthlyInstallment,
  });

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'],
    name: json['name'],
    type: json['type'] ?? 'Lainnya',
    totalAmount: double.parse((json['totalAmount'] ?? 0).toString()),
    remainingAmount: double.parse(json['remainingAmount'].toString()),
    monthlyInstallment: double.parse(
      (json['monthlyInstallment'] ?? 0).toString(),
    ),
  );
}

class Investment {
  final String id;
  final String name;
  final String type;
  final double investedAmount;
  final double currentAmount;

  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentAmount,
  });

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    investedAmount: double.parse(json['investedAmount'].toString()),
    currentAmount: double.parse(json['currentAmount'].toString()),
  );
}

class Asset {
  final String id;
  final String name;
  final String type;
  final double currentValue;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.currentValue,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    currentValue: double.parse(json['currentValue'].toString()),
  );
}

// Kelompok kategori transaksi, dikelola lewat menu Kategori (bukan diketik
// bebas lagi di form Transaksi) — dipakai bersama oleh Transaksi & Anggaran.
class Category {
  final String id;
  final String name;
  final String type; // "income" | "expense"

  Category({required this.id, required this.name, this.type = 'expense'});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    type: json['type'] ?? 'expense',
  );
}

class Transaction {
  final String id;
  final String type; // "income" | "expense"
  final double amount;
  final String name; // Nama Transaksi (bebas diisi)
  final Category category;
  final DateTime date;
  final String? note;
  final String accountId;
  final String? accountName;
  final String? debtId;
  final String? debtName;
  final String? invoiceUrl;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.name,
    required this.category,
    required this.date,
    this.note,
    required this.accountId,
    this.accountName,
    this.debtId,
    this.debtName,
    this.invoiceUrl,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    type: json['type'],
    amount: double.parse(json['amount'].toString()),
    name: json['name'],
    category: Category.fromJson(json['category']),
    date: DateTime.parse(json['date']),
    note: json['note'],
    accountId: json['accountId'],
    accountName: json['account']?['name'],
    debtId: json['debtId'],
    debtName: json['debt']?['name'],
    invoiceUrl: json['invoiceUrl'],
  );
}
