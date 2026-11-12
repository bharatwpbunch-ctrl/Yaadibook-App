import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/app.dart';
import 'package:yaadibook/features/onboarding/providers/onboarding_status_provider.dart';

void main() {
  testWidgets(
    'Bottom navigation tabs switch active screens and Add opens modal sheet',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingJourneyStatusProvider.overrideWithValue(
              OnboardingJourneyStatus.completed,
            ),
          ],
          child: const YaadibookApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Today screen is initial with Focus section and Summary Cards
      expect(find.text("Today's Focus"), findsOneWidget);
      expect(find.text('Total Customers'), findsOneWidget);
      expect(find.text('Pending Services'), findsOneWidget);

      // Switch to Customers tab
      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();
      expect(find.text('Customers'), findsWidgets);
      expect(find.text('Add Customer'), findsWidgets);

      // Switch to Reminders tab
      await tester.tap(find.byIcon(Icons.notifications_none_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Reminders'), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Overdue'), findsWidgets);

      // Switch to More tab
      await tester.tap(find.byIcon(Icons.more_horiz_outlined));
      await tester.pumpAndSettle();
      expect(find.text('More'), findsWidgets);
      expect(find.text('Business Management'), findsOneWidget);
      expect(find.text('Customer Communication'), findsOneWidget);

      // Tap center Add button -> opens modal bottom sheet
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('What would you like to add?'), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Add Service'), findsOneWidget);
      expect(find.text('Schedule Maintenance'), findsOneWidget);
      expect(find.text('Create AMC'), findsOneWidget);
    },
  );
}
