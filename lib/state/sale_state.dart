import 'package:flutter/foundation.dart';
import '../data/models/sale.dart';
import '../data/models/recipe.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/batch_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/models/stock_transaction.dart';
import '../core/enums/transaction_type.dart';

class SaleState extends ChangeNotifier {
  final SaleRepository _saleRepo = SaleRepository();
  final BatchRepository _batchRepo = BatchRepository();
  final TransactionRepository _txnRepo = TransactionRepository();

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;
  Sale? _lastSale;
  Map<String, double>? _stockAfterSale;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Sale? get lastSale => _lastSale;
  Map<String, double>? get stockAfterSale => _stockAfterSale;

  Future<void> loadSales(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _sales = await _saleRepo.getSales(storeId);
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat data penjualan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if we have enough stock for a recipe × quantity.
  Future<Map<String, dynamic>> checkStock(
      Recipe recipe, int saleQty) async {
    final Map<String, double> needed = {};
    final Map<String, double> available = {};
    final Map<String, String> units = {};
    bool sufficient = true;

    for (final ing in recipe.ingredients) {
      final totalNeeded = ing.quantity * saleQty;
      needed[ing.itemId] = totalNeeded;
      units[ing.itemId] = ing.unit;
      final totalAvailable = await _batchRepo.getTotalStock(ing.itemId);
      available[ing.itemId] = totalAvailable;
      if (totalAvailable < totalNeeded) sufficient = false;
    }

    return {
      'sufficient': sufficient,
      'needed': needed,
      'available': available,
      'units': units,
    };
  }

  /// Record a sale, deduct stock via FIFO, record transactions.
  Future<bool> recordSale({
    required String storeId,
    required Recipe recipe,
    required int quantity,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final totalPrice = recipe.sellPrice * quantity;

      // 1. Create sale record
      final sale = Sale(
        id: '',
        storeId: storeId,
        recipeId: recipe.id,
        productName: recipe.name,
        quantity: quantity,
        totalPrice: totalPrice,
        performedBy: userId,
        createdAt: DateTime.now(),
      );
      final newSale = await _saleRepo.createSale(sale);
      _lastSale = newSale;

      // 2. Deduct ingredients from batches (FIFO)
      _stockAfterSale = {};
      for (final ing in recipe.ingredients) {
        double remaining = ing.quantity * quantity;
        final batches = await _batchRepo.getAvailableBatches(ing.itemId);

        for (final batch in batches) {
          if (remaining <= 0) break;
          final deduct = remaining > batch.remainingQuantity
              ? batch.remainingQuantity
              : remaining;
          await _batchRepo.updateRemainingQuantity(
              batch.id, batch.remainingQuantity - deduct);

          // Record deduction
          final deduction = SaleDeduction(
            id: '',
            saleId: newSale.id,
            itemId: ing.itemId,
            batchId: batch.id,
            quantityDeducted: deduct,
            createdAt: DateTime.now(),
          );
          await _saleRepo.createDeductions([deduction]);

          remaining -= deduct;
        }

        // Record transaction
        final txn = StockTransaction(
          id: '',
          storeId: storeId,
          itemId: ing.itemId,
          type: TransactionType.sale,
          quantity: ing.quantity * quantity,
          notes: 'Penjualan ${recipe.name} x$quantity',
          performedBy: userId,
          createdAt: DateTime.now(),
        );
        await _txnRepo.createTransaction(txn);

        // Get remaining stock for display
        final stockLeft = await _batchRepo.getTotalStock(ing.itemId);
        _stockAfterSale![ing.itemId] = stockLeft;
      }

      _sales.insert(0, newSale);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal mencatat penjualan';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
