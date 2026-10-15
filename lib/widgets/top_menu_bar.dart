// lib/widgets/top_menu_bar.dart
// Baris menu utama (Beranda/Transaksi/Aset, Investasi & Utang/Anggaran/
// Laporan) — awalnya cuma ada di Beranda (lib/screens/home_screen.dart),
// sekarang diekstrak ke sini supaya bisa dipasang juga di halaman-halaman
// utama lainnya, sehingga pengguna bisa pindah antar menu dari halaman
// mana pun tanpa harus balik ke Beranda dulu.
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../screens/transactions_screen.dart';
import '../screens/accounts_assets_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/reports_screen.dart';

/// Menandai halaman mana (di antara 5 item menu) yang sedang aktif, supaya
/// bisa ditandai visual dan tap-nya di-skip (tidak perlu navigasi ke diri
/// sendiri).
enum TopMenuDestination { home, transactions, assets, budgets, reports }

class TopMenuBar extends StatelessWidget {
  final TopMenuDestination? current;
  const TopMenuBar({super.key, this.current});

  // Invariant: stack selalu [Beranda] atau [Beranda, satu halaman menu].
  // Dari Beranda harus push (bukan pushReplacement) — kalau Beranda ikut
  // terganti, stack jadi tanpa Beranda dan pop() berikutnya mengosongkan
  // navigator (layar hitam). Antar halaman non-Beranda pakai pushReplacement
  // supaya riwayat tidak menumpuk.
  void _go(BuildContext context, TopMenuDestination dest, Widget screen) {
    if (dest == current) return;
    final nav = Navigator.of(context);
    final route = MaterialPageRoute(builder: (_) => screen);
    if (current == TopMenuDestination.home) {
      nav.push(route);
    } else {
      nav.pushReplacement(route);
    }
  }

  void _goHome(BuildContext context) {
    if (current == TopMenuDestination.home) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(
        dest: TopMenuDestination.home,
        icon: Icons.home_outlined,
        color: AppColors.sky,
        label: S.t.home,
        onTap: () => _goHome(context),
      ),
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
      // IntrinsicHeight + stretch: semua kartu setinggi kartu tertinggi
      // (label "Aset, Investasi & Utang" 2 baris), jadi ukurannya seragam.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items.map((item) {
            final active = item.dest == current;
            return Expanded(
              child: Tooltip(
                message: item.label,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    alignment: Alignment.center,
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
