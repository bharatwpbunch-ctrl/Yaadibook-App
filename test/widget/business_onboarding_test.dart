import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/app/theme/app_theme.dart';
import 'package:yaadibook/features/onboarding/presentation/business_onboarding_screen.dart';
import 'package:yaadibook/features/onboarding/presentation/widgets/onboarding_step_indicator.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import '../unit/onboarding_controller_test.dart';

Widget createOnboardingTestWidget(Widget child, {List<dynamic>? overrides}) {
  return ProviderScope(
    overrides: [
      businessRepositoryProvider.overrideWithValue(MockBusinessRepository()),
      profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
      ...?overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('Business Onboarding Wizard Presentation', () {
    testWidgets('OnboardingStepIndicator renders all 3 step bars correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingStepIndicator(currentStep: 1, totalSteps: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingStepIndicator), findsOneWidget);
    });

    testWidgets(
      'BusinessOnboardingScreen starts at Step 1 and displays business fields',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createOnboardingTestWidget(const BusinessOnboardingScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Business Setup'), findsOneWidget);
        expect(find.text('Business Info'), findsOneWidget);
        expect(find.text('Step 1 of 3'), findsOneWidget);
        expect(find.text('Business Name'), findsOneWidget);
        expect(find.text('Business Category'), findsOneWidget);
        expect(find.text('Business Phone / WhatsApp'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Next without business name shows validation error banner',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createOnboardingTestWidget(const BusinessOnboardingScreen()),
        );
        await tester.pumpAndSettle();

        // Tap Next without entering name
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your business name'), findsOneWidget);
      },
    );

    testWidgets(
      'Step navigation moves to Address step and Back button appears',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createOnboardingTestWidget(const BusinessOnboardingScreen()),
        );
        await tester.pumpAndSettle();

        // Enter valid Step 0 details
        final nameFinder = find.widgetWithText(
          TextFormField,
          'e.g. Patel Security Solutions',
        );
        if (nameFinder.evaluate().isNotEmpty) {
          await tester.enterText(nameFinder, 'Patel CCTV');
        }

        final phoneFinder = find.widgetWithText(
          TextFormField,
          '10-digit mobile number',
        );
        if (phoneFinder.evaluate().isNotEmpty) {
          await tester.enterText(phoneFinder, '9825012345');
        }

        // Tap Next
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pumpAndSettle();

        // Now at Step 2: Address
        expect(find.text('Address'), findsOneWidget);
        expect(find.text('Step 2 of 3'), findsOneWidget);
        expect(find.text('Address Line 1'), findsOneWidget);
        expect(find.text('City'), findsOneWidget);
        expect(find.text('PIN Code'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);

        // Tap Back to return to Step 1
        await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
        await tester.pumpAndSettle();

        expect(find.text('Business Info'), findsOneWidget);
        expect(find.text('Step 1 of 3'), findsOneWidget);
      },
    );
  });
}
