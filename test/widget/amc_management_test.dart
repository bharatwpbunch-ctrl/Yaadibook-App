import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/features/amc/presentation/amc_overview_screen.dart';
import 'package:yaadibook/features/amc/presentation/widgets/amc_contract_card.dart';
import 'package:yaadibook/features/amc/providers/amc_providers.dart';
import 'package:yaadibook/shared/models/amc_contract.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/repositories/amc_repository.dart';

final mockCustomer = Customer(
  id: 'cust-1',
  businessId: 'biz-1',
  fullName: 'Dinesh Patel',
  primaryPhone: '9825022222',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final mockContract = AmcContract(
  id: 'amc-1',
  businessId: 'biz-1',
  customerId: 'cust-1',
  contractNumber: 'YB-AMC-000001',
  contractTitle: 'Comprehensive CCTV Coverage',
  startDate: DateTime.now().subtract(const Duration(days: 340)),
  endDate: DateTime.now().add(const Duration(days: 25)),
  contractAmount: 15000.0,
  numberOfVisits: 4,
  status: 'active',
  customer: mockCustomer,
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
  group('AmcOverviewScreen Widget Tests', () {
    testWidgets('Renders 4 metric cards, filter chips, and contracts list', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const AmcOverviewScreen(), [
          amcOverviewCountsProvider.overrideWith(
            (ref) async => const AmcOverviewCounts(
              active: 5,
              expiringSoon: 2,
              expired: 1,
              recentlyRenewed: 3,
            ),
          ),
          amcContractsListProvider.overrideWith((ref) async => [mockContract]),
        ]),
      );
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('AMC Contracts'), findsOneWidget);

      // Metric Counts
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Expiring Soon'), findsWidgets);
      expect(find.text('Expired'), findsWidgets);
      expect(find.text('Renewed'), findsWidgets);

      // Contract Item
      expect(find.text('YB-AMC-000001'), findsOneWidget);
      expect(find.text('Comprehensive CCTV Coverage'), findsOneWidget);
      expect(find.text('Dinesh Patel'), findsOneWidget);
      expect(find.text('₹15,000'), findsOneWidget);
      expect(find.text('Renew Contract'), findsOneWidget);
    });

    testWidgets('Renders empty state when no contracts exist', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const AmcOverviewScreen(), [
          amcOverviewCountsProvider.overrideWith(
            (ref) async => const AmcOverviewCounts(),
          ),
          amcContractsListProvider.overrideWith((ref) async => []),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No AMC contracts found. Create an AMC to track customer service warranties and annual recurring revenues!',
        ),
        findsOneWidget,
      );
    });
  });

  group('AmcContractCard Component Tests', () {
    testWidgets('Renders contract info and triggers renew callback', (
      tester,
    ) async {
      bool renewed = false;

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: AmcContractCard(
              contract: mockContract,
              onRenew: () => renewed = true,
            ),
          ),
          [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('YB-AMC-000001'), findsOneWidget);
      expect(find.text('Comprehensive CCTV Coverage'), findsOneWidget);
      expect(find.text('4 visits included'), findsOneWidget);
      expect(find.text('1-Click Remind'), findsOneWidget);
      expect(find.byTooltip('Choose Template / SMS'), findsOneWidget);
      expect(find.text('Renew Contract'), findsOneWidget);

      await tester.tap(find.text('Renew Contract'));
      expect(renewed, isTrue);
    });
  });
}
