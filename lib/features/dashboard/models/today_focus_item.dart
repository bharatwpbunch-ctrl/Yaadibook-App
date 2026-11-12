/// Source classification for items appearing in "Today's Focus".
enum TodayFocusSource {
  maintenance,
  amc,
  followup,
  service;

  String get label {
    switch (this) {
      case TodayFocusSource.maintenance:
        return 'Maintenance';
      case TodayFocusSource.amc:
        return 'AMC';
      case TodayFocusSource.followup:
        return 'Follow-up';
      case TodayFocusSource.service:
        return 'Service';
    }
  }
}

/// Domain entity representing a high-priority task, due visit, or follow-up
/// requiring the business owner's attention today.
class TodayFocusItem {
  final String id;
  final String title;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime dueDate;
  final TodayFocusSource source;
  final bool isOverdue;
  final double? amount;
  final String? notes;
  final String? serviceId;
  final String? maintenanceOccurrenceId;
  final String? amcContractId;
  final String? reminderId;

  const TodayFocusItem({
    required this.id,
    required this.title,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.dueDate,
    required this.source,
    this.isOverdue = false,
    this.amount,
    this.notes,
    this.serviceId,
    this.maintenanceOccurrenceId,
    this.amcContractId,
    this.reminderId,
  });

  /// Deep-link route to the underlying entity when tapped on the Today screen.
  String get targetRoute {
    if (reminderId != null && reminderId!.isNotEmpty) {
      return '/reminders/$reminderId';
    }
    if (maintenanceOccurrenceId != null &&
        maintenanceOccurrenceId!.isNotEmpty) {
      return '/maintenance/occurrences/$maintenanceOccurrenceId';
    }
    if (serviceId != null && serviceId!.isNotEmpty) {
      return '/services/$serviceId';
    }
    if (amcContractId != null && amcContractId!.isNotEmpty) {
      return '/amc/$amcContractId';
    }
    if (customerId != null && customerId!.isNotEmpty) {
      return '/customers/$customerId';
    }
    switch (source) {
      case TodayFocusSource.maintenance:
        return '/maintenance/occurrences/$id';
      case TodayFocusSource.amc:
        return '/amc/$id';
      case TodayFocusSource.service:
        return '/services/$id';
      case TodayFocusSource.followup:
        return '/reminders/$id';
    }
  }

  /// Template category to preselect when sending a manual message from this card.
  String get templateCategory {
    switch (source) {
      case TodayFocusSource.maintenance:
        return 'maintenance_reminder';
      case TodayFocusSource.amc:
        return 'amc_renewal';
      case TodayFocusSource.service:
        return 'service_update';
      case TodayFocusSource.followup:
        return 'follow_up';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayFocusItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          source == other.source &&
          dueDate == other.dueDate;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ source.hashCode ^ dueDate.hashCode;
}
