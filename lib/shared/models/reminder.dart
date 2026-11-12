/// Represents a unified follow-up or scheduled reminder in Yaadibook.
class Reminder {
  final String id;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? maintenanceOccurrenceId;
  final String? amcContractId;
  final String? serviceId;
  final String title;
  final String? description;
  final String reminderType; // 'maintenance', 'amc', 'follow_up', 'general'
  final String
  category; // 'customer_followup', 'call_customer', 'payment_followup', 'visit_customer', 'general_task', 'other'
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final DateTime dueAt;
  final String timezone;
  final bool notificationEnabled;
  final String
  status; // 'scheduled', 'due', 'overdue', 'completed', 'snoozed', 'cancelled'
  final DateTime? snoozedUntil;
  final DateTime? originalDueAt;
  final DateTime? completedAt;
  final String? completedNotes;
  final String? completedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.businessId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.maintenanceOccurrenceId,
    this.amcContractId,
    this.serviceId,
    required this.title,
    this.description,
    required this.reminderType,
    this.category = 'general_task',
    this.priority = 'normal',
    required this.dueAt,
    this.timezone = 'Asia/Kolkata',
    this.notificationEnabled = true,
    this.status = 'scheduled',
    this.snoozedUntil,
    this.originalDueAt,
    this.completedAt,
    this.completedNotes,
    this.completedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isSnoozed => status == 'snoozed';

  bool get isDueToday {
    if (isCompleted || isCancelled) return false;
    final now = DateTime.now();
    final localDue = dueAt.toLocal();
    return localDue.year == now.year &&
        localDue.month == now.month &&
        localDue.day == now.day;
  }

  bool get isOverdue {
    if (isCompleted || isCancelled) return false;
    if (status == 'overdue') return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDue = dueAt.toLocal();
    final dueDate = DateTime(localDue.year, localDue.month, localDue.day);
    return dueDate.isBefore(today);
  }

  bool get isUpcoming {
    if (isCompleted || isCancelled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDue = dueAt.toLocal();
    final dueDate = DateTime(localDue.year, localDue.month, localDue.day);
    return dueDate.isAfter(today);
  }

  /// Calculates human-friendly effective status for UI display
  String get effectiveStatus {
    if (isCompleted) return 'completed';
    if (isCancelled) return 'cancelled';
    if (isSnoozed) return 'snoozed';
    if (isOverdue) return 'overdue';
    if (isDueToday) return 'due';
    return 'scheduled';
  }

  Reminder copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? serviceId,
    String? title,
    String? description,
    String? reminderType,
    String? category,
    String? priority,
    DateTime? dueAt,
    String? timezone,
    bool? notificationEnabled,
    String? status,
    DateTime? snoozedUntil,
    DateTime? originalDueAt,
    DateTime? completedAt,
    String? completedNotes,
    String? completedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      maintenanceOccurrenceId:
          maintenanceOccurrenceId ?? this.maintenanceOccurrenceId,
      amcContractId: amcContractId ?? this.amcContractId,
      serviceId: serviceId ?? this.serviceId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderType: reminderType ?? this.reminderType,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      timezone: timezone ?? this.timezone,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      originalDueAt: originalDueAt ?? this.originalDueAt,
      completedAt: completedAt ?? this.completedAt,
      completedNotes: completedNotes ?? this.completedNotes,
      completedByUserId: completedByUserId ?? this.completedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    // Check for nested customer object if joined
    String? custName;
    String? custPhone;
    if (json['customers'] is Map<String, dynamic>) {
      final cust = json['customers'] as Map<String, dynamic>;
      custName = cust['full_name'] as String?;
      custPhone = cust['primary_phone'] as String?;
    }

    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val == null) return fallback ?? DateTime.now();
      if (val is DateTime) return val.toLocal();
      final dt = DateTime.tryParse(val.toString());
      return dt?.toLocal() ?? (fallback ?? DateTime.now());
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal();
    }

    return Reminder(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      customerId: json['customer_id']?.toString(),
      customerName: custName ?? (json['customer_name'] as String?),
      customerPhone: custPhone ?? (json['customer_phone'] as String?),
      maintenanceOccurrenceId: json['maintenance_occurrence_id']?.toString(),
      amcContractId: json['amc_contract_id']?.toString(),
      serviceId: json['service_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      reminderType: (json['reminder_type'] ?? 'general').toString(),
      category: (json['category'] as String?) ?? 'general_task',
      priority: (json['priority'] as String?) ?? 'normal',
      dueAt: parseDate(json['due_at']),
      timezone: (json['timezone'] as String?) ?? 'Asia/Kolkata',
      notificationEnabled: (json['notification_enabled'] as bool?) ?? true,
      status: (json['status'] as String?) ?? 'scheduled',
      snoozedUntil: parseNullableDate(json['snoozed_until']),
      originalDueAt: parseNullableDate(json['original_due_at']),
      completedAt: parseNullableDate(json['completed_at']),
      completedNotes: json['completed_notes'] as String?,
      completedByUserId: json['completed_by_user_id']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'maintenance_occurrence_id': maintenanceOccurrenceId,
      'amc_contract_id': amcContractId,
      'service_id': serviceId,
      'title': title,
      'description': description,
      'reminder_type': reminderType,
      'category': category,
      'priority': priority,
      'due_at': dueAt.toIso8601String(),
      'timezone': timezone,
      'notification_enabled': notificationEnabled,
      'status': status,
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'original_due_at': originalDueAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'completed_notes': completedNotes,
      'completed_by_user_id': completedByUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
