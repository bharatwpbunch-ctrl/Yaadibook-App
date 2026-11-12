import 'customer.dart';
import 'equipment.dart';
import 'maintenance_plan.dart';
import 'service_entry.dart';

/// Represents a single scheduled maintenance visit (an occurrence of a MaintenancePlan).
class MaintenanceOccurrence {
  final String id;
  final String businessId;
  final String maintenancePlanId;
  final String customerId;
  final String? equipmentId;
  final DateTime dueDate;
  final DateTime originalDueDate;
  final DateTime reminderTriggerDate;
  final int occurrenceNumber;
  final String
  status; // 'scheduled', 'upcoming', 'due', 'overdue', 'completed', 'skipped', 'cancelled'
  final String? completedServiceEntryId;
  final DateTime? completedAt;
  final String? workPerformed;
  final String? notes;
  final String? skipReason;
  final double? amount;
  final Customer? customer;
  final Equipment? equipment;
  final MaintenancePlan? maintenancePlan;
  final ServiceEntry? completedServiceEntry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceOccurrence({
    required this.id,
    required this.businessId,
    required this.maintenancePlanId,
    required this.customerId,
    this.equipmentId,
    required this.dueDate,
    required this.originalDueDate,
    required this.reminderTriggerDate,
    this.occurrenceNumber = 1,
    this.status = 'scheduled',
    this.completedServiceEntryId,
    this.completedAt,
    this.workPerformed,
    this.notes,
    this.skipReason,
    this.amount,
    this.customer,
    this.equipment,
    this.maintenancePlan,
    this.completedServiceEntry,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isSkipped => status.toLowerCase() == 'skipped';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  MaintenancePlan? get plan => maintenancePlan;

  /// Dynamically computes the effective operational status relative to today's date.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'skipped' || s == 'cancelled') {
      return s;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(today)) {
      return 'overdue';
    } else if (due.isAtSameMomentAs(today)) {
      return 'due';
    } else {
      return 'upcoming';
    }
  }

  bool get isDueToday => effectiveStatus == 'due';
  bool get isOverdue => effectiveStatus == 'overdue';
  bool get isUpcoming => effectiveStatus == 'upcoming';

  MaintenanceOccurrence copyWith({
    String? id,
    String? businessId,
    String? maintenancePlanId,
    String? customerId,
    String? equipmentId,
    DateTime? dueDate,
    DateTime? originalDueDate,
    DateTime? reminderTriggerDate,
    int? occurrenceNumber,
    String? status,
    String? completedServiceEntryId,
    DateTime? completedAt,
    String? workPerformed,
    String? notes,
    String? skipReason,
    double? amount,
    Customer? customer,
    Equipment? equipment,
    MaintenancePlan? maintenancePlan,
    ServiceEntry? completedServiceEntry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceOccurrence(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      maintenancePlanId: maintenancePlanId ?? this.maintenancePlanId,
      customerId: customerId ?? this.customerId,
      equipmentId: equipmentId ?? this.equipmentId,
      dueDate: dueDate ?? this.dueDate,
      originalDueDate: originalDueDate ?? this.originalDueDate,
      reminderTriggerDate: reminderTriggerDate ?? this.reminderTriggerDate,
      occurrenceNumber: occurrenceNumber ?? this.occurrenceNumber,
      status: status ?? this.status,
      completedServiceEntryId:
          completedServiceEntryId ?? this.completedServiceEntryId,
      completedAt: completedAt ?? this.completedAt,
      workPerformed: workPerformed ?? this.workPerformed,
      notes: notes ?? this.notes,
      skipReason: skipReason ?? this.skipReason,
      amount: amount ?? this.amount,
      customer: customer ?? this.customer,
      equipment: equipment ?? this.equipment,
      maintenancePlan: maintenancePlan ?? this.maintenancePlan,
      completedServiceEntry:
          completedServiceEntry ?? this.completedServiceEntry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MaintenanceOccurrence.fromJson(Map<String, dynamic> json) {
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

    MaintenancePlan? planObj;
    if (json['maintenance_plans'] != null &&
        json['maintenance_plans'] is Map<String, dynamic>) {
      planObj = MaintenancePlan.fromJson(
        json['maintenance_plans'] as Map<String, dynamic>,
      );
    }

    ServiceEntry? srvObj;
    if (json['service_entries'] != null &&
        json['service_entries'] is Map<String, dynamic>) {
      srvObj = ServiceEntry.fromJson(
        json['service_entries'] as Map<String, dynamic>,
      );
    }

    final due = DateTime.parse(json['due_date'] as String);
    final origDue = json['original_due_date'] != null
        ? DateTime.parse(json['original_due_date'] as String)
        : due;

    final triggerDate = json['reminder_trigger_date'] != null
        ? DateTime.parse(json['reminder_trigger_date'] as String)
        : due.subtract(const Duration(days: 7));

    return MaintenanceOccurrence(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      maintenancePlanId: json['maintenance_plan_id'] as String,
      customerId: json['customer_id'] as String,
      equipmentId: json['equipment_id'] as String?,
      dueDate: due,
      originalDueDate: origDue,
      reminderTriggerDate: triggerDate,
      occurrenceNumber: (json['occurrence_number'] as int?) ?? 1,
      status: (json['status'] as String?) ?? 'scheduled',
      completedServiceEntryId: json['completed_service_entry_id'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      workPerformed: json['work_performed'] as String?,
      notes: json['notes'] as String?,
      skipReason: json['skip_reason'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      customer: customerObj,
      equipment: eqObj,
      maintenancePlan: planObj,
      completedServiceEntry: srvObj,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'business_id': businessId,
      'maintenance_plan_id': maintenancePlanId,
      'customer_id': customerId,
      'equipment_id': equipmentId,
      'due_date': dueDate.toIso8601String().split('T').first,
      'original_due_date': originalDueDate.toIso8601String().split('T').first,
      'reminder_trigger_date': reminderTriggerDate
          .toIso8601String()
          .split('T')
          .first,
      'occurrence_number': occurrenceNumber,
      'status': status,
      'completed_service_entry_id': completedServiceEntryId,
      'completed_at': completedAt?.toIso8601String(),
      'work_performed': workPerformed,
      'notes': notes,
      'skip_reason': skipReason,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
