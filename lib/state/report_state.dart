import 'package:flutter/foundation.dart';
import '../data/models/sale.dart';
import '../data/models/stock_transaction.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/transaction_repository.dart';

class ReportState extends ChangeNotifier {
  final SaleRepository _saleRepo = SaleRepository();
  final TransactionRepository _txnRepo = TransactionRepository();

  double _totalSales = 0;
  int _saleCount = 0;
  List<Sale> _salesInRange = [];
  List<StockTransaction> _transactionsInRange = [];
  bool _isLoading = false;
  String? _error;
  DateTime _fromDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
  DateTime _toDate = DateTime.now();

  double get totalSales => _totalSales;
  int get saleCount => _saleCount;
  List<Sale> get salesInRange => _salesInRange;
  List<StockTransaction> get transactionsInRange => _transactionsInRange;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;

  // Computed stats
  int get restockCount => _transactionsInRange
      .where((t) => t.type.name == 'restock')
      .length;
  int get usageCount => _transactionsInRange
      .where((t) => t.type.name == 'usage')
      .length;

  void setDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  Future<void> loadReport(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _totalSales = await _saleRepo.getTotalSales(storeId, _fromDate, _toDate);
      _saleCount = await _saleRepo.getSaleCount(storeId, _fromDate, _toDate);
      _salesInRange =
          await _saleRepo.getSalesByDateRange(storeId, _fromDate, _toDate);
      _transactionsInRange =
          await _txnRepo.getTransactionsByDateRange(
              storeId, _fromDate, _toDate);
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat laporan';
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
