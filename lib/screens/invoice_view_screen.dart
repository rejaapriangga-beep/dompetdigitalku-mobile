// lib/screens/invoice_view_screen.dart
// Layar sederhana untuk lihat foto invoice — baik yang tersimpan lokal di HP
// (bytes, sudah didekripsi dari penyimpanan terenkripsi) maupun yang
// tersimpan di server/R2 (lewat endpoint /uploads/view yang butuh Bearer
// token, server yang redirect ke URL baca sementara).
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';

class InvoiceViewScreen extends StatelessWidget {
  final Uint8List? localBytes;
  final String? networkUrl;
  final Map<String, String>? networkHeaders;

  const InvoiceViewScreen.local(this.localBytes, {super.key})
    : networkUrl = null,
      networkHeaders = null;
  const InvoiceViewScreen.network(
    this.networkUrl,
    this.networkHeaders, {
    super.key,
  }) : localBytes = null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(S.t.invoicePhotoLabel),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: localBytes != null
              ? Image.memory(
                  localBytes!,
                  errorBuilder: (_, _, _) => const _LoadError(),
                )
              : Image.network(
                  networkUrl!,
                  headers: networkHeaders,
                  errorBuilder: (_, _, _) => const _LoadError(),
                ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        S.t.failedLoadInvoicePhoto,
        style: TextStyle(color: AppColors.border),
      ),
    );
  }
}
