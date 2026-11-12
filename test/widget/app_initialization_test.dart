import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/app.dart';
import 'package:yaadibook/features/onboarding/providers/onboarding_status_provider.dart';

void main() {
  testWidgets(
    'App initializes cleanly and renders Welcome screen when unauthenticated',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: YaadibookApp()));
      await tester.pumpAndSettle();

      // Verify unauthenticated user lands on Welcome screen
      expect(
        find.text('Manage your business, the simpler way.'),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    },
  );

  testWidgets('App renders Today dashboard when onboarding is completed', (
    WidgetTester tester,
  ) async {
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

    // Verify dashboard navigation destinations and initial shell render
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Reminders'), findsWidgets);
    expect(find.text('More'), findsOneWidget);
  });
}
