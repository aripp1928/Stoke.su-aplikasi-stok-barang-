/// Types of stock transactions.
enum TransactionType {
  restock('Restok'),
  usage('Pemakaian'),
  sale('Penjualan'),
  adjustment('Penyesuaian');

  const TransactionType(this.label);
  final String label;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => TransactionType.adjustment,
    );
  }
}

/// Reasons for stock usage.
enum UsageReason {
  kebutuhan('Kebutuhan'),
  tumpah('Tumpah'),
  rusak('Rusak'),
  basi('Basi'),
  lainnya('Lainnya');

  const UsageReason(this.label);
  final String label;

  static UsageReason fromString(String value) {
    return UsageReason.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UsageReason.lainnya,
    );
  }
}
