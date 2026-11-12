import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_empty_state.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../providers/communication_providers.dart';
import 'widgets/communication_composer_sheet.dart';

class CommunicationOverviewScreen extends ConsumerWidget {
  const CommunicationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(communicationStatsProvider);
    final logsAsync = ref.watch(communicationLogsProvider);
    final channelFilter = ref.watch(commChannelFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commOverviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: l10n.commUsageTitle,
            onPressed: () => context.push('/communications/usage'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.commSettingsTitle,
            onPressed: () => context.push('/communications/settings/whatsapp'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CommunicationComposerSheet.show(context),
        icon: const Icon(Icons.send_rounded),
        label: Text(l10n.commComposeAction),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communicationStatsProvider);
          ref.invalidate(communicationLogsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Metric Summary Cards
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _buildMetricCards(context, stats),
                loading: () => const Padding(
                  padding: AppSpacing.screenPadding,
                  child: Center(child: LinearProgressIndicator()),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // 2. Feature Navigation Hub (Templates, Campaigns, Usage)
            SliverToBoxAdapter(child: _buildNavigationHub(context)),

            // 3. Section Header & Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.commRecentActivityTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildChannelFilterChip(
                      label: l10n.remindersFilterAll,
                      isSelected: channelFilter == 'all',
                      onSelected: () =>
                          ref.read(commChannelFilterProvider.notifier).state =
                              'all',
                    ),
                    AppSpacing.gapH8,
                    _buildChannelFilterChip(
                      label: 'WhatsApp',
                      isSelected: channelFilter == 'whatsapp',
                      onSelected: () =>
                          ref.read(commChannelFilterProvider.notifier).state =
                              'whatsapp',
                    ),
                    AppSpacing.gapH8,
                    _buildChannelFilterChip(
                      label: 'SMS',
                      isSelected: channelFilter == 'sms',
                      onSelected: () =>
                          ref.read(commChannelFilterProvider.notifier).state =
                              'sms',
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Divider(height: 16, color: AppColors.borderSubtle),
            ),

            // 4. Communication Logs List
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: YbEmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: l10n.commLogsEmptyTitle,
                        message: l10n.commLogsEmptySubtitle,
                        actionLabel: l10n.commComposeAction,
                        onAction: () =>
                            CommunicationComposerSheet.show(context),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final log = logs[index];
                      return _buildLogCard(context, log);
                    }, childCount: logs.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: YbErrorState(
                    title: 'Unable to load communications',
                    message: err.toString(),
                    onRetry: () {
                      ref.invalidate(communicationStatsProvider);
                      ref.invalidate(communicationLogsProvider);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context, Map<String, int> stats) {
    final l10n = context.l10n;
    final total = stats['total'] ?? 0;
    final whatsapp = stats['whatsapp'] ?? 0;
    final sms = stats['sms'] ?? 0;
    final manualOpened = stats['manual_opened'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              title: l10n.commStatTotal,
              value: '$total',
              color: AppColors.primary,
              icon: Icons.mark_chat_read_outlined,
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildMetricItem(
              title: 'WhatsApp',
              value: '$whatsapp',
              color: AppColors.success,
              icon: Icons.chat_outlined,
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildMetricItem(
              title: 'SMS',
              value: '$sms',
              color: AppColors.info,
              icon: Icons.sms_outlined,
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildMetricItem(
              title: l10n.commStatOpened,
              value: '$manualOpened',
              color: AppColors.warning,
              icon: Icons.open_in_new_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          AppSpacing.gapV4,
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHub(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHubCard(
              context,
              icon: Icons.assignment_outlined,
              title: l10n.commTemplatesNavTitle,
              subtitle: l10n.commTemplatesNavSubtitle,
              color: AppColors.primary,
              onTap: () => context.push('/communications/templates'),
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildHubCard(
              context,
              icon: Icons.campaign_outlined,
              title: l10n.commCampaignsNavTitle,
              subtitle: l10n.commCampaignsNavSubtitle,
              color: Colors.deepPurple,
              onTap: () => context.push('/communications/campaigns'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 18, color: color),
                ],
              ),
              AppSpacing.gapV8,
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapV2,
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildChannelFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadii.badge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.badge),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, dynamic log) {
    final isWa = log.isWhatsApp;
    final channelColor = isWa ? AppColors.success : AppColors.info;
    final channelIcon = isWa ? Icons.chat_outlined : Icons.sms_outlined;

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
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    log.recipientName ?? log.recipientPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(context, log.status),
              ],
            ),
            AppSpacing.gapV8,
            Text(
              log.messageBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapV8,
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.gapH4,
                Text(
                  DateFormatter.formatDateTime(log.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  log.recipientPhone,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      'opened_in_app' => (l10n.commStatusOpenedInApp, AppColors.warning),
      'submitted' => (l10n.commStatusSubmitted, AppColors.info),
      'delivered' => (l10n.commStatusDelivered, AppColors.success),
      'read' => (l10n.commStatusRead, Colors.teal),
      'failed' => (l10n.commStatusFailed, AppColors.error),
      _ => (status.toUpperCase(), AppColors.textSecondary),
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
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
