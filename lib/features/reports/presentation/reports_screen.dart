import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_empty_state.dart';
import '../models/report_models.dart';
import '../providers/report_providers.dart';
import '../services/report_export_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = ref.watch(reportDateRangeProvider);
    final reportAsync = ref.watch(businessReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsOverviewTitle),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => report == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    enabled: !_isExporting,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    onSelected: (val) => _handleExport(val, report),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf_outlined),
                          title: Text(l10n.reportsExportPdf),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'csv',
                        child: ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: Text(l10n.reportsExportCsv),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Customers'),
            Tab(text: 'Services & Amounts'),
            Tab(text: 'Maintenance'),
            Tab(text: 'AMC Contracts'),
            Tab(text: 'Follow-ups'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDatePresetStrip(context, range),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 40,
                        color: AppColors.error,
                      ),
                      AppSpacing.gapV12,
                      Text(err.toString(), textAlign: TextAlign.center),
                      AppSpacing.gapV12,
                      FilledButton(
                        onPressed: () => ref.invalidate(businessReportProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (report) {
                if (report == null) {
                  return const YbEmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'No business selected',
                    message: 'Select or set up a business to view reports.',
                  );
                }
                return Column(
                  children: [
                    if (report.isOfflineEstimate)
                      Container(
                        width: double.infinity,
                        color: AppColors.warning.withValues(alpha: 0.14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.reportsOfflineEstimateNotice,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(businessReportProvider),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(context, report),
                            _buildCustomersTab(report),
                            _buildServicesTab(report),
                            _buildMaintenanceTab(report),
                            _buildAmcTab(report),
                            _buildFollowupsTab(report),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePresetStrip(BuildContext context, ReportDateRange current) {
    final l10n = context.l10n;
    final presets = <(ReportDatePreset, String)>[
      (ReportDatePreset.thisMonth, l10n.reportsThisMonth),
      (ReportDatePreset.lastMonth, l10n.reportsLastMonth),
      (ReportDatePreset.last3Months, l10n.reportsLast3Months),
      (ReportDatePreset.last6Months, l10n.reportsLast6Months),
      (ReportDatePreset.thisYear, l10n.reportsThisYear),
      (ReportDatePreset.custom, l10n.reportsCustomRange),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: presets.map((item) {
                final (preset, label) = item;
                final selected = current.preset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => _selectPreset(preset, current),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
            child: Text(
              'Period: ${DateFormatter.formatDate(current.startDate)} – ${DateFormatter.formatDate(current.endDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPreset(
    ReportDatePreset preset,
    ReportDateRange current,
  ) async {
    if (preset == ReportDatePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(
          start: current.startDate,
          end: current.endDate,
        ),
      );
      if (picked != null) {
        ref.read(reportDateRangeProvider.notifier).state = ReportDateRange(
          preset: ReportDatePreset.custom,
          startDate: picked.start,
          endDate: picked.end,
        );
      }
      return;
    }

    ref.read(reportDateRangeProvider.notifier).state =
        ReportDateRange.fromPreset(preset);
  }

  Future<void> _handleExport(String format, BusinessReportData report) async {
    setState(() => _isExporting = true);
    try {
      if (format == 'pdf') {
        await ReportExportService.sharePdfReport(report);
      } else {
        await ReportExportService.shareCsvReport(report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildOverviewTab(BuildContext context, BusinessReportData report) {
    final l10n = context.l10n;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MetricGrid(
          cards: [
            _MetricCardData(
              title: 'Customers Added',
              value: '+${report.customers.newInPeriod}',
              subtitle: '${report.customers.totalActive} total active',
              icon: Icons.people_outline,
              color: AppColors.primary,
            ),
            _MetricCardData(
              title: 'Services Completed',
              value: '${report.services.completedCount}',
              subtitle: '${report.services.pendingCount} pending',
              icon: Icons.build_circle_outlined,
              color: AppColors.success,
            ),
            _MetricCardData(
              title: 'Recorded Amounts',
              value: CurrencyFormatter.formatINR(
                report.services.recordedAmountInr,
              ),
              subtitle:
                  'Paid: ${CurrencyFormatter.formatINR(report.services.paidAmountInr)}',
              icon: Icons.currency_rupee,
              color: Colors.teal,
            ),
            _MetricCardData(
              title: 'Active AMCs',
              value: '${report.amc.activeCount}',
              subtitle:
                  '${report.amc.expiringWithin30Days} expiring within 30d',
              icon: Icons.verified_user_outlined,
              color: Colors.indigo,
            ),
            _MetricCardData(
              title: 'Maintenance Visits',
              value:
                  '${report.maintenance.completedCount}/${report.maintenance.totalInPeriod}',
              subtitle: '${report.maintenance.overdueCount} overdue',
              icon: Icons.event_repeat_outlined,
              color: AppColors.warning,
            ),
            _MetricCardData(
              title: 'Follow-ups Done',
              value: '${report.followups.completedCount}',
              subtitle:
                  '${report.followups.pendingCount} pending • ${report.followups.overdueCount} overdue',
              icon: Icons.notifications_active_outlined,
              color: AppColors.info,
            ),
          ],
        ),
        AppSpacing.gapV20,
        _SectionCard(
          title: 'Collection Breakdown (Recorded Service Amounts)',
          child: Column(
            children: [
              _BarMetricRow(
                label: 'Collected (Paid)',
                valueText: CurrencyFormatter.formatINR(
                  report.services.paidAmountInr,
                ),
                fraction: report.services.recordedAmountInr > 0
                    ? report.services.paidAmountInr /
                          report.services.recordedAmountInr
                    : 0,
                color: AppColors.success,
              ),
              AppSpacing.gapV12,
              _BarMetricRow(
                label: 'Pending Collection',
                valueText: CurrencyFormatter.formatINR(
                  report.services.pendingAmountInr,
                ),
                fraction: report.services.recordedAmountInr > 0
                    ? report.services.pendingAmountInr /
                          report.services.recordedAmountInr
                    : 0,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
        AppSpacing.gapV16,
        _SectionCard(
          title: 'Export Report',
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExport('pdf', report),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.reportsExportPdf),
                ),
              ),
              AppSpacing.gapH12,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExport('csv', report),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(l10n.reportsExportCsv),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapV16,
        Text(
          l10n.reportsRecordedAmountsDisclaimer,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCustomersTab(BusinessReportData report) {
    final c = report.customers;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MetricGrid(
          cards: [
            _MetricCardData(
              title: 'Total Active',
              value: '${c.totalActive}',
              subtitle: 'Non-archived customers',
              icon: Icons.groups_outlined,
              color: AppColors.primary,
            ),
            _MetricCardData(
              title: 'New Added',
              value: '${c.newInPeriod}',
              subtitle: 'In selected period',
              icon: Icons.person_add_outlined,
              color: AppColors.success,
            ),
            _MetricCardData(
              title: 'Repeat Customers',
              value: '${c.repeatCustomers}',
              subtitle: '2+ service entries',
              icon: Icons.repeat_rounded,
              color: Colors.indigo,
            ),
            _MetricCardData(
              title: 'Active AMC Holders',
              value: '${c.withActiveAmc}',
              subtitle: 'Covered under contract',
              icon: Icons.verified_outlined,
              color: Colors.teal,
            ),
          ],
        ),
        AppSpacing.gapV20,
        _SectionCard(
          title: 'Top Customers by Service Activity',
          child: c.topCustomers.isEmpty
              ? const Text('No service activity in this period.')
              : Column(
                  children: c.topCustomers.map((item) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.customerName),
                      subtitle: Text(item.phone),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.servicesCount} service(s)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            CurrencyFormatter.formatINR(item.recordedAmount),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildServicesTab(BusinessReportData report) {
    final s = report.services;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MetricGrid(
          cards: [
            _MetricCardData(
              title: 'Active Services',
              value: '${s.totalActiveCount}',
              subtitle: '${s.cancelledCount} cancelled excluded',
              icon: Icons.home_repair_service_outlined,
              color: AppColors.primary,
            ),
            _MetricCardData(
              title: 'Completed',
              value: '${s.completedCount}',
              subtitle: '${s.pendingCount} pending/in-progress',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
            _MetricCardData(
              title: 'Recorded Service Value',
              value: CurrencyFormatter.formatINR(s.recordedAmountInr),
              subtitle: 'Excludes cancelled entries',
              icon: Icons.currency_rupee,
              color: Colors.teal,
            ),
            _MetricCardData(
              title: 'Pending Collection',
              value: CurrencyFormatter.formatINR(s.pendingAmountInr),
              subtitle: 'Unpaid / partially paid',
              icon: Icons.pending_actions_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
        AppSpacing.gapV16,
        if (s.byType.isNotEmpty)
          _SectionCard(
            title: 'Services by Category',
            child: Column(
              children: s.byType.entries.map((e) {
                final total = s.totalActiveCount == 0 ? 1 : s.totalActiveCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BarMetricRow(
                    label: e.key,
                    valueText: '${e.value}',
                    fraction: e.value / total,
                    color: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
        AppSpacing.gapV16,
        _SectionCard(
          title: 'Service Entries (${s.entries.length})',
          child: s.entries.isEmpty
              ? const Text('No service entries in the selected date range.')
              : Column(
                  children: s.entries.take(40).map((entry) {
                    final amt = entry.totalAmount ?? entry.serviceAmount ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.title),
                      subtitle: Text(
                        '${entry.customer?.fullName ?? 'Customer'} • ${DateFormatter.formatDate(entry.serviceDate)} • ${entry.status}',
                      ),
                      trailing: Text(
                        CurrencyFormatter.formatINR(amt),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: entry.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTab(BusinessReportData report) {
    final m = report.maintenance;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MetricGrid(
          cards: [
            _MetricCardData(
              title: 'Total Visits',
              value: '${m.totalInPeriod}',
              subtitle: 'Scheduled in period',
              icon: Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
            _MetricCardData(
              title: 'Completed',
              value: '${m.completedCount}',
              subtitle: 'Finished visits',
              icon: Icons.task_alt_outlined,
              color: AppColors.success,
            ),
            _MetricCardData(
              title: 'Upcoming',
              value: '${m.upcomingCount}',
              subtitle: 'Due on/after today',
              icon: Icons.schedule_outlined,
              color: AppColors.info,
            ),
            _MetricCardData(
              title: 'Overdue',
              value: '${m.overdueCount}',
              subtitle: 'Requires immediate attention',
              icon: Icons.warning_amber_outlined,
              color: AppColors.error,
            ),
          ],
        ),
        AppSpacing.gapV16,
        _SectionCard(
          title: 'Maintenance Visits (${m.rows.length})',
          child: m.rows.isEmpty
              ? const Text('No maintenance visits recorded for this period.')
              : Column(
                  children: m.rows.take(40).map((row) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row.title),
                      subtitle: Text(
                        '${row.customerName} • Due ${DateFormatter.formatDate(row.dueDate)}',
                      ),
                      trailing: Chip(
                        label: Text(row.status),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildAmcTab(BusinessReportData report) {
    final a = report.amc;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MetricGrid(
          cards: [
            _MetricCardData(
              title: 'Active Contracts',
              value: '${a.activeCount}',
              subtitle: '${a.renewedInPeriod} renewed in period',
              icon: Icons.verified_user_outlined,
              color: AppColors.success,
            ),
            _MetricCardData(
              title: 'Expiring <= 30d',
              value: '${a.expiringWithin30Days}',
              subtitle: 'Renewal pipeline',
              icon: Icons.timelapse_outlined,
              color: AppColors.warning,
            ),
            _MetricCardData(
              title: 'Expired',
              value: '${a.expiredCount}',
              subtitle: 'Past end date',
              icon: Icons.event_busy_outlined,
              color: AppColors.error,
            ),
            _MetricCardData(
              title: 'Contract Portfolio Value',
              value: CurrencyFormatter.formatINR(a.portfolioContractValueInr),
              subtitle: 'Active & renewed contracts',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.indigo,
            ),
          ],
        ),
        AppSpacing.gapV16,
        _SectionCard(
          title: 'AMC Contracts (${a.contracts.length})',
          child: a.contracts.isEmpty
              ? const Text('No AMC contracts recorded yet.')
              : Column(
                  children: a.contracts.take(40).map((c) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.contractTitle),
                      subtitle: Text(
                        '${c.customer?.fullName ?? 'Customer'} • Ends ${DateFormatter.formatDate(c.endDate)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatINR(c.contractAmount),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.status,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildFollowupsTab(BusinessReportData report) {
    final f = report.followups;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MetricGrid(
          cards: [
            _MetricCardData(
              title: 'Completed',
              value: '${f.completedCount}',
              subtitle: 'Closed follow-ups & tasks',
              icon: Icons.done_all_outlined,
              color: AppColors.success,
            ),
            _MetricCardData(
              title: 'Pending',
              value: '${f.pendingCount}',
              subtitle: 'Scheduled / snoozed',
              icon: Icons.notifications_none_outlined,
              color: AppColors.info,
            ),
            _MetricCardData(
              title: 'Overdue',
              value: '${f.overdueCount}',
              subtitle: 'Missed due date',
              icon: Icons.alarm_off_outlined,
              color: AppColors.error,
            ),
            _MetricCardData(
              title: 'Messages Logged',
              value:
                  '${report.communications.whatsappCount + report.communications.smsCount}',
              subtitle:
                  'WA: ${report.communications.whatsappCount} • SMS: ${report.communications.smsCount}',
              icon: Icons.chat_outlined,
              color: Colors.teal,
            ),
          ],
        ),
        AppSpacing.gapV16,
        _SectionCard(
          title: 'Follow-ups & Reminders (${f.reminders.length})',
          child: f.reminders.isEmpty
              ? const Text('No reminders scheduled in this period.')
              : Column(
                  children: f.reminders.take(40).map((r) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.title),
                      subtitle: Text(
                        '${r.customerName ?? 'General'} • ${DateFormatter.formatDate(r.dueAt)} • ${r.reminderType}',
                      ),
                      trailing: Chip(
                        label: Text(r.status),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricCardData> cards;

  const _MetricGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, idx) {
        final item = cards[idx];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 18, color: item.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          child,
        ],
      ),
    );
  }
}

class _BarMetricRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double fraction;
  final Color color;

  const _BarMetricRow({
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeFrac = fraction.isNaN || fraction < 0
        ? 0.0
        : (fraction > 1 ? 1.0 : fraction);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              valueText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: safeFrac,
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
