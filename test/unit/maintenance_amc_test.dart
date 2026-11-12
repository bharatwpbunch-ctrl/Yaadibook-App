import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/features/amc/providers/amc_providers.dart';
import 'package:yaadibook/features/communications/providers/communication_providers.dart';
import 'package:yaadibook/features/maintenance/providers/maintenance_providers.dart';
import 'package:yaadibook/shared/models/amc_contract.dart';
import 'package:yaadibook/shared/models/equipment.dart';
import 'package:yaadibook/shared/models/maintenance_occurrence.dart';
import 'package:yaadibook/shared/models/maintenance_plan.dart';

DateTime calculateNextDate({
  required DateTime baseDate,
  required String frequencyType,
  int? intervalValue,
  String intervalUnit = 'months',
  int? anchorDay,
}) {
  final anchor = anchorDay ?? baseDate.day;

  if (frequencyType == 'one_time') {
    return baseDate;
  }

  if (frequencyType == 'custom' && intervalUnit.toLowerCase() == 'days') {
    final days = intervalValue ?? 1;
    return baseDate.add(Duration(days: days));
  }

  if (frequencyType == 'custom' && intervalUnit.toLowerCase() == 'weeks') {
    final weeks = intervalValue ?? 1;
    return baseDate.add(Duration(days: weeks * 7));
  }

  int monthsToAdd = 1;
  if (frequencyType == 'monthly') {
    monthsToAdd = 1;
  } else if (frequencyType == 'quarterly') {
    monthsToAdd = 3;
  } else if (frequencyType == 'half_yearly') {
    monthsToAdd = 6;
  } else if (frequencyType == 'yearly') {
    monthsToAdd = 12;
  } else if (frequencyType == 'custom' &&
      intervalUnit.toLowerCase() == 'years') {
    monthsToAdd = (intervalValue ?? 1) * 12;
  } else if (frequencyType == 'custom' &&
      intervalUnit.toLowerCase() == 'months') {
    monthsToAdd = intervalValue ?? 1;
  }

  // Pure calendar month addition with anchor day preservation
  var targetYear = baseDate.year;
  var targetMonth = baseDate.month + monthsToAdd;

  while (targetMonth > 12) {
    targetYear += 1;
    targetMonth -= 12;
  }

  final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final clampedDay = anchor > daysInTargetMonth ? daysInTargetMonth : anchor;

  return DateTime(targetYear, targetMonth, clampedDay);
}

