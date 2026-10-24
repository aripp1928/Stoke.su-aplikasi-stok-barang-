import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch_item.dart';
import '../services/supabase_service.dart';

class BatchRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Get all batches for an item, ordered by received_date (FIFO).
  Future<List<BatchItem>> getBatches(String itemId) async {
    final data = await _client
        .from('batches')
        .select('*, suppliers(name)')
        .eq('item_id', itemId)
        .order('received_date', ascending: true);
    return (data as List).map((e) => BatchItem.fromJson(e)).toList();
  }

  /// Get batches with remaining stock (FIFO order).
  Future<List<BatchItem>> getAvailableBatches(String itemId) async {
    final data = await _client
        .from('batches')
        .select('*, suppliers(name)')
        .eq('item_id', itemId)
        .gt('remaining_quantity', 0)
        .order('received_date', ascending: true);
    return (data as List).map((e) => BatchItem.fromJson(e)).toList();
  }

  /// Create a new batch (restock).
  Future<BatchItem> createBatch(BatchItem batch) async {
    final data = await _client
        .from('batches')
        .insert(batch.toInsertJson())
        .select()
        .single();
    return BatchItem.fromJson(data);
  }

  /// Update remaining quantity of a batch.
  Future<void> updateRemainingQuantity(
      String batchId, double remaining) async {
    await _client
        .from('batches')
        .update({'remaining_quantity': remaining})
        .eq('id', batchId);
  }

  /// Generate next batch code for an item. E.g., RB-01, RB-02...
  Future<String> generateBatchCode(String itemId, String itemPrefix) async {
    final data = await _client
        .from('batches')
        .select('batch_code')
        .eq('item_id', itemId)
        .order('created_at', ascending: false)
        .limit(1);

    if ((data as List).isEmpty) {
      return '$itemPrefix-01';
    }

    final lastCode = data[0]['batch_code'] as String;
    final parts = lastCode.split('-');
    if (parts.length >= 2) {
      final lastNum = int.tryParse(parts.last) ?? 0;
      return '$itemPrefix-${(lastNum + 1).toString().padLeft(2, '0')}';
    }
    return '$itemPrefix-01';
  }

  /// Get total remaining stock for an item across all batches.
  Future<double> getTotalStock(String itemId) async {
    final data = await _client
        .from('batches')
        .select('remaining_quantity')
        .eq('item_id', itemId)
        .gt('remaining_quantity', 0);
    double total = 0;
    for (final row in (data as List)) {
      total += (row['remaining_quantity'] as num).toDouble();
    }
    return total;
  }
}
