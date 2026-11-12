import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/features/customers/providers/customer_providers.dart';
import 'package:yaadibook/features/services/presentation/add_service_screen.dart';
import 'package:yaadibook/features/services/presentation/service_detail_screen.dart';
import 'package:yaadibook/features/services/presentation/services_list_screen.dart';
import 'package:yaadibook/features/services/presentation/services_overview_screen.dart';
import 'package:yaadibook/features/services/providers/service_providers.dart';
import 'package:yaadibook/shared/models/business.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/models/customer_address.dart';
import 'package:yaadibook/shared/models/service_activity.dart';
import 'package:yaadibook/shared/models/service_entry.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import 'package:yaadibook/shared/repositories/service_repository.dart';

final mockBusiness = Business(
  id: 'biz-1',
  ownerUserId: 'user-1',
  businessName: 'Apex Security & Air Conditioning',
  businessCategory: 'cctv',
  phone: '9825011111',
  email: 'apex@test.com',
  addressLine1: 'Main Market',
  city: 'Ahmedabad',
  postalCode: '380015',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final mockCustomer = Customer(
  id: 'cust-1',
  businessId: 'biz-1',
  fullName: 'Vikram Mehta',
  primaryPhone: '9825012345',
  customerType: 'individual',
  addresses: [
    CustomerAddress(
      id: 'addr-1',
      businessId: 'biz-1',
      customerId: 'cust-1',
      addressLine1: '402, Shivalik Tower',
      area: 'Vastrapur',
      city: 'Ahmedabad',
      state: 'Gujarat',
      postalCode: '380015',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final mockService1 = ServiceEntry(
  id: 'srv-1',
  businessId: 'biz-1',
  customerId: 'cust-1',
  serviceNumber: 'YB-SRV-000001',
  serviceType: 'repair',
  title: 'AC Gas Leakage Repair',
  description: 'Cooling reduced substantially',
  workPerformed: 'Welded copper pipe and refilled R32 refrigerant',
  serviceDate: DateTime(2026, 11, 5),
  status: 'pending',
  serviceAmount: 1800.0,
  additionalCharges: 200.0,
  discountAmount: 100.0,
  totalAmount: 1900.0,
  customer: mockCustomer,
  createdAt: DateTime(2026, 11, 5),
  updatedAt: DateTime(2026, 11, 5),
);

final mockService2 = ServiceEntry(
  id: 'srv-2',
  businessId: 'biz-1',
  customerId: 'cust-1',
  serviceNumber: 'YB-SRV-000002',
  serviceType: 'installation',
  title: 'CCTV 4-Camera Setup',
  serviceDate: DateTime(2026, 11, 4),
  status: 'completed',
  serviceAmount: 4500.0,
  totalAmount: 4500.0,
  completedAt: DateTime(2026, 11, 4),
  customer: mockCustomer,
  createdAt: DateTime(2026, 11, 4),
  updatedAt: DateTime(2026, 11, 4),
);

Widget createServiceWidgetWrapper({
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
  group('ServicesOverviewScreen Widget Tests', () {
    testWidgets('renders 4 summary cards and recent services list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createServiceWidgetWrapper(
          overrides: [
            servicesSummaryProvider.overrideWith(
              (ref) async => const ServiceSummaryCounts(
                totalServices: 12,
                pending: 3,
                inProgress: 2,
                completed: 7,
              ),
            ),
            pendingServicesListProvider.overrideWith(
              (ref) async => [mockService1],
            ),
            recentServicesProvider.overrideWith(
              (ref) async => [mockService1, mockService2],
            ),
          ],
          child: const ServicesOverviewScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check Screen Title in AppBar
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Services'),
        ),
        findsOneWidget,
      );

      // Check Summary Metric Counts
      expect(find.text('12'), findsOneWidget); // Total
      expect(find.text('3'), findsOneWidget); // Pending
      expect(find.text('2'), findsOneWidget); // In Progress
      expect(find.text('7'), findsOneWidget); // Completed

      // Check Pending and Recent services items
      expect(find.text('Pending Services'), findsOneWidget);
      expect(find.text('Recent Services'), findsOneWidget);
      expect(find.text('AC Gas Leakage Repair'), findsWidgets);
      expect(find.text('CCTV 4-Camera Setup'), findsOneWidget);

      // Check FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('ServicesListScreen Widget Tests', () {
    testWidgets('renders filter chips and displays service entries', (
      tester,
    ) async {
      await tester.pumpWidget(
        createServiceWidgetWrapper(
          overrides: [
            servicesListProvider.overrideWith(
              (ref) async => [mockService1, mockService2],
            ),
          ],
          child: const ServicesListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check Title
      expect(find.text('All Services'), findsOneWidget);

      // Check Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Check Filter Chips exist
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Cancelled'), findsOneWidget);

      // Check Services displayed
      expect(find.text('AC Gas Leakage Repair'), findsOneWidget);
      expect(find.text('CCTV 4-Camera Setup'), findsOneWidget);
      expect(find.text('YB-SRV-000001'), findsOneWidget);
      expect(find.text('YB-SRV-000002'), findsOneWidget);
    });
  });

  group('AddServiceScreen Widget Tests', () {
    testWidgets('renders customer selector and service input fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createServiceWidgetWrapper(
          overrides: [
            customersListProvider.overrideWith((ref) async => [mockCustomer]),
          ],
          child: const AddServiceScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Title
      expect(find.text('Add Service'), findsOneWidget);

      // Customer selection prompt
      expect(find.text('Customer *'), findsOneWidget);
      expect(
        find.text('Choose an existing customer for this service'),
        findsOneWidget,
      );

      // Service Title input
      expect(find.text('Service Title *'), findsOneWidget);

      // Service Type dropdown
      expect(find.text('Service Type *'), findsOneWidget);

      // Save button exists
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('ServiceDetailScreen Widget Tests', () {
    testWidgets('renders reference number, customer details, and charges', (
      tester,
    ) async {
      await tester.pumpWidget(
        createServiceWidgetWrapper(
          overrides: [
            serviceDetailProvider(
              'srv-1',
            ).overrideWith((ref) async => mockService1),
            serviceActivitiesProvider('srv-1').overrideWith(
              (ref) async => [
                ServiceActivity(
                  id: 'act-1',
                  businessId: 'biz-1',
                  serviceId: 'srv-1',
                  activityType: 'created',
                  title: 'Service entry created',
                  createdAt: DateTime(2026, 11, 5, 10, 0),
                ),
              ],
            ),
          ],
          child: const ServiceDetailScreen(serviceId: 'srv-1'),
        ),
      );

      await tester.pumpAndSettle();

      // Reference Number
      expect(find.text('YB-SRV-000001'), findsWidgets);

      // Service Title & Customer Info
      expect(find.text('AC Gas Leakage Repair'), findsOneWidget);
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('9825012345'), findsOneWidget);

      // Communication Actions
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Charges Breakdown
      expect(find.text('Charges (INR)'), findsOneWidget);
      expect(find.text('₹1,900'), findsOneWidget);

      // Activity Timeline
      expect(find.text('Service Activity Timeline'), findsOneWidget);
      expect(find.text('Service entry created'), findsOneWidget);
    });
  });
}
