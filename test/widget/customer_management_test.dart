import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/features/customers/models/customer_activity_item.dart';
import 'package:yaadibook/features/customers/presentation/add_customer_screen.dart';
import 'package:yaadibook/features/customers/presentation/customer_detail_screen.dart';
import 'package:yaadibook/features/customers/presentation/customers_screen.dart';
import 'package:yaadibook/features/customers/providers/customer_providers.dart';
import 'package:yaadibook/shared/models/business.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/models/customer_address.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';

final mockBusiness = Business(
  id: 'biz-1',
  ownerUserId: 'user-1',
  businessName: 'Shree Krishna Electronics',
  businessCategory: 'cctv',
  phone: '9825011111',
  email: 'business@test.com',
  addressLine1: 'Main Road',
  city: 'Ahmedabad',
  postalCode: '380015',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final mockCustomer1 = Customer(
  id: 'cust-1',
  businessId: 'biz-1',
  fullName: 'Ramesh Patel',
  primaryPhone: '9825012345',
  customerType: 'individual',
  addresses: [
    CustomerAddress(
      id: 'addr-1',
      businessId: 'biz-1',
      customerId: 'cust-1',
      addressLine1: 'Shop 10, Galaxy Complex',
      area: 'Satellite',
      city: 'Ahmedabad',
      state: 'Gujarat',
      postalCode: '380015',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ],
  notes: 'Key customer for CCTV installations',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final mockCustomer2 = Customer(
  id: 'cust-2',
  businessId: 'biz-1',
  fullName: 'Apex Tech Solutions',
  primaryPhone: '9825099999',
  customerType: 'business',
  createdAt: DateTime(2026, 1, 2),
  updatedAt: DateTime(2026, 1, 2),
);

Widget createCustomerWidgetWrapper({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      currentBusinessProvider.overrideWith((ref) async => mockBusiness),
      ...overrides,
    ],
    child: MaterialApp(
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
  group('CustomersScreen Widget Tests', () {
    testWidgets('renders empty state when customer list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        createCustomerWidgetWrapper(
          overrides: [
            customersListProvider.overrideWith((ref) async => const []),
          ],
          child: const CustomersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Your customer list is empty.'), findsOneWidget);
      expect(find.text('Add Customer'), findsWidgets);
      expect(find.text('Import from Contacts'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders customer cards when customers exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createCustomerWidgetWrapper(
          overrides: [
            customersListProvider.overrideWith(
              (ref) async => [mockCustomer1, mockCustomer2],
            ),
          ],
          child: const CustomersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header count
      expect(find.text('2 customers'), findsOneWidget);

      // Names
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('Apex Tech Solutions'), findsOneWidget);

      // Initials avatars
      expect(find.text('RP'), findsOneWidget);
      expect(find.text('AT'), findsOneWidget);

      // Business badge
      expect(find.text('Business'), findsOneWidget);

      // Location summary
      expect(find.text('Satellite, Ahmedabad'), findsOneWidget);

      // Quick action buttons
      expect(find.text('Call'), findsNWidgets(2));
      expect(find.text('WhatsApp'), findsNWidgets(2));
    });

    testWidgets('renders filter chips and responds to search field input', (
      tester,
    ) async {
      await tester.pumpWidget(
        createCustomerWidgetWrapper(
          overrides: [
            customersListProvider.overrideWith((ref) async => [mockCustomer1]),
          ],
          child: const CustomersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Filter chips
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);

      // Type in search bar
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Ramesh');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Ramesh'), findsOneWidget);
    });
  });

  group('AddCustomerScreen Widget Tests', () {
    testWidgets('renders all form fields and toggles customer type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createCustomerWidgetWrapper(child: const AddCustomerScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Customer Name *'), findsOneWidget);
      expect(find.text('Mobile Number *'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Alternate Mobile (Optional)'), findsOneWidget);
      expect(find.text('Email Address (Optional)'), findsOneWidget);
      expect(find.text('Customer Type'), findsOneWidget);
      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Address Details (Optional)'), findsOneWidget);
      expect(find.text('Notes (Optional)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Toggle Customer Type to Business
      await tester.tap(find.text('Business'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates required fields on submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createCustomerWidgetWrapper(child: const AddCustomerScreen()),
      );
      await tester.pumpAndSettle();

      // Tap Save without entering required fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Form validation errors triggered
      expect(find.text('Customer Name *'), findsWidgets);
      expect(find.text('Mobile Number *'), findsWidgets);
    });
  });

  group('CustomerDetailScreen Widget Tests', () {
    testWidgets(
      'renders customer details, quick communication, overview metrics & timeline',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createCustomerWidgetWrapper(
            overrides: [
              customerDetailProvider(
                mockCustomer1.id,
              ).overrideWith((ref) async => mockCustomer1),
              customerActivityProvider(mockCustomer1).overrideWith(
                (ref) async => [
                  CustomerActivityItem(
                    id: 'act-1',
                    type: CustomerActivityType.created,
                    title: 'Customer Added',
                    description: 'Customer profile was created',
                    timestamp: DateTime(2026, 1, 1, 10, 0),
                  ),
                ],
              ),
            ],
            child: CustomerDetailScreen(customerId: mockCustomer1.id),
          ),
        );
        await tester.pumpAndSettle();

        // Profile header & contact info
        expect(find.text('Customer Profile'), findsOneWidget);
        expect(find.text('Ramesh Patel'), findsOneWidget);
        expect(find.text('RP'), findsOneWidget);
        expect(find.text('9825012345'), findsOneWidget);

        // Quick action bar
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);

        // Address & Notes
        expect(
          find.text(
            'Shop 10, Galaxy Complex, Satellite, Ahmedabad, Gujarat, 380015',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Key customer for CCTV installations'),
          findsOneWidget,
        );

        // Service overview 2x2 grid metrics
        expect(find.text('Service & Maintenance Overview'), findsOneWidget);
        expect(find.text('Total Services'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Upcoming Reminders'), findsOneWidget);

        // Activity timeline
        expect(find.text('Activity Timeline'), findsOneWidget);
        expect(find.text('Customer Added'), findsOneWidget);
      },
    );
  });
}
