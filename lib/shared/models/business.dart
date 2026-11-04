/// Represents a business workspace in Yaadibook.
class Business {
  final String id;
  final String ownerUserId;
  final String businessName;
  final String businessCategory;
  final String? businessDescription;
  final String phone;
  final String? email;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? logoPath;
  final String currencyCode;
  final String timezone;
  final String preferredLanguage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.ownerUserId,
    required this.businessName,
    required this.businessCategory,
    this.businessDescription,
    required this.phone,
    this.email,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state = 'Gujarat',
    required this.postalCode,
    this.country = 'India',
    this.logoPath,
    this.currencyCode = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.preferredLanguage = 'en',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      businessName: json['business_name'] as String,
      businessCategory: json['business_category'] as String,
      businessDescription: json['business_description'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      addressLine1: json['address_line_1'] as String,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String,
      state: (json['state'] as String?) ?? 'Gujarat',
      postalCode: json['postal_code'] as String,
      country: (json['country'] as String?) ?? 'India',
      logoPath: json['logo_path'] as String?,
      currencyCode: (json['currency_code'] as String?) ?? 'INR',
      timezone: (json['timezone'] as String?) ?? 'Asia/Kolkata',
      preferredLanguage: (json['preferred_language'] as String?) ?? 'en',
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'business_name': businessName,
      'business_category': businessCategory,
      'business_description': businessDescription,
      'phone': phone,
      'email': email,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'logo_path': logoPath,
      'currency_code': currencyCode,
      'timezone': timezone,
      'preferred_language': preferredLanguage,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

