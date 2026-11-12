import '../../../shared/models/amc_contract.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/models/reminder.dart';
import '../../../shared/models/service_entry.dart';

enum ReportDatePreset {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  custom,
}

class ReportDateRange {
  final ReportDatePreset preset;
  final DateTime startDate;
  final DateTime endDate;

  const ReportDateRange({
    required this.preset,
    required this.startDate,
    required this.endDate,
  });

  factory ReportDateRange.fromPreset(
    ReportDatePreset preset, {
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case ReportDatePreset.thisMonth:
        return ReportDateRange(
          preset: preset,
          startDate: DateTime(today.year, today.month, 1),
          endDate: today,
        );
      case ReportDatePreset.lastMonth:
        final firstOfThisMonth = DateTime(today.year, today.month, 1);
        final lastOfPrevMonth = firstOfThisMonth.subtract(
          const Duration(days: 1),
        );
        return ReportDateRange(
          preset: preset,
          startDate: DateTime(lastOfPrevMonth.year, lastOfPrevMonth.month, 1),
          endDate: lastOfPrevMonth,
        );
      case ReportDatePreset.last3Months:
        return ReportDateRange(
          preset: preset,
          startDate: DateTime(today.year, today.month - 2, 1),
          endDate: today,
        );
      case ReportDatePreset.last6Months:
        return ReportDateRange(
          preset: preset,
          startDate: DateTime(today.year, today.month - 5, 1),
          endDate: today,
        );
      case ReportDatePreset.thisYear:
        // Indian financial year / calendar view: Jan 1 to today
        return ReportDateRange(
          preset: preset,
          startDate: DateTime(today.year, 1, 1),
          endDate: today,
        );
      case ReportDatePreset.custom:
        return ReportDateRange(
          preset: ReportDatePreset.custom,
          startDate: DateTime(today.year, today.month, 1),
          endDate: today,
        );
    }
  }
}

class CustomerActivitySummary {
  final String customerId;
  final String customerName;
  final String phone;
  final int servicesCount;
  final double recordedAmount;

  const CustomerActivitySummary({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.servicesCount,
    required this.recordedAmount,
  });
}

class CustomerReportMetrics {
  final int totalActive;
  final int newInPeriod;
  final int repeatCustomers;
  final int withActiveAmc;
  final List<CustomerActivitySummary> topCustomers;

  const CustomerReportMetrics({
    this.totalActive = 0,
    this.newInPeriod = 0,
    this.repeatCustomers = 0,
    this.withActiveAmc = 0,
    this.topCustomers = const [],
  });
}

class ServiceReportMetrics {
  final int totalActiveCount;
  final int completedCount;
  final int pendingCount;
  final int cancelledCount;
  final double recordedAmountInr;
  final double paidAmountInr;
  final double pendingAmountInr;
  final Map<String, int> byType;
  final List<ServiceEntry> entries;

  const ServiceReportMetrics({
    this.totalActiveCount = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.cancelledCount = 0,
    this.recordedAmountInr = 0,
    this.paidAmountInr = 0,
    this.pendingAmountInr = 0,
    this.byType = const {},
    this.entries = const [],
  });
}

class MaintenanceReportRow {
  final String id;
  final String title;
  final String customerName;
  final DateTime dueDate;
  final String status;

  const MaintenanceReportRow({
    required this.id,
    required this.title,
    required this.customerName,
    required this.dueDate,
    required this.status,
  });
}

class MaintenanceReportMetrics {
  final int totalInPeriod;
  final int completedCount;
  final int upcomingCount;
  final int overdueCount;
  final List<MaintenanceReportRow> rows;

  const MaintenanceReportMetrics({
    this.totalInPeriod = 0,
    this.completedCount = 0,
    this.upcomingCount = 0,
    this.overdueCount = 0,
    this.rows = const [],
  });
}

class AmcReportMetrics {
  final int activeCount;
  final int expiringWithin30Days;
  final int expiredCount;
  final int renewedInPeriod;
  final double portfolioContractValueInr;
  final List<AmcContract> contracts;

  const AmcReportMetrics({
    this.activeCount = 0,
    this.expiringWithin30Days = 0,
    this.expiredCount = 0,
    this.renewedInPeriod = 0,
    this.portfolioContractValueInr = 0,
    this.contracts = const [],
  });
}

