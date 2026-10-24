import 'package:flutter/foundation.dart';
import '../data/models/recipe.dart';
import '../data/repositories/recipe_repository.dart';

class RecipeState extends ChangeNotifier {
  final RecipeRepository _repo = RecipeRepository();

  List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Recipe> get recipes {
    if (_searchQuery.isEmpty) return _recipes;
    return _recipes
        .where(
            (r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
  List<Recipe> get allRecipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecipes(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _recipes = await _repo.getRecipes(storeId);
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat resep';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecipeDetail(String recipeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedRecipe = await _repo.getRecipe(recipeId);
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat detail resep';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRecipe(
      Recipe recipe, List<RecipeIngredient> ingredients) async {
    _isLoading = true;
    notifyListeners();
    try {
      final created = await _repo.createRecipe(recipe, ingredients);
      _recipes.add(created);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menambah resep';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRecipe(
      Recipe recipe, List<RecipeIngredient> ingredients) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _repo.updateRecipe(recipe, ingredients);
      final idx = _recipes.indexWhere((r) => r.id == recipe.id);
      if (idx >= 0) _recipes[idx] = updated;
      _selectedRecipe = updated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal mengubah resep';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRecipe(String recipeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.deleteRecipe(recipeId);
      _recipes.removeWhere((r) => r.id == recipeId);
      if (_selectedRecipe?.id == recipeId) _selectedRecipe = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus resep';
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
