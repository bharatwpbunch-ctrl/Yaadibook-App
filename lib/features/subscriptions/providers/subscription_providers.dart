import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/services/billing_service.dart';
import '../../../shared/models/subscription_models.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<ISubscriptionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSubscriptionRepository(client);
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).getPlans();
});

/// Central authoritative entitlements snapshot for the current business.
/// Falls back to Free baseline cleanly when unprovisioned or offline.
final entitlementsProvider = FutureProvider<EntitlementSnapshot>((ref) async {
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) {
    return EntitlementSnapshot.freeFallback('');
  }
  return ref
      .watch(subscriptionRepositoryProvider)
      .getBusinessEntitlements(business.id);
});

/// Authoritative entitlement flag derived from backend `get_business_entitlements`.
/// Replaces the development-only hardcoded true flag.
final isBulkMessagingEntitledProvider = Provider<bool>((ref) {
  final snap = ref.watch(entitlementsProvider).valueOrNull;
  return snap?.entitlements.canUseBulkMessaging ?? false;
});

final subscriptionTransactionsProvider =
    FutureProvider<List<SubscriptionTransactionRecord>>((ref) async {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) return const [];
      return ref
          .watch(subscriptionRepositoryProvider)
          .getTransactionHistory(business.id);
    });

class SubscriptionControllerState {
  final bool isBusy;
  final BillingPurchaseState billingState;
  final String? statusMessage;
  final List<ProductDetails> storeProducts;

  const SubscriptionControllerState({
    this.isBusy = false,
    this.billingState = BillingPurchaseState.idle,
    this.statusMessage,
    this.storeProducts = const [],
  });

  SubscriptionControllerState copyWith({
    bool? isBusy,
    BillingPurchaseState? billingState,
    String? statusMessage,
    bool clearMessage = false,
    List<ProductDetails>? storeProducts,
  }) {
    return SubscriptionControllerState(
      isBusy: isBusy ?? this.isBusy,
      billingState: billingState ?? this.billingState,
      statusMessage: clearMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      storeProducts: storeProducts ?? this.storeProducts,
    );
  }
}

class SubscriptionController
    extends StateNotifier<SubscriptionControllerState> {
  final Ref _ref;
  late final PlayBillingService _billingService;

  SubscriptionController(this._ref)
    : super(const SubscriptionControllerState()) {
    _billingService = PlayBillingService(
      _ref.read(subscriptionRepositoryProvider),
    );
  }

  Future<void> initializeForBusiness(String businessId) async {
    _billingService.bindBusiness(
      businessId,
      listener: (event) {
        final busy =
            event.state == BillingPurchaseState.purchasing ||
            event.state == BillingPurchaseState.verifying;
        state = state.copyWith(
          isBusy: busy,
          billingState: event.state,
          statusMessage: event.message,
        );
        if (event.state == BillingPurchaseState.purchased ||
            event.state == BillingPurchaseState.restored) {
          _ref.invalidate(entitlementsProvider);
          _ref.invalidate(subscriptionTransactionsProvider);
        }
      },
    );
    final products = await _billingService.loadStoreProducts();
    if (mounted) {
      state = state.copyWith(storeProducts: products);
    }
  }

  Future<void> startUpgrade(String productId) async {
    final matching = state.storeProducts
        .where((p) => p.id == productId)
        .toList();
    if (matching.isEmpty) {
      state = state.copyWith(
        billingState: BillingPurchaseState.storeUnavailable,
        statusMessage: _billingService.isPlatformSupported
            ? 'Google Play product "$productId" is not configured on Play Console yet.'
            : 'Google Play Billing checkout requires the Android Play Store release.',
      );
      return;
    }
    state = state.copyWith(isBusy: true, clearMessage: true);
    await _billingService.buySubscription(matching.first);
    if (mounted) {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isBusy: true, clearMessage: true);
    await _billingService.restorePurchases();
    _ref.invalidate(entitlementsProvider);
    _ref.invalidate(subscriptionTransactionsProvider);
    if (mounted) {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> refreshEntitlements() async {
    _ref.invalidate(entitlementsProvider);
    _ref.invalidate(subscriptionTransactionsProvider);
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionControllerState>((
      ref,
    ) {
      return SubscriptionController(ref);
    });