class FollowupReportMetrics {
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final Map<String, int> byType;
  final List<Reminder> reminders;

  const FollowupReportMetrics({
    this.completedCount = 0,
    this.pendingCount = 0,
    this.overdueCount = 0,
    this.byType = const {},
    this.reminders = const [],
  });
}

class CommunicationReportMetrics {
  final int whatsappCount;
  final int smsCount;
  final double recordedCostInr;

  const CommunicationReportMetrics({
    this.whatsappCount = 0,
    this.smsCount = 0,
    this.recordedCostInr = 0,
  });
}

class BusinessReportData {
  final String businessId;
  final String businessName;
  final String businessPhone;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final String timezone;
  final bool isOfflineEstimate;
  final CustomerReportMetrics customers;
  final ServiceReportMetrics services;
  final MaintenanceReportMetrics maintenance;
  final AmcReportMetrics amc;
  final FollowupReportMetrics followups;
  final CommunicationReportMetrics communications;
  final DateTime generatedAt;

  const BusinessReportData({
    required this.businessId,
    required this.businessName,
    required this.businessPhone,
    required this.startDate,
    required this.endDate,
    this.currencyCode = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.isOfflineEstimate = false,
    required this.customers,
    required this.services,
    required this.maintenance,
    required this.amc,
    required this.followups,
    required this.communications,
    required this.generatedAt,
  });

