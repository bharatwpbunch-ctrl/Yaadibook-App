import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/subscription_models.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _initializedBizId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bizAsync = ref.watch(currentBusinessProvider);
    final entAsync = ref.watch(entitlementsProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final txAsync = ref.watch(subscriptionTransactionsProvider);
    final billingState = ref.watch(subscriptionControllerProvider);
    final billingCtrl = ref.read(subscriptionControllerProvider.notifier);

    final biz = bizAsync.valueOrNull;
    if (biz != null && _initializedBizId != biz.id) {
      _initializedBizId = biz.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        billingCtrl.initializeForBusiness(biz.id);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionTitle),
        actions: [
          TextButton(
            onPressed: billingState.isBusy
                ? null
                : billingCtrl.restorePurchases,
            child: Text(l10n.subscriptionRestoreAction),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => billingCtrl.refreshEntitlements(),
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            if (billingState.statusMessage != null) ...[
              Container(
                padding: AppSpacing.paddingMd,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  billingState.statusMessage!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            entAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Unable to load entitlements: $err'),
              data: (snap) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CurrentPlanCard(snapshot: snap),
                  AppSpacing.gapV16,
                  _UsageLimitsCard(
                    snapshot: snap,
                    title: l10n.subscriptionUsageTitle,
                  ),
                  AppSpacing.gapV20,
                  Text(
                    'Available Plans',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapV12,
                  plansAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load plans: $e'),
                    data: (plans) => Column(
                      children: plans.map((plan) {
                        final isCurrent = snap.effectivePlanCode == plan.code;
                        return _PlanCard(
                          plan: plan,
                          isCurrent: isCurrent,
                          isBusy: billingState.isBusy,
                          onUpgrade: plan.playProductId == null || isCurrent
                              ? null
                              : () => billingCtrl.startUpgrade(
                                  plan.playProductId!,
                                ),
                        );
                      }).toList(),
                    ),
                  ),
                  AppSpacing.gapV20,
                  Text(
                    'Subscription Billing History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapV8,
                  txAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load history: $e'),
                    data: (txs) {
                      if (txs.isEmpty) {
                        return Container(
                          padding: AppSpacing.paddingLg,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'No verified subscription transactions yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: txs.map((tx) {
                            return ListTile(
                              title: Text(
                                '${tx.planCode} (${tx.transactionType})',
                              ),
                              subtitle: Text(
                                '${DateFormatter.formatDateTime(tx.createdAt)} • ${tx.status}',
                              ),
                              trailing: Text(
                                CurrencyFormatter.formatINR(tx.amountInr),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final EntitlementSnapshot snapshot;

  const _CurrentPlanCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (snapshot.subscriptionStatus) {
      'active' => AppColors.success,
      'trial' => AppColors.info,
      'grace_period' => AppColors.warning,
      'cancelled' => Colors.orange,
      'expired' || 'revoked' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: snapshot.isPro ? AppColors.primary : AppColors.border,
          width: snapshot.isPro ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  snapshot.planName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.badge),
                ),
                child: Text(
                  snapshot.subscriptionStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            snapshot.isPro
                ? 'Active paid entitlements unlocked (${snapshot.billingPeriod}).'
                : 'Essential free plan. Core customer, service, maintenance, AMC, and reminder tools remain yours permanently.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (snapshot.currentPeriodEnd != null) ...[
            AppSpacing.gapV8,
            Text(
              snapshot.autoRenew
                  ? 'Renews on ${DateFormatter.formatDate(snapshot.currentPeriodEnd!.toLocal())}'
                  : 'Current period ends on ${DateFormatter.formatDate(snapshot.currentPeriodEnd!.toLocal())}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (snapshot.isInGracePeriod) ...[
            AppSpacing.gapV8,
            const Text(
              'Payment issue detected — your Pro features remain active during the Google Play grace period.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ] else if (snapshot.isExpired) ...[
            AppSpacing.gapV8,
            const Text(
              'Paid subscription expired. Your existing business records are safely preserved on the Free plan.',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageLimitsCard extends StatelessWidget {
  final EntitlementSnapshot snapshot;
  final String title;

  const _UsageLimitsCard({required this.snapshot, required this.title});

  @override
  Widget build(BuildContext context) {
    final maxCust = snapshot.entitlements.maxCustomers;
    final usedCust = snapshot.usage.customersCount;
    final maxMsg = snapshot.entitlements.maxMonthlyCampaignMessages;
    final usedMsg = snapshot.usage.monthlyApiMessagesCount;
    final usedMb = (snapshot.usage.storageBytesUsed / (1024 * 1024));
    final maxMb = (snapshot.entitlements.maxStorageBytes / (1024 * 1024));

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.gapV12,
          _UsageBar(
            label: 'Active Customers',
            valueLabel: maxCust == null
                ? '$usedCust / Unlimited'
                : '$usedCust / $maxCust',
            ratio: maxCust == null ? 0.15 : (usedCust / maxCust),
          ),
          AppSpacing.gapV12,
          _UsageBar(
            label: 'Monthly API / Campaign Messages',
            valueLabel: maxMsg == 0 ? 'Locked on Free' : '$usedMsg / $maxMsg',
            ratio: maxMsg == 0 ? 0 : (usedMsg / maxMsg),
          ),
          AppSpacing.gapV12,
          _UsageBar(
            label: 'Attachment Storage',
            valueLabel:
                '${usedMb.toStringAsFixed(1)} MB / ${maxMb.toStringAsFixed(0)} MB',
            ratio: maxMb == 0 ? 0 : (usedMb / maxMb),
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double ratio;

  const _UsageBar({
    required this.label,
    required this.valueLabel,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final safeRatio = ratio.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: safeRatio,
            minHeight: 7,
            backgroundColor: AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isBusy;
  final VoidCallback? onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isBusy,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                plan.priceInr == 0
                    ? 'Free'
                    : '${CurrencyFormatter.formatINR(plan.priceInr)} / ${plan.billingPeriod}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            plan.description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV12,
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          if (!plan.isFree) ...[
            AppSpacing.gapV12,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isCurrent || isBusy ? null : onUpgrade,
                child: Text(
                  isCurrent ? 'Current Plan' : 'Upgrade via Google Play',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
