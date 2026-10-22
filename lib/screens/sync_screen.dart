// lib/screens/sync_screen.dart
// Pengaturan Sinkron Google Drive (lib/sync/drive_sync.dart): aktifkan
// (pilih akun Google → buat/masukkan sandi sinkron), sinkron manual, lihat
// status, dan matikan.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../locale_controller.dart';
import '../sync/drive_sync.dart';
import '../theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _working = false;
  String? _error;

  Future<void> _enable() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final remoteExists = await DriveSync.connect();
      if (remoteExists == null || !mounted) return;
      while (mounted) {
        final pass = await _askPassphrase(creating: !remoteExists);
        if (pass == null) return;
        try {
          await DriveSync.enable(pass);
          return;
        } on WrongSyncPassphrase {
          if (mounted) _snack(S.t.syncWrongPass);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = S.t.syncConnectFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _syncNow() async {
    if (DriveSync.state.value.problem == SyncProblem.needsSignIn) {
      await DriveSync.reconnect();
    } else {
      await DriveSync.syncNow();
    }
  }

  Future<void> _disable({required bool deleteRemote}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          deleteRemote ? S.t.syncDeleteRemoteButton : S.t.syncDisableButton,
        ),
        content: Text(
          deleteRemote ? S.t.syncDeleteRemoteConfirm : S.t.syncDisableConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              deleteRemote ? S.t.delete : S.t.syncDisableButton,
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await DriveSync.disable(deleteRemote: deleteRemote);
    } catch (_) {
      if (mounted) setState(() => _error = S.t.syncConnectFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String?> _askPassphrase({required bool creating}) {
    final pass = TextEditingController();
    final repeat = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(
            creating ? S.t.syncCreatePassTitle : S.t.syncEnterPassTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creating ? S.t.syncCreatePassBody : S.t.syncEnterPassBody,
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pass,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(labelText: S.t.syncPassLabel),
                ),
                if (creating)
                  TextField(
                    controller: repeat,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: S.t.syncPassConfirmLabel,
                    ),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: AppColors.coral, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.t.cancel),
            ),
            TextButton(
              onPressed: () {
                if (pass.text.length < 8) {
                  setDialog(() => error = S.t.syncPassTooShort);
                } else if (creating && pass.text != repeat.text) {
                  setDialog(() => error = S.t.syncPassMismatch);
                } else {
                  Navigator.pop(ctx, pass.text);
                }
              },
              child: Text(S.t.continueButton),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _problemText(SyncProblem p) => switch (p) {
    SyncProblem.none => null,
    SyncProblem.wrongPassphrase => S.t.syncWrongPassStored,
    SyncProblem.needsSignIn => S.t.syncNeedsSignIn,
    SyncProblem.network => S.t.syncNetworkError,
    SyncProblem.unknown => S.t.syncUnknownError,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.syncTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ValueListenableBuilder<SyncState>(
        valueListenable: DriveSync.state,
        builder: (context, st, _) {
          final problem = _problemText(st.problem);
          final last = st.lastSyncAt;
          final busy = _working || st.syncing;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Icon(
                Icons.cloud_sync_outlined,
                size: 44,
                color: st.enabled ? AppColors.primary : AppColors.inkSoft,
              ),
              const SizedBox(height: 12),
              Text(
                S.t.syncDescription,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 20),
              if (st.enabled) ...[
                if (st.email != null)
                  Text(
                    syncConnectedAs(st.email!),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 4),
                Text(
                  st.syncing
                      ? S.t.syncSyncing
                      : last == null
                      ? S.t.syncNever
                      : syncLastAt(
                          DateFormat(
                            'd MMM yyyy, HH:mm',
                            LocaleController.instance.isEnglish
                                ? 'en_US'
                                : 'id_ID',
                          ).format(last.toLocal()),
                        ),
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
              ],
              if (problem != null || _error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error ?? problem!,
                    style: TextStyle(color: AppColors.coral, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!st.enabled)
                ElevatedButton.icon(
                  onPressed: busy ? null : _enable,
                  icon: const Icon(Icons.cloud_done_outlined),
                  label: Text(S.t.syncEnableButton),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: busy ? null : _syncNow,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(S.t.syncNowButton),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy ? null : () => _disable(deleteRemote: false),
                  child: Text(S.t.syncDisableButton),
                ),
                TextButton(
                  onPressed: busy ? null : () => _disable(deleteRemote: true),
                  child: Text(
                    S.t.syncDeleteRemoteButton,
                    style: TextStyle(color: AppColors.coral),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
