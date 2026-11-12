import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/communication_providers.dart';

class CommunicationUsageScreen extends ConsumerWidget {
  const CommunicationUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final usageAsync = ref.watch(communicationUsageSummaryProvider);
    final statsAsync = ref.watch(communicationStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commUsageTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communicationUsageSummaryProvider);
          ref.invalidate(communicationStatsProvider);
        },
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Top Summary Card
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
                    Text(
                      l10n.commUsageSummaryTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV12,
                    statsAsync.when(
                      data: (stats) {
                        final total = stats['total'] ?? 0;
                        final wa = stats['whatsapp'] ?? 0;
                        final sms = stats['sms'] ?? 0;
                        final estCost = (wa * 0.85) + (sms * 0.20);

                        return Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'Total Messages',
                                '$total',
                                AppColors.primary,
                              ),
                            ),
                            AppSpacing.gapH12,
                            Expanded(
                              child: _buildMetricTile(
                                'Est. Cost',
                                CurrencyFormatter.format(estCost),
                                AppColors.success,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapV16,

            // Pricing Transparency Note
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Standard Indian Commercial Messaging Rates',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapV8,
                  const Text(
                    '• WhatsApp Business Cloud API: ~₹0.85 per delivered marketing / utility message.\n• Indian DLT-Compliant SMS: ~₹0.20 per 160-character transactional SMS.\n• Manual dispatch via device apps: ₹0.00 (included with your phone plan).',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapV16,

            // Daily Usage Breakdown
            const Text(
              'Daily Usage Records',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapV8,
            usageAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'No API gateway usage recorded yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children: records.map((u) {
                    final isWa = u.channel == 'whatsapp';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isWa
                              ? AppColors.successContainer
                              : AppColors.info.withValues(alpha: 0.12),
                          child: Icon(
                            isWa ? Icons.chat_outlined : Icons.sms_outlined,
                            size: 16,
                            color: isWa ? AppColors.success : AppColors.info,
                          ),
                        ),
                        title: Text(
                          '${u.channel.toUpperCase()} (${u.category})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          DateFormatter.formatDate(u.usageDate),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${u.messageCount} msgs',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(u.totalCostInr),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading usage: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          AppSpacing.gapV2,
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
