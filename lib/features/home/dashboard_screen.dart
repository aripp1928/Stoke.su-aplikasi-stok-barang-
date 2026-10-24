import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/stock_transaction.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/stock_state.dart';
import '../stock/add_stock_sheet.dart';
import '../stock/reduce_stock_sheet.dart';

/// Beranda: ringkasan stok, aksi cepat, peringatan, dan aktivitas terakhir.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final storeId = context.read<AuthState>().storeId;
    if (storeId.isEmpty) return;
    await Future.wait([
      context.read<ItemState>().loadItems(storeId),
      context.read<StockState>().loadTransactions(storeId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final items = context.watch<ItemState>();
    final stock = context.watch<StockState>();

    final userName = auth.userName.isNotEmpty ? auth.userName : (auth.isAdmin ? 'Admin' : 'Crew');
    final storeName = auth.storeName.isNotEmpty ? auth.storeName : 'Kedai Kopi';
    final alerts = items.lowStockItems;
    final recent = stock.transactions.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // ── Hero ──
            _HeroCard(
              greeting: auth.greeting,
              userName: userName,
              subtitle: '$storeName · ${Formatters.fullDate(DateTime.now())}',
              total: items.totalItemCount,
              low: items.lowStockCount,
              empty: items.emptyStockCount,
              onTapStats: () => context.goNamed(RouteNames.inventory),
            ),
            const SizedBox(height: 18),

            // ── Aksi cepat ──
            Row(
              children: [
                _QuickAction(
                  icon: Icons.add_box_outlined,
                  label: 'Restok',
                  onTap: () => AddStockSheet.show(context),
                ),
                _QuickAction(
                  icon: Icons.remove_circle_outline_rounded,
                  label: 'Pakai',
                  onTap: () => ReduceStockSheet.show(context),
                ),
                _QuickAction(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Jual',
                  onTap: () => context.goNamed(RouteNames.sales),
                ),
                _QuickAction(
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  onTap: () => context.pushNamed(RouteNames.stockHistory),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // ── Peringatan stok ──
            _SectionTitle(
              title: 'Perlu perhatian',
              action: alerts.isEmpty ? null : 'Lihat barang',
              onAction: () => context.goNamed(RouteNames.inventory),
            ),
            const SizedBox(height: 10),
            _Panel(
              child: alerts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Semua stok aman. Tidak ada yang perlu direstok.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < alerts.length && i < 5; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _AlertRow(
                            name: alerts[i].name,
                            minimum:
                                'Minimum ${Formatters.number(alerts[i].minStock)} ${alerts[i].unit}',
                            current:
                                '${Formatters.number(alerts[i].currentStock)} ${alerts[i].unit}',
                            status: alerts[i].stockStatusLabel,
                            isDanger: alerts[i].isEmpty,
                            onTap: () => context.pushNamed(
                              RouteNames.itemDetail,
                              extra: alerts[i].id,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 26),

            // ── Aktivitas terakhir ──
            _SectionTitle(
              title: 'Aktivitas terakhir',
              action: recent.isEmpty ? null : 'Semua',
              onAction: () => context.pushNamed(RouteNames.stockHistory),
            ),
            const SizedBox(height: 10),
            _Panel(
              child: recent.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Belum ada aktivitas stok.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < recent.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _ActivityRow(txn: recent[i]),
                        ],
                      ],
                    ),
            ),
            if (!auth.isAdmin) ...[
              const SizedBox(height: 18),
              const Text(
                'Akses Crew: pemakaian & stok tanpa informasi harga.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.navInactive),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Komponen layar ───────────────────────────

class _HeroCard extends StatelessWidget {
  final String greeting;
  final String userName;
  final String subtitle;
  final int total;
  final int low;
  final int empty;
  final VoidCallback onTapStats;

  const _HeroCard({
    required this.greeting,
    required this.userName,
    required this.subtitle,
    required this.total,
    required this.low,
    required this.empty,
    required this.onTapStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.heroEnd],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x332C1A12), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(fontSize: 12, color: Color(0xFFD9C9BE)),
          ),
          const SizedBox(height: 2),
          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFB8A79B)),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTapStats,
            child: Row(
              children: [
                _HeroStat(value: '$total', label: 'Total barang', color: Colors.white),
                const _HeroDivider(),
                _HeroStat(value: '$low', label: 'Menipis', color: AppColors.gold),
                const _HeroDivider(),
                _HeroStat(
                  value: '$empty',
                  label: 'Habis',
                  color: empty > 0 ? const Color(0xFFFF9A8B) : Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HeroStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFFD9C9BE)),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0x33FFFFFF));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'serif',
            color: AppColors.textPrimary,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AlertRow extends StatelessWidget {
  final String name;
  final String minimum;
  final String current;
  final String status;
  final bool isDanger;
  final VoidCallback onTap;

  const _AlertRow({
    required this.name,
    required this.minimum,
    required this.current,
    required this.status,
    required this.isDanger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    minimum,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  current,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                StatusBadge.custom(status, isWarning: !isDanger, isDanger: isDanger),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final StockTransaction txn;

  const _ActivityRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isRestock = txn.type == TransactionType.restock;
    final color = isRestock ? AppColors.success : AppColors.error;
    final bg = isRestock ? AppColors.successLight : AppColors.errorLight;
    final sign = isRestock ? '+' : '-';
    final icon = isRestock
        ? Icons.south_west_rounded
        : (txn.type == TransactionType.sale
            ? Icons.point_of_sale_rounded
            : Icons.north_east_rounded);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.itemName ?? 'Bahan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${txn.type.label} · ${Formatters.dateTime(txn.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            '$sign${Formatters.number(txn.quantity)} ${txn.itemUnit ?? ''}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