  /// Deterministic report calculator used for unit tests & offline fallback.
  /// Strictly excludes `cancelled` services from active count and recorded revenue.
  static BusinessReportData computeFromEntities({
    required String businessId,
    required String businessName,
    required String businessPhone,
    required DateTime startDate,
    required DateTime endDate,
    required List<Customer> customers,
    required List<ServiceEntry> services,
    required List<AmcContract> amcs,
    required List<Reminder> reminders,
    List<MaintenanceReportRow> maintenanceRows = const [],
    bool isOfflineEstimate = false,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = DateTime(startDate.year, startDate.month, startDate.day);
    final rangeEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    bool inRange(DateTime dt) {
      final local = dt.toLocal();
      return !local.isBefore(rangeStart) && !local.isAfter(rangeEnd);
    }

    final activeCustomers = customers.where((c) => !c.isArchived).toList();
    final newCustCount = activeCustomers
        .where((c) => inRange(c.createdAt))
        .length;

    final servicesByCustomerAll = <String, int>{};
    for (final s in services.where((s) => s.status != 'cancelled')) {
      servicesByCustomerAll.update(
        s.customerId,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    final repeatCustomers = servicesByCustomerAll.values
        .where((cnt) => cnt > 1)
        .length;

    final customerIdsWithAmc = amcs
        .where((a) => a.status == 'active' || a.status == 'expiring')
        .map((a) => a.customerId)
        .toSet();

    final periodServices = services
        .where((s) => inRange(s.serviceDate))
        .toList();
    final activePeriodServices = periodServices
        .where((s) => s.status != 'cancelled')
        .toList();
    final cancelledServices = periodServices
        .where((s) => s.status == 'cancelled')
        .toList();

    double recordedAmt = 0;
    double paidAmt = 0;
    double pendingAmt = 0;
    final byType = <String, int>{};
    final perCustAmount = <String, double>{};
    final perCustCount = <String, int>{};

    for (final s in activePeriodServices) {
      final amt = s.totalAmount ?? s.serviceAmount ?? 0.0;
      recordedAmt += amt;
      if (s.paymentStatus == 'paid') {
        paidAmt += amt;
      } else {
        pendingAmt += amt;
      }
      byType.update(s.serviceType, (v) => v + 1, ifAbsent: () => 1);
      perCustAmount.update(s.customerId, (v) => v + amt, ifAbsent: () => amt);
      perCustCount.update(s.customerId, (v) => v + 1, ifAbsent: () => 1);
    }

    final custById = {for (final c in activeCustomers) c.id: c};
    final topCust = perCustCount.entries.map((e) {
      final c = custById[e.key];
      return CustomerActivitySummary(
        customerId: e.key,
        customerName: c?.fullName ?? 'Customer',
        phone: c?.primaryPhone ?? '',
        servicesCount: e.value,
        recordedAmount: perCustAmount[e.key] ?? 0.0,
      );
    }).toList()..sort((a, b) => b.servicesCount.compareTo(a.servicesCount));

    final periodMaint = maintenanceRows
        .where((m) => inRange(m.dueDate))
        .toList();
    final maintCompleted = periodMaint
        .where((m) => m.status == 'completed')
        .length;
    final maintOverdue = periodMaint
        .where(
          (m) =>
              m.status == 'overdue' ||
              ((m.status == 'scheduled' || m.status == 'due') &&
                  DateTime(
                    m.dueDate.year,
                    m.dueDate.month,
                    m.dueDate.day,
                  ).isBefore(today)),
        )
        .length;
    final maintUpcoming = periodMaint
        .where(
          (m) =>
              (m.status == 'scheduled' || m.status == 'due') &&
              !DateTime(
                m.dueDate.year,
                m.dueDate.month,
                m.dueDate.day,
              ).isBefore(today),
        )
        .length;

    final activeAmcs = amcs
        .where(
          (a) =>
              (a.status == 'active' || a.status == 'expiring') && !a.isExpired,
        )
        .length;
    final expiring30 = amcs.where((a) {
      if (a.status != 'active' && a.status != 'expiring') return false;
      final d = a.daysRemaining;
      return d >= 0 && d <= 30;
    }).length;
    final expiredAmcs = amcs
        .where((a) => a.status == 'expired' || a.isExpired)
        .length;
    final renewedAmcs = amcs
        .where((a) => a.renewedFromContractId != null && inRange(a.startDate))
        .length;
    final amcValue = amcs
        .where(
          (a) =>
              a.status == 'active' ||
              a.status == 'expiring' ||
              a.status == 'renewed',
        )
        .fold<double>(0.0, (sum, a) => sum + a.contractAmount);

    final periodReminders = reminders.where((r) => inRange(r.dueAt)).toList();
    final remCompleted = periodReminders.where((r) => r.isCompleted).length;
    final remOverdue = periodReminders.where((r) => r.isOverdue).length;
    final remPending = periodReminders
        .where((r) => !r.isCompleted && !r.isCancelled && !r.isOverdue)
        .length;
    final remByType = <String, int>{};
    for (final r in periodReminders) {
      remByType.update(r.reminderType, (v) => v + 1, ifAbsent: () => 1);
    }

    return BusinessReportData(
      businessId: businessId,
      businessName: businessName,
      businessPhone: businessPhone,
      startDate: startDate,
      endDate: endDate,
      isOfflineEstimate: isOfflineEstimate,
      customers: CustomerReportMetrics(
        totalActive: activeCustomers.length,
        newInPeriod: newCustCount,
        repeatCustomers: repeatCustomers,
        withActiveAmc: customerIdsWithAmc.length,
        topCustomers: topCust.take(10).toList(),
      ),
      services: ServiceReportMetrics(
        totalActiveCount: activePeriodServices.length,
        completedCount: activePeriodServices
            .where((s) => s.status == 'completed')
            .length,
        pendingCount: activePeriodServices
            .where((s) => s.status == 'pending' || s.status == 'in_progress')
            .length,
        cancelledCount: cancelledServices.length,
        recordedAmountInr: recordedAmt,
        paidAmountInr: paidAmt,
        pendingAmountInr: pendingAmt,
        byType: byType,
        entries: periodServices,
      ),
      maintenance: MaintenanceReportMetrics(
        totalInPeriod: periodMaint.length,
        completedCount: maintCompleted,
        upcomingCount: maintUpcoming,
        overdueCount: maintOverdue,
        rows: periodMaint,
      ),
      amc: AmcReportMetrics(
        activeCount: activeAmcs,
        expiringWithin30Days: expiring30,
        expiredCount: expiredAmcs,
        renewedInPeriod: renewedAmcs,
        portfolioContractValueInr: amcValue,
        contracts: amcs,
      ),
      followups: FollowupReportMetrics(
        completedCount: remCompleted,
        pendingCount: remPending,
        overdueCount: remOverdue,
        byType: remByType,
        reminders: periodReminders,
      ),
      communications: const CommunicationReportMetrics(),
      generatedAt: now,
    );
  }
}
