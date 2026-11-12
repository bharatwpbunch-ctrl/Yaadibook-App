/// Daily and aggregated usage and cost tracking for WhatsApp and SMS communications.
class CommunicationUsage {
  final String id;
  final String businessId;
  final String channel; // 'whatsapp', 'sms'
  final String
  category; // 'transactional', 'service_update', 'amc_renewal', 'marketing'
  final int messageCount;
  final double totalCostInr;
  final DateTime usageDate;

  const CommunicationUsage({
    required this.id,
    required this.businessId,
    required this.channel,
    required this.category,
    this.messageCount = 0,
    this.totalCostInr = 0.0,
    required this.usageDate,
  });

  factory CommunicationUsage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    return CommunicationUsage(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      channel: (json['channel'] ?? 'whatsapp').toString(),
      category: (json['category'] ?? 'transactional').toString(),
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      totalCostInr: (json['total_cost_inr'] as num?)?.toDouble() ?? 0.0,
      usageDate: parseDate(json['usage_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'channel': channel,
      'category': category,
      'message_count': messageCount,
      'total_cost_inr': totalCostInr,
      'usage_date': usageDate.toIso8601String().split('T').first,
    };
  }
}
