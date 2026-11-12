/// Represents a record of communication sent or initiated with a customer.
class CommunicationLog {
  final String id;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? serviceId;
  final String? maintenanceOccurrenceId;
  final String? amcContractId;
  final String? templateId;
  final String channel; // 'whatsapp', 'sms'
  final String messageType; // 'manual', 'cloud_api', 'bulk_campaign'
  final String recipientPhone;
  final String? recipientName;
  final String direction; // 'outbound', 'inbound'
  final String
  status; // 'draft', 'opened_in_app', 'queued', 'submitted', 'accepted', 'delivered', 'read', 'failed', 'cancelled'
  final String messageBody;
  final Map<String, dynamic>? providerResponse;
  final double cost;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunicationLog({
    required this.id,
    required this.businessId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.serviceId,
    this.maintenanceOccurrenceId,
    this.amcContractId,
    this.templateId,
    required this.channel,
    this.messageType = 'manual',
    required this.recipientPhone,
    this.recipientName,
    this.direction = 'outbound',
    required this.status,
    required this.messageBody,
    this.providerResponse,
    this.cost = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isManual => messageType == 'manual';
  bool get wasOpenedInApp => status == 'opened_in_app';
  bool get isDelivered => status == 'delivered' || status == 'read';
  bool get isFailed => status == 'failed';
  bool get isWhatsApp => channel == 'whatsapp';
  bool get isSms => channel == 'sms';

  CommunicationLog copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? serviceId,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? templateId,
    String? channel,
    String? messageType,
    String? recipientPhone,
    String? recipientName,
    String? direction,
    String? status,
    String? messageBody,
    Map<String, dynamic>? providerResponse,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunicationLog(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceId: serviceId ?? this.serviceId,
      maintenanceOccurrenceId:
          maintenanceOccurrenceId ?? this.maintenanceOccurrenceId,
      amcContractId: amcContractId ?? this.amcContractId,
      templateId: templateId ?? this.templateId,
      channel: channel ?? this.channel,
      messageType: messageType ?? this.messageType,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      messageBody: messageBody ?? this.messageBody,
      providerResponse: providerResponse ?? this.providerResponse,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CommunicationLog.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    String? custName;
    String? custPhone;
    if (json['customers'] is Map<String, dynamic>) {
      final cust = json['customers'] as Map<String, dynamic>;
      custName = cust['full_name'] as String?;
      custPhone = cust['primary_phone'] as String?;
    }

    return CommunicationLog(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      customerId: json['customer_id']?.toString(),
      customerName: custName ?? (json['customer_name'] as String?),
      customerPhone: custPhone ?? (json['customer_phone'] as String?),
      serviceId: json['service_id']?.toString(),
      maintenanceOccurrenceId: json['maintenance_occurrence_id']?.toString(),
      amcContractId: json['amc_contract_id']?.toString(),
      templateId: json['template_id']?.toString(),
      channel: (json['channel'] ?? 'whatsapp').toString(),
      messageType: (json['message_type'] ?? 'manual').toString(),
      recipientPhone: (json['recipient_phone'] ?? '').toString(),
      recipientName: json['recipient_name'] as String?,
      direction: (json['direction'] ?? 'outbound').toString(),
      status: (json['status'] ?? 'opened_in_app').toString(),
      messageBody: (json['message_body'] ?? '').toString(),
      providerResponse: json['provider_response'] as Map<String, dynamic>?,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'service_id': serviceId,
      'maintenance_occurrence_id': maintenanceOccurrenceId,
      'amc_contract_id': amcContractId,
      'template_id': templateId,
      'channel': channel,
      'message_type': messageType,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'direction': direction,
      'status': status,
      'message_body': messageBody,
      if (providerResponse != null) 'provider_response': providerResponse,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
