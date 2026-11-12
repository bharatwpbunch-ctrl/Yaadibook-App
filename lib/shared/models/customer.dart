import 'customer_address.dart';

/// Represents a customer record belonging to a business.
class Customer {
  final String id;
  final String businessId;
  final String fullName;
  final String primaryPhone;
  final String? alternatePhone;
  final String? email;
  final String customerType; // 'individual' or 'business'
  final String? notes;
  final String? source;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CustomerAddress> addresses;

  const Customer({
    required this.id,
    required this.businessId,
    required this.fullName,
    required this.primaryPhone,
    this.alternatePhone,
    this.email,
    this.customerType = 'individual',
    this.notes,
    this.source,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.addresses = const [],
  });

  bool get isArchived => archivedAt != null;
  bool get isBusiness => customerType == 'business';
  String get phone => primaryPhone;

  CustomerAddress? get primaryAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  String? get city => primaryAddress?.city;
  String? get area => primaryAddress?.area;

  String get locationSummary {
    final a = area?.trim() ?? '';
    final c = city?.trim() ?? '';
    if (a.isNotEmpty && c.isNotEmpty) return '$a, $c';
    if (a.isNotEmpty) return a;
    if (c.isNotEmpty) return c;
    return '';
  }

  /// Calculates up to 2 uppercase initials for avatars (e.g. "Bharat Patel" -> "BP").
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'C';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      final combined = '$first$second'.toUpperCase();
      return combined.isNotEmpty ? combined : 'C';
    }
    return trimmed[0].toUpperCase();
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    List<CustomerAddress> loadedAddresses = const [];
    if (json['customer_addresses'] != null &&
        json['customer_addresses'] is List) {
      loadedAddresses = (json['customer_addresses'] as List)
          .map((a) => CustomerAddress.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return Customer(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      fullName: json['full_name'] as String,
      primaryPhone: json['primary_phone'] as String,
      alternatePhone: json['alternate_phone'] as String?,
      email: json['email'] as String?,
      customerType: (json['customer_type'] as String?) ?? 'individual',
      notes: json['notes'] as String?,
      source: json['source'] as String?,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      addresses: loadedAddresses,
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
      'customer_type': customerType,
      'notes': notes,
      'source': source,
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? businessId,
    String? fullName,
    String? primaryPhone,
    String? alternatePhone,
    String? email,
    String? customerType,
    String? notes,
    String? source,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CustomerAddress>? addresses,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      fullName: fullName ?? this.fullName,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      customerType: customerType ?? this.customerType,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addresses: addresses ?? this.addresses,
    );
  }
}
