// lib/screens/biometric_lock_screen.dart
// Layar kunci yang tampil di depan Beranda saat kunci sidik jari aktif (lihat
// _AuthGate di main.dart) — sesi login (token) sudah ada, cuma perlu
// diverifikasi ulang lewat sidik jari/Face ID sebelum konten app terbuka.
import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../biometric/biometric_service.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _checking = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Langsung tampilkan prompt begitu layar ini terbuka — pengguna tidak
    // perlu tap tombol dulu di kondisi normal (tombol tetap ada buat
    // coba lagi kalau prompt pertama gagal/dibatalkan).
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() {
      _checking = true;
      _failed = false;
    });
    final ok = await BiometricService.authenticate(S.t.biometricUnlockReason);
    if (!mounted) return;
    if (ok) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }
    setState(() {
      _checking = false;
      _failed = true;
    });
  }

  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  S.t.biometricLockedScreenTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (_failed) ...[
                  const SizedBox(height: 8),
                  Text(
                    S.t.biometricUnlockFailed,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.coral, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checking ? null : _authenticate,
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(S.t.biometricUnlockButton),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _checking ? null : _logout,
                  child: Text(S.t.logoutTooltip),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
