// lib/screens/migration_screen.dart
// Layar pindahan satu kali: data pengguna lama diunduh dari server ke
// database lokal HP (lib/data/server_migration.dart), lalu pengguna
// ditawari menghapus salinannya di server. Tampil otomatis saat aplikasi
// dibuka dengan sesi login lama, atau setelah "Ambil Data dari Akun Lama"
// di layar Backup.
import 'package:flutter/material.dart';
import '../api/auth_api.dart' show ApiException;
import '../data/server_migration.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import 'home_screen.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  MigrationResult? _result;
  String? _error;
  bool _deleting = false;
  String? _deleteError;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _result = null;
    });
    try {
      final result = await ServerMigration.run();
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = S.t.genericConnectionError);
    }
  }

  Future<void> _deleteServerData() async {
    setState(() {
      _deleting = true;
      _deleteError = null;
    });
    try {
      await ServerMigration.deleteServerData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t.migrationServerDeleted)));
      _goHome();
    } on ApiException catch (e) {
      setState(() => _deleteError = e.message);
    } catch (_) {
      setState(() => _deleteError = S.t.genericConnectionError);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  result != null
                      ? Icons.check_circle_outline
                      : _error != null
                      ? Icons.cloud_off_outlined
                      : Icons.phone_android,
                  size: 48,
                  color: _error != null ? AppColors.coral : AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  result != null
                      ? S.t.migrationDoneTitle
                      : _error != null
                      ? S.t.migrationFailedTitle
                      : S.t.migrationTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (result == null && _error == null) ...[
                  Text(
                    S.t.migrationIntro,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  Text(
                    S.t.migrationRunning,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _run,
                    child: Text(S.t.migrationRetryButton),
                  ),
                ],
                if (result != null) ...[
                  Text(
                    migrationDoneBody(
                      result.transactionCount,
                      result.invoiceCount,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  ),
                  if (result.invoiceFailedCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      migrationInvoiceFailedNote(result.invoiceFailedCount),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.coral, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    S.t.migrationDeleteServerQuestion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.5),
                  ),
                  if (_deleteError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _deleteError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.coral, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _deleting ? null : _deleteServerData,
                    child: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(S.t.migrationDeleteServerButton),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _deleting ? null : _goHome,
                    child: Text(S.t.migrationLaterButton),
                  ),
                  Text(
                    S.t.migrationLaterNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
