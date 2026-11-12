import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../communications/providers/communication_providers.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final recipientsAsync = ref.watch(campaignRecipientsProvider(campaignId));

    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Details')),
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return const Center(child: Text('Campaign not found'));
          }

          final isWa = campaign.channel == 'whatsapp';
          final channelColor = isWa ? AppColors.success : AppColors.info;
          final channelIcon = isWa ? Icons.chat_outlined : Icons.sms_outlined;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(campaignDetailProvider(campaignId));
              ref.invalidate(campaignRecipientsProvider(campaignId));
            },
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // Top Header Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: channelColor.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                channelIcon,
                                size: 16,
                                color: channelColor,
                              ),
                            ),
                            AppSpacing.gapH8,
                            Expanded(
                              child: Text(
                                campaign.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _buildStatusBadge(campaign.status),
                          ],
                        ),
                        AppSpacing.gapV12,

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: campaign.progress,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              channelColor,
                            ),
                          ),
                        ),
                        AppSpacing.gapV12,

                        // Metric Counters Row
                        Row(
                          children: [
                            _buildMetricItem(
                              'Total',
                              '${campaign.totalRecipients}',
                              AppColors.primary,
                            ),
                            const Spacer(),
                            _buildMetricItem(
                              'Delivered',
                              '${campaign.successfulCount}',
                              AppColors.success,
                            ),
                            const Spacer(),
                            _buildMetricItem(
                              'Failed',
                              '${campaign.failedCount}',
                              AppColors.error,
                            ),
                            const Spacer(),
                            _buildMetricItem(
                              'Cost',
                              CurrencyFormatter.format(
                                campaign.actualCostInr > 0
                                    ? campaign.actualCostInr
                                    : campaign.estimatedCostInr,
                              ),
                              AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapV16,

                // Recipients Section Header
                const Text(
                  'Recipients Dispatch Log',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapV8,

                // Recipients List
                recipientsAsync.when(
                  data: (recipients) {
                    if (recipients.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: Text(
                            'No recipients recorded for this campaign.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: recipients.map((r) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            side: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            title: Text(
                              r.customerName ?? r.customerPhone,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              r.customerPhone,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: _buildRecipientStatusBadge(
                              r.submissionStatus,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading recipients: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final (label, color) = switch (status) {
      'completed' => ('Completed', AppColors.success),
      'processing' => ('In Progress', AppColors.warning),
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

  Widget _buildRecipientStatusBadge(String status) {
    final (label, color) = switch (status) {
      'delivered' => ('Delivered', AppColors.success),
      'submitted' => ('Submitted', AppColors.info),
      'skipped_opted_out' => ('Opted Out', AppColors.warning),
      'failed' => ('Failed', AppColors.error),
      _ => ('Pending', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
