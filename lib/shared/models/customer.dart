/// Represents a customer record belonging to a business.
class Customer {
  final String id;
  final String businessId;
  final String fullName;
  final String primaryPhone;
  final String? alternatePhone;
  final String? email;
  final String? notes;
  final String? source;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.businessId,
    required this.fullName,
    required this.primaryPhone,
    this.alternatePhone,
    this.email,
    this.notes,
    this.source,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isArchived => archivedAt != null;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      fullName: json['full_name'] as String,
      primaryPhone: json['primary_phone'] as String,
      alternatePhone: json['alternate_phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      source: json['source'] as String?,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'full_name': fullName,
      'primary_phone': primaryPhone,
      'alternate_phone': alternatePhone,
      'email': email,
      'notes': notes,
      'source': source,
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
