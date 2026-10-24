import '../../core/enums/transaction_type.dart';

class StockTransaction {
  final String id;
  final String storeId;
  final String itemId;
  final String? batchId;
  final TransactionType type;
  final double quantity;
  final String? reason;
  final String? notes;
  final String performedBy;
  final DateTime createdAt;

  // Joined fields
  final String? itemName;
  final String? itemUnit;
  final String? batchCode;
  final String? performedByName;

  const StockTransaction({
    required this.id,
    required this.storeId,
    required this.itemId,
    this.batchId,
    required this.type,
    required this.quantity,
    this.reason,
    this.notes,
    required this.performedBy,
    required this.createdAt,
    this.itemName,
    this.itemUnit,
    this.batchCode,
    this.performedByName,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      itemId: json['item_id'] as String,
      batchId: json['batch_id'] as String?,
      type: TransactionType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      performedBy: json['performed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemName: json['item_name'] as String? ??
          (json['items'] is Map ? json['items']['name'] as String? : null),
      itemUnit: json['item_unit'] as String? ??
          (json['items'] is Map ? json['items']['unit'] as String? : null),
      batchCode: json['batch_code'] as String? ??
          (json['batches'] is Map
              ? json['batches']['batch_code'] as String?
              : null),
      performedByName: json['performed_by_name'] as String? ??
          (json['profiles'] is Map
              ? json['profiles']['full_name'] as String?
              : null),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'store_id': storeId,
        'item_id': itemId,
        'batch_id': batchId,
        'type': type.name,
        'quantity': quantity,
        'reason': reason,
        'notes': notes,
        'performed_by': performedBy,
      };

  /// Returns "+500 g" or "-20 ml" depending on type.
  String get quantityLabel {
    final prefix = type == TransactionType.restock ? '+' : '-';
    return '$prefix${quantity.toStringAsFixed(0)} ${itemUnit ?? ''}';
  }

  /// Returns a brief description like "Restok Robusta +500 g"
  String get summary =>
      '${type.label} ${itemName ?? 'Barang'} ${quantityLabel.trim()}';
}
