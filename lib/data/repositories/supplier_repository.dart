import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';
import '../services/supabase_service.dart';

class SupplierRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<Supplier>> getSuppliers(String storeId) async {
    final data = await _client
        .from('suppliers')
        .select()
        .eq('store_id', storeId)
        .order('name');
    return (data as List).map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> getSupplier(String supplierId) async {
    final data = await _client
        .from('suppliers')
        .select()
        .eq('id', supplierId)
        .single();
    return Supplier.fromJson(data);
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    final data = await _client
        .from('suppliers')
        .insert(supplier.toInsertJson())
        .select()
        .single();
    return Supplier.fromJson(data);
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    final data = await _client
        .from('suppliers')
        .update(supplier.toUpdateJson())
        .eq('id', supplier.id)
        .select()
        .single();
    return Supplier.fromJson(data);
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _client.from('suppliers').delete().eq('id', supplierId);
  }

  /// Get purchase history for a supplier.
  Future<List<Map<String, dynamic>>> getPurchaseHistory(
      String supplierId) async {
    final data = await _client
        .from('batches')
        .select('*, items(name, unit)')
        .eq('supplier_id', supplierId)
        .order('received_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Supplier>> searchSuppliers(
      String storeId, String query) async {
    final data = await _client
        .from('suppliers')
        .select()
        .eq('store_id', storeId)
        .or('name.ilike.%$query%,phone.ilike.%$query%')
        .order('name');
    return (data as List).map((e) => Supplier.fromJson(e)).toList();
  }
}
