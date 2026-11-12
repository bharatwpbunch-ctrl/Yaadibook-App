import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/logger.dart';
import '../../shared/repositories/subscription_repository.dart';

enum BillingPurchaseState {
  idle,
  loadingStore,
  purchasing,
  verifying,
  purchased,
  restored,
  pending,
  cancelled,
  storeUnavailable,
  error,
}

class BillingStatusEvent {
  final BillingPurchaseState state;
  final String? message;

  const BillingStatusEvent({required this.state, this.message});
}

/// Manages Google Play Billing lifecycle safely across Android and unsupported platforms (Web/Desktop).
/// Never unlocks Pro entitlements client-side without server verification via `verify-play-purchase`.
class PlayBillingService {
  static const Set<String> knownProductIds = {
    'yaadibook_pro_monthly',
    'yaadibook_pro_yearly',
  };

  final ISubscriptionRepository _subscriptionRepo;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  String? _activeBusinessId;
  void Function(BillingStatusEvent event)? onEvent;

  bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  PlayBillingService(this._subscriptionRepo);

  void bindBusiness(
    String businessId, {
    void Function(BillingStatusEvent event)? listener,
  }) {
    _activeBusinessId = businessId;
    onEvent = listener;
    if (!isPlatformSupported) return;

    _purchaseSub ??= InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object err) {
        AppLogger.error('PlayBillingService stream error', err);
        onEvent?.call(
          BillingStatusEvent(
            state: BillingPurchaseState.error,
            message: err.toString(),
          ),
        );
      },
    );
  }

  Future<List<ProductDetails>> loadStoreProducts() async {
    if (!isPlatformSupported) {
      return const [];
    }
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        onEvent?.call(
          const BillingStatusEvent(
            state: BillingPurchaseState.storeUnavailable,
            message:
                'Google Play Store billing is unavailable on this device/build.',
          ),
        );
        return const [];
      }
      final response = await InAppPurchase.instance.queryProductDetails(
        knownProductIds,
      );
      if (response.error != null) {
        AppLogger.warning(
          'PlayBillingService.queryProductDetails error: ${response.error?.message}',
        );
      }
      return response.productDetails;
    } catch (e) {
      AppLogger.warning('PlayBillingService.loadStoreProducts failed: $e');
      return const [];
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    if (!isPlatformSupported) {
      onEvent?.call(
        const BillingStatusEvent(
          state: BillingPurchaseState.storeUnavailable,
          message:
              'Google Play subscriptions can only be purchased on the Android Play Store build.',
        ),
      );
      return;
    }
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        onEvent?.call(
          const BillingStatusEvent(
            state: BillingPurchaseState.storeUnavailable,
            message: 'Google Play Billing is currently unavailable.',
          ),
        );
        return;
      }
      onEvent?.call(
        const BillingStatusEvent(state: BillingPurchaseState.purchasing),
      );
      final param = PurchaseParam(productDetails: product);
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      onEvent?.call(
        BillingStatusEvent(
          state: BillingPurchaseState.error,
          message: 'Could not launch Google Play checkout: $e',
        ),
      );
    }
  }

  Future<void> restorePurchases() async {
    if (!isPlatformSupported) {
      onEvent?.call(
        const BillingStatusEvent(
          state: BillingPurchaseState.storeUnavailable,
          message: 'Purchase restore requires the Android Google Play app.',
        ),
      );
      return;
    }
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      onEvent?.call(
        BillingStatusEvent(
          state: BillingPurchaseState.error,
          message: 'Failed to restore purchases: $e',
        ),
      );
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final businessId = _activeBusinessId;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onEvent?.call(
            const BillingStatusEvent(
              state: BillingPurchaseState.pending,
              message: 'Payment is pending confirmation from Google Play.',
            ),
          );
          break;
        case PurchaseStatus.canceled:
          onEvent?.call(
            const BillingStatusEvent(
              state: BillingPurchaseState.cancelled,
              message: 'Purchase was cancelled.',
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          onEvent?.call(
            BillingStatusEvent(
              state: BillingPurchaseState.error,
              message: purchase.error?.message ?? 'Purchase failed.',
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (businessId == null) {
            onEvent?.call(
              const BillingStatusEvent(
                state: BillingPurchaseState.error,
                message: 'No active business selected to attach subscription.',
              ),
            );
            continue;
          }
          onEvent?.call(
            const BillingStatusEvent(state: BillingPurchaseState.verifying),
          );
          try {
            final token = purchase.verificationData.serverVerificationData;
            await _subscriptionRepo.verifyPlayPurchase(
              businessId: businessId,
              productId: purchase.productID,
              purchaseToken: token,
              orderId: purchase.purchaseID,
              isRestore: purchase.status == PurchaseStatus.restored,
            );
            if (purchase.pendingCompletePurchase) {
              await InAppPurchase.instance.completePurchase(purchase);
            }
            onEvent?.call(
              BillingStatusEvent(
                state: purchase.status == PurchaseStatus.restored
                    ? BillingPurchaseState.restored
                    : BillingPurchaseState.purchased,
                message: 'Subscription verified and activated.',
              ),
            );
          } catch (e) {
            onEvent?.call(
              BillingStatusEvent(
                state: BillingPurchaseState.error,
                message: e.toString(),
              ),
            );
          }
          break;
      }
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
  }
}
