/// Represents a batch or bulk communication campaign.
class CommunicationCampaign {
  final String id;
  final String businessId;
  final String? templateId;
  final String title;
  final String channel; // 'whatsapp', 'sms'
  final String
  category; // 'service_update', 'amc_renewal', 'festive_offer', 'general_announcement'
  final String
  status; // 'draft', 'scheduled', 'processing', 'completed', 'failed', 'cancelled'
  final int totalRecipients;
  final int successfulCount;
  final int failedCount;
  final double estimatedCostInr;
  final double actualCostInr;
  final Map<String, dynamic> filterCriteria;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunicationCampaign({
    required this.id,
    required this.businessId,
    this.templateId,
    required this.title,
    required this.channel,
    this.category = 'general_announcement',
    this.status = 'draft',
    this.totalRecipients = 0,
    this.successfulCount = 0,
    this.failedCount = 0,
    this.estimatedCostInr = 0.0,
    this.actualCostInr = 0.0,
    this.filterCriteria = const {},
    this.scheduledFor,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isDraft => status == 'draft';

  double get progress {
    if (totalRecipients == 0) return 0.0;
    return (successfulCount + failedCount) / totalRecipients;
  }

  CommunicationCampaign copyWith({
    String? id,
    String? businessId,
    String? templateId,
    String? title,
    String? channel,
    String? category,
    String? status,
    int? totalRecipients,
    int? successfulCount,
    int? failedCount,
    double? estimatedCostInr,
    double? actualCostInr,
    Map<String, dynamic>? filterCriteria,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunicationCampaign(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      channel: channel ?? this.channel,
      category: category ?? this.category,
      status: status ?? this.status,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      successfulCount: successfulCount ?? this.successfulCount,
      failedCount: failedCount ?? this.failedCount,
      estimatedCostInr: estimatedCostInr ?? this.estimatedCostInr,
      actualCostInr: actualCostInr ?? this.actualCostInr,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CommunicationCampaign.fromJson(Map<String, dynamic> json) {
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

    return CommunicationCampaign(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      templateId: json['template_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      channel: (json['channel'] ?? 'whatsapp').toString(),
      category: (json['category'] ?? 'general_announcement').toString(),
      status: (json['status'] ?? 'draft').toString(),
      totalRecipients: (json['total_recipients'] as num?)?.toInt() ?? 0,
      successfulCount: (json['successful_count'] as num?)?.toInt() ?? 0,
      failedCount: (json['failed_count'] as num?)?.toInt() ?? 0,
      estimatedCostInr: (json['estimated_cost_inr'] as num?)?.toDouble() ?? 0.0,
      actualCostInr: (json['actual_cost_inr'] as num?)?.toDouble() ?? 0.0,
      filterCriteria:
          json['filter_criteria'] as Map<String, dynamic>? ?? const {},
      scheduledFor: parseNullableDate(json['scheduled_for']),
      startedAt: parseNullableDate(json['started_at']),
      completedAt: parseNullableDate(json['completed_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'template_id': templateId,
      'title': title,
      'channel': channel,
      'category': category,
      'status': status,
      'total_recipients': totalRecipients,
      'successful_count': successfulCount,
      'failed_count': failedCount,
      'estimated_cost_inr': estimatedCostInr,
      'actual_cost_inr': actualCostInr,
      'filter_criteria': filterCriteria,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Represents an individual recipient inside a campaign.
class CampaignRecipient {
  final String id;
  final String campaignId;
  final String customerId;
  final String? customerName;
  final String customerPhone;
  final String
  submissionStatus; // 'pending', 'submitted', 'delivered', 'failed', 'skipped_opted_out'
  final String? providerMessageId;
  final String? errorMessage;
  final DateTime? dispatchedAt;

  const CampaignRecipient({
    required this.id,
    required this.campaignId,
    required this.customerId,
    this.customerName,
    required this.customerPhone,
    this.submissionStatus = 'pending',
    this.providerMessageId,
    this.errorMessage,
    this.dispatchedAt,
  });

  factory CampaignRecipient.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal();
    }

    String? custName;
    if (json['customers'] is Map<String, dynamic>) {
      custName = (json['customers'] as Map<String, dynamic>)['full_name'];
    }

    return CampaignRecipient(
      id: (json['id'] ?? '').toString(),
      campaignId: (json['campaign_id'] ?? '').toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      customerName: custName ?? (json['customer_name'] as String?),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      submissionStatus: (json['submission_status'] ?? 'pending').toString(),
      providerMessageId: json['provider_message_id'] as String?,
      errorMessage: json['error_message'] as String?,
      dispatchedAt: parseNullableDate(json['dispatched_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      'customer_phone': customerPhone,
      'submission_status': submissionStatus,
      if (providerMessageId != null) 'provider_message_id': providerMessageId,
      if (errorMessage != null) 'error_message': errorMessage,
      if (dispatchedAt != null)
        'dispatched_at': dispatchedAt?.toIso8601String(),
    };
  }
}
