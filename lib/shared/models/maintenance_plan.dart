import 'customer.dart';
import 'equipment.dart';
import 'maintenance_occurrence.dart';
import 'service_entry.dart';

/// Represents a customer maintenance plan (source of truth for recurring or one-time maintenance).
class MaintenancePlan {
  final String id;
  final String businessId;
  final String customerId;
  final String? equipmentId;
  final String? serviceEntryId;
  final String planNumber;
  final String title;
  final String
  maintenanceType; // 'general', 'cctv', 'ac', 'ro', 'appliance', 'electrical', 'inspection', 'other'
  final String? description;
  final String
  frequencyType; // 'one_time', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'custom'
  final int? intervalValue;
  final String intervalUnit; // 'days', 'weeks', 'months', 'years'
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final int? anchorDay;
  final int reminderDaysBefore;
  final String status; // 'active', 'paused', 'cancelled', 'completed'
  final String? notes;
  final Customer? customer;
  final Equipment? equipment;
  final ServiceEntry? serviceEntry;
  final List<MaintenanceOccurrence> occurrences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenancePlan({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.equipmentId,
    this.serviceEntryId,
    this.planNumber = '',
    this.title = 'Maintenance Plan',
    this.maintenanceType = 'general',
    this.description,
    required this.frequencyType,
    this.intervalValue,
    this.intervalUnit = 'months',
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
    this.anchorDay,
    this.reminderDaysBefore = 7,
    this.status = 'active',
    this.notes,
    this.customer,
    this.equipment,
    this.serviceEntry,
    this.occurrences = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isOneTime => frequencyType == 'one_time';
  bool get isRecurring => frequencyType != 'one_time';

  String get frequencyDisplay {
    switch (frequencyType.toLowerCase()) {
      case 'one_time':
        return 'One-Time';
      case 'monthly':
        return 'Every 1 Month';
      case 'quarterly':
        return 'Every 3 Months';
      case 'half_yearly':
        return 'Every 6 Months';
      case 'yearly':
        return 'Every 12 Months';
      case 'custom':
        final val = intervalValue ?? 1;
        final unit = intervalUnit.toLowerCase();
        if (unit == 'days') return 'Every $val Days';
        if (unit == 'weeks') return 'Every $val Weeks';
        if (unit == 'years') return 'Every $val Years';
        return 'Every $val Months';
      default:
        return frequencyType;
    }
  }

  String get maintenanceTypeDisplay {
    switch (maintenanceType.toLowerCase()) {
      case 'routine':
        return 'Routine Service';
      case 'periodic':
        return 'Periodic Service';
      case 'seasonal':
        return 'Seasonal Service';
      case 'cctv':
        return 'CCTV System';
      case 'ac':
        return 'AC Servicing';
      case 'ro':
        return 'RO Filter';
      case 'appliance':
        return 'Appliance';
      case 'electrical':
        return 'Electrical';
      case 'inspection':
        return 'Inspection';
      case 'general':
      case 'other':
      default:
        return 'General Maintenance';
    }
  }

  String get typeDisplay => maintenanceTypeDisplay;

  MaintenancePlan copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? equipmentId,
    String? serviceEntryId,
    String? planNumber,
    String? title,
    String? maintenanceType,
    String? description,
    String? frequencyType,
    int? intervalValue,
    String? intervalUnit,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    int? anchorDay,
    int? reminderDaysBefore,
    String? status,
    String? notes,
    Customer? customer,
    Equipment? equipment,
    ServiceEntry? serviceEntry,
    List<MaintenanceOccurrence>? occurrences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenancePlan(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      equipmentId: equipmentId ?? this.equipmentId,
      serviceEntryId: serviceEntryId ?? this.serviceEntryId,
      planNumber: planNumber ?? this.planNumber,
      title: title ?? this.title,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
      anchorDay: anchorDay ?? this.anchorDay,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      customer: customer ?? this.customer,
      equipment: equipment ?? this.equipment,
      serviceEntry: serviceEntry ?? this.serviceEntry,
      occurrences: occurrences ?? this.occurrences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MaintenancePlan.fromJson(Map<String, dynamic> json) {
    Customer? customerObj;
    if (json['customers'] != null &&
        json['customers'] is Map<String, dynamic>) {
      customerObj = Customer.fromJson(
        json['customers'] as Map<String, dynamic>,
      );
    }

    Equipment? eqObj;
    if (json['equipment'] != null &&
        json['equipment'] is Map<String, dynamic>) {
      eqObj = Equipment.fromJson(json['equipment'] as Map<String, dynamic>);
    }

    ServiceEntry? srvObj;
    if (json['service_entries'] != null &&
        json['service_entries'] is Map<String, dynamic>) {
      srvObj = ServiceEntry.fromJson(
        json['service_entries'] as Map<String, dynamic>,
      );
    }

    final rawOcc = json['maintenance_occurrences'] as List<dynamic>?;
    final occList = rawOcc != null
        ? rawOcc
              .whereType<Map<String, dynamic>>()
              .map(MaintenanceOccurrence.fromJson)
              .toList()
        : <MaintenanceOccurrence>[];

    return MaintenancePlan(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      equipmentId: json['equipment_id'] as String?,
      serviceEntryId: json['service_entry_id'] as String?,
      planNumber: (json['plan_number'] as String?) ?? '',
      title: json['title'] as String,
      maintenanceType: (json['maintenance_type'] as String?) ?? 'general',
      description: json['description'] as String?,
      frequencyType: json['frequency_type'] as String,
      intervalValue: json['interval_value'] as int?,
      intervalUnit: (json['interval_unit'] as String?) ?? 'months',
      startDate: DateTime.parse(json['start_date'] as String),
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      anchorDay: json['anchor_day'] as int?,
      reminderDaysBefore: (json['reminder_days_before'] as int?) ?? 7,
      status: (json['status'] as String?) ?? 'active',
      notes: json['notes'] as String?,
      customer: customerObj,
      equipment: eqObj,
      serviceEntry: srvObj,
      occurrences: occList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'equipment_id': equipmentId,
      'service_entry_id': serviceEntryId,
      if (planNumber.isNotEmpty) 'plan_number': planNumber,
      'title': title,
      'maintenance_type': maintenanceType,
      'description': description,
      'frequency_type': frequencyType,
      'interval_value': intervalValue,
      'interval_unit': intervalUnit,
      'start_date': startDate.toIso8601String().split('T').first,
      'next_due_date': nextDueDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'anchor_day': anchorDay,
      'reminder_days_before': reminderDaysBefore,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
