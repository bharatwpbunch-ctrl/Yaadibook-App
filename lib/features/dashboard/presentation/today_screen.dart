import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../models/dashboard_metrics.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/summary_card_grid.dart';
import 'widgets/today_focus_section.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardMetricsProvider);
    ref.invalidate(todayFocusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final focusItemsAsync = ref.watch(todayFocusProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: metricsAsync.when(
            data: (metrics) => focusItemsAsync.when(
              data: (focusItems) => _buildContent(
                context,
                metrics: metrics,
                focusItems: focusItems,
                isLoading: false,
              ),
              loading: () => _buildContent(
                context,
                metrics: metrics,
                focusItems: const [],
                isLoading: true,
              ),
              error: (err, _) => _buildError(context, ref, err),
            ),
            loading: () => _buildContent(
              context,
              metrics: DashboardMetrics.zero,
              focusItems: const [],
              isLoading: true,
            ),
            error: (err, _) => _buildError(context, ref, err),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required DashboardMetrics metrics,
    required List<dynamic> focusItems,
    required bool isLoading,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      children: [
        const DashboardHeader(),
        AppSpacing.gapV20,
        SummaryCardGrid(metrics: metrics, isLoading: isLoading),
        AppSpacing.gapV24,
        TodayFocusSection(items: focusItems.cast(), isLoading: isLoading),
        AppSpacing.gapV32,
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      children: [
        const DashboardHeader(),
        AppSpacing.gapV48,
        YbErrorState(
          title: 'Unable to Load Dashboard',
          message:
              'Please check your network connection and try again. ($error)',
          onRetry: () => _refresh(ref),
        ),
      ],
    );
  }
}
