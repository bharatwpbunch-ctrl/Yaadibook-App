/// Represents an in-app notification in Yaadibook's Notification Centre.
class InAppNotification {
  final String id;
  final String businessId;
  final String? userId;
  final String? reminderId;
  final String title;
  final String body;
  final String
  category; // 'maintenance', 'amc', 'followup', 'general', 'system'
  final bool isRead;
  final DateTime? readAt;
  final String
  providerStatus; // 'queued', 'sent_to_provider', 'provider_accepted', 'delivered', 'failed'
  final String? providerMessageId;
  final String? failureReason;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const InAppNotification({
    required this.id,
    required this.businessId,
    this.userId,
    this.reminderId,
    required this.title,
    required this.body,
    this.category = 'general',
    this.isRead = false,
    this.readAt,
    this.providerStatus = 'queued',
    this.providerMessageId,
    this.failureReason,
    this.payload = const {},
    required this.createdAt,
  });

  InAppNotification copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? reminderId,
    String? title,
    String? body,
    String? category,
    bool? isRead,
    DateTime? readAt,
    String? providerStatus,
    String? providerMessageId,
    String? failureReason,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      providerStatus: providerStatus ?? this.providerStatus,
      providerMessageId: providerMessageId ?? this.providerMessageId,
      failureReason: failureReason ?? this.failureReason,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String?,
      reminderId: json['reminder_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      category: (json['category'] as String?) ?? 'general',
      isRead: (json['is_read'] as bool?) ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      providerStatus: (json['provider_status'] as String?) ?? 'queued',
      providerMessageId: json['provider_message_id'] as String?,
      failureReason: json['failure_reason'] as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'reminder_id': reminderId,
      'title': title,
      'body': body,
      'category': category,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'provider_status': providerStatus,
      'provider_message_id': providerMessageId,
      'failure_reason': failureReason,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
