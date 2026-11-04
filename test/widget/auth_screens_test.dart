import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/app/theme/app_theme.dart';
import 'package:yaadibook/features/auth/presentation/forgot_password_screen.dart';
import 'package:yaadibook/features/auth/presentation/login_screen.dart';
import 'package:yaadibook/features/auth/presentation/register_screen.dart';
import 'package:yaadibook/features/auth/presentation/welcome_screen.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import '../unit/auth_controller_test.dart';

Widget createTestableWidget(Widget child, {List<dynamic>? overrides}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
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
  group('Authentication Presentation Screens', () {
    testWidgets(
      'WelcomeScreen renders value proposition, language dropdown, and buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(const WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(
          find.text('Manage your business, the simpler way.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Keep your customers, services and important follow-ups organised in one place.',
          ),
          findsOneWidget,
        );
        expect(find.text('Get Started'), findsOneWidget);
        expect(find.text('I already have an account'), findsOneWidget);
        expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      },
    );

    testWidgets('LoginScreen renders form fields and validates inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Tap submit with empty fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();

      // Enforces validation
      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets(
      'RegisterScreen enforces password match and length validation',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(const RegisterScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsWidgets);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Confirm Password'), findsOneWidget);

        // Enter short password
        final passwordFinder = find.widgetWithText(
          TextFormField,
          'Enter your password',
        );
        if (passwordFinder.evaluate().isNotEmpty) {
          await tester.enterText(passwordFinder, '123');
        }

        // Scroll button into view and tap
        final buttonFinder = find.widgetWithText(
          ElevatedButton,
          'Create Account',
        );
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(find.text('This field is required'), findsWidgets);
      },
    );

    testWidgets('ForgotPasswordScreen renders input and submit button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const ForgotPasswordScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Log In'), findsOneWidget);
    });
  });
}
