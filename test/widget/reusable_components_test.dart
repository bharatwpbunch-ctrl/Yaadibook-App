import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/theme/app_theme.dart';
import 'package:yaadibook/core/widgets/widgets.dart';

void main() {
  group('Reusable UI Components', () {
    testWidgets('YbPrimaryButton renders label and triggers callback', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: YbPrimaryButton(
              label: 'Save Record',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Record'), findsOneWidget);
      await tester.tap(find.text('Save Record'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'YbPrimaryButton displays spinner when loading and ignores tap',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: YbPrimaryButton(
                label: 'Save Record',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Save Record'), findsNothing);
        await tester.tap(find.byType(ElevatedButton));
        expect(tapped, isFalse);
      },
    );

    testWidgets('YbSecondaryButton renders label and triggers callback', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: YbSecondaryButton(
              label: 'Cancel Action',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Cancel Action'), findsOneWidget);
      await tester.tap(find.text('Cancel Action'));
      expect(tapped, isTrue);
    });

    testWidgets('YbTextInput renders label, hint, and receives input', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: YbTextInput(
              label: 'Customer Name',
              hint: 'Enter full name',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Enter full name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Rajesh Kumar');
      expect(controller.text, 'Rajesh Kumar');
    });

    testWidgets('YbStatusBadge renders label and dot', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: YbStatusBadge(
              label: 'Overdue',
              statusType: YbStatusType.overdue,
            ),
          ),
        ),
      );

      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('YbCustomerCard renders customer data and actions', (
      tester,
    ) async {
      bool called = false;
      bool whatsApp = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: YbCustomerCard(
              name: 'Suresh Patel',
              phone: '+91 98980 12345',
              address: 'Ashram Road, Ahmedabad',
              tag: 'VIP',
              onCall: () => called = true,
              onWhatsApp: () => whatsApp = true,
            ),
          ),
        ),
      );

      expect(find.text('Suresh Patel'), findsOneWidget);
      expect(find.text('+91 98980 12345'), findsOneWidget);
      expect(find.text('Ashram Road, Ahmedabad'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);

      await tester.tap(find.text('Call'));
      expect(called, isTrue);

      await tester.tap(find.text('WhatsApp'));
      expect(whatsApp, isTrue);
    });

    testWidgets('YbEmptyState renders title, message, and action', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: YbEmptyState(
              title: 'No Customers Found',
              message: 'Add your first customer to start tracking services.',
              actionLabel: 'Add Customer',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Customers Found'), findsOneWidget);
      expect(
        find.text('Add your first customer to start tracking services.'),
        findsOneWidget,
      );
      expect(find.text('Add Customer'), findsOneWidget);

      await tester.tap(find.text('Add Customer'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('YbErrorState renders retry button and triggers callback', (
      tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: YbErrorState(
              title: 'Connection Error',
              message: 'Unable to reach servers.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
