class Item {
  final String id;
  final String storeId;
  final String name;
  final String category;
  final String unit; // g, ml, pcs
  final double minStock;
  final double? buyPrice;
  final String? supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  // Calculated field — sum of remaining batch quantities
  final double currentStock;

  const Item({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.unit,
    required this.minStock,
    this.buyPrice,
    this.supplierId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.currentStock = 0,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      minStock: (json['min_stock'] as num).toDouble(),
      buyPrice: json['buy_price'] != null
          ? (json['buy_price'] as num).toDouble()
          : null,
      supplierId: json['supplier_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
      currentStock: json['current_stock'] != null
          ? (json['current_stock'] as num).toDouble()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'name': name,
        'category': category,
        'unit': unit,
        'min_stock': minStock,
        'buy_price': buyPrice,
        'supplier_id': supplierId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
      };

  /// Map for inserting (without calculated fields and timestamps).
  Map<String, dynamic> toInsertJson() => {
        'store_id': storeId,
        'name': name,
        'category': category,
        'unit': unit,
        'min_stock': minStock,
        'buy_price': buyPrice,
        'supplier_id': supplierId,
        'created_by': createdBy,
      };

  /// Map for updating.
  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category,
        'unit': unit,
        'min_stock': minStock,
        'buy_price': buyPrice,
        'supplier_id': supplierId,
        'updated_at': DateTime.now().toIso8601String(),
      };

  bool get isLowStock => currentStock > 0 && currentStock <= minStock;
  bool get isEmpty => currentStock <= 0;
  bool get isSafe => currentStock > minStock;

  String get stockStatusLabel {
    if (isEmpty) return 'Habis';
    if (isLowStock) return 'Menipis';
    return 'Aman';
  }

  Item copyWith({
    String? name,
    String? category,
    String? unit,
    double? minStock,
    double? buyPrice,
    String? supplierId,
    double? currentStock,
  }) {
    return Item(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      buyPrice: buyPrice ?? this.buyPrice,
      supplierId: supplierId ?? this.supplierId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      currentStock: currentStock ?? this.currentStock,
    );
  }
}
