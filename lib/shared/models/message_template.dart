/// Represents a reusable message template for customer communications.
class MessageTemplate {
  final String id;
  final String businessId;
  final String name;
  final String
  category; // 'service_update', 'amc_renewal', 'maintenance_reminder', 'payment_reminder', 'custom'
  final String channel; // 'whatsapp', 'sms', 'both'
  final String language; // 'en', 'gu', 'hi'
  final String content;
  final List<String> variables;
  final String? dltTemplateId;
  final bool isSystemDefault;
  final String
  providerStatus; // 'approved', 'pending', 'rejected', 'not_submitted'
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageTemplate({
    required this.id,
    required this.businessId,
    required this.name,
    required this.category,
    this.channel = 'both',
    this.language = 'en',
    required this.content,
    this.variables = const [],
    this.dltTemplateId,
    this.isSystemDefault = false,
    this.providerStatus = 'not_submitted',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Substitutes placeholder variables like `{{customer_name}}` with values from `data`.
  String render(Map<String, dynamic> data) {
    var rendered = content;
    data.forEach((key, value) {
      final placeholder = '{{$key}}';
      rendered = rendered.replaceAll(placeholder, value?.toString() ?? '');
    });
    return rendered;
  }

  MessageTemplate copyWith({
    String? id,
    String? businessId,
    String? name,
    String? category,
    String? channel,
    String? language,
    String? content,
    List<String>? variables,
    String? dltTemplateId,
    bool? isSystemDefault,
    String? providerStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageTemplate(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      category: category ?? this.category,
      channel: channel ?? this.channel,
      language: language ?? this.language,
      content: content ?? this.content,
      variables: variables ?? this.variables,
      dltTemplateId: dltTemplateId ?? this.dltTemplateId,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
      providerStatus: providerStatus ?? this.providerStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    List<String> parseVariables(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return MessageTemplate(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'custom').toString(),
      channel: (json['channel'] ?? 'both').toString(),
      language: (json['language'] ?? 'en').toString(),
      content: (json['content'] ?? '').toString(),
      variables: parseVariables(json['variables']),
      dltTemplateId: json['dlt_template_id'] as String?,
      isSystemDefault: (json['is_system_default'] as bool?) ?? false,
      providerStatus: (json['provider_status'] ?? 'not_submitted').toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'category': category,
      'channel': channel,
      'language': language,
      'content': content,
      'variables': variables,
      if (dltTemplateId != null) 'dlt_template_id': dltTemplateId,
      'is_system_default': isSystemDefault,
      'provider_status': providerStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
