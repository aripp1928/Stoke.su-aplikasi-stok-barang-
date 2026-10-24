import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/recipe.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/recipe_state.dart';

class RecipeFormSheet extends StatefulWidget {
  final dynamic recipe;

  const RecipeFormSheet({super.key, this.recipe});

  static Future<void> show(BuildContext context, {dynamic recipe}) {
    return BottomSheetWrapper.show(
      context: context,
      title: recipe != null ? 'Edit resep' : 'Tambah resep',
      subtitle: 'Takaran untuk 1 porsi · Admin',
      child: RecipeFormSheet(recipe: recipe),
    );
  }

  @override
  State<RecipeFormSheet> createState() => _RecipeFormSheetState();
}

class _RecipeFormSheetState extends State<RecipeFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _portionController;
  final List<Map<String, dynamic>> _ingredients = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    String initialName = '';
    String initialPrice = '';

    if (r is Recipe) {
      initialName = r.name;
      initialPrice = r.sellPrice.toStringAsFixed(0);
      for (final ing in r.ingredients) {
        _ingredients.add({
          'itemId': ing.itemId,
          'name': ing.itemName ?? 'Bahan',
          'quantity': ing.quantity,
          'unit': ing.unit,
        });
      }
    } else if (r is Map) {
      initialName = r['name']?.toString() ?? '';
      initialPrice = r['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    }

    _nameController = TextEditingController(text: initialName);
    _priceController = TextEditingController(text: initialPrice);
    _portionController = TextEditingController(text: '1 cup');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  void _showAddIngredientDialog() {
    final itemState = context.read<ItemState>();
    final items = itemState.allItems;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada barang di inventori. Tambahkan bahan baku terlebih dulu.')),
      );
      return;
    }

    String selectedItemId = items.first.id;
    final qtyController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final selectedItem = items.firstWhere(
              (i) => i.id == selectedItemId,
              orElse: () => items.first,
            );

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Pilih bahan resep',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E1E19)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Bahan baku', style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2DDD7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedItemId,
                        isExpanded: true,
                        items: items.map((i) => DropdownMenuItem(
                          value: i.id,
                          child: Text('${i.name} (${i.unit})', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedItemId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Takaran per porsi (${selectedItem.unit})',
                    hint: 'cth. 18',
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF8D7B75))),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text.trim()) ?? 0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Takaran bahan per porsi harus lebih dari 0')),
                      );
                      return;
                    }

                    setState(() {
                      // Check if already added
                      final existingIndex = _ingredients.indexWhere((i) => i['itemId'] == selectedItemId);
                      if (existingIndex >= 0) {
                        _ingredients[existingIndex]['quantity'] = qty;
                      } else {
                        _ingredients.add({
                          'itemId': selectedItemId,
                          'name': selectedItem.name,
                          'quantity': qty,
                          'unit': selectedItem.unit,
                        });
                      }
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38241D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tambah', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk resep wajib diisi')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga jual wajib diisi dengan angka valid')),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 bahan baku harus ditambahkan ke resep')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authState = context.read<AuthState>();
    final recipeState = context.read<RecipeState>();

    try {
      final existingRecipe = widget.recipe is Recipe ? (widget.recipe as Recipe) : null;

      final recipeIngredients = _ingredients.map((ing) {
        return RecipeIngredient(
          id: '',
          recipeId: existingRecipe?.id ?? '',
          itemId: ing['itemId'] as String,
          quantity: (ing['quantity'] as num).toDouble(),
          unit: ing['unit'] as String,
          itemName: ing['name'] as String?,
        );
      }).toList();

      if (existingRecipe != null) {
        final updated = existingRecipe.copyWith(
          name: name,
          sellPrice: price,
        );
        final success = await recipeState.updateRecipe(updated, recipeIngredients);
        if (mounted) {
          if (success) {
            await recipeState.loadRecipes(authState.storeId);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Resep $name berhasil diperbarui')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(recipeState.error ?? 'Gagal memperbarui resep')),
            );
          }
        }
      } else {
        final newRecipe = Recipe(
          id: '',
          storeId: authState.storeId,
          name: name,
          sellPrice: price,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await recipeState.createRecipe(newRecipe, recipeIngredients);
        if (mounted) {
          if (success) {
            await recipeState.loadRecipes(authState.storeId);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Resep $name berhasil disimpan')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(recipeState.error ?? 'Gagal menambahkan resep')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nama produk',
          hint: 'cth. Kopsu Gula Aren, Americano, Matcha Latte',
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Harga jual (Rp)',
                hint: 'cth. 25000',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Porsi',
                hint: '1 cup',
                controller: _portionController,
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bahan & takaran',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D4E48)),
            ),
            Text(
              '${_ingredients.length} bahan',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_ingredients.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E3DD)),
            ),
            child: const Center(
              child: Text(
                'Belum ada bahan ditambahkan.\nKlik tombol di bawah untuk memilih bahan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E3DD)),
            ),
            child: Column(
              children: [
                ..._ingredients.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ing['name'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19)),
                          ),
                        ),
                        Text(
                          '${ing['quantity']} ${ing['unit']}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _ingredients.remove(ing));
                          },
                          child: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _showAddIngredientDialog,
          icon: const Icon(Icons.add, size: 16, color: Color(0xFF38241D)),
          label: const Text(
            '+ Tambah bahan',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF38241D)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFD6CDC4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Takaran per porsi digunakan sistem untuk memotong stok bahan secara otomatis (FIFO/FEFO) saat kasir mencatat penjualan.',
            style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF8A5812)),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          text: widget.recipe != null ? 'Simpan perubahan' : 'Simpan resep',
          isLoading: _isSaving,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
