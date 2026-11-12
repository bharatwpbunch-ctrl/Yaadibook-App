import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../models/dashboard_metrics.dart';

class SummaryCardGrid extends StatelessWidget {
  final DashboardMetrics metrics;
  final bool isLoading;

  const SummaryCardGrid({
    super.key,
    required this.metrics,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n.metricTotalCustomers,
                count: metrics.totalCustomers,
                icon: Icons.people_alt_outlined,
                iconColor: AppColors.primary,
                bgColor: AppColors.primaryContainer.withValues(alpha: 0.3),
                isLoading: isLoading,
                onTap: () => context.go('/customers'),
              ),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: _MetricCard(
                title: l10n.metricPendingServices,
                count: metrics.pendingServices,
                icon: Icons.pending_actions_outlined,
                iconColor: AppColors.warningText,
                bgColor: AppColors.warningBg.withValues(alpha: 0.5),
                isLoading: isLoading,
                onTap: () => context.push('/services/list?status=pending'),
              ),
            ),
          ],
        ),
        AppSpacing.gapV12,
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n.metricMaintenanceDue,
                count: metrics.maintenanceDue,
                icon: Icons.build_circle_outlined,
                iconColor: AppColors.error,
                bgColor: AppColors.errorBg.withValues(alpha: 0.6),
                isLoading: isLoading,
                onTap: () => context.push('/maintenance'),
              ),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: _MetricCard(
                title: l10n.metricAmcExpiring,
                count: metrics.amcExpiringSoon,
                icon: Icons.verified_outlined,
                iconColor: AppColors.secondary,
                bgColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
                isLoading: isLoading,
                onTap: () => context.push('/amc?status=expiring'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                ],
              ),
              AppSpacing.gapV12,
              isLoading
                  ? const SizedBox(
                      height: 28,
                      width: 48,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
              AppSpacing.gapV4,
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
