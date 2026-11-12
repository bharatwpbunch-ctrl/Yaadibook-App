/// Represents a chronological audit/history item for a service entry.
class ServiceActivity {
  final String id;
  final String businessId;
  final String serviceId;
  final String
  activityType; // 'created', 'status_changed', 'details_updated', 'attachment_added', 'attachment_removed', 'completed', 'cancelled', 'resumed'
  final String title;
  final String? description;
  final String? oldStatus;
  final String? newStatus;
  final String? actorUserId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ServiceActivity({
    required this.id,
    required this.businessId,
    required this.serviceId,
    required this.activityType,
    required this.title,
    this.description,
    this.oldStatus,
    this.newStatus,
    this.actorUserId,
    this.metadata = const {},
    required this.createdAt,
  });

  factory ServiceActivity.fromJson(Map<String, dynamic> json) {
    return ServiceActivity(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      serviceId: json['service_id'] as String,
      activityType: json['activity_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String?,
      actorUserId: json['actor_user_id'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'service_id': serviceId,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'old_status': oldStatus,
      'new_status': newStatus,
      'actor_user_id': actorUserId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
