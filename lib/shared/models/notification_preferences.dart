/// Represents the owner's notification preferences for their business.
class NotificationPreferences {
  final String id;
  final String businessId;
  final bool pushNotificationsEnabled;
  final bool reminderNotificationsEnabled;
  final bool maintenanceNotificationsEnabled;
  final bool amcNotificationsEnabled;
  final bool followupNotificationsEnabled;
  final bool generalNotificationsEnabled;
  final List<int> maintenanceAdvanceDays; // e.g. [7, 1, 0]
  final List<int> amcAdvanceDays; // e.g. [30, 7, 1, 0]
  final bool quietHoursEnabled;
  final String quietHoursStart; // '22:00:00'
  final String quietHoursEnd; // '08:00:00'
  final String preferredNotificationTime; // '09:00:00'
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.id,
    required this.businessId,
    this.pushNotificationsEnabled = true,
    this.reminderNotificationsEnabled = true,
    this.maintenanceNotificationsEnabled = true,
    this.amcNotificationsEnabled = true,
    this.followupNotificationsEnabled = true,
    this.generalNotificationsEnabled = true,
    this.maintenanceAdvanceDays = const [7, 1, 0],
    this.amcAdvanceDays = const [30, 7, 1, 0],
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00:00',
    this.quietHoursEnd = '08:00:00',
    this.preferredNotificationTime = '09:00:00',
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationPreferences copyWith({
    String? id,
    String? businessId,
    bool? pushNotificationsEnabled,
    bool? reminderNotificationsEnabled,
    bool? maintenanceNotificationsEnabled,
    bool? amcNotificationsEnabled,
    bool? followupNotificationsEnabled,
    bool? generalNotificationsEnabled,
    List<int>? maintenanceAdvanceDays,
    List<int>? amcAdvanceDays,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? preferredNotificationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      reminderNotificationsEnabled:
          reminderNotificationsEnabled ?? this.reminderNotificationsEnabled,
      maintenanceNotificationsEnabled:
          maintenanceNotificationsEnabled ??
          this.maintenanceNotificationsEnabled,
      amcNotificationsEnabled:
          amcNotificationsEnabled ?? this.amcNotificationsEnabled,
      followupNotificationsEnabled:
          followupNotificationsEnabled ?? this.followupNotificationsEnabled,
      generalNotificationsEnabled:
          generalNotificationsEnabled ?? this.generalNotificationsEnabled,
      maintenanceAdvanceDays:
          maintenanceAdvanceDays ?? this.maintenanceAdvanceDays,
      amcAdvanceDays: amcAdvanceDays ?? this.amcAdvanceDays,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      preferredNotificationTime:
          preferredNotificationTime ?? this.preferredNotificationTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    List<int> parseDays(dynamic list) {
      if (list is List) {
        return list.map((e) => (e as num).toInt()).toList();
      }
      return const [7, 1, 0];
    }

    return NotificationPreferences(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      pushNotificationsEnabled:
          (json['push_notifications_enabled'] as bool?) ?? true,
      reminderNotificationsEnabled:
          (json['reminder_notifications_enabled'] as bool?) ?? true,
      maintenanceNotificationsEnabled:
          (json['maintenance_notifications_enabled'] as bool?) ?? true,
      amcNotificationsEnabled:
          (json['amc_notifications_enabled'] as bool?) ?? true,
      followupNotificationsEnabled:
          (json['followup_notifications_enabled'] as bool?) ?? true,
      generalNotificationsEnabled:
          (json['general_notifications_enabled'] as bool?) ?? true,
      maintenanceAdvanceDays: json['maintenance_advance_days'] != null
          ? parseDays(json['maintenance_advance_days'])
          : const [7, 1, 0],
      amcAdvanceDays: json['amc_advance_days'] != null
          ? parseDays(json['amc_advance_days'])
          : const [30, 7, 1, 0],
      quietHoursEnabled: (json['quiet_hours_enabled'] as bool?) ?? false,
      quietHoursStart: (json['quiet_hours_start'] as String?) ?? '22:00:00',
      quietHoursEnd: (json['quiet_hours_end'] as String?) ?? '08:00:00',
      preferredNotificationTime:
          (json['preferred_notification_time'] as String?) ?? '09:00:00',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'push_notifications_enabled': pushNotificationsEnabled,
      'reminder_notifications_enabled': reminderNotificationsEnabled,
      'maintenance_notifications_enabled': maintenanceNotificationsEnabled,
      'amc_notifications_enabled': amcNotificationsEnabled,
      'followup_notifications_enabled': followupNotificationsEnabled,
      'general_notifications_enabled': generalNotificationsEnabled,
      'maintenance_advance_days': maintenanceAdvanceDays,
      'amc_advance_days': amcAdvanceDays,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'preferred_notification_time': preferredNotificationTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
