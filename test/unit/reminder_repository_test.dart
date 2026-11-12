import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/shared/models/models.dart';

void main() {
  group('Reminder Model & Lifecycle Tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10, 0);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    test('Reminder calculates effectiveStatus as due today correctly', () {
      final reminder = Reminder(
        id: 'rem-1',
        businessId: 'biz-1',
        title: 'Call customer regarding quotation',
        reminderType: 'follow_up',
        category: 'call_customer',
        priority: 'high',
        dueAt: today,
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      );

      expect(reminder.isDueToday, isTrue);
      expect(reminder.isOverdue, isFalse);
      expect(reminder.isUpcoming, isFalse);
      expect(reminder.effectiveStatus, equals('due'));
    });

    test('Reminder calculates effectiveStatus as overdue correctly', () {
      final reminder = Reminder(
        id: 'rem-2',
        businessId: 'biz-1',
        title: 'Payment follow-up',
        reminderType: 'general',
        category: 'payment_followup',
        priority: 'urgent',
        dueAt: yesterday,
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      );

      expect(reminder.isDueToday, isFalse);
      expect(reminder.isOverdue, isTrue);
      expect(reminder.isUpcoming, isFalse);
      expect(reminder.effectiveStatus, equals('overdue'));
    });

    test('Reminder calculates effectiveStatus as upcoming correctly', () {
      final reminder = Reminder(
        id: 'rem-3',
        businessId: 'biz-1',
        title: 'Visit site for measurement',
        reminderType: 'follow_up',
        category: 'visit_customer',
        dueAt: tomorrow,
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      );

      expect(reminder.isDueToday, isFalse);
      expect(reminder.isOverdue, isFalse);
      expect(reminder.isUpcoming, isTrue);
      expect(reminder.effectiveStatus, equals('scheduled'));
    });

    test('Reminder completed overrides overdue calculation', () {
      final reminder = Reminder(
        id: 'rem-4',
        businessId: 'biz-1',
        title: 'Old completed task',
        reminderType: 'general',
        dueAt: yesterday,
        status: 'completed',
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(reminder.isCompleted, isTrue);
      expect(reminder.isOverdue, isFalse);
      expect(reminder.effectiveStatus, equals('completed'));
    });

    test(
      'Reminder snoozed preserves original due date and sets snoozedUntil',
      () {
        final snoozeTarget = tomorrow.add(const Duration(hours: 4));
        final original = Reminder(
          id: 'rem-5',
          businessId: 'biz-1',
          title: 'Snoozed task',
          reminderType: 'general',
          dueAt: today,
          status: 'scheduled',
          createdAt: now,
          updatedAt: now,
        );

        final snoozed = original.copyWith(
          status: 'snoozed',
          originalDueAt: original.dueAt,
          snoozedUntil: snoozeTarget,
          dueAt: snoozeTarget,
        );

        expect(snoozed.isSnoozed, isTrue);
        expect(snoozed.effectiveStatus, equals('snoozed'));
        expect(snoozed.originalDueAt, equals(today));
        expect(snoozed.snoozedUntil, equals(snoozeTarget));
      },
    );

    test('Reminder serializes to and from JSON preserving all fields', () {
      final reminder = Reminder(
        id: 'rem-100',
        businessId: 'biz-1',
        customerId: 'cust-1',
        maintenanceOccurrenceId: 'occ-1',
        amcContractId: 'amc-1',
        serviceId: 'srv-1',
        title: 'RO filter checkup reminder',
        description: 'Verify membrane and TDS level',
        reminderType: 'maintenance',
        category: 'visit_customer',
        priority: 'high',
        dueAt: today,
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      );

      final json = reminder.toJson();
      expect(json['id'], equals('rem-100'));
      expect(json['reminder_type'], equals('maintenance'));
      expect(json['category'], equals('visit_customer'));
      expect(json['priority'], equals('high'));

      final reconstructed = Reminder.fromJson(json);
      expect(reconstructed.id, equals(reminder.id));
      expect(reconstructed.title, equals(reminder.title));
      expect(reconstructed.priority, equals(reminder.priority));
      expect(reconstructed.category, equals(reminder.category));
    });
  });

  group('Notification Preferences & In-App Notifications Tests', () {
    final now = DateTime.now();

    test('NotificationPreferences defaults are configured sensibly', () {
      final prefs = NotificationPreferences(
        id: 'pref-1',
        businessId: 'biz-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(prefs.pushNotificationsEnabled, isTrue);
      expect(prefs.maintenanceNotificationsEnabled, isTrue);
      expect(prefs.amcNotificationsEnabled, isTrue);
      expect(prefs.quietHoursEnabled, isFalse);
      expect(prefs.maintenanceAdvanceDays, containsAll([7, 1, 0]));
      expect(prefs.amcAdvanceDays, containsAll([30, 7, 1, 0]));
    });

    test('InAppNotification serializes accurately', () {
      final notif = InAppNotification(
        id: 'notif-1',
        businessId: 'biz-1',
        reminderId: 'rem-1',
        title: 'Maintenance due tomorrow',
        body: 'RO Purifier service for Rahul Shah',
        category: 'maintenance',
        isRead: false,
        providerStatus: 'provider_accepted',
        createdAt: now,
      );

      final json = notif.toJson();
      expect(json['category'], equals('maintenance'));
      expect(json['is_read'], isFalse);

      final parsed = InAppNotification.fromJson(json);
      expect(parsed.title, equals('Maintenance due tomorrow'));
      expect(parsed.providerStatus, equals('provider_accepted'));
    });
  });
}
