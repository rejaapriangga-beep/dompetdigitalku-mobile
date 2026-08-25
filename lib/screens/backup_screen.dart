// lib/screens/backup_screen.dart
// Backup & Pulihkan Data — buat salinan terenkripsi data rumah tangga
// (simpan/kirim lewat share sheet Android, termasuk bisa langsung ke Google
// Drive dari situ), atau pulihkan dari salinan tersebut. Saat membuat
// backup, ada pilihan centang untuk menyertakan lampiran (foto invoice
// mode "Lokal") ke dalam file backup yang sama, atau cuma data keuangannya
// saja. Enkripsi AES-256 dengan passphrase yang dibuat sendiri oleh
// pengguna (lihat lib/backup/backup_crypto.dart) — kalau lupa
// passphrase-nya, backup tidak bisa dipulihkan lagi, itu memang cara kerja
// enkripsi yang aman.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backup/backup_crypto.dart';
import '../backup/backup_service.dart';
import '../l10n/app_strings.dart';
import '../locale_controller.dart';
import '../theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _CreateBackupChoice {
  final String passphrase;
  final bool includeAttachments;
  _CreateBackupChoice(this.passphrase, this.includeAttachments);
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _busyLabel;
  String? _error;
  String? _success;

  void _setBusy(String? label) {
    setState(() {
      _busy = label != null;
      _busyLabel = label;
      _error = null;
      _success = null;
    });
  }

  void _fail(Object e) {
    setState(() {
      _busy = false;
      _error = e is BackupDecryptException ? e.message : e.toString();
    });
  }

  void _done(String message) {
    setState(() {
      _busy = false;
      _success = message;
    });
  }

  Future<_CreateBackupChoice?> _askCreatePassphrase() {
    return showModalBottomSheet<_CreateBackupChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _CreatePassphraseSheet(),
    );
  }

  Future<String?> _askRestorePassphrase() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _RestorePassphraseSheet(),
    );
  }

  Future<bool> _confirmReplace(BackupPreview preview) async {
    final label = preview.exportedAt != null
        ? DateFormat(
            'd MMMM yyyy, HH:mm',
            LocaleController.instance.dateLocale,
          ).format(preview.exportedAt!)
        : S.t.unknownLabel;
    final lampiranInfo = preview.attachmentCount > 0
        ? attachmentInfoSuffix(preview.attachmentCount)
        : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t.confirmRestoreTitle),
        content: Text(
          confirmRestoreBody(
            label,
            preview.transactionCount,
            preview.accountCount,
            lampiranInfo,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.t.restoreButton,
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _createLocal() async {
    final choice = await _askCreatePassphrase();
    if (choice == null) return;
    _setBusy(S.t.creatingBackup);
    try {
      final attachmentCount = await BackupService.createAndShareLocal(
        choice.passphrase,
        includeAttachments: choice.includeAttachments,
      );
      _done(
        choice.includeAttachments
            ? backupCreatedWithAttachments(attachmentCount)
            : S.t.backupCreatedSuccess,
      );
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _restoreLocal() async {
    final pass = await _askRestorePassphrase();
    if (pass == null) return;
    _setBusy(S.t.readingBackupFile);
    try {
      final preview = await BackupService.pickAndDecryptLocalFile(pass);
      if (preview == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() => _busy = false);
      if (!await _confirmReplace(preview)) return;
      _setBusy(S.t.restoringData);
      await BackupService.restore(preview);
      _done(S.t.restoreSuccess);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.t.backupRestoreTooltip,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _busyLabel ?? S.t.processingLabel,
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.coral, fontSize: 13),
                ),
              ),
            if (_success != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _success!,
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),

            Text(
              S.t.createBackupTitle,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              S.t.createBackupDescription,
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.save_alt,
              color: AppColors.primary,
              title: S.t.createSaveBackupTitle,
              subtitle: S.t.createSaveBackupSubtitle,
              onTap: _createLocal,
            ),

            const SizedBox(height: 22),
            Text(
              S.t.restoreFromBackupTitle,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              S.t.restoreDescription,
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.file_open_outlined,
              color: AppColors.gold,
              title: S.t.chooseBackupFileTitle,
              subtitle: S.t.chooseBackupFileSubtitle,
              onTap: _restoreLocal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _CreatePassphraseSheet extends StatefulWidget {
  const _CreatePassphraseSheet();

  @override
  State<_CreatePassphraseSheet> createState() => _CreatePassphraseSheetState();
}

class _CreatePassphraseSheetState extends State<_CreatePassphraseSheet> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _includeAttachments = true;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pass = _passCtrl.text;
    if (pass.length < 8) {
      setState(() => _error = S.t.passphraseMinLength);
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = S.t.passphraseMismatch);
      return;
    }
    Navigator.pop(context, _CreateBackupChoice(pass, _includeAttachments));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t.createPassphraseTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              S.t.passphraseWarning,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gold,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: S.t.passphraseLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: S.t.repeatPassphraseLabel),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: _includeAttachments,
            onChanged: (v) => setState(() => _includeAttachments = v ?? true),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              S.t.includeAttachmentsTitle,
              style: TextStyle(fontSize: 13, color: AppColors.ink),
            ),
            subtitle: Text(
              _includeAttachments
                  ? S.t.includeAttachmentsSubtitleOn
                  : S.t.includeAttachmentsSubtitleOff,
              style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(color: AppColors.coral, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: Text(S.t.continueButton)),
        ],
      ),
    );
  }
}

class _RestorePassphraseSheet extends StatefulWidget {
  const _RestorePassphraseSheet();

  @override
  State<_RestorePassphraseSheet> createState() =>
      _RestorePassphraseSheetState();
}

class _RestorePassphraseSheetState extends State<_RestorePassphraseSheet> {
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t.enterPassphraseTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: S.t.passphraseLabel),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _passCtrl.text),
            child: Text(S.t.continueButton),
          ),
        ],
      ),
    );
  }
}
