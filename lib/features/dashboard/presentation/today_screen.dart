import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/widgets.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              DateFormatter.formatShort(
                now,
                locale: context.currentLocale.languageCode,
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.appTagline)));
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Welcome greeting banner
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardWelcome,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      AppSpacing.gapV4,
                      Text(
                        l10n.dashboardTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.trending_up,
                  size: 32,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          AppSpacing.gapV24,

          // Quick metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: l10n.dashboardPendingFollowups,
                  count: '3',
                  color: AppColors.warningText,
                  bg: AppColors.warningBg,
                ),
              ),
              AppSpacing.gapH12,
              Expanded(
                child: _buildMetricTile(
                  title: l10n.dashboardUpcomingServices,
                  count: '5',
                  color: AppColors.primaryDark,
                  bg: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          AppSpacing.gapV24,

          // Section 1: Today's Follow-up
          YbSectionHeader(
            title: l10n.remindersTitle,
            subtitle: l10n.remindersSubtitle,
            actionLabel: l10n.actionViewAll,
            onAction: () {},
          ),
          AppSpacing.gapV8,
          YbReminderCard(
            title: l10n.sampleReminderNote,
            customerName: l10n.sampleCustomerName,
            dueDateText: DateFormatter.formatShort(now),
            isOverdue: false,
            typeBadge: 'AMC',
            onTap: () {},
            onComplete: () {},
          ),
          AppSpacing.gapV20,

          // Section 2: Recent Services
          YbSectionHeader(
            title: l10n.dashboardUpcomingServices,
            actionLabel: l10n.actionViewAll,
            onAction: () {},
          ),
          AppSpacing.gapV8,
          YbServiceCard(
            serviceTitle: l10n.sampleServiceName,
            customerName: l10n.sampleCustomerName,
            dateText: DateFormatter.formatShort(now),
            amount: 1450,
            statusLabel: l10n.statusCompleted,
            statusType: YbStatusType.completed,
            onTap: () {},
          ),
          AppSpacing.gapV12,
          YbServiceCard(
            serviceTitle: 'CCTV 4-Cam Installation',
            customerName: 'Kailash Electronics',
            dateText: DateFormatter.formatShort(
              now.add(const Duration(days: 1)),
            ),
            amount: 18500,
            statusLabel: l10n.statusPending,
            statusType: YbStatusType.pending,
            onTap: () {},
          ),
          AppSpacing.gapV24,
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
