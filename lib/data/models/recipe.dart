class Recipe {
  final String id;
  final String storeId;
  final String name;
  final double sellPrice;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.storeId,
    required this.name,
    required this.sellPrice,
    this.ingredients = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredientsList = json['recipe_ingredients'] as List<dynamic>?;
    return Recipe(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      sellPrice: (json['sell_price'] as num).toDouble(),
      ingredients: ingredientsList != null
          ? ingredientsList
              .map((e) =>
                  RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'name': name,
        'sell_price': sellPrice,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'store_id': storeId,
        'name': name,
        'sell_price': sellPrice,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'sell_price': sellPrice,
        'updated_at': DateTime.now().toIso8601String(),
      };

  double get sellingPrice => sellPrice;
  String get portion => '1 cup';

  /// Short summary of ingredients: "1 bahan · Susu, Gula Aren"
  String get ingredientSummary {
    if (ingredients.isEmpty) return 'Belum ada bahan';
    final names = ingredients.map((e) => e.itemName ?? 'Bahan').join(', ');
    return '${ingredients.length} bahan · $names';
  }

  Recipe copyWith({
    String? name,
    double? sellPrice,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      sellPrice: sellPrice ?? this.sellPrice,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class RecipeIngredient {
  final String id;
  final String recipeId;
  final String itemId;
  final double quantity;
  final String unit;

  // Joined
  final String? itemName;

  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.itemId,
    required this.quantity,
    required this.unit,
    this.itemName,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      itemId: json['item_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      itemName: json['item_name'] as String? ??
          (json['items'] is Map ? json['items']['name'] as String? : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipe_id': recipeId,
        'item_id': itemId,
        'quantity': quantity,
        'unit': unit,
      };

  Map<String, dynamic> toInsertJson() => {
        'recipe_id': recipeId,
        'item_id': itemId,
        'quantity': quantity,
        'unit': unit,
      };
}