void main() {
  group('Maintenance Recurrence Calculation Unit Tests', () {
    test('Calculates simple monthly interval correctly', () {
      final base = DateTime(2026, 3, 15);
      final next = calculateNextDate(baseDate: base, frequencyType: 'monthly');

      expect(next.year, 2026);
      expect(next.month, 4);
      expect(next.day, 15);
    });

    test('Calculates quarterly (3-month) interval correctly', () {
      final base = DateTime(2026, 1, 10);
      final next = calculateNextDate(
        baseDate: base,
        frequencyType: 'quarterly',
      );

      expect(next.year, 2026);
      expect(next.month, 4);
      expect(next.day, 10);
    });

    test(
      'Calculates half-yearly (6-month) interval crossing year boundary',
      () {
        final base = DateTime(2026, 9, 20);
        final next = calculateNextDate(
          baseDate: base,
          frequencyType: 'half_yearly',
        );

        expect(next.year, 2027);
        expect(next.month, 3);
        expect(next.day, 20);
      },
    );

    test('Calculates yearly interval correctly', () {
      final base = DateTime(2026, 5, 1);
      final next = calculateNextDate(baseDate: base, frequencyType: 'yearly');

      expect(next.year, 2027);
      expect(next.month, 5);
      expect(next.day, 1);
    });

    test(
      'Preserves month-end anchor day when passing February: Jan 31 -> Feb 28 -> Mar 31',
      () {
        // 2026 is non-leap year (Feb has 28 days)
        final jan31 = DateTime(2026, 1, 31);
        final feb = calculateNextDate(
          baseDate: jan31,
          frequencyType: 'monthly',
          anchorDay: 31,
        );

        expect(feb.year, 2026);
        expect(feb.month, 2);
        expect(feb.day, 28); // Clamped to 28 for February

        // Next month from February preserves anchor day 31!
        final mar = calculateNextDate(
          baseDate: feb,
          frequencyType: 'monthly',
          anchorDay: 31,
        );

        expect(mar.year, 2026);
        expect(mar.month, 3);
        expect(mar.day, 31); // Restored to 31 in March!
      },
    );

    test('Handles leap year month-end correctly: Jan 31 -> Feb 29 in 2028', () {
      // 2028 is a leap year (Feb has 29 days)
      final jan31 = DateTime(2028, 1, 31);
      final feb = calculateNextDate(
        baseDate: jan31,
        frequencyType: 'monthly',
        anchorDay: 31,
      );

      expect(feb.year, 2028);
      expect(feb.month, 2);
      expect(feb.day, 29); // Clamped to 29 in leap year
    });

    test('Calculates custom intervals in days and weeks', () {
      final base = DateTime(2026, 4, 1);

      final next10Days = calculateNextDate(
        baseDate: base,
        frequencyType: 'custom',
        intervalValue: 10,
        intervalUnit: 'days',
      );
      expect(next10Days, DateTime(2026, 4, 11));

      final next2Weeks = calculateNextDate(
        baseDate: base,
        frequencyType: 'custom',
        intervalValue: 2,
        intervalUnit: 'weeks',
      );
      expect(next2Weeks, DateTime(2026, 4, 15));
    });

    test('One-time plan returns identical base date', () {
      final base = DateTime(2026, 8, 12);
      final next = calculateNextDate(baseDate: base, frequencyType: 'one_time');
      expect(next, base);
    });
  });

  group('Maintenance Occurrence Effective Status Tests', () {
    test('Derives "due" when due_date is today and status is scheduled', () {
      final now = DateTime.now();
      final occ = MaintenanceOccurrence(
        id: 'occ-1',
        businessId: 'biz-1',
        maintenancePlanId: 'plan-1',
        customerId: 'cust-1',
        dueDate: DateTime(now.year, now.month, now.day),
        originalDueDate: DateTime(now.year, now.month, now.day),
        reminderTriggerDate: now.subtract(const Duration(days: 3)),
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      );

      expect(occ.effectiveStatus, 'due');
    });

    test(
      'Derives "overdue" when due_date is in past and status is scheduled',
      () {
        final now = DateTime.now();
        final occ = MaintenanceOccurrence(
          id: 'occ-2',
          businessId: 'biz-1',
          maintenancePlanId: 'plan-1',
          customerId: 'cust-1',
          dueDate: now.subtract(const Duration(days: 5)),
          originalDueDate: now.subtract(const Duration(days: 5)),
          reminderTriggerDate: now.subtract(const Duration(days: 8)),
          status: 'scheduled',
          createdAt: now,
          updatedAt: now,
        );

        expect(occ.effectiveStatus, 'overdue');
      },
    );

    test(
      'Derives "upcoming" when due_date is in future and status is scheduled',
      () {
        final now = DateTime.now();
        final occ = MaintenanceOccurrence(
          id: 'occ-3',
          businessId: 'biz-1',
          maintenancePlanId: 'plan-1',
          customerId: 'cust-1',
          dueDate: now.add(const Duration(days: 10)),
          originalDueDate: now.add(const Duration(days: 10)),
          reminderTriggerDate: now.add(const Duration(days: 7)),
          status: 'scheduled',
          createdAt: now,
          updatedAt: now,
        );

        expect(occ.effectiveStatus, 'upcoming');
      },
    );

    test('Maintains terminal status: completed, skipped, cancelled', () {
      final now = DateTime.now();
      final occCompleted = MaintenanceOccurrence(
        id: 'occ-4',
        businessId: 'biz-1',
        maintenancePlanId: 'plan-1',
        customerId: 'cust-1',
        dueDate: now.subtract(const Duration(days: 10)),
        originalDueDate: now.subtract(const Duration(days: 10)),
        reminderTriggerDate: now.subtract(const Duration(days: 13)),
        status: 'completed',
        createdAt: now,
        updatedAt: now,
      );
      expect(occCompleted.effectiveStatus, 'completed');

      final occSkipped = occCompleted.copyWith(status: 'skipped');
      expect(occSkipped.effectiveStatus, 'skipped');

      final occCancelled = occCompleted.copyWith(status: 'cancelled');
      expect(occCancelled.effectiveStatus, 'cancelled');
    });
  });

  group('AMC Contract Status and Validity Unit Tests', () {
    test('Identifies active contract with valid future expiry', () {
      final now = DateTime.now();
      final contract = AmcContract(
        id: 'amc-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        contractTitle: 'AC Annual Plan',
        contractNumber: 'YB-AMC-000001',
        startDate: now.subtract(const Duration(days: 100)),
        endDate: now.add(const Duration(days: 120)),
        contractAmount: 5000.0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(contract.effectiveStatus, 'active');
      expect(contract.isExpired, isFalse);
      expect(contract.isExpiringSoon, isFalse);
      expect(contract.daysRemaining, greaterThan(30));
    });

    test('Identifies expiring soon contract when within 30 days', () {
      final now = DateTime.now();
      final contract = AmcContract(
        id: 'amc-2',
        businessId: 'biz-1',
        customerId: 'cust-1',
        contractTitle: 'CCTV Annual Plan',
        contractNumber: 'YB-AMC-000002',
        startDate: now.subtract(const Duration(days: 350)),
        endDate: now.add(const Duration(days: 15)),
        contractAmount: 12000.0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(contract.effectiveStatus, 'expiring');
      expect(contract.isExpiringSoon, isTrue);
      expect(contract.isExpired, isFalse);
      expect(contract.daysRemaining, 15);
      expect(contract.expiryText, contains('Expires in 15 days'));
    });

    test('Identifies expired contract when end_date has passed', () {
      final now = DateTime.now();
      final contract = AmcContract(
        id: 'amc-3',
        businessId: 'biz-1',
        customerId: 'cust-1',
        contractTitle: 'RO Annual Plan',
        contractNumber: 'YB-AMC-000003',
        startDate: now.subtract(const Duration(days: 400)),
        endDate: now.subtract(const Duration(days: 5)),
        contractAmount: 3500.0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(contract.effectiveStatus, 'expired');
      expect(contract.isExpired, isTrue);
      expect(contract.isExpiringSoon, isFalse);
      expect(contract.expiryText, contains('Expired 5 days ago'));
    });

    test(
      'Respects explicit status over date calculations: renewed or cancelled',
      () {
        final now = DateTime.now();
        final contractRenewed = AmcContract(
          id: 'amc-4',
          businessId: 'biz-1',
          customerId: 'cust-1',
          contractTitle: 'Commercial Refrigerator Plan',
          contractNumber: 'YB-AMC-000004',
          startDate: now.subtract(const Duration(days: 370)),
          endDate: now.subtract(const Duration(days: 10)),
          contractAmount: 25000.0,
          status: 'renewed',
          createdAt: now,
          updatedAt: now,
        );

        expect(contractRenewed.effectiveStatus, 'renewed');

        final contractCancelled = contractRenewed.copyWith(status: 'cancelled');
        expect(contractCancelled.effectiveStatus, 'cancelled');
      },
    );
  });

  group('Model Serialization Roundtrip Tests', () {
    test('MaintenancePlan serialization and deserialization', () {
      final now = DateTime.now().toUtc();
      final plan = MaintenancePlan(
        id: 'plan-roundtrip',
        businessId: 'biz-123',
        customerId: 'cust-456',
        equipmentId: 'eq-789',
        planNumber: 'YB-MP-000099',
        title: 'Water Purifier Routine',
        maintenanceType: 'ro',
        frequencyType: 'quarterly',
        intervalValue: 3,
        intervalUnit: 'months',
        startDate: now,
        nextDueDate: now.add(const Duration(days: 90)),
        anchorDay: now.day,
        reminderDaysBefore: 5,
        status: 'active',
        notes: 'Check sediment and carbon filters',
        createdAt: now,
        updatedAt: now,
      );

      final json = plan.toJson();
      final restored = MaintenancePlan.fromJson(json);

      expect(restored.id, plan.id);
      expect(restored.businessId, plan.businessId);
      expect(restored.customerId, plan.customerId);
      expect(restored.equipmentId, plan.equipmentId);
      expect(restored.planNumber, plan.planNumber);
      expect(restored.maintenanceType, plan.maintenanceType);
      expect(restored.frequencyType, plan.frequencyType);
      expect(restored.anchorDay, plan.anchorDay);
      expect(restored.notes, plan.notes);
    });

    test('AmcContract serialization and deserialization', () {
      final now = DateTime.now().toUtc();
      final contract = AmcContract(
        id: 'amc-roundtrip',
        businessId: 'biz-123',
        customerId: 'cust-456',
        equipmentId: 'eq-789',
        contractTitle: 'Complete HVAC Coverage',
        contractNumber: 'YB-AMC-000088',
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        contractAmount: 18500.0,
        numberOfVisits: 4,
        includedServices: 'Free gas top-up, 4 wet services',
        excludedServices: 'Compressor replacement',
        specialTerms: 'Parts charged at 15% discount',
        status: 'active',
        notes: 'VIP customer',
        createdAt: now,
        updatedAt: now,
      );

      final json = contract.toJson();
      final restored = AmcContract.fromJson(json);

      expect(restored.id, contract.id);
      expect(restored.businessId, contract.businessId);
      expect(restored.contractTitle, contract.contractTitle);
      expect(restored.contractNumber, contract.contractNumber);
      expect(restored.contractAmount, contract.contractAmount);
      expect(restored.numberOfVisits, contract.numberOfVisits);
      expect(restored.includedServices, contract.includedServices);
      expect(restored.excludedServices, contract.excludedServices);
      expect(restored.status, contract.status);
    });
  });

  group('Maintenance & AMC Form State & One-Click Reminder Helpers', () {
    test(
      'resolveMaintenanceFrequencyType maps intervals to DB-valid enums',
      () {
        expect(
          resolveMaintenanceFrequencyType(
            isOneTime: true,
            intervalValue: 1,
            intervalUnit: 'months',
          ),
          'one_time',
        );
        expect(
          resolveMaintenanceFrequencyType(
            isOneTime: false,
            intervalValue: 1,
            intervalUnit: 'months',
          ),
          'monthly',
        );
        expect(
          resolveMaintenanceFrequencyType(
            isOneTime: false,
            intervalValue: 3,
            intervalUnit: 'months',
          ),
          'quarterly',
        );
        expect(
          resolveMaintenanceFrequencyType(
            isOneTime: false,
            intervalValue: 6,
            intervalUnit: 'months',
          ),
          'half_yearly',
        );
        expect(
          resolveMaintenanceFrequencyType(
            isOneTime: false,
            intervalValue: 1,
            intervalUnit: 'years',
          ),
          'yearly',
        );
        expect(
          resolveMaintenanceFrequencyType(
            isOneTime: false,
            intervalValue: 15,
            intervalUnit: 'days',
          ),
          'custom',
        );
      },
    );

    test(
      'MaintenancePlanFormNotifier never emits invalid "recurring" frequency',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          maintenancePlanFormControllerProvider(null).notifier,
        );
        expect(
          container
              .read(maintenancePlanFormControllerProvider(null))
              .frequencyType,
          'monthly',
        );

        notifier.setInterval(3, 'months');
        expect(
          container
              .read(maintenancePlanFormControllerProvider(null))
              .frequencyType,
          'quarterly',
        );

        notifier.setInterval(2, 'weeks');
        expect(
          container
              .read(maintenancePlanFormControllerProvider(null))
              .frequencyType,
          'custom',
        );

        notifier.setFrequencyType('one_time');
        expect(
          container
              .read(maintenancePlanFormControllerProvider(null))
              .frequencyType,
          'one_time',
        );

        // Even if legacy 'recurring' is passed, it normalizes to valid DB enum
        notifier.setFrequencyType('recurring');
        expect(
          container
              .read(maintenancePlanFormControllerProvider(null))
              .frequencyType,
          'custom',
        );
      },
    );

    test('AmcFormNotifier manages reminderDaysBefore lead time cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(amcFormControllerProvider(null)).reminderDaysBefore,
        15,
      );

      final notifier = container.read(amcFormControllerProvider(null).notifier);
      notifier.setReminderDaysBefore(30);
      expect(
        container.read(amcFormControllerProvider(null)).reminderDaysBefore,
        30,
      );

      notifier.setReminderDaysBefore(-5);
      expect(
        container.read(amcFormControllerProvider(null)).reminderDaysBefore,
        0,
      );
    });

    test('Equipment compares equal when ID matches across instances', () {
      final now = DateTime(2026, 1, 1);
      final eq1 = Equipment(
        id: 'eq-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        equipmentName: '16CH NVR',
        category: 'cctv',
        createdAt: now,
        updatedAt: now,
      );
      final eq2 = Equipment(
        id: 'eq-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        equipmentName: '16CH NVR',
        category: 'cctv',
        createdAt: now,
        updatedAt: now,
      );
      expect(eq1, eq2);
      expect(eq1.hashCode, eq2.hashCode);
    });

    test(
      'buildDefaultReminderMessage formats maintenance and AMC reminders',
      () {
        final maintMsg =
            CommunicationComposerController.buildDefaultReminderMessage(
              category: 'maintenance_reminder',
              customerName: 'Rameshbhai',
              businessName: 'Bharat CCTV',
              title: '8CH DVR',
              maintenanceDate: '20 Nov 2026',
            );
        expect(maintMsg, contains('Rameshbhai'));
        expect(maintMsg, contains('Bharat CCTV'));
        expect(maintMsg, contains('8CH DVR'));
        expect(maintMsg, contains('20 Nov 2026'));

        final amcMsg =
            CommunicationComposerController.buildDefaultReminderMessage(
              category: 'amc_renewal',
              customerName: 'Shreeji Jewellers',
              businessName: 'Bharat CCTV',
              title: 'Annual Camera AMC',
              amcEndDate: '31 Dec 2026',
              amount: '12000',
            );
        expect(amcMsg, contains('Shreeji Jewellers'));
        expect(amcMsg, contains('Annual Camera AMC'));
        expect(amcMsg, contains('31 Dec 2026'));
        expect(amcMsg, contains('12000'));
      },
    );
  });
}
