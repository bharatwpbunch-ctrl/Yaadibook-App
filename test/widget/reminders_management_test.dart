import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/app/theme/app_theme.dart';
import 'package:yaadibook/features/reminders/presentation/create_reminder_screen.dart';
import 'package:yaadibook/features/reminders/presentation/reminders_screen.dart';
import 'package:yaadibook/features/reminders/presentation/widgets/reminder_card.dart';
import 'package:yaadibook/features/reminders/providers/reminder_providers.dart';
import 'package:yaadibook/shared/models/models.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import 'package:yaadibook/shared/repositories/reminder_repository.dart';

class _FakeReminderRepository implements IReminderRepository {
  final List<Reminder> _reminders;

  _FakeReminderRepository(this._reminders);

  @override
  Future<List<Reminder>> getReminders({
    String? status,
    String? type,
    String? category,
    String? customerId,
    bool includeCompleted = false,
  }) async {
    return _reminders;
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    return _reminders.firstWhere((r) => r.id == id);
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    return reminder;
  }

  @override
  Future<Reminder> updateReminder(Reminder reminder) async {
    return reminder;
  }

  @override
  Future<void> snoozeReminder(String id, DateTime snoozeUntil) async {}

  @override
  Future<void> completeReminder(String id, {String? notes}) async {}

  @override
  Future<void> markCompleted(String id) async {}

  @override
  Future<void> cancelReminder(String id) async {}

  @override
  Future<ReminderOverviewStats> getOverviewStats() async {
    return const ReminderOverviewStats(
      dueToday: 3,
      overdue: 1,
      upcoming: 4,
      completed: 7,
    );
  }
}

Widget _wrapWithApp(Widget child, {List<Reminder>? reminders}) {
  final repo = _FakeReminderRepository(reminders ?? []);

  return ProviderScope(
    overrides: [
      reminderRepositoryProvider.overrideWithValue(repo),
      remindersOverviewStatsProvider.overrideWith(
        (_) => Future.value(
          const ReminderOverviewStats(
            dueToday: 3,
            overdue: 1,
            upcoming: 4,
            completed: 7,
          ),
        ),
      ),
      filteredRemindersProvider.overrideWith(
        (_) => Future.value(reminders ?? []),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('Reminders Screen Widget Tests', () {
    final now = DateTime.now();

    final testReminders = [
      Reminder(
        id: 'rem-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        customerName: 'Rahul Shah',
        customerPhone: '9825012345',
        title: 'RO checkup service due',
        description: 'Check membrane filter',
        reminderType: 'maintenance',
        category: 'visit_customer',
        priority: 'high',
        dueAt: DateTime(now.year, now.month, now.day, 10, 0),
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      ),
      Reminder(
        id: 'rem-2',
        businessId: 'biz-1',
        title: 'Collect pending payment',
        reminderType: 'general',
        category: 'payment_followup',
        priority: 'normal',
        dueAt: DateTime(now.year, now.month, now.day, 14, 0),
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    testWidgets(
      'RemindersScreen renders 4 metric summary cards and reminder list',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(const RemindersScreen(), reminders: testReminders),
        );
        await tester.pumpAndSettle();

        // Metric summary counts
        expect(find.text('3'), findsOneWidget); // Due Today
        expect(find.text('1'), findsOneWidget); // Overdue
        expect(find.text('4'), findsOneWidget); // Upcoming
        expect(find.text('7'), findsOneWidget); // Completed

        // Reminder cards rendered
        expect(find.text('RO checkup service due'), findsOneWidget);
        expect(find.text('Collect pending payment'), findsOneWidget);
        expect(find.text('Rahul Shah'), findsOneWidget);
      },
    );

    testWidgets('ReminderCard displays action buttons and priority badge', (
      tester,
    ) async {
      final rem = testReminders.first;

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: ReminderCard(
              reminder: rem,
              onTap: () {},
              onComplete: () {},
              onSnooze: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RO checkup service due'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Mark Complete'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
    });

    testWidgets(
      'CreateReminderScreen renders required title, date, and priority fields',
      (tester) async {
        await tester.pumpWidget(_wrapWithApp(const CreateReminderScreen()));
        await tester.pumpAndSettle();

        expect(find.text('New Reminder'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsAtLeastNWidgets(2),
        ); // Title & Description
        expect(find.text('Normal'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );
  });
}
