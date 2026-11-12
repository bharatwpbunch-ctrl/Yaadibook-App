import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_secondary_button.dart';
import '../../../shared/repositories/service_repository.dart';
import '../providers/service_providers.dart';
import 'widgets/service_card.dart';

/// Services Overview dashboard displaying live statistics, pending actions, and recent records.
class ServicesOverviewScreen extends ConsumerWidget {
  const ServicesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summaryAsync = ref.watch(servicesSummaryProvider);
    final recentAsync = ref.watch(recentServicesProvider);
    final pendingAsync = ref.watch(pendingServicesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.servicesOverviewTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: l10n.addServiceTitle,
            onPressed: () => context.push('/services/add'),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: YbLoadingState()),
        error: (err, _) => YbErrorState(
          title: 'Failed to load services',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(servicesSummaryProvider);
            ref.invalidate(recentServicesProvider);
            ref.invalidate(pendingServicesListProvider);
          },
        ),
        data: (summary) {
          if (summary.totalServices == 0) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        size: 40,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    AppSpacing.gapV20,
                    Text(
                      l10n.serviceEmptyTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapV8,
                    Text(
                      l10n.serviceEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.gapV24,
                    YbPrimaryButton(
                      label: l10n.addServiceTitle,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => context.push('/services/add'),
                    ),
                    AppSpacing.gapV12,
                    YbSecondaryButton(
                      label: l10n.navCustomers,
                      icon: const Icon(Icons.people_outline_rounded),
                      onPressed: () => context.go('/customers'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(servicesSummaryProvider);
              ref.invalidate(recentServicesProvider);
              ref.invalidate(pendingServicesListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 4 Summary Metrics (2x2 Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: l10n
                            .metricTotalCustomers, // Reusing localized total or count
                        title: l10n.servicesOverviewTitle,
                        count: summary.totalServices,
                        icon: Icons.assignment_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primaryContainer,
                        onTap: () {
                          ref.read(serviceFilterProvider.notifier).state =
                              ServiceFilter.all;
                          context.push('/services/list');
                        },
                      ),
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Pending',
                        title: l10n.serviceStatusPending,
                        count: summary.pending,
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        bgColor: AppColors.warningBg,
                        onTap: () {
                          ref.read(serviceFilterProvider.notifier).state =
                              ServiceFilter.pending;
                          context.push('/services/list');
                        },
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV12,
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'In Progress',
                        title: l10n.serviceStatusInProgress,
                        count: summary.inProgress,
                        icon: Icons.engineering_outlined,
                        color: AppColors.info,
                        bgColor: AppColors.infoBg,
                        onTap: () {
                          ref.read(serviceFilterProvider.notifier).state =
                              ServiceFilter.inProgress;
                          context.push('/services/list');
                        },
                      ),
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Completed',
                        title: l10n.serviceStatusCompleted,
                        count: summary.completed,
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        bgColor: AppColors.successBg,
                        onTap: () {
                          ref.read(serviceFilterProvider.notifier).state =
                              ServiceFilter.completed;
                          context.push('/services/list');
                        },
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV16,

                // Quick Navigation to Full List
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(
                    Icons.list_alt_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    l10n.serviceViewAll,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  onPressed: () {
                    ref.read(serviceFilterProvider.notifier).state =
                        ServiceFilter.all;
                    context.push('/services/list');
                  },
                ),
                AppSpacing.gapV20,

                // Pending Section
                if (summary.pending > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.servicePendingHeader,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(serviceFilterProvider.notifier).state =
                              ServiceFilter.pending;
                          context.push('/services/list');
                        },
                        child: Text(l10n.serviceViewAll),
                      ),
                    ],
                  ),
                  AppSpacing.gapV8,
                  pendingAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, stack) => const SizedBox.shrink(),
                    data: (pendingList) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingList.length,
                        separatorBuilder: (ctx, i) => AppSpacing.gapV8,
                        itemBuilder: (ctx, i) =>
                            ServiceCard(service: pendingList[i]),
                      );
                    },
                  ),
                  AppSpacing.gapV20,
                ],

                // Recent Services Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.serviceRecentHeader,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(serviceFilterProvider.notifier).state =
                            ServiceFilter.all;
                        context.push('/services/list');
                      },
                      child: Text(l10n.serviceViewAll),
                    ),
                  ],
                ),
                AppSpacing.gapV8,
                recentAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  data: (recentList) {
                    if (recentList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text('No recent services found.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentList.length,
                      separatorBuilder: (ctx, i) => AppSpacing.gapV8,
                      itemBuilder: (ctx, i) =>
                          ServiceCard(service: recentList[i]),
                    );
                  },
                ),
                AppSpacing.gapV24,
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/services/add'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addServiceTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: count > 0
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            AppSpacing.gapV12,
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
