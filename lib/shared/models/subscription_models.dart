/// Subscription plan definition synced from `subscription_plans` table.
class SubscriptionPlan {
  final String code;
  final String name;
  final String description;
  final String billingPeriod; // 'free', 'monthly', 'yearly'
  final double priceInr;
  final String? playProductId;
  final int? maxCustomers; // null = unlimited
  final int maxMonthlyCampaignMessages;
  final int maxStorageBytes;
  final bool canExportAdvancedReports;
  final bool canUseBulkMessaging;
  final bool canUseWhatsappApi;
  final bool canUseSmsApi;
  final List<String> features;
  final int sortOrder;

  const SubscriptionPlan({
    required this.code,
    required this.name,
    required this.description,
    required this.billingPeriod,
    required this.priceInr,
    this.playProductId,
    this.maxCustomers,
    this.maxMonthlyCampaignMessages = 0,
    this.maxStorageBytes = 104857600,
    this.canExportAdvancedReports = false,
    this.canUseBulkMessaging = false,
    this.canUseWhatsappApi = false,
    this.canUseSmsApi = false,
    this.features = const [],
    this.sortOrder = 0,
  });

  bool get isFree => code == 'free';

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features_json'];
    final featuresList = rawFeatures is List
        ? rawFeatures.map((e) => e.toString()).toList()
        : <String>[];

