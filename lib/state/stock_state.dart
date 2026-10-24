import 'package:flutter/foundation.dart';
import '../data/models/stock_transaction.dart';
import '../data/models/batch_item.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/batch_repository.dart';
import '../core/enums/transaction_type.dart';

class StockState extends ChangeNotifier {
  final TransactionRepository _txnRepo = TransactionRepository();
  final BatchRepository _batchRepo = BatchRepository();

  List<StockTransaction> _transactions = [];
  List<StockTransaction> _restockTransactions = [];
  List<StockTransaction> _usageTransactions = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<StockTransaction> get transactions => _transactions;
  List<StockTransaction> get restockTransactions => _restockTransactions;
  List<StockTransaction> get usageTransactions => _usageTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadTransactions(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _txnRepo.getTransactions(storeId);
      _restockTransactions =
          await _txnRepo.getTransactionsByType(storeId, 'restock');
      _usageTransactions =
          await _txnRepo.getTransactionsByType(storeId, 'usage');
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat pergerakan stok';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add stock (restock) — creates a batch and records the transaction.
  Future<bool> addStock({
    required String storeId,
    required String itemId,
    required String batchCode,
    required double quantity,
    double? buyPrice,
    String? supplierId,
    required DateTime receivedDate,
    DateTime? expiryDate,
    required String userId,
  }) async {
    _isLoading = true;
    _successMessage = null;
    notifyListeners();
    try {
      // Create batch
      final batch = BatchItem(
        id: '', // auto-generated
        itemId: itemId,
        batchCode: batchCode,
        initialQuantity: quantity,
        remainingQuantity: quantity,
        buyPrice: buyPrice,
        supplierId: supplierId,
        receivedDate: receivedDate,
        expiryDate: expiryDate,
        createdAt: DateTime.now(),
        createdBy: userId,
      );
      final newBatch = await _batchRepo.createBatch(batch);

      // Record transaction
      final txn = StockTransaction(
        id: '',
        storeId: storeId,
        itemId: itemId,
        batchId: newBatch.id,
        type: TransactionType.restock,
        quantity: quantity,
        notes: 'Restok batch $batchCode',
        performedBy: userId,
        createdAt: DateTime.now(),
      );
      await _txnRepo.createTransaction(txn);

      _successMessage = 'Stok berhasil ditambahkan';
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menambah stok';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reduce stock (usage) — deducts from batches using FIFO.
  Future<Map<String, dynamic>?> reduceStock({
    required String storeId,
    required String itemId,
    required double quantity,
    String? reason,
    String? notes,
    required String userId,
  }) async {
    _isLoading = true;
    _successMessage = null;
    notifyListeners();
    try {
      // Get available batches in FIFO order
      final batches = await _batchRepo.getAvailableBatches(itemId);
      double remaining = quantity;
      double totalBefore = batches.fold(0, (s, b) => s + b.remainingQuantity);

      if (totalBefore < quantity) {
        _error =
            'Stok tidak cukup. Stok tersedia: ${totalBefore.toStringAsFixed(0)}';
        notifyListeners();
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Deduct FIFO
      for (final batch in batches) {
        if (remaining <= 0) break;
        final deduct =
            remaining > batch.remainingQuantity
                ? batch.remainingQuantity
                : remaining;
        await _batchRepo.updateRemainingQuantity(
            batch.id, batch.remainingQuantity - deduct);
        remaining -= deduct;
      }

      // Record transaction
      final txn = StockTransaction(
        id: '',
        storeId: storeId,
        itemId: itemId,
        type: TransactionType.usage,
        quantity: quantity,
        reason: reason,
        notes: notes,
        performedBy: userId,
        createdAt: DateTime.now(),
      );
      await _txnRepo.createTransaction(txn);

      _successMessage = 'Pemakaian tercatat';
      _error = null;
      notifyListeners();

      return {
        'before': totalBefore,
        'used': quantity,
        'after': totalBefore - quantity,
      };
    } catch (e) {
      _error = 'Gagal mengurangi stok';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<StockTransaction>> getRecentActivity(String storeId) async {
    return _txnRepo.getRecentActivity(storeId);
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
