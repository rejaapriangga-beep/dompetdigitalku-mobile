// lib/screens/delete_account_screen.dart
// Halaman "Zona Berbahaya" — hapus akun & seluruh data rumah tangga secara
// permanen (pemenuhan hak hapus data UU PDP Pasal 26). Butuh ketik "HAPUS"
// untuk konfirmasi, mencerminkan versi web di app/settings/account/page.tsx.
import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../api/data_api.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  bool _deleting = false;
  String? _error;

  bool get _canDelete =>
      _confirmCtrl.text.trim().toUpperCase() == S.t.deleteConfirmWord;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    final really = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t.areYouSureTitle),
        content: Text(S.t.deleteAccountConfirmBody),
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
    if (really != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await DataApi.deleteUserAccount();
      await AuthApi.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = S.t.deleteAccountFailedGeneric);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.deleteAccountLink,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.t.dangerZoneTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.t.dangerZoneDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  typeConfirmWordToConfirm(S.t.deleteConfirmWord),
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: S.t.deleteConfirmWord),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.coral, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canDelete
                          ? AppColors.coral
                          : AppColors.border,
                    ),
                    onPressed: (_canDelete && !_deleting)
                        ? _confirmAndDelete
                        : null,
                    child: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            S.t.deleteAccountAndAllDataButton,
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
