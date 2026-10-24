import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../../state/recipe_state.dart';
import '../../state/supplier_state.dart';
import '../../app/router/route_names.dart';
import 'category_filter_sheet.dart';
import 'item_form_sheet.dart';
import '../recipe/recipe_form_sheet.dart';
import '../supplier/supplier_form_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchItemController = TextEditingController();
  final _searchRecipeController = TextEditingController();
  final _searchSupplierController = TextEditingController();
  String _selectedCategory = 'Semua kategori';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  void _loadAll() {
    final authState = context.read<AuthState>();
    final storeId = authState.storeId;
    if (storeId.isNotEmpty) {
      context.read<ItemState>().loadItems(storeId);
      context.read<RecipeState>().loadRecipes(storeId);
      context.read<SupplierState>().loadSuppliers(storeId);
    }
  }

  void _openAddItem() {
    ItemFormSheet.show(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchItemController.dispose();
    _searchRecipeController.dispose();
    _searchSupplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final isAdmin = authState.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: const AppHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tabController.index == 0
                      ? 'Persediaan kedai'
                      : _tabController.index == 1
                          ? 'Resep kedai'
                          : 'Mitra persediaan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: Color(0xFF2E1E19),
                  ),
                ),
                const SizedBox(height: 12),
                // 3 Segmented Tabs
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF2E1E19),
                    unselectedLabelColor: const Color(0xFF8D7B75),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Barang'),
                      Tab(text: 'Resep'),
                      Tab(text: 'Supplier'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBarangTab(isAdmin),
                _buildResepTab(isAdmin),
                _buildSupplierTab(isAdmin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Barang (Items) ──
  Widget _buildBarangTab(bool isAdmin) {
    final itemState = context.watch<ItemState>();
    final allItems = itemState.allItems;

    var items = allItems;
    if (_selectedCategory != 'Semua kategori') {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }
    final query = _searchItemController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(query)).toList();
    }

    return Column(
      children: [
        // Search & Filter & Add row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchItemController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2E1E19)),
                    decoration: InputDecoration(
                      hintText: 'Cari nama bahan...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA89F99)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFA89F99)),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DDD7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DDD7)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  CategoryFilterSheet.show(
                    context,
                    currentCategory: _selectedCategory,
                    onSelect: (cat) => setState(() => _selectedCategory = cat),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2DDD7)),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF5D4037)),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openAddItem,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38241D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedCategory · ${items.length} barang',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: itemState.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF38241D)))
              : items.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Belum ada bahan baku',
                      message: query.isNotEmpty
                          ? 'Tidak ada bahan baku yang cocok dengan "$query"'
                          : 'Tambahkan data bahan baku untuk mulai memantau stok kedai.',
                      action: isAdmin
                          ? ElevatedButton.icon(
                              onPressed: _openAddItem,
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text('Tambah barang baru', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38241D)),
                            )
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final item = items[idx];
                        return InkWell(
                          onTap: () => context.pushNamed(RouteNames.itemDetail, extra: item.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8E3DD)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E1E19),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.category} · min. ${Formatters.number(item.minStock)} ${item.unit}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${Formatters.number(item.currentStock)} ${item.unit}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2E1E19),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    StatusBadge.custom(
                                      item.stockStatusLabel,
                                      isWarning: item.isLowStock,
                                      isDanger: item.isEmpty,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (isAdmin && items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAddItem,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Tambah barang baru',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38241D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Tab 2: Resep (Recipes) ──
  Widget _buildResepTab(bool isAdmin) {
    final recipeState = context.watch<RecipeState>();
    final allRecipes = recipeState.allRecipes;

    final query = _searchRecipeController.text.trim().toLowerCase();
    final recipes = query.isEmpty
        ? allRecipes
        : allRecipes.where((r) => r.name.toLowerCase().contains(query)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchRecipeController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2E1E19)),
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA89F99)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFA89F99)),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DDD7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DDD7)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: recipeState.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF38241D)))
              : recipes.isEmpty
                  ? EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'Belum ada resep',
                      message: query.isNotEmpty
                          ? 'Tidak ada resep yang cocok dengan "$query"'
                          : 'Tambahkan resep agar takaran bahan dapat dipotong otomatis saat penjualan.',
                      action: isAdmin
                          ? ElevatedButton.icon(
                              onPressed: () => RecipeFormSheet.show(context),
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text('Tambah resep baru', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38241D)),
                            )
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: recipes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final recipe = recipes[idx];
                        final ingredientSummary = recipe.ingredients
                            .map((i) => '${i.itemName ?? 'Bahan'} ${Formatters.number(i.quantity)} ${i.unit}')
                            .join(' · ');

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E3DD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    recipe.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'serif',
                                      color: Color(0xFF2E1E19),
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(recipe.sellingPrice),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E1E19),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${recipe.ingredients.length} bahan · ${recipe.portion}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                              ),
                              if (ingredientSummary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF7F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ingredientSummary,
                                    style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF5D4E48)),
                                  ),
                                ),
                              ],
                              if (isAdmin) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 34,
                                  child: OutlinedButton(
                                    onPressed: () => RecipeFormSheet.show(context, recipe: recipe),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFD6CDC4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Lihat & edit resep',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
        if (isAdmin && recipes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => RecipeFormSheet.show(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Tambah resep',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38241D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Tab 3: Supplier ──
  Widget _buildSupplierTab(bool isAdmin) {
    final supplierState = context.watch<SupplierState>();
    final allSuppliers = supplierState.allSuppliers;

    final query = _searchSupplierController.text.trim().toLowerCase();
    final suppliers = query.isEmpty
        ? allSuppliers
        : allSuppliers.where((s) =>
            s.name.toLowerCase().contains(query) ||
            (s.phone ?? '').contains(query)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchSupplierController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2E1E19)),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau nomor HP...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA89F99)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFA89F99)),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DDD7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DDD7)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${suppliers.length} mitra aktif', style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: supplierState.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF38241D)))
              : suppliers.isEmpty
                  ? EmptyState(
                      icon: Icons.business_outlined,
                      title: 'Belum ada supplier',
                      message: query.isNotEmpty
                          ? 'Tidak ada supplier yang cocok dengan "$query"'
                          : 'Tambahkan data mitra supplier untuk mempermudah restok bahan.',
                      action: isAdmin
                          ? ElevatedButton.icon(
                              onPressed: () => SupplierFormSheet.show(context),
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text('Tambah supplier baru', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38241D)),
                            )
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: suppliers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final sup = suppliers[idx];
                        return InkWell(
                          onTap: () => context.pushNamed(RouteNames.supplierDetail, extra: sup.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8E3DD)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0EAE1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.business_outlined, size: 18, color: Color(0xFF5D4037)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sup.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E1E19),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${sup.phone ?? 'Belum ada no HP'}${sup.contactPerson != null ? ' · ${sup.contactPerson}' : ''}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: Color(0xFFA89F99)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (isAdmin && suppliers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => SupplierFormSheet.show(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Tambah supplier',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38241D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
