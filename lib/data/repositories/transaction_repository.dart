import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_transaction.dart';
import '../services/supabase_service.dart';

class TransactionRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Get all transactions for a store, newest first.
  Future<List<StockTransaction>> getTransactions(
    String storeId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _client
        .from('stock_transactions')
        .select('*, items(name, unit), batches(batch_code), profiles(full_name)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List)
        .map((e) => StockTransaction.fromJson(e))
        .toList();
  }

  /// Get transactions filtered by type.
  Future<List<StockTransaction>> getTransactionsByType(
    String storeId,
    String type, {
    int limit = 50,
  }) async {
    final data = await _client
        .from('stock_transactions')
        .select('*, items(name, unit), batches(batch_code), profiles(full_name)')
        .eq('store_id', storeId)
        .eq('type', type)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => StockTransaction.fromJson(e))
        .toList();
  }

  /// Get transactions for a specific item.
  Future<List<StockTransaction>> getItemTransactions(
      String itemId) async {
    final data = await _client
        .from('stock_transactions')
        .select('*, items(name, unit), batches(batch_code), profiles(full_name)')
        .eq('item_id', itemId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => StockTransaction.fromJson(e))
        .toList();
  }

  /// Record a new transaction.
  Future<StockTransaction> createTransaction(
      StockTransaction transaction) async {
    final data = await _client
        .from('stock_transactions')
        .insert(transaction.toInsertJson())
        .select()
        .single();
    return StockTransaction.fromJson(data);
  }

  /// Get recent activity (last N transactions).
  Future<List<StockTransaction>> getRecentActivity(
      String storeId, {int limit = 5}) async {
    final data = await _client
        .from('stock_transactions')
        .select('*, items(name, unit), profiles(full_name)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => StockTransaction.fromJson(e))
        .toList();
  }

  /// Get transactions filtered by date range.
  Future<List<StockTransaction>> getTransactionsByDateRange(
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _client
        .from('stock_transactions')
        .select('*, items(name, unit), batches(batch_code), profiles(full_name)')
        .eq('store_id', storeId)
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String())
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => StockTransaction.fromJson(e))
        .toList();
  }
}
