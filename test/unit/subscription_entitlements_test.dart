import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/features/subscriptions/providers/subscription_providers.dart';
import 'package:yaadibook/shared/models/subscription_models.dart';

void main() {
  group('EntitlementSnapshot & subscription gating', () {
    test('parses Free tier snapshot and customer limits accurately', () {
      final snap = EntitlementSnapshot.fromJson({
        'business_id': 'b1',
        'effective_plan_code': 'free',
        'plan_name': 'Yaadibook Free',
        'billing_period': 'free',
        'price_inr': 0,
        'subscription_status': 'active',
        'raw_plan_code': 'free',
        'entitlements': {
          'max_customers': 100,
          'max_monthly_campaign_messages': 0,
          'max_storage_bytes': 104857600,
          'can_export_advanced_reports': false,
          'can_use_bulk_messaging': false,
          'can_use_whatsapp_api': false,
          'can_use_sms_api': false,
        },
        'usage': {
          'customers_count': 100,
          'services_count': 12,
          'monthly_api_messages_count': 0,
          'storage_bytes_used': 5242880,
        },
        'evaluated_at': '2026-11-12T10:00:00Z',
      });

      expect(snap.isPro, isFalse);
      expect(snap.canAddCustomer, isFalse);
      expect(snap.remainingCustomerSlots, 0);
      expect(snap.entitlements.canUseBulkMessaging, isFalse);
    });

    test('parses active Pro snapshot and exposes remaining quota', () {
      final snap = EntitlementSnapshot.fromJson({
        'business_id': 'b1',
        'effective_plan_code': 'pro_monthly',
        'plan_name': 'Yaadibook Pro (Monthly)',
        'billing_period': 'monthly',
        'price_inr': 299,
        'subscription_status': 'grace_period',
        'raw_plan_code': 'pro_monthly',
        'current_period_end': '2026-12-12T10:00:00Z',
        'grace_period_end': '2026-12-15T10:00:00Z',
        'auto_renew': true,
        'entitlements': {
          'max_customers': null,
          'max_monthly_campaign_messages': 1000,
          'max_storage_bytes': 2147483648,
          'can_export_advanced_reports': true,
          'can_use_bulk_messaging': true,
          'can_use_whatsapp_api': true,
          'can_use_sms_api': true,
        },
        'usage': {
          'customers_count': 240,
          'services_count': 45,
          'monthly_api_messages_count': 125,
          'storage_bytes_used': 10485760,
        },
        'evaluated_at': '2026-11-12T10:00:00Z',
      });

      expect(snap.isPro, isTrue);
      expect(snap.isInGracePeriod, isTrue);
      expect(snap.canAddCustomer, isTrue);
      expect(snap.remainingCustomerSlots, isNull);
      expect(snap.remainingMonthlyMessages, 875);
      expect(snap.entitlements.canUseWhatsappApi, isTrue);
      expect(snap.entitlements.canUseSmsApi, isTrue);
    });

    test(
      'isBulkMessagingEntitledProvider derives directly from authoritative entitlementsProvider',
      () async {
        final containerFree = ProviderContainer(
          overrides: [
            entitlementsProvider.overrideWith(
              (ref) async => EntitlementSnapshot.freeFallback('b1'),
            ),
          ],
        );
        addTearDown(containerFree.dispose);
        await containerFree.read(entitlementsProvider.future);
        expect(containerFree.read(isBulkMessagingEntitledProvider), isFalse);

        final containerPro = ProviderContainer(
          overrides: [
            entitlementsProvider.overrideWith(
              (ref) async => EntitlementSnapshot(
                businessId: 'b1',
                effectivePlanCode: 'pro_monthly',
                planName: 'Yaadibook Pro (Monthly)',
                billingPeriod: 'monthly',
                subscriptionStatus: 'active',
                rawPlanCode: 'pro_monthly',
                entitlements: const EntitlementFlags(
                  maxCustomers: null,
                  maxMonthlyCampaignMessages: 1000,
                  canExportAdvancedReports: true,
                  canUseBulkMessaging: true,
                  canUseWhatsappApi: true,
                  canUseSmsApi: true,
                ),
                usage: const UsageMetrics(),
                evaluatedAt: DateTime.now().toUtc(),
              ),
            ),
          ],
        );
        addTearDown(containerPro.dispose);
        await containerPro.read(entitlementsProvider.future);
        expect(containerPro.read(isBulkMessagingEntitledProvider), isTrue);
      },
    );
  });
}
