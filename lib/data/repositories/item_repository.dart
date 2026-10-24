import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';
import '../services/supabase_service.dart';

class ItemRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch all items for a store, with current_stock calculated from batches.
  Future<List<Item>> getItems(String storeId) async {
    final data = await _client.rpc('get_items_with_stock', params: {
      'p_store_id': storeId,
    });
    return (data as List).map((e) => Item.fromJson(e)).toList();
  }

  /// Fallback: fetch items without stock calculation (simpler query).
  Future<List<Item>> getItemsSimple(String storeId) async {
    final data = await _client
        .from('items')
        .select()
        .eq('store_id', storeId)
        .order('name');
    return (data as List).map((e) => Item.fromJson(e)).toList();
  }

  /// Get a single item by id.
  Future<Item> getItem(String itemId) async {
    final data = await _client
        .from('items')
        .select()
        .eq('id', itemId)
        .single();
    return Item.fromJson(data);
  }

  /// Create a new item.
  Future<Item> createItem(Item item) async {
    final data = await _client
        .from('items')
        .insert(item.toInsertJson())
        .select()
        .single();
    return Item.fromJson(data);
  }

  /// Update an existing item.
  Future<Item> updateItem(Item item) async {
    final data = await _client
        .from('items')
        .update(item.toUpdateJson())
        .eq('id', item.id)
        .select()
        .single();
    return Item.fromJson(data);
  }

  /// Delete an item and its related data.
  Future<void> deleteItem(String itemId) async {
    await _client.from('items').delete().eq('id', itemId);
  }

  /// Get items filtered by category.
  Future<List<Item>> getItemsByCategory(
      String storeId, String category) async {
    final data = await _client
        .from('items')
        .select()
        .eq('store_id', storeId)
        .eq('category', category)
        .order('name');
    return (data as List).map((e) => Item.fromJson(e)).toList();
  }

  /// Search items by name.
  Future<List<Item>> searchItems(String storeId, String query) async {
    final data = await _client
        .from('items')
        .select()
        .eq('store_id', storeId)
        .ilike('name', '%$query%')
        .order('name');
    return (data as List).map((e) => Item.fromJson(e)).toList();
  }

  /// Get all unique categories for a store.
  Future<List<String>> getCategories(String storeId) async {
    final data = await _client
        .from('items')
        .select('category')
        .eq('store_id', storeId);
    final categories = (data as List)
        .map((e) => e['category'] as String)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}
