import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/recipe_state.dart';
import '../../state/sale_state.dart';
import '../../data/models/item.dart';
import '../../app/router/route_names.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String? _selectedRecipeId;
  int _quantity = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthState>();
      if (authState.storeId.isNotEmpty) {
        context.read<RecipeState>().loadRecipes(authState.storeId);
        context.read<ItemState>().loadItems(authState.storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final recipeState = context.watch<RecipeState>();
    final itemState = context.watch<ItemState>();
    final saleState = context.watch<SaleState>();

    final recipes = recipeState.recipes;
    final items = itemState.allItems;

    if (recipeState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        appBar: AppHeader(),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF38241D))),
      );
    }

    if (recipes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: const AppHeader(),
        body: Center(
          child: EmptyState(
            icon: Icons.point_of_sale_outlined,
            title: 'Belum ada resep produk',
            message: 'Buat resep produk di menu Barang terlebih dahulu untuk mencatat penjualan kasir.',
            action: ElevatedButton.icon(
              onPressed: () => context.goNamed(RouteNames.inventory),
              icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              label: const Text('Buka menu Resep', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38241D)),
            ),
          ),
        ),
      );
    }

    // Default select first recipe if not set or invalid
    if (_selectedRecipeId == null || !recipes.any((r) => r.id == _selectedRecipeId)) {
      _selectedRecipeId = recipes.first.id;
    }

    final selectedRecipe = recipes.firstWhere(
      (r) => r.id == _selectedRecipeId,
      orElse: () => recipes.first,
    );

    final totalPrice = _quantity * selectedRecipe.sellingPrice;

    // Check stock for each ingredient
    bool hasInsufficientStock = false;
    String insufficientMessage = '';

    final ingredientChecks = selectedRecipe.ingredients.map((ing) {
      Item? item;
      try {
        item = items.firstWhere((i) => i.id == ing.itemId);
      } catch (_) {
        try {
          item = items.firstWhere((i) => (ing.itemName != null && ing.itemName!.isNotEmpty) && i.name.toLowerCase() == ing.itemName!.toLowerCase());
        } catch (_) {
          item = null;
        }
      }

      final needed = ing.quantity * _quantity;
      final available = item?.currentStock ?? 0;
      final isShort = item == null || available < needed;
      final itemName = ing.itemName ?? item?.name ?? 'Bahan #${ing.itemId}';

      if (isShort && !hasInsufficientStock) {
        hasInsufficientStock = true;
        if (item == null) {
          insufficientMessage = 'Bahan baku "$itemName" tidak ditemukan di daftar barang inventaris.';
        } else {
          final shortage = needed - available;
          insufficientMessage = 'Stok $itemName tidak cukup! Dibutuhkan ${Formatters.number(needed)} ${ing.unit}, tersedia ${Formatters.number(available)} ${ing.unit} (Kurang ${Formatters.number(shortage)} ${ing.unit}).';
        }
      }

      final afterStock = available - needed;

      return {
        'name': itemName,
        'needed': needed,
        'available': available,
        'after': afterStock,
        'unit': ing.unit,
        'isShort': isShort,
      };
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Catat penjualan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 14),
            // Product & Quantity Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Produk',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F6F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRecipeId,
                                  isExpanded: true,
                                  items: recipes.map((r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(
                                      r.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRecipeId = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jumlah',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (_quantity > 1) setState(() => _quantity--);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('—', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF38241D))),
                                  ),
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _quantity++),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38241D))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF2ECE6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Harga per porsi',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75)),
                      ),
                      Text(
                        Formatters.currency(selectedRecipe.sellingPrice),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total penjualan',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                      ),
                      Text(
                        Formatters.currency(totalPrice),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2E1E19)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Ingredients Deductions Card
            const Text(
              'Pemotongan otomatis bahan (FEFO)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: ingredientChecks.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Resep ini belum memiliki komposisi bahan baku.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < ingredientChecks.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Color(0xFFF2ECE6)),
                          _buildIngredientRow(
                            name: ingredientChecks[i]['name'] as String,
                            calc: (ingredientChecks[i]['isShort'] as bool)
                                ? '${Formatters.number(ingredientChecks[i]['available'] as num)} / ${Formatters.number(ingredientChecks[i]['needed'] as num)} ${ingredientChecks[i]['unit']}'
                                : '${Formatters.number(ingredientChecks[i]['available'] as num)} → ${Formatters.number(ingredientChecks[i]['after'] as num)} ${ingredientChecks[i]['unit']}',
                            deduct: '-${Formatters.number(ingredientChecks[i]['needed'] as num)} ${ingredientChecks[i]['unit']}',
                            status: (ingredientChecks[i]['isShort'] as bool) ? 'Kurang' : 'Aman',
                            isDanger: ingredientChecks[i]['isShort'] as bool,
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            if (hasInsufficientStock) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stok bahan tidak mencukupi!',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insufficientMessage,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const AppButton(
                text: 'Stok tidak mencukupi',
                backgroundColor: Color(0xFFD6CDC4),
                onPressed: null,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3E3C7)),
                ),
                child: const Text(
                  'METODE FEFO AKTIF\nBatch bahan dengan tanggal kedaluwarsa terdekat akan dipotong terlebih dahulu secara otomatis.',
                  style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF8A5812)),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Konfirmasi $_quantity penjualan (${Formatters.currency(totalPrice)})',
                isLoading: _isSaving || saleState.isLoading,
                onPressed: () async {
                  setState(() => _isSaving = true);
                  try {
                    final success = await saleState.recordSale(
                      storeId: authState.storeId,
                      recipe: selectedRecipe,
                      quantity: _quantity,
                      userId: authState.userId,
                    );

                    if (mounted) {
                      if (success) {
                        await itemState.loadItems(authState.storeId);
                        context.pushNamed(RouteNames.saleResult, extra: {
                          'product': selectedRecipe.name,
                          'qty': _quantity,
                          'total': totalPrice,
                          'deductions': ingredientChecks,
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(saleState.error ?? 'Gagal mencatat penjualan')),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientRow({
    required String name,
    required String calc,
    required String deduct,
    required String status,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF2E1E19),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              calc,
              style: TextStyle(fontSize: 11, color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF5D4E48)),
            ),
          ),
          Text(
            deduct,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF8D7B75),
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge.custom(status, isDanger: isDanger),
        ],
      ),
    );
  }
}
