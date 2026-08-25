// lib/screens/transaction_detail_screen.dart
// Detail transaksi yang sudah tercatat — tampilan read-only yang mengikuti
// susunan field yang sama seperti saat pertama kali diinput (jumlah,
// kategori, tanggal, akun, utang terkait, catatan, foto invoice).
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../locale_controller.dart';
import '../models/models.dart';
import '../storage/local_invoice_store.dart';
import '../storage/token_storage.dart';
import '../theme.dart';
import 'invoice_view_screen.dart';
import 'transactions_screen.dart' show rp, AddTransactionSheet;

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  final bool hasLocalInvoice;
  final List<Account> accounts;
  final List<Debt> debts;
  final List<Category> categories;
  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.hasLocalInvoice,
    required this.accounts,
    required this.debts,
    required this.categories,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Uint8List? _localBytes;
  bool _loadingInvoice = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    if (widget.hasLocalInvoice) {
      final bytes = await LocalInvoiceStore.getLocalInvoiceBytes(
        widget.transaction.id,
      );
      if (mounted) setState(() => _localBytes = bytes);
    }
    if (mounted) setState(() => _loadingInvoice = false);
  }

  Future<void> _openFullInvoice() async {
    final t = widget.transaction;
    if (_localBytes != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InvoiceViewScreen.local(_localBytes)),
      );
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

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddTransactionSheet(
        accounts: widget.accounts,
        debts: widget.debts,
        categories: widget.categories,
        editing: widget.transaction,
        onSaved: () {
          // Balik ke daftar transaksi supaya datanya ikut ter-refresh —
          // detail di layar ini sudah tidak up-to-date lagi setelah diubah.
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isExpense = t.type == 'expense';
    final hasInvoice = _localBytes != null || t.invoiceUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.transactionDetailTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: S.t.editButton,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpense
                        ? AppColors.coral.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isExpense ? S.t.statExpense : S.t.statIncome,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isExpense ? AppColors.coral : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${isExpense ? '-' : '+'}${rp(t.amount)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isExpense ? AppColors.coral : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: S.t.transactionNameLabel, value: t.name),
          _DetailRow(label: S.t.categoryLabel, value: t.category.name),
          _DetailRow(
            label: S.t.dateFieldLabel,
            value: DateFormat(
              'd MMMM yyyy',
              LocaleController.instance.dateLocale,
            ).format(t.date),
          ),
          if (t.accountName != null)
            _DetailRow(label: S.t.cashAccountLabel, value: t.accountName!),
          if (t.debtName != null)
            _DetailRow(label: S.t.debtLinkLabel, value: t.debtName!),
          if (t.note != null && t.note!.isNotEmpty)
            _DetailRow(label: S.t.noteLabel, value: t.note!),
          if (hasInvoice || _loadingInvoice) ...[
            const SizedBox(height: 16),
            Text(
              S.t.invoicePhotoLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (_loadingInvoice)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              InkWell(
                onTap: _openFullInvoice,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _localBytes != null
                      ? Image.memory(
                          _localBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : FutureBuilder<String?>(
                          future: TokenStorage.instance.getAccessToken(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            return Image.network(
                              DataApi.invoiceViewUrl(t.invoiceUrl!),
                              headers: {
                                'Authorization': 'Bearer ${snapshot.data}',
                              },
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => SizedBox(
                                height: 180,
                                child: Center(
                                  child: Text(
                                    S.t.failedLoadPhoto,
                                    style: TextStyle(color: AppColors.inkSoft),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
