/// Represents an address associated with a customer.
class CustomerAddress {
  final String id;
  final String businessId;
  final String customerId;
  final String addressLabel;
  final String addressLine1;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String? landmark;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerAddress({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.addressLabel = 'Main',
    required this.addressLine1,
    this.addressLine2,
    required this.area,
    required this.city,
    this.state = 'Gujarat',
    required this.postalCode,
    this.landmark,
    this.isDefault = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formats the address into a human-readable single-line or multi-line string.
  String get formattedAddress {
    final parts = <String>[];
    if (addressLine1.trim().isNotEmpty) parts.add(addressLine1.trim());
    if (addressLine2 != null && addressLine2!.trim().isNotEmpty) {
      parts.add(addressLine2!.trim());
    }
    if (area.trim().isNotEmpty) parts.add(area.trim());
    if (city.trim().isNotEmpty) parts.add(city.trim());
    if (state.trim().isNotEmpty) parts.add(state.trim());
    if (postalCode.trim().isNotEmpty) parts.add(postalCode.trim());
    return parts.join(', ');
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      addressLabel: (json['address_label'] as String?) ?? 'Main',
      addressLine1: (json['address_line_1'] as String?) ?? '',
      addressLine2: json['address_line_2'] as String?,
      area: (json['area'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? 'Gujarat',
      postalCode: (json['postal_code'] as String?) ?? '',
      landmark: json['landmark'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'address_label': addressLabel,
      'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      'area': area,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      if (landmark != null) 'landmark': landmark,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
