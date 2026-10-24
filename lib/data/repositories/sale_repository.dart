import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../services/supabase_service.dart';

class SaleRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Get all sales for a store.
  Future<List<Sale>> getSales(String storeId, {int limit = 150}) async {
    final data = await _client
        .from('sales')
        .select('*, profiles(full_name), sale_deductions(*, items(name, unit))')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }

  /// Get sales within a date range (for reports).
  Future<List<Sale>> getSalesByDateRange(
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _client
        .from('sales')
        .select('*, profiles(full_name)')
        .eq('store_id', storeId)
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String())
        .order('created_at', ascending: false);
    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }

  /// Record a sale.
  Future<Sale> createSale(Sale sale) async {
    final data = await _client
        .from('sales')
        .insert(sale.toInsertJson())
        .select()
        .single();
    return Sale.fromJson(data);
  }

  /// Record sale deductions (stock cuts per batch).
  Future<void> createDeductions(List<SaleDeduction> deductions) async {
    if (deductions.isEmpty) return;
    final inserts = deductions.map((d) => d.toInsertJson()).toList();
    await _client.from('sale_deductions').insert(inserts);
  }

  /// Get total sales amount for a date range.
  Future<double> getTotalSales(
      String storeId, DateTime from, DateTime to) async {
    final data = await _client
        .from('sales')
        .select('total_price')
        .eq('store_id', storeId)
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String());
    double total = 0;
    for (final row in (data as List)) {
      total += (row['total_price'] as num).toDouble();
    }
    return total;
  }

  /// Get sale count for a date range.
  Future<int> getSaleCount(
      String storeId, DateTime from, DateTime to) async {
    final data = await _client
        .from('sales')
        .select('id')
        .eq('store_id', storeId)
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String());
    return (data as List).length;
  }
}
