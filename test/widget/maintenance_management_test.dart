import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/features/maintenance/presentation/maintenance_overview_screen.dart';
import 'package:yaadibook/features/maintenance/presentation/maintenance_plans_screen.dart';
import 'package:yaadibook/features/maintenance/presentation/widgets/occurrence_card.dart';
import 'package:yaadibook/features/maintenance/providers/maintenance_providers.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/models/maintenance_occurrence.dart';
import 'package:yaadibook/shared/models/maintenance_plan.dart';
import 'package:yaadibook/shared/repositories/maintenance_repository.dart';

final mockCustomer = Customer(
  id: 'cust-1',
  businessId: 'biz-1',
  fullName: 'Arun Sharma',
  primaryPhone: '9825099999',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final mockPlan = MaintenancePlan(
  id: 'plan-1',
  businessId: 'biz-1',
  customerId: 'cust-1',
  planNumber: 'YB-MP-000001',
  title: 'AC Routine Servicing',
  maintenanceType: 'routine',
  frequencyType: 'quarterly',
  intervalValue: 3,
  intervalUnit: 'months',
  startDate: DateTime(2026, 11, 1),
  nextDueDate: DateTime(2026, 11, 15),
  status: 'active',
  customer: mockCustomer,
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

final mockOccurrenceDue = MaintenanceOccurrence(
  id: 'occ-1',
  businessId: 'biz-1',
  maintenancePlanId: 'plan-1',
  customerId: 'cust-1',
  occurrenceNumber: 1,
  dueDate: DateTime.now(),
  originalDueDate: DateTime.now(),
  reminderTriggerDate: DateTime.now().subtract(const Duration(days: 3)),
  status: 'scheduled',
  customer: mockCustomer,
  maintenancePlan: mockPlan,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

Widget createTestableWidget(Widget child, List<dynamic> overrides) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('gu'), Locale('hi')],
      home: child,
    ),
  );
}

void main() {
  group('MaintenanceOverviewScreen Widget Tests', () {
    testWidgets('Renders 4 metric summary cards and occurrence cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const MaintenanceOverviewScreen(), [
          maintenanceOverviewCountsProvider.overrideWith(
            (ref) async => const MaintenanceOverviewCounts(
              dueToday: 1,
              overdue: 0,
              upcoming: 2,
              activePlans: 3,
            ),
          ),
          maintenanceOccurrencesListProvider.overrideWith(
            (ref) async => [mockOccurrenceDue],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Maintenance Plans'), findsOneWidget);

      // 4 Metric cards
      expect(find.text('Due Today'), findsWidgets);
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Active Plans'), findsOneWidget);

      // Occurrence item
      expect(find.text('Arun Sharma'), findsOneWidget);
      expect(find.text('9825099999'), findsOneWidget);
      expect(find.text('Mark as Completed'), findsOneWidget);
      expect(find.text('Skip Visit'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
    });

    testWidgets('Renders empty state when no occurrences match filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const MaintenanceOverviewScreen(), [
          maintenanceOverviewCountsProvider.overrideWith(
            (ref) async => const MaintenanceOverviewCounts(),
          ),
          maintenanceOccurrencesListProvider.overrideWith((ref) async => []),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No scheduled maintenance visits found.'),
        findsOneWidget,
      );
    });
  });

  group('OccurrenceCard Component Tests', () {
    testWidgets('Triggers completion, skip, and reschedule callbacks', (
      tester,
    ) async {
      bool completed = false;
      bool skipped = false;
      bool rescheduled = false;

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: OccurrenceCard(
              occurrence: mockOccurrenceDue,
              onComplete: () => completed = true,
              onSkip: () => skipped = true,
              onReschedule: () => rescheduled = true,
            ),
          ),
          [],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Complete
      await tester.tap(find.text('Mark as Completed'));
      expect(completed, isTrue);

      // Tap Skip
      await tester.tap(find.text('Skip Visit'));
      expect(skipped, isTrue);

      // Tap Reschedule
      await tester.tap(find.text('Reschedule'));
      expect(rescheduled, isTrue);

      // Verify 1-click reminder & template/SMS composer actions exist on card
      expect(find.text('Remind'), findsOneWidget);
      expect(find.byTooltip('Edit Message / SMS'), findsOneWidget);
    });
  });

  group('MaintenancePlansScreen Widget Tests', () {
    testWidgets('Renders search bar, filter tabs, and plan cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const MaintenancePlansScreen(), [
          maintenancePlansListProvider.overrideWith((ref) async => [mockPlan]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Maintenance Plans'), findsOneWidget);
      expect(find.text('YB-MP-000001'), findsOneWidget);
      expect(find.text('Arun Sharma'), findsOneWidget);
      expect(find.text('Routine Service'), findsOneWidget);
    });
  });
}
