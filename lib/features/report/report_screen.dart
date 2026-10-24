import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/sale.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/sale_state.dart';
import '../../state/stock_state.dart';
import 'export_report_sheet.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedRange = 'Hari ini';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthState>();
      if (authState.storeId.isNotEmpty) {
        context.read<SaleState>().loadSales(authState.storeId);
        context.read<StockState>().loadTransactions(authState.storeId);
        context.read<ItemState>().loadItems(authState.storeId);
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E1E19),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2E1E19),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedRange = 'Pilih Tanggal';
      });
    }
  }

  List<Sale> _getFilteredSales(List<Sale> allSales) {
    final now = DateTime.now();

    switch (_selectedRange) {
      case 'Hari ini':
        return allSales.where((s) {
          return s.createdAt.year == now.year &&
              s.createdAt.month == now.month &&
              s.createdAt.day == now.day;
        }).toList();

      case '7 Hari':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return allSales.where((s) => s.createdAt.isAfter(sevenDaysAgo)).toList();

      case 'Bulan ini':
        return allSales.where((s) {
          return s.createdAt.year == now.year && s.createdAt.month == now.month;
        }).toList();

      case 'Pilih Tanggal':
        if (_customDateRange != null) {
          final start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );
          final end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
          return allSales.where((s) {
            return s.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                s.createdAt.isBefore(end.add(const Duration(seconds: 1)));
          }).toList();
        }
        return allSales;

      case 'Semua':
      default:
        return allSales;
    }
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case 'Hari ini':
        return 'Hari ini · ${Formatters.fullDate(now)}';
      case '7 Hari':
        final start = now.subtract(const Duration(days: 7));
        return '${Formatters.shortDate(start)} – ${Formatters.shortDate(now)}';
      case 'Bulan ini':
        return 'Bulan ini (${Formatters.shortDate(DateTime(now.year, now.month, 1))} – ${Formatters.shortDate(now)})';
      case 'Pilih Tanggal':
        if (_customDateRange != null) {
          return '${Formatters.shortDate(_customDateRange!.start)} – ${Formatters.shortDate(_customDateRange!.end)}';
        }
        return 'Rentang tanggal kustom';
      default:
        return 'Semua waktu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final itemState = context.watch<ItemState>();
    final saleState = context.watch<SaleState>();
    final stockState = context.watch<StockState>();

    final isAdmin = authState.isAdmin;
    final allSales = saleState.sales;
    final filteredSales = _getFilteredSales(allSales);

    final totalSalesQty = filteredSales.fold<int>(0, (sum, s) => sum + s.quantity);
    final totalRevenue = filteredSales.fold<double>(0, (sum, s) => sum + s.totalPrice);
    final totalTransactions = filteredSales.length;
    final avgTicket = totalTransactions > 0 ? (totalRevenue / totalTransactions) : 0.0;
    final avgCupPerTxn = totalTransactions > 0 ? (totalSalesQty / totalTransactions).toStringAsFixed(1) : '0';

    // Group sales by product
    final Map<String, _ProductSalesSummary> productMap = {};
    for (final sale in filteredSales) {
      if (!productMap.containsKey(sale.productName)) {
        productMap[sale.productName] = _ProductSalesSummary(
          name: sale.productName,
          quantity: 0,
          revenue: 0.0,
          orderCount: 0,
        );
      }
      final current = productMap[sale.productName]!;
      productMap[sale.productName] = _ProductSalesSummary(
        name: current.name,
        quantity: current.quantity + sale.quantity,
        revenue: current.revenue + sale.totalPrice,
        orderCount: current.orderCount + 1,
      );
    }

    final productSummaries = productMap.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final restocks = stockState.restockTransactions;
    final usages = stockState.usageTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAdmin ? 'Laporan penjualan' : 'Laporan operasional',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: Color(0xFF2E1E19),
                  ),
                ),
                if (isAdmin)
                  OutlinedButton.icon(
                    onPressed: () => ExportReportSheet.show(
                      context,
                      storeName: authState.storeName,
                      userName: authState.userName,
                      periodLabel: _getPeriodLabel(),
                      sales: filteredSales,
                      items: itemState.items,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF2E1E19)),
                    label: const Text('Unduh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: Color(0xFFD8C7B8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.white,
                    ),
                  )
                else if (saleState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E1E19)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Period selector pills
            Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEBE6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildPeriodPill('Hari ini'),
                  _buildPeriodPill('7 Hari'),
                  _buildPeriodPill('Bulan ini'),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickCustomDateRange,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedRange == 'Pilih Tanggal' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedRange == 'Pilih Tanggal'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: _selectedRange == 'Pilih Tanggal'
                                  ? const Color(0xFF2E1E19)
                                  : const Color(0xFF8D7B75),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tanggal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _selectedRange == 'Pilih Tanggal'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selectedRange == 'Pilih Tanggal'
                                    ? const Color(0xFF2E1E19)
                                    : const Color(0xFF8D7B75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Period label
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF8D7B75)),
                const SizedBox(width: 5),
                Text(
                  _getPeriodLabel(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D4E48)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Cards
            if (isAdmin) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DD)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pendapatan',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(totalRevenue),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'serif',
                                color: Color(0xFF2E1E19),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF4E8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF3E3C7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Porsi terjual', style: TextStyle(fontSize: 10, color: Color(0xFF8A5812))),
                              Text(
                                '$totalSalesQty cup',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A5812)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF2ECE6)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryMetric(
                            label: 'Total Transaksi',
                            value: '$totalTransactions pesanan',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFF2ECE6)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _buildSummaryMetric(
                              label: 'Rata-rata Order',
                              value: Formatters.currency(avgTicket),
                              icon: Icons.analytics_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Volume Terjual', style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75))),
                            const SizedBox(height: 4),
                            Text(
                              '$totalSalesQty cup',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'serif', color: Color(0xFF2E1E19)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F0EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalTransactions transaksi',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D4E48)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rata-rata $avgCupPerTxn cup per transaksi kasir.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Section 1: Detail Penjualan per Menu / Produk
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kinerja per menu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: Color(0xFF2E1E19),
                  ),
                ),
                Text(
                  '${productSummaries.length} menu terjual',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (productSummaries.isEmpty)
              _buildEmptyBox('Belum ada menu yang terjual pada periode ini.')
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DD)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < productSummaries.length; i++) ...[
                      if (i > 0) const Divider(height: 20, color: Color(0xFFF2ECE6)),
                      _buildProductRow(
                        rank: i + 1,
                        summary: productSummaries[i],
                        totalCups: totalSalesQty,
                        isAdmin: isAdmin,
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Section 2: Rincian Transaksi Penjualan Terperinci
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat rincian penjualan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: Color(0xFF2E1E19),
                  ),
                ),
                Text(
                  '$totalTransactions transaksi',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredSales.isEmpty)
              _buildEmptyBox('Belum ada catatan transaksi penjualan.')
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DD)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < filteredSales.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: Color(0xFFF2ECE6)),
                      _buildDetailedSaleItem(filteredSales[i], isAdmin),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Section 3: Ringkasan Operasional & Mutasi Stok
            const Text(
              'Ringkasan operasional & stok',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: Column(
                children: [
                  _buildOpRow(
                    'Kondisi inventaris',
                    '${itemState.totalItemCount} jenis · ${itemState.lowStockCount} menipis · ${itemState.emptyStockCount} habis',
                  ),
                  const Divider(height: 16, color: Color(0xFFF2ECE6)),
                  _buildOpRow(
                    'Barang masuk (Restok)',
                    '${restocks.length} batch restok tercatat',
                  ),
                  const Divider(height: 16, color: Color(0xFFF2ECE6)),
                  _buildOpRow(
                    'Pemakaian operasional',
                    '${usages.length} kali pemakaian non-penjualan',
                  ),
                  const Divider(height: 16, color: Color(0xFFF2ECE6)),
                  _buildOpRow(
                    'Total pemotongan FEFO',
                    '$totalSalesQty porsi menu terjual terpotong otomatis',
                  ),
                ],
              ),
            ),

            if (isAdmin) ...[
              const SizedBox(height: 16),
              AppButton(
                text: 'Unduh laporan ($_selectedRange)',
                isOutlined: true,
                icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF2E1E19)),
                onPressed: () => ExportReportSheet.show(
                  context,
                  storeName: authState.storeName,
                  userName: authState.userName,
                  periodLabel: _getPeriodLabel(),
                  sales: filteredSales,
                  items: itemState.items,
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodPill(String period) {
    final isSelected = _selectedRange == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRange = period;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            period,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2E1E19) : const Color(0xFF8D7B75),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF6E5649)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8D7B75))),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductRow({
    required int rank,
    required _ProductSalesSummary summary,
    required int totalCups,
    required bool isAdmin,
  }) {
    final percent = totalCups > 0 ? (summary.quantity / totalCups) : 0.0;
    final percentStr = (percent * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? const Color(0xFF2E1E19) : const Color(0xFFEFEBE6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? Colors.white : const Color(0xFF5D4E48),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                  ),
                  Text(
                    '${summary.orderCount} kali dipesan',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8D7B75)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${summary.quantity} cup',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                ),
                if (isAdmin)
                  Text(
                    Formatters.currency(summary.revenue),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A5812), fontWeight: FontWeight.w600),
                  )
                else
                  Text(
                    '$percentStr%',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar for visual share
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: const Color(0xFFF2ECE6),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D4E48)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedSaleItem(Sale sale, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.dateTime(sale.createdAt),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                  ),
                ],
              ),
              if (sale.performedByName != null && sale.performedByName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2ECE6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Oleh ${sale.performedByName}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF6E5649)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${sale.productName} × ${sale.quantity} cup',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                ),
              ),
              Text(
                isAdmin ? Formatters.currency(sale.totalPrice) : '${sale.quantity} cup',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
              ),
            ],
          ),
          if (sale.deductions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sale.deductions.map((d) {
                final itemName = d.itemName ?? 'Bahan';
                final qty = Formatters.number(d.quantityDeducted);
                final unit = d.itemUnit ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE8E3DD)),
                  ),
                  child: Text(
                    'FEFO: $itemName -$qty $unit',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF7A6B65)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8D7B75))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19))),
      ],
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DD)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFFC7BDB6)),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8D7B75)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSalesSummary {
  final String name;
  final int quantity;
  final double revenue;
  final int orderCount;

  const _ProductSalesSummary({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.orderCount,
  });
}
