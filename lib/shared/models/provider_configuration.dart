/// Configuration metadata for WhatsApp Cloud API and SMS Gateways (non-secret credentials).
class ProviderConfiguration {
  final String id;
  final String businessId;
  final String providerType; // 'whatsapp_cloud_api', 'sms_gateway_dlt'
  final String? wabaId;
  final String? phoneNumberId;
  final String? smsSenderId;
  final String? smsEntityId;
  final String? webhookUrl;
  final String connectionStatus; // 'connected', 'disconnected', 'pending'
  final DateTime? lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderConfiguration({
    required this.id,
    required this.businessId,
    required this.providerType,
    this.wabaId,
    this.phoneNumberId,
    this.smsSenderId,
    this.smsEntityId,
    this.webhookUrl,
    this.connectionStatus = 'disconnected',
    this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isConnected => connectionStatus == 'connected';
  bool get isWhatsApp => providerType == 'whatsapp_cloud_api';
  bool get isSms => providerType == 'sms_gateway_dlt';

  ProviderConfiguration copyWith({
    String? id,
    String? businessId,
    String? providerType,
    String? wabaId,
    String? phoneNumberId,
    String? smsSenderId,
    String? smsEntityId,
    String? webhookUrl,
    String? connectionStatus,
    DateTime? lastSyncAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderConfiguration(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      providerType: providerType ?? this.providerType,
      wabaId: wabaId ?? this.wabaId,
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      smsSenderId: smsSenderId ?? this.smsSenderId,
      smsEntityId: smsEntityId ?? this.smsEntityId,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProviderConfiguration.fromJson(Map<String, dynamic> json) {
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

    return ProviderConfiguration(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      providerType: (json['provider_type'] ?? 'whatsapp_cloud_api').toString(),
      wabaId: json['waba_id'] as String?,
      phoneNumberId: json['phone_number_id'] as String?,
      smsSenderId: json['sms_sender_id'] as String?,
      smsEntityId: json['sms_entity_id'] as String?,
      webhookUrl: json['webhook_url'] as String?,
      connectionStatus: (json['connection_status'] ?? 'disconnected')
          .toString(),
      lastSyncAt: parseNullableDate(json['last_sync_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'provider_type': providerType,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'sms_sender_id': smsSenderId,
      'sms_entity_id': smsEntityId,
      'webhook_url': webhookUrl,
      'connection_status': connectionStatus,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
