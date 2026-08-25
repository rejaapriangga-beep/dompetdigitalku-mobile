// lib/screens/categories_screen.dart
// Mirror dari app/settings/categories/page.tsx: kelola kategori transaksi
// (tambah, ubah nama, hapus) — dipakai bersama oleh form Transaksi (pilihan,
// bukan ketik bebas) dan Anggaran Bulanan. Dipisah 2 tab (Pengeluaran/
// Pemasukan) lewat Category.type.
import 'package:flutter/material.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
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
      final cats = await DataApi.getCategories();
      setState(() => _categories = cats);
    } catch (_) {
      setState(() => _error = S.t.errorLoadData);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            S.t.categoryScreenTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: S.t.tabExpenseCategory),
              Tab(text: S.t.tabIncomeCategory),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _CategoryTypeList(
                    type: 'expense',
                    categories: _categories
                        .where((c) => c.type == 'expense')
                        .toList(),
                    error: _error,
                    onReload: _load,
                  ),
                  _CategoryTypeList(
                    type: 'income',
                    categories: _categories
                        .where((c) => c.type == 'income')
                        .toList(),
                    error: _error,
                    onReload: _load,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CategoryTypeList extends StatefulWidget {
  final String type;
  final List<Category> categories;
  final String? error;
  final Future<void> Function() onReload;
  const _CategoryTypeList({
    required this.type,
    required this.categories,
    required this.error,
    required this.onReload,
  });

  @override
  State<_CategoryTypeList> createState() => _CategoryTypeListState();
}

class _CategoryTypeListState extends State<_CategoryTypeList> {
  final _nameCtrl = TextEditingController();
  bool _adding = false;
  String? _addError;
  String? _editingId;
  final _editCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _addError = S.t.categoryNameRequired);
      return;
    }
    setState(() {
      _adding = true;
      _addError = null;
    });
    try {
      await DataApi.createCategory(name, type: widget.type);
      _nameCtrl.clear();
      await widget.onReload();
    } catch (_) {
      setState(() => _addError = S.t.addCategoryFailed);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _startEdit(Category c) {
    setState(() {
      _editingId = c.id;
      _editCtrl.text = c.name;
    });
  }

  Future<void> _saveEdit(String id) async {
    final name = _editCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await DataApi.updateCategory(id, name);
      setState(() => _editingId = null);
      widget.onReload();
    } catch (_) {
      _snack(S.t.updateCategoryFailed);
    }
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirmDeleteCategoryMessage(c.name)),
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
      await DataApi.deleteCategory(c.id);
      widget.onReload();
    } catch (_) {
      _snack(S.t.deleteCategoryInUse);
    }
  }

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.type == 'expense';
    return RefreshIndicator(
      onRefresh: widget.onReload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.error!,
                style: TextStyle(color: AppColors.coral),
              ),
            ),
          Text(
            isExpense
                ? S.t.expenseCategoryDescription
                : S.t.incomeCategoryDescription,
            style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: isExpense
                        ? S.t.newExpenseCategoryHint
                        : S.t.newIncomeCategoryHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _adding ? null : _add,
                child: _adding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(S.t.addButton),
              ),
            ],
          ),
          if (_addError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _addError!,
                style: TextStyle(color: AppColors.coral, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 16),
          if (widget.categories.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                isExpense ? S.t.noExpenseCategoryYet : S.t.noIncomeCategoryYet,
                style: TextStyle(color: AppColors.inkSoft),
              ),
            )
          else
            ...widget.categories.map((c) {
              final isEditing = _editingId == c.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.check, color: AppColors.primary),
                            onPressed: () => _saveEdit(c.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppColors.coral),
                            onPressed: () => setState(() => _editingId = null),
                          ),
                        ],
                      )
                    : Row(
                        children: [
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
                              c.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _startEdit(c),
                            child: Text(S.t.editButton),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.coral,
                            ),
                            onPressed: () => _delete(c),
                          ),
                        ],
                      ),
              );
            }),
        ],
      ),
    );
  }
}