    return SubscriptionPlan(
      code: json['code'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      billingPeriod: (json['billing_period'] as String?) ?? 'free',
      priceInr: (json['price_inr'] as num?)?.toDouble() ?? 0.0,
      playProductId: json['play_product_id'] as String?,
      maxCustomers: (json['max_customers'] as num?)?.toInt(),
      maxMonthlyCampaignMessages:
          (json['max_monthly_campaign_messages'] as num?)?.toInt() ?? 0,
      maxStorageBytes:
          (json['max_storage_bytes'] as num?)?.toInt() ?? 104857600,
      canExportAdvancedReports:
          (json['can_export_advanced_reports'] as bool?) ?? false,
      canUseBulkMessaging: (json['can_use_bulk_messaging'] as bool?) ?? false,
      canUseWhatsappApi: (json['can_use_whatsapp_api'] as bool?) ?? false,
      canUseSmsApi: (json['can_use_sms_api'] as bool?) ?? false,
      features: featuresList,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static const SubscriptionPlan defaultFree = SubscriptionPlan(
    code: 'free',
    name: 'Yaadibook Free',
    description:
        'Essential customer, service, maintenance, AMC, and reminder tools.',
    billingPeriod: 'free',
    priceInr: 0,
    maxCustomers: 100,
    maxMonthlyCampaignMessages: 0,
    maxStorageBytes: 104857600,
    features: [
      'Up to 100 active customers',
      'Services, Maintenance & AMC tracking',
      'Unified Reminders & Notifications',
      'Manual WhatsApp & SMS shortcuts',
      'Standard CSV & PDF overview export',
      'Offline access & auto sync',
    ],
  );
}

class EntitlementFlags {
  final int? maxCustomers;
  final int maxMonthlyCampaignMessages;
  final int maxStorageBytes;
  final bool canExportAdvancedReports;
  final bool canUseBulkMessaging;
  final bool canUseWhatsappApi;
  final bool canUseSmsApi;

  const EntitlementFlags({
    this.maxCustomers = 100,
    this.maxMonthlyCampaignMessages = 0,
    this.maxStorageBytes = 104857600,
    this.canExportAdvancedReports = false,
    this.canUseBulkMessaging = false,
    this.canUseWhatsappApi = false,
    this.canUseSmsApi = false,
  });

  factory EntitlementFlags.fromJson(Map<String, dynamic> json) {
    return EntitlementFlags(
      maxCustomers: (json['max_customers'] as num?)?.toInt(),
      maxMonthlyCampaignMessages:
          (json['max_monthly_campaign_messages'] as num?)?.toInt() ?? 0,
      maxStorageBytes:
          (json['max_storage_bytes'] as num?)?.toInt() ?? 104857600,
      canExportAdvancedReports:
          (json['can_export_advanced_reports'] as bool?) ?? false,
      canUseBulkMessaging: (json['can_use_bulk_messaging'] as bool?) ?? false,
      canUseWhatsappApi: (json['can_use_whatsapp_api'] as bool?) ?? false,
      canUseSmsApi: (json['can_use_sms_api'] as bool?) ?? false,
    );
  }
}

class UsageMetrics {
  final int customersCount;
  final int servicesCount;
  final int monthlyApiMessagesCount;
  final int storageBytesUsed;

  const UsageMetrics({
    this.customersCount = 0,
    this.servicesCount = 0,
    this.monthlyApiMessagesCount = 0,
    this.storageBytesUsed = 0,
  });

  factory UsageMetrics.fromJson(Map<String, dynamic> json) {
    return UsageMetrics(
      customersCount: (json['customers_count'] as num?)?.toInt() ?? 0,
      servicesCount: (json['services_count'] as num?)?.toInt() ?? 0,
      monthlyApiMessagesCount:
          (json['monthly_api_messages_count'] as num?)?.toInt() ?? 0,
      storageBytesUsed: (json['storage_bytes_used'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Authoritative entitlement snapshot computed server-side via `get_business_entitlements`.
class EntitlementSnapshot {
  final String businessId;
  final String effectivePlanCode;
  final String planName;
  final String billingPeriod;
  final double priceInr;
  final String subscriptionStatus;
  final String rawPlanCode;
  final String storeProvider;
  final String? productId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? gracePeriodEnd;
  final bool autoRenew;
  final DateTime? cancelledAt;
  final EntitlementFlags entitlements;
  final UsageMetrics usage;
  final DateTime evaluatedAt;

  const EntitlementSnapshot({
    required this.businessId,
    required this.effectivePlanCode,
    required this.planName,
    required this.billingPeriod,
    this.priceInr = 0,
    required this.subscriptionStatus,
    required this.rawPlanCode,
    this.storeProvider = 'system',
    this.productId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.gracePeriodEnd,
    this.autoRenew = false,
    this.cancelledAt,
    required this.entitlements,
    required this.usage,
    required this.evaluatedAt,
  });

  bool get isPro => effectivePlanCode != 'free';
  bool get isInGracePeriod => subscriptionStatus == 'grace_period';
  bool get isPending => subscriptionStatus == 'pending';
  bool get isCancelled => subscriptionStatus == 'cancelled';
  bool get isExpired =>
      subscriptionStatus == 'expired' || subscriptionStatus == 'revoked';

  bool get canAddCustomer {
    final limit = entitlements.maxCustomers;
    if (limit == null) return true;
    return usage.customersCount < limit;
  }

  int? get remainingCustomerSlots {
    final limit = entitlements.maxCustomers;
    if (limit == null) return null;
    final rem = limit - usage.customersCount;
    return rem < 0 ? 0 : rem;
  }

  int get remainingMonthlyMessages {
    final rem =
        entitlements.maxMonthlyCampaignMessages - usage.monthlyApiMessagesCount;
    return rem < 0 ? 0 : rem;
  }

  factory EntitlementSnapshot.freeFallback(String businessId) {
    return EntitlementSnapshot(
      businessId: businessId,
      effectivePlanCode: 'free',
      planName: 'Yaadibook Free',
      billingPeriod: 'free',
      priceInr: 0,
      subscriptionStatus: 'active',
      rawPlanCode: 'free',
      storeProvider: 'system',
      entitlements: const EntitlementFlags(),
      usage: const UsageMetrics(),
      evaluatedAt: DateTime.now().toUtc(),
    );
  }

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return EntitlementSnapshot(
      businessId: json['business_id'] as String? ?? '',
      effectivePlanCode: (json['effective_plan_code'] as String?) ?? 'free',
      planName: (json['plan_name'] as String?) ?? 'Yaadibook Free',
      billingPeriod: (json['billing_period'] as String?) ?? 'free',
      priceInr: (json['price_inr'] as num?)?.toDouble() ?? 0.0,
      subscriptionStatus: (json['subscription_status'] as String?) ?? 'active',
      rawPlanCode: (json['raw_plan_code'] as String?) ?? 'free',
      storeProvider: (json['store_provider'] as String?) ?? 'system',
      productId: json['product_id'] as String?,
      currentPeriodStart: parseDt(json['current_period_start']),
      currentPeriodEnd: parseDt(json['current_period_end']),
      gracePeriodEnd: parseDt(json['grace_period_end']),
      autoRenew: (json['auto_renew'] as bool?) ?? false,
      cancelledAt: parseDt(json['cancelled_at']),
      entitlements: EntitlementFlags.fromJson(
        (json['entitlements'] as Map<String, dynamic>?) ?? const {},
      ),
      usage: UsageMetrics.fromJson(
        (json['usage'] as Map<String, dynamic>?) ?? const {},
      ),
      evaluatedAt: parseDt(json['evaluated_at']) ?? DateTime.now().toUtc(),
    );
  }
}

class SubscriptionTransactionRecord {
  final String id;
  final String planCode;
  final String transactionType;
  final String storeProvider;
  final String? productId;
  final String? externalTransactionId;
  final double amountInr;
  final String currency;
  final String status;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const SubscriptionTransactionRecord({
    required this.id,
    required this.planCode,
    required this.transactionType,
    required this.storeProvider,
    this.productId,
    this.externalTransactionId,
    required this.amountInr,
    this.currency = 'INR',
    required this.status,
    this.verifiedAt,
    required this.createdAt,
  });

  factory SubscriptionTransactionRecord.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransactionRecord(
      id: json['id'] as String,
      planCode: (json['plan_code'] as String?) ?? 'free',
      transactionType: (json['transaction_type'] as String?) ?? 'purchase',
      storeProvider: (json['store_provider'] as String?) ?? 'google_play',
      productId: json['product_id'] as String?,
      externalTransactionId: json['external_transaction_id'] as String?,
      amountInr: (json['amount_inr'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'INR',
      status: (json['status'] as String?) ?? 'verified',
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
