// lib/widgets/rename_dialog.dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';

/// Dialog ubah nama. Mengembalikan nama baru (sudah di-trim), atau null
/// kalau dibatalkan, kosong, atau tidak berubah.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String currentName,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(currentName: currentName),
  );
  final name = result?.trim();
  if (name == null || name.isEmpty || name == currentName) return null;
  return name;
}

class _RenameDialog extends StatefulWidget {
  final String currentName;
  const _RenameDialog({required this.currentName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _ctrl = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.t.renameTitle),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.t.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: Text(
            S.t.saveChanges,
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// Tombol ikon pensil kecil untuk membuka [showRenameDialog] di baris daftar.
class RenameIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  const RenameIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
      tooltip: S.t.editButton,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
