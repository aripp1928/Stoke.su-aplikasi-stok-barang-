class Sale {
  final String id;
  final String storeId;
  final String? recipeId;
  final String productName;
  final int quantity;
  final double totalPrice;
  final String performedBy;
  final DateTime createdAt;

  // Joined
  final String? performedByName;
  final List<SaleDeduction> deductions;

  const Sale({
    required this.id,
    required this.storeId,
    this.recipeId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.performedBy,
    required this.createdAt,
    this.performedByName,
    this.deductions = const [],
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final deductionsList = json['sale_deductions'] as List<dynamic>?;
    return Sale(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      recipeId: json['recipe_id'] as String?,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      performedBy: json['performed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      performedByName: json['performed_by_name'] as String? ??
          (json['profiles'] is Map
              ? json['profiles']['full_name'] as String?
              : null),
      deductions: deductionsList != null
          ? deductionsList
              .map((e) => SaleDeduction.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'store_id': storeId,
        'recipe_id': recipeId,
        'product_name': productName,
        'quantity': quantity,
        'total_price': totalPrice,
        'performed_by': performedBy,
      };
}

class SaleDeduction {
  final String id;
  final String saleId;
  final String itemId;
  final String? batchId;
  final double quantityDeducted;
  final DateTime createdAt;

  // Joined
  final String? itemName;
  final String? itemUnit;
  final String? batchCode;

  const SaleDeduction({
    required this.id,
    required this.saleId,
    required this.itemId,
    this.batchId,
    required this.quantityDeducted,
    required this.createdAt,
    this.itemName,
    this.itemUnit,
    this.batchCode,
  });

  factory SaleDeduction.fromJson(Map<String, dynamic> json) {
    return SaleDeduction(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      itemId: json['item_id'] as String,
      batchId: json['batch_id'] as String?,
      quantityDeducted: (json['quantity_deducted'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      itemName: json['item_name'] as String? ??
          (json['items'] is Map ? json['items']['name'] as String? : null),
      itemUnit: json['item_unit'] as String? ??
          (json['items'] is Map ? json['items']['unit'] as String? : null),
      batchCode: json['batch_code'] as String? ??
          (json['batches'] is Map
              ? json['batches']['batch_code'] as String?
              : null),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'sale_id': saleId,
        'item_id': itemId,
        'batch_id': batchId,
        'quantity_deducted': quantityDeducted,
      };
}
