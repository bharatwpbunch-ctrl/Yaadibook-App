import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/core/database/offline_store.dart';
import 'package:yaadibook/core/sync/connectivity_service.dart';
import 'package:yaadibook/core/sync/sync_providers.dart';
import 'package:yaadibook/features/offline_sync/presentation/offline_sync_screen.dart';
import 'package:yaadibook/features/reports/models/report_models.dart';
import 'package:yaadibook/features/reports/presentation/reports_screen.dart';
import 'package:yaadibook/features/reports/providers/report_providers.dart';
import 'package:yaadibook/features/settings/presentation/legal_and_deletion_screens.dart';
import 'package:yaadibook/features/subscriptions/presentation/subscription_screen.dart';
import 'package:yaadibook/features/subscriptions/providers/subscription_providers.dart';
import 'package:yaadibook/shared/models/subscription_models.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';

Widget _wrapApp(
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('gu', ''),
        Locale('hi', ''),
      ],
      home: child,
    ),
  );
}

void main() {
  testWidgets('ReportsScreen renders summary KPIs and disclaimer cleanly', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 12);
    final mockReport = BusinessReportData(
      businessId: 'b1',
      businessName: 'Bharat CCTV Company',
      businessPhone: '+919876543210',
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
      isOfflineEstimate: true,
      customers: const CustomerReportMetrics(totalActive: 14, newInPeriod: 3),
      services: const ServiceReportMetrics(
        totalActiveCount: 8,
        completedCount: 6,
        pendingCount: 2,
        recordedAmountInr: 18500,
        paidAmountInr: 12000,
        pendingAmountInr: 6500,
      ),
      maintenance: const MaintenanceReportMetrics(
        totalInPeriod: 5,
        completedCount: 3,
      ),
      amc: const AmcReportMetrics(activeCount: 4, expiringWithin30Days: 1),
      followups: const FollowupReportMetrics(
        completedCount: 7,
        pendingCount: 2,
      ),
      communications: const CommunicationReportMetrics(
        whatsappCount: 5,
        smsCount: 1,
      ),
      generatedAt: now,
    );

    await tester.pumpWidget(
      _wrapApp(
        const ReportsScreen(),
        overrides: [
          businessReportProvider.overrideWith((ref) async => mockReport),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Business Reports'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(
      find.textContaining('Offline mode: showing cached local data summary'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
  });

  testWidgets(
    'SubscriptionScreen renders Free plan, usage bars, and Pro upgrade cards',
    (tester) async {
      await tester.pumpWidget(
        _wrapApp(
          const SubscriptionScreen(),
          overrides: [
            currentBusinessProvider.overrideWith((ref) async => null),
            entitlementsProvider.overrideWith(
              (ref) async => EntitlementSnapshot.freeFallback('b1'),
            ),
            subscriptionPlansProvider.overrideWith(
              (ref) async => const [
                SubscriptionPlan.defaultFree,
                SubscriptionPlan(
                  code: 'pro_monthly',
                  name: 'Yaadibook Pro (Monthly)',
                  description: 'All pro tools',
                  billingPeriod: 'monthly',
                  priceInr: 299,
                  playProductId: 'yaadibook_pro_monthly',
                  maxMonthlyCampaignMessages: 1000,
                  canExportAdvancedReports: true,
                  canUseBulkMessaging: true,
                  canUseWhatsappApi: true,
                  canUseSmsApi: true,
                  features: ['Unlimited customers'],
                ),
              ],
            ),
            subscriptionTransactionsProvider.overrideWith(
              (ref) async => const [],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscription & Plan'), findsOneWidget);
      expect(find.text('Yaadibook Free'), findsNWidgets(2));
      expect(find.text('Yaadibook Pro (Monthly)'), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);
      expect(find.text('Upgrade via Google Play'), findsOneWidget);
    },
  );

  testWidgets(
    'OfflineSyncScreen renders status and trilingual Gujarati legal screen works',
    (tester) async {
      final store = InMemoryOfflineStore();
      await tester.pumpWidget(
        _wrapApp(
          const OfflineSyncScreen(),
          overrides: [
            offlineStoreProvider.overrideWithValue(store),
            isOnlineProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Sync & Storage'), findsOneWidget);
      expect(find.text('Offline Mode Active'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.text('Clear Local Cache'), findsOneWidget);
    },
  );

  testWidgets('DeleteAccountScreen renders Hindi localization and safeguard', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapApp(
        const DeleteAccountScreen(),
        locale: const Locale('hi'),
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => null),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('खाता और डेटा हटाएं'), findsOneWidget);
    expect(find.text('Permanently Delete Account'), findsOneWidget);
  });
}
