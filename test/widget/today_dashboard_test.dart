import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/app.dart';
import 'package:yaadibook/app/localization/locale_provider.dart';
import 'package:yaadibook/features/dashboard/models/dashboard_metrics.dart';
import 'package:yaadibook/features/dashboard/models/today_focus_item.dart';
import 'package:yaadibook/features/dashboard/providers/dashboard_providers.dart';
import 'package:yaadibook/features/onboarding/providers/onboarding_status_provider.dart';
import 'package:yaadibook/shared/models/business.dart';
import 'package:yaadibook/shared/models/user_profile.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';

void main() {
  final sampleOwner = UserProfile(
    id: 'user-1',
    fullName: 'Bharat Patel',
    phone: '+91 98250 11223',
    email: 'bharat@marutiservices.com',
    preferredLanguage: 'en',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleBusiness = Business(
    id: 'biz-1',
    ownerUserId: 'user-1',
    businessName: 'Maruti AC & CCTV',
    businessCategory: 'CCTV & Security Systems',
    phone: '+91 98250 11223',
    addressLine1: 'Shop 4, City Center',
    city: 'Ahmedabad',
    state: 'Gujarat',
    postalCode: '380015',
    country: 'India',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets(
    'Today dashboard renders header, 4 zero summary cards, and friendly empty state',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingJourneyStatusProvider.overrideWithValue(
              OnboardingJourneyStatus.completed,
            ),
            currentUserProfileProvider.overrideWith((ref) => sampleOwner),
            currentBusinessProvider.overrideWith((ref) => sampleBusiness),
            dashboardMetricsProvider.overrideWith(
              (ref) => DashboardMetrics.zero,
            ),
            todayFocusProvider.overrideWith((ref) => const []),
          ],
          child: const YaadibookApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header with owner first name & business name
      expect(find.textContaining('Bharat'), findsOneWidget);
      expect(find.text('Maruti AC & CCTV'), findsOneWidget);

      // Verify summary cards with zero counts
      expect(find.text('Total Customers'), findsOneWidget);
      expect(find.text('Pending Services'), findsOneWidget);
      expect(find.text('Maintenance Due'), findsOneWidget);
      expect(find.text('AMC Expiring Soon'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(4));

      // Verify friendly empty state
      expect(find.text("You're all caught up!"), findsOneWidget);
      expect(
        find.text(
          'Your important tasks will appear here when something needs attention.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Today dashboard renders populated metrics and real focus items',
    (WidgetTester tester) async {
      final populatedMetrics = const DashboardMetrics(
        totalCustomers: 45,
        pendingServices: 3,
        maintenanceDue: 2,
        amcExpiringSoon: 1,
      );

      final focusItems = [
        TodayFocusItem(
          id: 'f-1',
          title: 'Quarterly RO Purifier Servicing',
          customerName: 'Kailash Jewellers',
          dueDate: DateTime.now(),
          source: TodayFocusSource.maintenance,
          isOverdue: false,
        ),
        TodayFocusItem(
          id: 'f-2',
          title: 'CCTV Annual Contract Renewal',
          customerName: 'Shree Krishna Electronics',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          source: TodayFocusSource.amc,
          isOverdue: true,
        ),
        TodayFocusItem(
          id: 'f-3',
          title: 'AC Gas Recharging & Filter Cleaning',
          customerName: 'Ramesh Patel',
          dueDate: DateTime.now(),
          source: TodayFocusSource.service,
          amount: 1450,
          isOverdue: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingJourneyStatusProvider.overrideWithValue(
              OnboardingJourneyStatus.completed,
            ),
            currentUserProfileProvider.overrideWith((ref) => sampleOwner),
            currentBusinessProvider.overrideWith((ref) => sampleBusiness),
            dashboardMetricsProvider.overrideWith((ref) => populatedMetrics),
            todayFocusProvider.overrideWith((ref) => focusItems),
          ],
          child: const YaadibookApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify populated metric counts
      expect(find.text('45'), findsOneWidget);
      expect(
        find.text('3'),
        findsNWidgets(2),
      ); // metric count 3 & badge count 3
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Verify focus items render with customer names and source labels
      expect(find.text('Quarterly RO Purifier Servicing'), findsOneWidget);
      expect(find.text('Kailash Jewellers'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);

      expect(find.text('CCTV Annual Contract Renewal'), findsOneWidget);
      expect(find.text('Shree Krishna Electronics'), findsOneWidget);
      expect(find.text('AMC'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);

      expect(find.text('AC Gas Recharging & Filter Cleaning'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('₹1,450'), findsOneWidget);
    },
  );

  testWidgets('Notification bell opens Notification Centre with empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingJourneyStatusProvider.overrideWithValue(
            OnboardingJourneyStatus.completed,
          ),
          currentUserProfileProvider.overrideWith((ref) => sampleOwner),
          currentBusinessProvider.overrideWith((ref) => sampleBusiness),
          dashboardMetricsProvider.overrideWith((ref) => DashboardMetrics.zero),
          todayFocusProvider.overrideWith((ref) => const []),
        ],
        child: const YaadibookApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap notification bell in dashboard header
    await tester.tap(find.byIcon(Icons.notifications_none_outlined).first);
    await tester.pumpAndSettle();

    // Verify Notification Centre
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No new notifications'), findsOneWidget);
    expect(
      find.text("You're up to date with all your reminders and alerts."),
      findsOneWidget,
    );

    // Verify back navigation returns to dashboard
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text("Today's Focus"), findsOneWidget);
  });

  testWidgets(
    'Live language switching updates dashboard into Gujarati & Hindi',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          onboardingJourneyStatusProvider.overrideWithValue(
            OnboardingJourneyStatus.completed,
          ),
          currentUserProfileProvider.overrideWith((ref) => sampleOwner),
          currentBusinessProvider.overrideWith((ref) => sampleBusiness),
          dashboardMetricsProvider.overrideWith((ref) => DashboardMetrics.zero),
          todayFocusProvider.overrideWith((ref) => const []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YaadibookApp(),
        ),
      );
      await tester.pumpAndSettle();

      // English baseline
      expect(find.text("Today's Focus"), findsOneWidget);

      // Switch to Gujarati
      container.read(localeProvider.notifier).setLocale(AppLocales.gujarati);
      await tester.pumpAndSettle();

      expect(find.text("આજનું ફોકસ"), findsOneWidget);
      expect(find.text("કુલ ગ્રાહકો"), findsOneWidget);
      expect(find.text("બાકી સર્વિસ"), findsOneWidget);

      // Switch to Hindi
      container.read(localeProvider.notifier).setLocale(AppLocales.hindi);
      await tester.pumpAndSettle();

      expect(find.text("आज का फोकस"), findsOneWidget);
      expect(find.text("कुल ग्राहक"), findsOneWidget);
      expect(find.text("लंबित सेवाएं"), findsOneWidget);
    },
  );
}
