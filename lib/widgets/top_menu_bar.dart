// lib/widgets/top_menu_bar.dart
// Baris menu utama (Transaksi/Aset, Investasi & Utang/Anggaran/Laporan) —
// awalnya cuma ada di Beranda (lib/screens/home_screen.dart), sekarang
// diekstrak ke sini supaya bisa dipasang juga di halaman-halaman utama
// lainnya, sehingga pengguna bisa pindah antar menu dari halaman mana pun
// tanpa harus balik ke Beranda dulu.
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../screens/transactions_screen.dart';
import '../screens/accounts_assets_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/reports_screen.dart';

/// Menandai halaman mana (di antara 4 item menu) yang sedang aktif, supaya
/// bisa ditandai visual dan tap-nya di-skip (tidak perlu navigasi ke diri
/// sendiri). `null` dipakai di Beranda, karena Beranda bukan salah satu
/// dari 4 item ini.
enum TopMenuDestination { transactions, assets, budgets, reports }

class TopMenuBar extends StatelessWidget {
  final TopMenuDestination? current;
  const TopMenuBar({super.key, this.current});

  void _go(BuildContext context, TopMenuDestination dest, Widget screen) {
    if (dest == current) return;
    // Dipakai dari dalam salah satu dari 4 halaman tujuan ini sendiri (bukan
    // dari Beranda) — pakai pushReplacement supaya pindah menu dari menu
    // terasa seperti ganti tab, bukan numpuk riwayat navigasi tanpa henti.
    // Beranda tetap pakai Navigator.push biasa (lihat home_screen.dart) agar
    // tombol kembali selalu mengarah balik ke Beranda.
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(
        dest: TopMenuDestination.transactions,
        icon: Icons.swap_horiz,
        color: AppColors.primary,
        label: S.t.menuTransactions,
        onTap: () =>
            _go(context, TopMenuDestination.transactions, const TransactionsScreen()),
      ),
      _Item(
        dest: TopMenuDestination.assets,
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.gold,
        label: S.t.menuAssets,
        onTap: () =>
            _go(context, TopMenuDestination.assets, const AccountsAssetsScreen()),
      ),
      _Item(
        dest: TopMenuDestination.budgets,
        icon: Icons.pie_chart_outline,
        color: AppColors.plum,
        label: S.t.menuBudget,
        onTap: () => _go(context, TopMenuDestination.budgets, const BudgetsScreen()),
      ),
      _Item(
        dest: TopMenuDestination.reports,
        icon: Icons.bar_chart,
        color: AppColors.teal,
        label: S.t.menuReportsShort,
        onTap: () => _go(context, TopMenuDestination.reports, const ReportsScreen()),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: items.map((item) {
          final active = item.dest == current;
          return Expanded(
            child: Tooltip(
              message: item.label,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: active ? 0.26 : 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 22, color: item.color),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: item.color,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Item {
  final TopMenuDestination dest;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  _Item({
    required this.dest,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}
