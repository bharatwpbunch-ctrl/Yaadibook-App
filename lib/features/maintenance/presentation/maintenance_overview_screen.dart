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
import '../../../core/widgets/yb_loading_state.dart';
import '../../../shared/models/maintenance_occurrence.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/maintenance_providers.dart';
import 'widgets/occurrence_card.dart';

/// Maintenance Overview dashboard screen displaying scheduled visits, metrics, and actions.
class MaintenanceOverviewScreen extends ConsumerStatefulWidget {
  const MaintenanceOverviewScreen({super.key});

  @override
  ConsumerState<MaintenanceOverviewScreen> createState() =>
      _MaintenanceOverviewScreenState();
}

class _MaintenanceOverviewScreenState
    extends ConsumerState<MaintenanceOverviewScreen> {
  Future<void> _showCompleteDialog(MaintenanceOccurrence occurrence) async {
    final l10n = context.l10n;
    DateTime completionDate = DateTime.now();
    final workController = TextEditingController();
    final notesController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.dialog),
          ),
          title: Text(l10n.maintenanceCompleteDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.maintenanceCompleteDialogMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Completion Date picker tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Completion Date',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(DateFormatter.formatDate(completionDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: completionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => completionDate = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Work performed
                TextField(
                  controller: workController,
                  decoration: InputDecoration(
                    labelText: l10n.maintenanceWorkPerformedLabel,
                    hintText: 'Work done or parts cleaned...',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Amount
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: l10n.maintenanceAmountLabel,
                    hintText: '0.00',
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              child: Text(l10n.maintenanceActionComplete),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final repo = ref.read(maintenanceRepositoryProvider);
        final amount = double.tryParse(amountController.text.trim());
        await repo.completeOccurrence(
          occurrenceId: occurrence.id,
          completionDate: completionDate,
          workPerformed: workController.text.trim().isNotEmpty
              ? workController.text.trim()
              : null,
          notes: notesController.text.trim().isNotEmpty
              ? notesController.text.trim()
              : null,
          amount: amount,
        );

        ref.invalidate(maintenanceOccurrencesListProvider);
        ref.invalidate(maintenanceOverviewCountsProvider);
        ref.invalidate(maintenancePlansListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.maintenanceVisitCompleted),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showSkipDialog(MaintenanceOccurrence occurrence) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
        title: Text(l10n.maintenanceSkipDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.maintenanceSkipDialogMessage,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.maintenanceSkipReasonLabel,
                hintText: l10n.maintenanceSkipReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(l10n.maintenanceActionSkip),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final repo = ref.read(maintenanceRepositoryProvider);
        await repo.skipOccurrence(
          occurrenceId: occurrence.id,
          reason: reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : null,
        );

        ref.invalidate(maintenanceOccurrencesListProvider);
        ref.invalidate(maintenanceOverviewCountsProvider);
        ref.invalidate(maintenancePlansListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.maintenanceVisitSkipped),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRescheduleDialog(MaintenanceOccurrence occurrence) async {
    final l10n = context.l10n;
    final picked = await showDatePicker(
      context: context,
      initialDate: occurrence.dueDate.isBefore(DateTime.now())
          ? DateTime.now()
          : occurrence.dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2035),
      helpText: l10n.maintenanceRescheduleNewDate,
    );

    if (picked != null) {
      try {
        final repo = ref.read(maintenanceRepositoryProvider);
        await repo.rescheduleOccurrence(
          occurrenceId: occurrence.id,
          newDueDate: picked,
        );

        ref.invalidate(maintenanceOccurrencesListProvider);
        ref.invalidate(maintenanceOverviewCountsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.maintenanceVisitRescheduled(
                  DateFormatter.formatDate(picked),
                ),
              ),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countsAsync = ref.watch(maintenanceOverviewCountsProvider);
    final occurrencesAsync = ref.watch(maintenanceOccurrencesListProvider);
    final activeFilter = ref.watch(occurrenceFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.maintenanceTitle,
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
          TextButton.icon(
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: Text(l10n.maintenancePlans),
            onPressed: () => context.push('/maintenance/plans'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.maintenanceScheduleVisit),
        onPressed: () => context.push('/maintenance/add'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(maintenanceOverviewCountsProvider);
          ref.invalidate(maintenanceOccurrencesListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // 1. Metric Counts Cards Row
            SliverToBoxAdapter(
              child: countsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
                error: (err, stack) => const SizedBox.shrink(),
                data: (counts) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      // Due Today
                      Expanded(
                        child: _MetricCard(
                          title: l10n.maintenanceDueToday,
                          count: counts.dueToday,
                          color: AppColors.warning,
                          bgColor: AppColors.warningBg,
                          icon: Icons.today_rounded,
                          isSelected:
                              activeFilter ==
                              MaintenanceOccurrenceFilter.dueToday,
                          onTap: () =>
                              ref
                                      .read(occurrenceFilterProvider.notifier)
                                      .state =
                                  MaintenanceOccurrenceFilter.dueToday,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Overdue
                      Expanded(
                        child: _MetricCard(
                          title: l10n.maintenanceOverdue,
                          count: counts.overdue,
                          color: AppColors.error,
                          bgColor: AppColors.errorBg,
                          icon: Icons.warning_amber_rounded,
                          isSelected:
                              activeFilter ==
                              MaintenanceOccurrenceFilter.overdue,
                          onTap: () =>
                              ref
                                      .read(occurrenceFilterProvider.notifier)
                                      .state =
                                  MaintenanceOccurrenceFilter.overdue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Upcoming
                      Expanded(
                        child: _MetricCard(
                          title: l10n.maintenanceUpcoming,
                          count: counts.upcoming,
                          color: AppColors.info,
                          bgColor: AppColors.infoBg,
                          icon: Icons.event_available_rounded,
                          isSelected:
                              activeFilter ==
                              MaintenanceOccurrenceFilter.upcoming,
                          onTap: () =>
                              ref
                                      .read(occurrenceFilterProvider.notifier)
                                      .state =
                                  MaintenanceOccurrenceFilter.upcoming,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Active Plans
                      Expanded(
                        child: _MetricCard(
                          title: l10n.maintenanceActivePlans,
                          count: counts.activePlans,
                          color: AppColors.success,
                          bgColor: AppColors.successBg,
                          icon: Icons.repeat_rounded,
                          isSelected: false,
                          onTap: () => context.push('/maintenance/plans'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Filter Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.serviceFilterAll,
                      selected: activeFilter == MaintenanceOccurrenceFilter.all,
                      onSelected: () =>
                          ref.read(occurrenceFilterProvider.notifier).state =
                              MaintenanceOccurrenceFilter.all,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.maintenanceDueToday,
                      selected:
                          activeFilter == MaintenanceOccurrenceFilter.dueToday,
                      onSelected: () =>
                          ref.read(occurrenceFilterProvider.notifier).state =
                              MaintenanceOccurrenceFilter.dueToday,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.maintenanceOverdue,
                      selected:
                          activeFilter == MaintenanceOccurrenceFilter.overdue,
                      onSelected: () =>
                          ref.read(occurrenceFilterProvider.notifier).state =
                              MaintenanceOccurrenceFilter.overdue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.maintenanceUpcoming,
                      selected:
                          activeFilter == MaintenanceOccurrenceFilter.upcoming,
                      onSelected: () =>
                          ref.read(occurrenceFilterProvider.notifier).state =
                              MaintenanceOccurrenceFilter.upcoming,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.maintenanceCompleted,
                      selected:
                          activeFilter == MaintenanceOccurrenceFilter.completed,
                      onSelected: () =>
                          ref.read(occurrenceFilterProvider.notifier).state =
                              MaintenanceOccurrenceFilter.completed,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Occurrences List / State
            occurrencesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: YbLoadingState()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: YbErrorState(
                  title: 'Failed to load maintenance visits',
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(maintenanceOccurrencesListProvider),
                ),
              ),
              data: (occurrences) {
                if (occurrences.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: YbEmptyState(
                      title: l10n.maintenanceEmptyOccurrences,
                      message:
                          'Keep equipment and client assets in peak condition with scheduled visits.',
                      icon: Icons.event_note_rounded,
                      actionLabel: l10n.maintenanceScheduleVisit,
                      onAction: () => context.push('/maintenance/add'),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final occ = occurrences[index];
                    return OccurrenceCard(
                      occurrence: occ,
                      onComplete: () => _showCompleteDialog(occ),
                      onSkip: () => _showSkipDialog(occ),
                      onReschedule: () => _showRescheduleDialog(occ),
                    );
                  }, childCount: occurrences.length),
                );
              },
            ),

            // Bottom Spacing for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
