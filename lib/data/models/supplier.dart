class Supplier {
  final String id;
  final String storeId;
  final String name;
  final String? phone;
  final String? address;
  final String? contactPerson;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.storeId,
    required this.name,
    this.phone,
    this.address,
    this.contactPerson,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      contactPerson: json['contact_person'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'name': name,
        'phone': phone,
        'address': address,
        'contact_person': contactPerson,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'store_id': storeId,
        'name': name,
        'phone': phone,
        'address': address,
        'contact_person': contactPerson,
        'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'phone': phone,
        'address': address,
        'contact_person': contactPerson,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Display string: "Bumi Roastery · 0812-3456-7891"
  String get displayInfo {
    if (phone != null && phone!.isNotEmpty) return '$name · $phone';
    return name;
  }

  Supplier copyWith({
    String? name,
    String? phone,
    String? address,
    String? contactPerson,
    String? notes,
  }) {
    return Supplier(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
