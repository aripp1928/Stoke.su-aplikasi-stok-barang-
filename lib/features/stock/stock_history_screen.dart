import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock_transaction.dart';
import '../../state/auth_state.dart';
import '../../state/stock_state.dart';
import 'add_stock_sheet.dart';
import 'reduce_stock_sheet.dart';

enum _Filter { all, incoming, outgoing }

/// Riwayat stok dalam satu daftar, bisa disaring Semua / Masuk / Keluar.
/// Restok & pemakaian bisa dicatat langsung dari tombol di bawah.
class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final storeId = context.read<AuthState>().storeId;
    if (storeId.isNotEmpty) {
      await context.read<StockState>().loadTransactions(storeId);
    }
  }

  List<StockTransaction> _apply(List<StockTransaction> all) {
    switch (_filter) {
      case _Filter.incoming:
        return all.where((t) => t.type == TransactionType.restock).toList();
      case _Filter.outgoing:
        return all.where((t) => t.type != TransactionType.restock).toList();
      case _Filter.all:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockState>();
    final list = _apply(stock.transactions);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Riwayat stok',
        subtitle: 'Barang masuk & keluar',
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                _chip('Semua', _Filter.all),
                const SizedBox(width: 8),
                _chip('Masuk', _Filter.incoming),
                const SizedBox(width: 8),
                _chip('Keluar', _Filter.outgoing),
                const Spacer(),
                Text(
                  '${list.length} data',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Expanded(
            child: stock.isLoading && stock.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                icon: Icons.history_rounded,
                                title: 'Belum ada riwayat',
                                message: 'Restok, pemakaian, dan penjualan akan tercatat di sini.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _TransactionCard(txn: list[i]),
                          ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Pakai',
                      isOutlined: true,
                      icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.textPrimary),
                      onPressed: () => ReduceStockSheet.show(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Restok',
                      icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      onPressed: () => AddStockSheet.show(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = value),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final StockTransaction txn;

  const _TransactionCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isRestock = txn.type == TransactionType.restock;
    final isSale = txn.type == TransactionType.sale;
    final color = isRestock ? AppColors.success : AppColors.error;
    final sign = isRestock ? '+' : '-';
    final badge = isRestock ? 'Restok' : (isSale ? 'Terjual' : (txn.reason ?? txn.type.label));
    final meta = [
      Formatters.dateTime(txn.createdAt),
      if (txn.performedByName != null) txn.performedByName!,
      if (txn.batchCode != null) 'Batch ${txn.batchCode}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  txn.itemName ?? 'Bahan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$sign${Formatters.number(txn.quantity)} ${txn.itemUnit ?? ''}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  meta,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.custom(badge, isWarning: !isRestock && !isSale),
            ],
          ),
          if (txn.notes != null && txn.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                txn.notes!,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
