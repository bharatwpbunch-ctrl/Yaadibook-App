import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/subscription_models.dart';

abstract class ISubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();
  Future<EntitlementSnapshot> getBusinessEntitlements(String businessId);
  Future<List<SubscriptionTransactionRecord>> getTransactionHistory(
    String businessId,
  );
  Future<EntitlementSnapshot> verifyPlayPurchase({
    required String businessId,
    required String productId,
    required String purchaseToken,
    String? orderId,
    bool isRestore = false,
  });
  Future<void> requestAccountDeletion({
    required String confirmationPhrase,
    String? reason,
  });
}

class SupabaseSubscriptionRepository implements ISubscriptionRepository {
  final SupabaseClient? _client;

  SupabaseSubscriptionRepository([this._client]);

  SupabaseClient get _safeClient {
    final c = _client;
    if (c == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return c;
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final data = await _safeClient
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (data as List)
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.warning('getPlans fallback to defaults: $e\n$st');
      return const [
        SubscriptionPlan.defaultFree,
        SubscriptionPlan(
          code: 'pro_monthly',
          name: 'Yaadibook Pro (Monthly)',
          description:
              'Unlimited customers, advanced reports, WhatsApp/SMS APIs & bulk campaigns.',
          billingPeriod: 'monthly',
          priceInr: 299,
          playProductId: 'yaadibook_pro_monthly',
          maxCustomers: null,
          maxMonthlyCampaignMessages: 1000,
          maxStorageBytes: 2147483648,
          canExportAdvancedReports: true,
          canUseBulkMessaging: true,
          canUseWhatsappApi: true,
          canUseSmsApi: true,
          features: [
            'Unlimited customers',
            'Full Business & Revenue Reports',
            'Official WhatsApp & SMS APIs',
            'Up to 1,000 campaign messages/month',
            '2 GB attachment storage',
          ],
          sortOrder: 2,
        ),
        SubscriptionPlan(
          code: 'pro_yearly',
          name: 'Yaadibook Pro (Yearly)',
          description: 'Annual Pro billing with 2 months savings.',
          billingPeriod: 'yearly',
          priceInr: 2999,
          playProductId: 'yaadibook_pro_yearly',
          maxCustomers: null,
          maxMonthlyCampaignMessages: 1500,
          maxStorageBytes: 5368709120,
          canExportAdvancedReports: true,
          canUseBulkMessaging: true,
          canUseWhatsappApi: true,
          canUseSmsApi: true,
          features: [
            'Everything in Pro Monthly',
            '1,500 campaign messages/month',
            '5 GB attachment storage',
            '2 months free annually',
          ],
          sortOrder: 3,
        ),
      ];
    }
  }

  @override
  Future<EntitlementSnapshot> getBusinessEntitlements(String businessId) async {
    try {
      final res = await _safeClient.rpc(
        'get_business_entitlements',
        params: {'p_business_id': businessId},
      );
      if (res is Map<String, dynamic>) {
        return EntitlementSnapshot.fromJson(res);
      }
      if (res is Map) {
        return EntitlementSnapshot.fromJson(Map<String, dynamic>.from(res));
      }
      return EntitlementSnapshot.freeFallback(businessId);
    } catch (e) {
      AppLogger.warning(
        'getBusinessEntitlements RPC unavailable ($e), returning Free baseline',
      );
      return EntitlementSnapshot.freeFallback(businessId);
    }
  }

  @override
  Future<List<SubscriptionTransactionRecord>> getTransactionHistory(
    String businessId,
  ) async {
    try {
      final data = await _safeClient
          .from('subscription_transactions')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false)
          .limit(30);

      return (data as List)
          .map(
            (e) => SubscriptionTransactionRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.warning('getTransactionHistory unavailable: $e');
      return const [];
    }
  }

  @override
  Future<EntitlementSnapshot> verifyPlayPurchase({
    required String businessId,
    required String productId,
    required String purchaseToken,
    String? orderId,
    bool isRestore = false,
  }) async {
    final res = await _safeClient.functions.invoke(
      'verify-play-purchase',
      body: {
        'businessId': businessId,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'orderId': orderId,
        'isRestore': isRestore,
      },
    );

    if (res.status >= 400) {
      final data = res.data;
      final msg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Purchase verification failed (${res.status})';
      throw AppStorageException(msg);
    }

    final data = res.data;
    if (data is Map && data['snapshot'] is Map) {
      return EntitlementSnapshot.fromJson(
        Map<String, dynamic>.from(data['snapshot'] as Map),
      );
    }
    return getBusinessEntitlements(businessId);
  }

  @override
  Future<void> requestAccountDeletion({
    required String confirmationPhrase,
    String? reason,
  }) async {
    final res = await _safeClient.functions.invoke(
      'request-account-deletion',
      body: {
        'confirmationPhrase': confirmationPhrase,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    if (res.status >= 400) {
      final data = res.data;
      final msg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Account deletion request failed (${res.status})';
      throw AppStorageException(msg);
    }
  }
}
