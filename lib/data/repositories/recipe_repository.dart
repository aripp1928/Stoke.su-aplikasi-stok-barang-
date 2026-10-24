import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';

class RecipeRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch all recipes for a store with ingredients.
  Future<List<Recipe>> getRecipes(String storeId) async {
    final data = await _client
        .from('recipes')
        .select('*, recipe_ingredients(*, items(name))')
        .eq('store_id', storeId)
        .order('name');
    return (data as List).map((e) => Recipe.fromJson(e)).toList();
  }

  /// Get a single recipe with ingredients.
  Future<Recipe> getRecipe(String recipeId) async {
    final data = await _client
        .from('recipes')
        .select('*, recipe_ingredients(*, items(name))')
        .eq('id', recipeId)
        .single();
    return Recipe.fromJson(data);
  }

  /// Create a recipe and its ingredients.
  Future<Recipe> createRecipe(
      Recipe recipe, List<RecipeIngredient> ingredients) async {
    final recipeData = await _client
        .from('recipes')
        .insert(recipe.toInsertJson())
        .select()
        .single();
    final newRecipe = Recipe.fromJson(recipeData);

    // Insert ingredients
    if (ingredients.isNotEmpty) {
      final ingredientInserts = ingredients
          .map((i) => {
                'recipe_id': newRecipe.id,
                'item_id': i.itemId,
                'quantity': i.quantity,
                'unit': i.unit,
              })
          .toList();
      await _client.from('recipe_ingredients').insert(ingredientInserts);
    }

    return getRecipe(newRecipe.id);
  }

  /// Update a recipe and replace its ingredients.
  Future<Recipe> updateRecipe(
      Recipe recipe, List<RecipeIngredient> ingredients) async {
    await _client
        .from('recipes')
        .update(recipe.toUpdateJson())
        .eq('id', recipe.id);

    // Replace ingredients
    await _client
        .from('recipe_ingredients')
        .delete()
        .eq('recipe_id', recipe.id);

    if (ingredients.isNotEmpty) {
      final ingredientInserts = ingredients
          .map((i) => {
                'recipe_id': recipe.id,
                'item_id': i.itemId,
                'quantity': i.quantity,
                'unit': i.unit,
              })
          .toList();
      await _client.from('recipe_ingredients').insert(ingredientInserts);
    }

    return getRecipe(recipe.id);
  }

  /// Delete a recipe and its ingredients.
  Future<void> deleteRecipe(String recipeId) async {
    await _client.from('recipes').delete().eq('id', recipeId);
  }

  /// Search recipes by name.
  Future<List<Recipe>> searchRecipes(String storeId, String query) async {
    final data = await _client
        .from('recipes')
        .select('*, recipe_ingredients(*, items(name))')
        .eq('store_id', storeId)
        .ilike('name', '%$query%')
        .order('name');
    return (data as List).map((e) => Recipe.fromJson(e)).toList();
  }
}
