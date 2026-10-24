import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/item.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/stock_state.dart';
import '../../state/supplier_state.dart';

class ItemFormSheet extends StatefulWidget {
  final bool isEdit;
  final Item? item;
  final String? itemName;
  final ValueChanged<Map<String, dynamic>>? onSaved;

  const ItemFormSheet({
    super.key,
    this.isEdit = false,
    this.item,
    this.itemName,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    bool isEdit = false,
    Item? item,
    String? itemName,
    ValueChanged<Map<String, dynamic>>? onSaved,
  }) {
    return BottomSheetWrapper.show(
      context: context,
      title: isEdit ? 'Edit barang' : 'Tambah barang',
      subtitle: isEdit ? 'Perbarui identitas & parameter stok' : 'Input data bahan baku baru',
      child: ItemFormSheet(
        isEdit: isEdit,
        item: item,
        itemName: itemName,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<ItemFormSheet> {
  int _currentStep = 1;
  bool _isSaving = false;

  // Step 1 Form fields
  late TextEditingController _nameController;
  String _selectedCategory = 'Biji kopi';
  String _selectedUnit = 'g (gram)';
  late TextEditingController _initialStockController;
  late TextEditingController _minStockController;

  // Step 2 Form fields
  late TextEditingController _buyPriceController;
  String? _selectedSupplierId;
  DateTime? _expiryDate;

  final List<String> _categories = [
    'Biji kopi',
    'Dairy',
    'Sirup',
    'Kemasan',
    'Bubuk',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? (widget.itemName ?? ''));
    _selectedCategory = item?.category ?? 'Biji kopi';
    if (!_categories.contains(_selectedCategory)) {
      _categories.insert(0, _selectedCategory);
    }
    
    final unit = item?.unit ?? 'g';
    if (unit == 'ml') {
      _selectedUnit = 'ml (mililiter)';
    } else if (unit == 'pcs') {
      _selectedUnit = 'pcs (satuan)';
    } else {
      _selectedUnit = 'g (gram)';
    }

    _initialStockController = TextEditingController(text: item != null ? item.currentStock.toStringAsFixed(0) : '');
    _minStockController = TextEditingController(text: item != null ? item.minStock.toStringAsFixed(0) : '');
    _buyPriceController = TextEditingController(text: item?.buyPrice != null ? item!.buyPrice!.toStringAsFixed(0) : '');
    _selectedSupplierId = item?.supplierId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialStockController.dispose();
    _minStockController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama barang wajib diisi')),
      );
      return;
    }

    final buyPriceStr = _buyPriceController.text.trim();
    if (buyPriceStr.isNotEmpty && (double.tryParse(buyPriceStr) == null || double.parse(buyPriceStr) < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga beli harus berupa angka valid')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authState = context.read<AuthState>();
    final itemState = context.read<ItemState>();
    final stockState = context.read<StockState>();

    final unitShort = _selectedUnit.split(' ').first;
    final minStock = double.tryParse(_minStockController.text.trim()) ?? 0;
    final initialStock = double.tryParse(_initialStockController.text.trim()) ?? 0;
    final buyPrice = double.tryParse(_buyPriceController.text.trim());

    try {
      if (widget.isEdit && widget.item != null) {
        final updated = widget.item!.copyWith(
          name: name,
          category: _selectedCategory,
          unit: unitShort,
          minStock: minStock,
          buyPrice: buyPrice,
          supplierId: _selectedSupplierId,
        );
        final success = await itemState.updateItem(updated);
        if (mounted) {
          if (success) {
            await itemState.loadItems(authState.storeId);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Barang $name berhasil diperbarui')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(itemState.error ?? 'Gagal memperbarui barang')),
            );
          }
        }
      } else {
        final newItem = Item(
          id: '',
          storeId: authState.storeId,
          name: name,
          category: _selectedCategory,
          unit: unitShort,
          minStock: minStock,
          buyPrice: buyPrice,
          supplierId: _selectedSupplierId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: authState.userId,
        );

        final success = await itemState.createItem(newItem);
        if (success) {
          // If user specified initial stock > 0, create initial batch
          if (initialStock > 0) {
            final created = itemState.allItems.firstWhere(
              (i) => i.name == name,
              orElse: () => newItem,
            );
            if (created.id.isNotEmpty) {
              final prefix = name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'BT';
              await stockState.addStock(
                storeId: authState.storeId,
                itemId: created.id,
                batchCode: '$prefix-01',
                quantity: initialStock,
                buyPrice: buyPrice,
                supplierId: _selectedSupplierId,
                receivedDate: DateTime.now(),
                expiryDate: _expiryDate,
                userId: authState.userId,
              );
            }
          }

          await itemState.loadItems(authState.storeId);
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Barang $name berhasil disimpan ke inventori')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(itemState.error ?? 'Gagal menyimpan barang')),
            );
          }
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
  }

  @override
  Widget build(BuildContext context) {
    final supplierState = context.watch<SupplierState>();
    final suppliers = supplierState.suppliers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _currentStep == 1
              ? '1 dari 2 · Identitas & batas stok'
              : '2 dari 2 · Pembelian & kedaluwarsa',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8D7B75)),
        ),
        const SizedBox(height: 12),
        if (_currentStep == 1) ...[
          // Step 1: Identitas
          AppTextField(
            label: 'Nama barang',
            hint: 'cth. Robusta, Susu, Matcha, Gula Aren',
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          const Text(
            'Kategori',
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
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Satuan',
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
                value: _selectedUnit,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'g (gram)', child: Text('g (gram)')),
                  DropdownMenuItem(value: 'ml (mililiter)', child: Text('ml (mililiter)')),
                  DropdownMenuItem(value: 'pcs (satuan)', child: Text('pcs (satuan)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUnit = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Stok awal',
                  hint: 'cth. 1500',
                  controller: _initialStockController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Batas minimum',
                  hint: 'cth. 500',
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Stok awal adalah saldo pembuka. Perubahan stok berikutnya dicatat lewat menu Tambah atau Kurangi.',
              style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF8A5812)),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Lanjut ke harga & supplier',
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama barang wajib diisi')),
                );
                return;
              }
              final minStockStr = _minStockController.text.trim();
              if (minStockStr.isNotEmpty && (double.tryParse(minStockStr) == null || double.parse(minStockStr) < 0)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batas minimum stok harus berupa angka valid')),
                );
                return;
              }
              final initialStockStr = _initialStockController.text.trim();
              if (initialStockStr.isNotEmpty && (double.tryParse(initialStockStr) == null || double.parse(initialStockStr) < 0)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stok awal harus berupa angka valid')),
                );
                return;
              }
              setState(() => _currentStep = 2);
            },
          ),
        ] else ...[
          // Step 2: Pembelian & Kedaluwarsa
          AppTextField(
            label: 'Harga beli per unit (Rp) · Admin',
            hint: 'cth. 180',
            controller: _buyPriceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
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
                    child: Text('Tanpa supplier / Input nanti', style: TextStyle(fontSize: 13, color: Color(0xFF8D7B75))),
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
          const SizedBox(height: 12),
          AppTextField(
            label: 'Kedaluwarsa batch terdekat (opsional)',
            hint: _expiryDate != null
                ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                : 'Pilih tanggal kedaluwarsa',
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ringkasan data:\n${_nameController.text.trim()} · $_selectedCategory · Satuan ${_selectedUnit.split(' ').first} · Minimum ${_minStockController.text.trim().isEmpty ? '0' : _minStockController.text.trim()}',
              style: const TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF8A5812)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Kembali',
                  isOutlined: true,
                  onPressed: () => setState(() => _currentStep = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: widget.isEdit ? 'Simpan perubahan' : 'Simpan barang',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
