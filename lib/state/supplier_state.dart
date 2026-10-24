import 'package:flutter/foundation.dart';
import '../data/models/supplier.dart';
import '../data/repositories/supplier_repository.dart';

class SupplierState extends ChangeNotifier {
  final SupplierRepository _repo = SupplierRepository();

  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  List<Map<String, dynamic>> _purchaseHistory = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Supplier> get suppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers
        .where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (s.phone ?? '').contains(_searchQuery))
        .toList();
  }
  List<Supplier> get allSuppliers => _suppliers;
  Supplier? get selectedSupplier => _selectedSupplier;
  List<Map<String, dynamic>> get purchaseHistory => _purchaseHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSuppliers(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _suppliers = await _repo.getSuppliers(storeId);
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat supplier';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSupplierDetail(String supplierId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedSupplier = await _repo.getSupplier(supplierId);
      _purchaseHistory = await _repo.getPurchaseHistory(supplierId);
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat detail supplier';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSupplier(Supplier supplier) async {
    _isLoading = true;
    notifyListeners();
    try {
      final created = await _repo.createSupplier(supplier);
      _suppliers.add(created);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menambah supplier';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _repo.updateSupplier(supplier);
      final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (idx >= 0) _suppliers[idx] = updated;
      _selectedSupplier = updated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal mengubah supplier';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSupplier(String supplierId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.deleteSupplier(supplierId);
      _suppliers.removeWhere((s) => s.id == supplierId);
      if (_selectedSupplier?.id == supplierId) _selectedSupplier = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus supplier';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
