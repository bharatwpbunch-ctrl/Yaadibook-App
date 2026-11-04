/// Represents a follow-up or scheduled reminder in Yaadibook.
class Reminder {
  final String id;
  final String businessId;
  final String? customerId;
  final String? maintenanceOccurrenceId;
  final String? amcContractId;
  final String title;
  final String? description;
  final String reminderType;
  final DateTime dueAt;
  final String timezone;
  final bool notificationEnabled;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.businessId,
    this.customerId,
    this.maintenanceOccurrenceId,
    this.amcContractId,
    required this.title,
    this.description,
    required this.reminderType,
    required this.dueAt,
    this.timezone = 'Asia/Kolkata',
    this.notificationEnabled = true,
    this.status = 'scheduled',
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isOverdue =>
      status == 'overdue' ||
      (status != 'completed' && dueAt.isBefore(DateTime.now()));

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String?,
      maintenanceOccurrenceId: json['maintenance_occurrence_id'] as String?,
      amcContractId: json['amc_contract_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      reminderType: json['reminder_type'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
      timezone: (json['timezone'] as String?) ?? 'Asia/Kolkata',
      notificationEnabled: (json['notification_enabled'] as bool?) ?? true,
      status: (json['status'] as String?) ?? 'scheduled',
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'maintenance_occurrence_id': maintenanceOccurrenceId,
      'amc_contract_id': amcContractId,
      'title': title,
      'description': description,
      'reminder_type': reminderType,
      'due_at': dueAt.toIso8601String(),
      'timezone': timezone,
      'notification_enabled': notificationEnabled,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
