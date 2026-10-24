import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/stock_state.dart';
import '../../state/supplier_state.dart';
import '../../core/utils/formatters.dart';

class AddStockSheet extends StatefulWidget {
  final String? initialItemId;

  const AddStockSheet({super.key, this.initialItemId});

  static Future<void> show(BuildContext context, {String? initialItemId}) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    return BottomSheetWrapper.show(
      context: context,
      title: 'Tambah stok',
      subtitle: 'Barang masuk · ${Formatters.shortDate(now)}, $timeStr',
      child: AddStockSheet(initialItemId: initialItemId),
    );
  }

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  String? _selectedItemId;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedSupplierId;
  DateTime _receivedDate = DateTime.now();
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedItemId = widget.initialItemId;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final stockState = context.watch<StockState>();
    final itemState = context.watch<ItemState>();
    final supplierState = context.watch<SupplierState>();

    final isAdmin = authState.isAdmin;
    final items = itemState.allItems;
    final suppliers = supplierState.suppliers;

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
              'Tambahkan bahan baku di menu Barang terlebih dahulu sebelum menambah stok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75)),
            ),
          ],
        ),
      );
    }

    // Default select first item if not set or invalid
    if (_selectedItemId == null || !items.any((i) => i.id == _selectedItemId)) {
      _selectedItemId = items.first.id;
    }

    final selectedItem = items.firstWhere(
      (i) => i.id == _selectedItemId,
      orElse: () => items.first,
    );

    // Initialize price controller with item buyPrice if empty
    if (_priceController.text.isEmpty && selectedItem.buyPrice != null) {
      _priceController.text = selectedItem.buyPrice!.toStringAsFixed(0);
    }

    // Default supplier from item if available
    if (_selectedSupplierId == null && selectedItem.supplierId != null) {
      _selectedSupplierId = selectedItem.supplierId;
    }

    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? (selectedItem.buyPrice ?? 0);
    final totalCost = qty * price;

    final prefix = selectedItem.name.length >= 2 ? selectedItem.name.substring(0, 2).toUpperCase() : 'BT';
    final generatedBatchCode = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown Barang
        const Text(
          'Barang',
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
              value: _selectedItemId,
              isExpanded: true,
              items: items.map((i) => DropdownMenuItem(
                value: i.id,
                child: Text('${i.name} (${i.unit})', style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedItemId = val;
                    final newItem = items.firstWhere((i) => i.id == val);
                    if (newItem.buyPrice != null) {
                      _priceController.text = newItem.buyPrice!.toStringAsFixed(0);
                    }
                    _selectedSupplierId = newItem.supplierId;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Jumlah and Harga beli row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Jumlah (${selectedItem.unit})',
                hint: 'cth. 500',
                controller: _qtyController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Harga beli / ${selectedItem.unit}',
                  hint: 'cth. 180',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        // Supplier
        const Text(
          'Supplier (opsional)',
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
            child: DropdownButton<String?>(
              value: _selectedSupplierId,
              isExpanded: true,
              hint: const Text('Pilih supplier', style: TextStyle(color: Color(0xFFA89F99), fontSize: 13)),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tanpa supplier', style: TextStyle(fontSize: 13, color: Color(0xFF8D7B75))),
                ),
                ...suppliers.map((s) => DropdownMenuItem<String?>(
                  value: s.id,
                  child: Text(s.name, style: const TextStyle(fontSize: 13)),
                )),
              ],
              onChanged: (val) => setState(() => _selectedSupplierId = val),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Tanggal Masuk
        AppTextField(
          label: 'Tanggal masuk',
          hint: Formatters.fullDate(_receivedDate),
          readOnly: true,
          suffix: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF8D7B75)),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _receivedDate,
              firstDate: DateTime(2025),
              lastDate: DateTime(2035),
            );
            if (picked != null) setState(() => _receivedDate = picked);
          },
        ),
        const SizedBox(height: 14),
        // Kedaluwarsa (opsional)
        AppTextField(
          label: 'Kedaluwarsa (opsional)',
          hint: _expiryDate != null ? Formatters.fullDate(_expiryDate!) : 'Pilih tanggal kedaluwarsa',
          readOnly: true,
          suffix: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF8D7B75)),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2035),
            );
            if (picked != null) setState(() => _expiryDate = picked);
          },
        ),
        const SizedBox(height: 16),
        // Batch summary info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF3E3C7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch baru · $generatedBatchCode',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8A5812)),
              ),
              const SizedBox(height: 2),
              Text(
                'Stok saat ini ${Formatters.number(selectedItem.currentStock)} ${selectedItem.unit} + ${Formatters.number(qty)} ${selectedItem.unit}.'
                '${isAdmin ? ' Total pembelian ${Formatters.currency(totalCost)}.' : ''}',
                style: const TextStyle(fontSize: 10, color: Color(0xFFA67128)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          text: 'Simpan stok',
          isLoading: _isSaving || stockState.isLoading,
          onPressed: () async {
            if (qty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jumlah stok harus lebih dari 0')),
              );
              return;
            }

            if (price < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Harga beli tidak boleh negatif')),
              );
              return;
            }

            setState(() => _isSaving = true);
            try {
              final success = await stockState.addStock(
                storeId: authState.storeId,
                itemId: selectedItem.id,
                batchCode: generatedBatchCode,
                quantity: qty,
                buyPrice: price > 0 ? price : null,
                supplierId: _selectedSupplierId,
                receivedDate: _receivedDate,
                expiryDate: _expiryDate,
                userId: authState.userId,
              );

              if (mounted) {
                if (success) {
                  await itemState.loadItems(authState.storeId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stok ${selectedItem.name} +${Formatters.number(qty)} ${selectedItem.unit} berhasil ditambahkan')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(stockState.error ?? 'Gagal menambahkan stok')),
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
}
