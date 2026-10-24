import 'package:flutter/foundation.dart';
import '../data/models/item.dart';
import '../data/models/batch_item.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/batch_repository.dart';

/// State management for inventory items and batches.
class ItemState extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final BatchRepository _batchRepo = BatchRepository();

  List<Item> _items = [];
  List<String> _categories = [];
  Set<String> _selectedCategories = {};
  Item? _selectedItem;
  List<BatchItem> _batches = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // ── Getters ──
  List<Item> get items => _filteredItems;
  List<Item> get allItems => _items;
  List<String> get categories => _categories;
  Set<String> get selectedCategories => _selectedCategories;
  Item? get selectedItem => _selectedItem;
  List<BatchItem> get batches => _batches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<Item> get _filteredItems {
    var result = _items;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((i) =>
              i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategories.isNotEmpty) {
      result = result
          .where((i) => _selectedCategories.contains(i.category))
          .toList();
    }
    return result;
  }

  /// Dashboard stats
  int get totalItemCount => _items.length;
  int get lowStockCount => _items.where((i) => i.isLowStock).length;
  int get emptyStockCount => _items.where((i) => i.isEmpty).length;
  List<Item> get lowStockItems =>
      _items.where((i) => i.isLowStock || i.isEmpty).toList();

  // ── Actions ──

  Future<void> loadItems(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _itemRepo.getItems(storeId);
      _categories = await _itemRepo.getCategories(storeId);
    } catch (e) {
      // Fallback to simple query if RPC not set up
      try {
        _items = await _itemRepo.getItemsSimple(storeId);
        _categories = await _itemRepo.getCategories(storeId);
      } catch (e2) {
        _error = 'Gagal memuat data barang';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadItemDetail(String itemId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedItem = await _itemRepo.getItem(itemId);
      _batches = await _batchRepo.getBatches(itemId);
      // Update current_stock from batches
      final totalStock = _batches.fold<double>(
          0, (sum, b) => sum + b.remainingQuantity);
      _selectedItem = _selectedItem!.copyWith(currentStock: totalStock);
    } catch (e) {
      _error = 'Gagal memuat detail barang';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createItem(Item item) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newItem = await _itemRepo.createItem(item);
      _items.add(newItem);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menambah barang';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem(Item item) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _itemRepo.updateItem(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index >= 0) _items[index] = updated;
      if (_selectedItem?.id == item.id) _selectedItem = updated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal mengubah barang';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(String itemId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _itemRepo.deleteItem(itemId);
      _items.removeWhere((i) => i.id == itemId);
      if (_selectedItem?.id == itemId) _selectedItem = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus barang';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategories = {};
    _searchQuery = '';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
