/// Tracks messaging consent, channel opt-ins, and opt-out preferences for a customer.
class CustomerMessagingPreference {
  final String id;
  final String businessId;
  final String customerId;
  final bool whatsappOptIn;
  final bool smsOptIn;
  final bool marketingConsent;
  final String consentSource; // 'in_person', 'verbal', 'electronic', 'default'
  final bool isOptedOut;
  final DateTime? optedOutAt;
  final String? optOutReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerMessagingPreference({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.whatsappOptIn = true,
    this.smsOptIn = true,
    this.marketingConsent = false,
    this.consentSource = 'default',
    this.isOptedOut = false,
    this.optedOutAt,
    this.optOutReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canReceiveTransactionalWhatsApp => !isOptedOut && whatsappOptIn;
  bool get canReceiveTransactionalSms => !isOptedOut && smsOptIn;
  bool get canReceiveMarketing => !isOptedOut && marketingConsent;

  CustomerMessagingPreference copyWith({
    String? id,
    String? businessId,
    String? customerId,
    bool? whatsappOptIn,
    bool? smsOptIn,
    bool? marketingConsent,
    String? consentSource,
    bool? isOptedOut,
    DateTime? optedOutAt,
    String? optOutReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerMessagingPreference(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      whatsappOptIn: whatsappOptIn ?? this.whatsappOptIn,
      smsOptIn: smsOptIn ?? this.smsOptIn,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      consentSource: consentSource ?? this.consentSource,
      isOptedOut: isOptedOut ?? this.isOptedOut,
      optedOutAt: optedOutAt ?? this.optedOutAt,
      optOutReason: optOutReason ?? this.optOutReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerMessagingPreference.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal();
    }

    return CustomerMessagingPreference(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      whatsappOptIn: (json['whatsapp_opt_in'] as bool?) ?? true,
      smsOptIn: (json['sms_opt_in'] as bool?) ?? true,
      marketingConsent: (json['marketing_consent'] as bool?) ?? false,
      consentSource: (json['consent_source'] ?? 'default').toString(),
      isOptedOut: (json['is_opted_out'] as bool?) ?? false,
      optedOutAt: parseNullableDate(json['opted_out_at']),
      optOutReason: json['opt_out_reason'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'whatsapp_opt_in': whatsappOptIn,
      'sms_opt_in': smsOptIn,
      'marketing_consent': marketingConsent,
      'consent_source': consentSource,
      'is_opted_out': isOptedOut,
      'opted_out_at': optedOutAt?.toIso8601String(),
      'opt_out_reason': optOutReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
