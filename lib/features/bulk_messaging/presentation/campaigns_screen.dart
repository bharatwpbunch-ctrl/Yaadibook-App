import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_empty_state.dart';
import '../../../shared/models/communication_campaign.dart';
import '../../communications/providers/communication_providers.dart';
import '../../subscriptions/providers/subscription_providers.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final campaignsAsync = ref.watch(campaignsListProvider);
    final isEntitled = ref.watch(isBulkMessagingEntitledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commCampaignsNavTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: l10n.commUsageTitle,
            onPressed: () => context.push('/communications/usage'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isEntitled
            ? () => context.push('/communications/campaigns/create')
            : () => _showUpgradePrompt(context),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(l10n.commCreateCampaignAction),
      ),
      body: Column(
        children: [
          // Entitlement Banner
          _buildEntitlementBanner(context, isEntitled),

          // Campaigns List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(campaignsListProvider);
              },
              child: campaignsAsync.when(
                data: (campaigns) {
                  if (campaigns.isEmpty) {
                    return Center(
                      child: YbEmptyState(
                        icon: Icons.campaign_outlined,
                        title: l10n.commCampaignsEmptyTitle,
                        message: l10n.commCampaignsEmptySubtitle,
                        actionLabel: l10n.commCreateCampaignAction,
                        onAction: isEntitled
                            ? () => context.push(
                                '/communications/campaigns/create',
                              )
                            : () => _showUpgradePrompt(context),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 8),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final camp = campaigns[index];
                      return _buildCampaignCard(context, camp);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntitlementBanner(BuildContext context, bool isEntitled) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isEntitled
            ? AppColors.successContainer.withValues(alpha: 0.4)
            : AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isEntitled ? AppColors.success : AppColors.primary,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEntitled ? Icons.verified_outlined : Icons.lock_outline,
            size: 20,
            color: isEntitled ? AppColors.success : AppColors.primary,
          ),
          AppSpacing.gapH8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEntitled
                      ? l10n.commEntitledBannerTitle
                      : l10n.commLockedBannerTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isEntitled ? AppColors.success : AppColors.primary,
                  ),
                ),
                Text(
                  isEntitled
                      ? l10n.commEntitledBannerSubtitle
                      : l10n.commLockedBannerSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    CommunicationCampaign campaign,
  ) {
    final isWa = campaign.channel == 'whatsapp';
    final channelIcon = isWa ? Icons.chat_outlined : Icons.sms_outlined;
    final channelColor = isWa ? AppColors.success : AppColors.info;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: () => context.push('/communications/campaigns/${campaign.id}'),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Title, Channel & Status Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: channelColor.withValues(alpha: 0.12),
                    child: Icon(channelIcon, size: 14, color: channelColor),
                  ),
                  AppSpacing.gapH8,
                  Expanded(
                    child: Text(
                      campaign.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _buildCampaignStatusBadge(campaign.status),
                ],
              ),
              AppSpacing.gapV12,

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: campaign.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(channelColor),
                ),
              ),
              AppSpacing.gapV8,

              // Metrics & Cost Row
              Row(
                children: [
                  Text(
                    '${campaign.successfulCount}/${campaign.totalRecipients} Sent',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (campaign.failedCount > 0) ...[
                    AppSpacing.gapH8,
                    Text(
                      '(${campaign.failedCount} Failed)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(
                      campaign.actualCostInr > 0
                          ? campaign.actualCostInr
                          : campaign.estimatedCostInr,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapV4,

              // Date
              Text(
                'Created ${DateFormatter.formatDate(campaign.createdAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignStatusBadge(String status) {
    final (label, color) = switch (status) {
      'completed' => ('Completed', AppColors.success),
      'processing' => ('Sending...', AppColors.warning),
      'scheduled' => ('Scheduled', AppColors.info),
      'failed' => ('Failed', AppColors.error),
      _ => ('Draft', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showUpgradePrompt(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.star_rounded, size: 36, color: Colors.amber),
        title: Text(l10n.commUpgradeDialogTitle),
        content: Text(l10n.commUpgradeDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/settings/subscription');
            },
            child: Text(l10n.commUpgradeAction),
          ),
        ],
      ),
    );
  }
}
