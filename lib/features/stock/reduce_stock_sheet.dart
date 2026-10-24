import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/formatters.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/stock_state.dart';

class ReduceStockSheet extends StatefulWidget {
  final String? initialItemId;

  const ReduceStockSheet({super.key, this.initialItemId});

  static Future<void> show(BuildContext context, {String? initialItemId}) {
    final now = DateTime.now();
    return BottomSheetWrapper.show(
      context: context,
      title: 'Kurangi stok',
      subtitle: 'Pemakaian manual · ${Formatters.shortDate(now)}',
      child: ReduceStockSheet(initialItemId: initialItemId),
    );
  }

  @override
  State<ReduceStockSheet> createState() => _ReduceStockSheetState();
}

class _ReduceStockSheetState extends State<ReduceStockSheet> {
  String? _selectedItemId;
  final _qtyController = TextEditingController();
  String _selectedReason = 'Dipakai crew';
  final _notesController = TextEditingController();
  bool _isSuccess = false;
  bool _isSaving = false;
  double _savedQty = 0;
  double _beforeStock = 0;
  double _afterStock = 0;

  final List<String> _reasons = [
    'Dipakai crew',
    'Kedaluwarsa / rusak',
    'Penyesuaian stok',
    'Bahan tumpah / sisa kalibrasi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _selectedItemId = widget.initialItemId;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final stockState = context.watch<StockState>();
    final itemState = context.watch<ItemState>();
    final items = itemState.allItems;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: const [
            Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF8D7B75)),
            SizedBox(height: 12),
            Text(
              'Belum ada data barang di inventori.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E1E19)),
            ),
            SizedBox(height: 4),
            Text(
              'Tambahkan data barang terlebih dahulu.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75)),
            ),
          ],
        ),
      );
    }

    if (_selectedItemId == null || !items.any((i) => i.id == _selectedItemId)) {
      _selectedItemId = items.first.id;
    }

    final selectedItem = items.firstWhere(
      (i) => i.id == _selectedItemId,
      orElse: () => items.first,
    );

    if (_isSuccess) {
      return _buildSuccessView(selectedItem.name, selectedItem.unit);
    }

    final enteredQty = double.tryParse(_qtyController.text) ?? 0;
    final isInvalidQty = _qtyController.text.trim().isNotEmpty && enteredQty <= 0;
    final isOverStock = enteredQty > selectedItem.currentStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown Barang
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Barang',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D4E48)),
            ),
            Text(
              'Stok tersedia: ${Formatters.number(selectedItem.currentStock)} ${selectedItem.unit}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2DDD7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedItemId,
              isExpanded: true,
              items: items.map((i) => DropdownMenuItem(
                value: i.id,
                child: Text('${i.name} (Tersedia: ${Formatters.number(i.currentStock)} ${i.unit})', style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedItemId = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Jumlah
        AppTextField(
          label: 'Jumlah (${selectedItem.unit})',
          hint: 'cth. 50',
          controller: _qtyController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        if (isOverStock) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Tidak valid! Maksimal ${Formatters.number(selectedItem.currentStock)} ${selectedItem.unit}. Kurangi jumlah.',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
            ),
          ),
        ] else if (isInvalidQty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Jumlah pengurangan harus lebih dari 0.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Alasan
        const Text(
          'Alasan pengurangan',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D4E48)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2DDD7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              isExpanded: true,
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Catatan
        AppTextField(
          label: 'Catatan tambahan (opsional)',
          hint: 'cth. Testing menu baru, tumpah saat kalibrasi',
          controller: _notesController,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Pengurangan stok akan memotong batch tertua terlebih dahulu (metode FIFO).\nData pemakaian akan dicatat di Riwayat Stok.',
            style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF8A5812)),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          text: 'Konfirmasi pengurangan',
          isLoading: _isSaving || stockState.isLoading,
          onPressed: (enteredQty <= 0 || isOverStock)
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  try {
                    _beforeStock = selectedItem.currentStock;
                    _savedQty = enteredQty;
                    _afterStock = _beforeStock - _savedQty;

                    final res = await stockState.reduceStock(
                      storeId: authState.storeId,
                      itemId: selectedItem.id,
                      quantity: enteredQty,
                      reason: _selectedReason,
                      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                      userId: authState.userId,
                    );

                    if (mounted) {
                      if (res != null) {
                        await itemState.loadItems(authState.storeId);
                        setState(() => _isSuccess = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(stockState.error ?? 'Gagal mengurangi stok')),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
        ),
      ],
    );
  }

  Widget _buildSuccessView(String itemName, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pemakaian tercatat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'serif', color: Color(0xFF2E1E19)),
        ),
        const SizedBox(height: 2),
        Text(
          'Tercatat · ${Formatters.shortDate(DateTime.now())}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
        ),
        const SizedBox(height: 12),
        Text(
          '$itemName dikurangi ${_notesController.text.isNotEmpty ? 'untuk ${_notesController.text}' : 'dengan alasan $_selectedReason'}.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
        ),
        const SizedBox(height: 16),
        // Stock delta box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E2D9)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sebelum', style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75))),
                  Text('${Formatters.number(_beforeStock)} $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedReason, style: const TextStyle(fontSize: 12, color: Color(0xFF8D7B75))),
                  Text('-${Formatters.number(_savedQty)} $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFE8E2D9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sesudah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19))),
                  Text('${Formatters.number(_afterStock)} $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Selesai',
          backgroundColor: const Color(0xFF2E7D32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
