class BatchItem {
  final String id;
  final String itemId;
  final String batchCode;
  final double initialQuantity;
  final double remainingQuantity;
  final double? buyPrice;
  final String? supplierId;
  final DateTime receivedDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final String createdBy;

  // Joined field
  final String? supplierName;

  const BatchItem({
    required this.id,
    required this.itemId,
    required this.batchCode,
    required this.initialQuantity,
    required this.remainingQuantity,
    this.buyPrice,
    this.supplierId,
    required this.receivedDate,
    this.expiryDate,
    required this.createdAt,
    required this.createdBy,
    this.supplierName,
  });

  factory BatchItem.fromJson(Map<String, dynamic> json) {
    return BatchItem(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      batchCode: json['batch_code'] as String,
      initialQuantity: (json['initial_quantity'] as num).toDouble(),
      remainingQuantity: (json['remaining_quantity'] as num).toDouble(),
      buyPrice: json['buy_price'] != null
          ? (json['buy_price'] as num).toDouble()
          : null,
      supplierId: json['supplier_id'] as String?,
      receivedDate: DateTime.parse(json['received_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
      supplierName: json['supplier_name'] as String? ??
          (json['suppliers'] is Map
              ? json['suppliers']['name'] as String?
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'batch_code': batchCode,
        'initial_quantity': initialQuantity,
        'remaining_quantity': remainingQuantity,
        'buy_price': buyPrice,
        'supplier_id': supplierId,
        'received_date': receivedDate.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'created_by': createdBy,
      };

  Map<String, dynamic> toInsertJson() => {
        'item_id': itemId,
        'batch_code': batchCode,
        'initial_quantity': initialQuantity,
        'remaining_quantity': remainingQuantity,
        'buy_price': buyPrice,
        'supplier_id': supplierId,
        'received_date': receivedDate.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'created_by': createdBy,
      };

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntil = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntil > 0 && daysUntil <= 7;
  }

  bool get hasStock => remainingQuantity > 0;

  BatchItem copyWith({double? remainingQuantity}) {
    return BatchItem(
      id: id,
      itemId: itemId,
      batchCode: batchCode,
      initialQuantity: initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      buyPrice: buyPrice,
      supplierId: supplierId,
      receivedDate: receivedDate,
      expiryDate: expiryDate,
      createdAt: createdAt,
      createdBy: createdBy,
      supplierName: supplierName,
    );
  }
}
