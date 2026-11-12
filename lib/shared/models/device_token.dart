/// Represents a registered FCM device push token for an authenticated business owner.
class DeviceToken {
  final String id;
  final String userId;
  final String businessId;
  final String fcmToken;
  final String platform; // 'android', 'ios', 'web'
  final String? deviceName;
  final String? deviceId;
  final bool isActive;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceToken({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.fcmToken,
    this.platform = 'android',
    this.deviceName,
    this.deviceId,
    this.isActive = true,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      fcmToken: json['fcm_token'] as String,
      platform: (json['platform'] as String?) ?? 'android',
      deviceName: json['device_name'] as String?,
      deviceId: json['device_id'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'fcm_token': fcmToken,
      'platform': platform,
      'device_name': deviceName,
      'device_id': deviceId,
      'is_active': isActive,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
