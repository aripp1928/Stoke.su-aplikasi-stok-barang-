import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/utils/formatters.dart';
import '../../state/auth_state.dart';
import '../../app/router/route_names.dart';

class SalesResultScreen extends StatelessWidget {
  final Map<String, dynamic>? saleData;

  const SalesResultScreen({super.key, this.saleData});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    final product = saleData?['product'] as String? ?? 'Produk';
    final qty = saleData?['qty'] as int? ?? 1;
    final total = (saleData?['total'] as num?)?.toDouble() ?? 0.0;
    final deductions = (saleData?['deductions'] as List<dynamic>?) ?? [];

    final timeStr = Formatters.dateTime(DateTime.now());
    final userStr = authState.userName.isNotEmpty ? authState.userName : 'Kasir';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: const AppHeader(showActions: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Penjualan tercatat.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 14),

            // Success Card
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
                      Expanded(
                        child: Text(
                          '$qty $product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'serif',
                            color: Color(0xFF2E1E19),
                          ),
                        ),
                      ),
                      const StatusBadge(
                        label: 'Tersimpan',
                        textColor: Color(0xFF2E7D32),
                        bgColor: Color(0xFFE8F5E9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$timeStr · $userStr',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    Formatters.currency(total),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      color: Color(0xFF2E1E19),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Stok sesudah
            const Text(
              'Stok sesudah',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: deductions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Resep ini tidak memiliki komposisi bahan yang dipotong.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < deductions.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Color(0xFFF2ECE6)),
                          _buildRealAfterStockRow(deductions[i] as Map<String, dynamic>),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Dark confirmation pill banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF38241D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deductions.isNotEmpty
                          ? '$qty penjualan tersimpan. ${deductions.length} bahan baku diperbarui secara FEFO.'
                          : '$qty penjualan tersimpan.',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            AppButton(
              text: 'Catat Penjualan Lagi',
              onPressed: () => context.goNamed(RouteNames.sales),
            ),
            const SizedBox(height: 10),
            AppButton(
              text: 'Kembali ke Beranda',
              isOutlined: true,
              onPressed: () => context.goNamed(RouteNames.dashboard),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRealAfterStockRow(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Bahan';
    final needed = (item['needed'] as num?) ?? 0;
    final available = (item['available'] as num?) ?? 0;
    final after = (item['after'] as num?) ?? (available - needed);
    final unit = item['unit'] as String? ?? '';

    final isZero = after <= 0;
    final status = isZero ? 'Habis' : 'Tersisa';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EAE1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF5D4037)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dipotong: -${Formatters.number(needed)} $unit (${Formatters.number(available)} → ${Formatters.number(after)} $unit)',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8D7B75)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Formatters.number(after)} $unit',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
              ),
              const SizedBox(height: 2),
              StatusBadge.custom(status, isWarning: isZero),
            ],
          ),
        ],
      ),
    );
  }
}
