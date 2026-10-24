import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/item.dart';
import '../../data/models/batch_item.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../stock/add_stock_sheet.dart';
import '../stock/reduce_stock_sheet.dart';
import 'item_form_sheet.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemName;

  const ItemDetailScreen({super.key, this.itemName = ''});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final itemState = context.read<ItemState>();
    final item = itemState.allItems.firstWhere(
      (i) => i.id == widget.itemName || i.name.toLowerCase() == widget.itemName.toLowerCase(),
      orElse: () => itemState.allItems.isNotEmpty ? itemState.allItems.first : Item(
        id: '',
        storeId: '',
        name: 'Barang',
        category: 'Umum',
        unit: 'g',
        minStock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: '',
      ),
    );
    if (item.id.isNotEmpty) {
      itemState.loadItemDetail(item.id);
    }
  }

  void _showDeleteConfirmation(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus barang?'),
        content: Text('Barang ${item.name} beserta seluruh batch stoknya akan dihapus permanen dari inventori kedai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8D7B75))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authState = context.read<AuthState>();
              final success = await context.read<ItemState>().deleteItem(item.id);
              if (mounted) {
                if (success) {
                  await context.read<ItemState>().loadItems(authState.storeId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.name} berhasil dihapus')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus barang')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final itemState = context.watch<ItemState>();
    final isAdmin = authState.isAdmin;

    final item = itemState.allItems.firstWhere(
      (i) => i.id == widget.itemName || i.name.toLowerCase() == widget.itemName.toLowerCase(),
      orElse: () => itemState.selectedItem ?? Item(
        id: '',
        storeId: '',
        name: 'Barang',
        category: 'Umum',
        unit: 'g',
        minStock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: '',
      ),
    );

    final batches = itemState.batches;
    final totalValue = (item.buyPrice ?? 0) * item.currentStock;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppHeader(
        title: item.name,
        subtitle: 'Persediaan kedai',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top card: Details & total stock
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
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'serif',
                              color: Color(0xFF2E1E19),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.category} · satuan ${item.unit}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                          ),
                        ],
                      ),
                      StatusBadge.custom(
                        item.stockStatusLabel,
                        isWarning: item.isLowStock,
                        isDanger: item.isEmpty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${Formatters.number(item.currentStock)} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      color: Color(0xFF2E1E19),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isAdmin) ...[
                    Text(
                      'Minimum ${Formatters.number(item.minStock)} ${item.unit}${item.buyPrice != null ? ' · ${Formatters.currency(item.buyPrice!)} / ${item.unit}' : ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                    ),
                    if (item.buyPrice != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Total nilai aset stok: ${Formatters.currency(totalValue)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Minimum ${Formatters.number(item.minStock)} ${item.unit}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Akses operasional · harga beli tersembunyi.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFAFA49D)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Action buttons
                  if (isAdmin)
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Edit barang',
                            isOutlined: true,
                            height: 38,
                            onPressed: () => ItemFormSheet.show(context, isEdit: true, item: item),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'Hapus',
                            isOutlined: true,
                            textColor: const Color(0xFFDC2626),
                            height: 38,
                            onPressed: () => _showDeleteConfirmation(context, item),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: '+ Tambah stok',
                            height: 38,
                            onPressed: () => AddStockSheet.show(context, initialItemId: item.id),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: '— Kurangi stok',
                            isOutlined: true,
                            height: 38,
                            onPressed: () => ReduceStockSheet.show(context, initialItemId: item.id),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Section: Batch - urutan FIFO
            const Text(
              'Batch stok aktif (FIFO)',
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
              child: batches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              'Belum ada batch stok aktif.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gunakan tombol Tambah Stok untuk menambah pasokan batch baru.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => AddStockSheet.show(context, initialItemId: item.id),
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text('+ Tambah stok', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38241D)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < batches.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Color(0xFFF2ECE6)),
                          _buildBatchItem(batches[i], item.unit),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3E3C7)),
              ),
              child: const Text(
                'Batch terdekat dipakai dulu.\nSistem secara otomatis memotong stok dari batch tertua/kedaluwarsa terdekat saat kasir mencatat pesanan.',
                style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF8A5812)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchItem(BatchItem batch, String unit) {
    final expiryStr = batch.expiryDate != null ? ' · exp. ${Formatters.shortDate(batch.expiryDate!)}' : '';
    final receivedStr = 'Masuk ${Formatters.shortDate(batch.receivedDate)}';
    final isExpiringSoon = batch.expiryDate != null &&
        batch.expiryDate!.difference(DateTime.now()).inDays <= 7;

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
                Row(
                  children: [
                    Text(
                      batch.batchCode,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${Formatters.number(batch.remainingQuantity)} $unit',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$receivedStr$expiryStr',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8D7B75)),
                ),
              ],
            ),
          ),
          StatusBadge.custom(
            isExpiringSoon ? 'Mendekati' : 'Aman',
            isWarning: isExpiringSoon,
          ),
        ],
      ),
    );
  }
}
