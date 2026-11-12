import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_empty_state.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../shared/repositories/reminder_repository.dart';
import '../providers/reminder_providers.dart';
import 'widgets/reminder_card.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusFilter = ref.watch(reminderStatusFilterProvider);
    final sourceFilter = ref.watch(reminderSourceFilterProvider);
    final statsAsync = ref.watch(remindersOverviewStatsProvider);
    final remindersAsync = ref.watch(filteredRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remindersOverviewTitle),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Notification Centre',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(
              Icons.tune_outlined,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Notification Preferences',
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reminders/create'),
        icon: const Icon(Icons.add),
        label: Text(l10n.remindersCreateShortcut),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(remindersOverviewStatsProvider);
          ref.invalidate(filteredRemindersProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Metric Summary Header (4-card row) - Always rendered and interactive
            SliverToBoxAdapter(
              child: _buildMetricSummaryRow(
                context,
                ref,
                statsAsync: statsAsync,
                statusFilter: statusFilter,
              ),
            ),

            // 2. Status Filter Chips Row
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: l10n.remindersFilterAll,
                      isSelected: statusFilter == 'all',
                      onSelected: () =>
                          ref
                                  .read(reminderStatusFilterProvider.notifier)
                                  .state =
                              'all',
                    ),
                    AppSpacing.gapH8,
                    _buildFilterChip(
                      label: l10n.remindersDueTodayCount,
                      isSelected: statusFilter == 'today',
                      onSelected: () =>
                          ref
                                  .read(reminderStatusFilterProvider.notifier)
                                  .state =
                              'today',
                    ),
                    AppSpacing.gapH8,
                    _buildFilterChip(
                      label: l10n.remindersUpcomingCount,
                      isSelected: statusFilter == 'upcoming',
                      onSelected: () =>
                          ref
                                  .read(reminderStatusFilterProvider.notifier)
                                  .state =
                              'upcoming',
                    ),
                    AppSpacing.gapH8,
                    _buildFilterChip(
                      label: l10n.remindersOverdueCount,
                      isSelected: statusFilter == 'overdue',
                      onSelected: () =>
                          ref
                                  .read(reminderStatusFilterProvider.notifier)
                                  .state =
                              'overdue',
                    ),
                    AppSpacing.gapH8,
                    _buildFilterChip(
                      label: l10n.remindersCompletedCount,
                      isSelected: statusFilter == 'completed',
                      onSelected: () =>
                          ref
                                  .read(reminderStatusFilterProvider.notifier)
                                  .state =
                              'completed',
                    ),
                  ],
                ),
              ),
            ),

            // 3. Source Filter Chips Row
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _buildSourceChip(
                          label: l10n.remindersSourceAll,
                          isSelected: sourceFilter == 'all',
                          onSelected: () =>
                              ref
                                      .read(
                                        reminderSourceFilterProvider.notifier,
                                      )
                                      .state =
                                  'all',
                        ),
                        AppSpacing.gapH8,
                        _buildSourceChip(
                          label: l10n.remindersSourceMaintenance,
                          isSelected: sourceFilter == 'maintenance',
                          onSelected: () =>
                              ref
                                      .read(
                                        reminderSourceFilterProvider.notifier,
                                      )
                                      .state =
                                  'maintenance',
                        ),
                        AppSpacing.gapH8,
                        _buildSourceChip(
                          label: l10n.remindersSourceAmc,
                          isSelected: sourceFilter == 'amc',
                          onSelected: () =>
                              ref
                                      .read(
                                        reminderSourceFilterProvider.notifier,
                                      )
                                      .state =
                                  'amc',
                        ),
                        AppSpacing.gapH8,
                        _buildSourceChip(
                          label: l10n.remindersSourceFollowup,
                          isSelected: sourceFilter == 'follow_up',
                          onSelected: () =>
                              ref
                                      .read(
                                        reminderSourceFilterProvider.notifier,
                                      )
                                      .state =
                                  'follow_up',
                        ),
                        AppSpacing.gapH8,
                        _buildSourceChip(
                          label: l10n.remindersSourceGeneral,
                          isSelected: sourceFilter == 'general',
                          onSelected: () =>
                              ref
                                      .read(
                                        reminderSourceFilterProvider.notifier,
                                      )
                                      .state =
                                  'general',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 12, color: AppColors.borderSubtle),
                ],
              ),
            ),

            // 4. Reminders List / Empty State / Loading State / Error State
            ...remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    ),
                  ];
                }

                return [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: 88, // Clearance for FAB
                    ),
                    sliver: SliverList.builder(
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final rem = reminders[index];
                        return ReminderCard(
                          reminder: rem,
                          onTap: () => context.push('/reminders/${rem.id}'),
                          onComplete: () =>
                              _showCompleteDialog(context, ref, rem.id),
                          onSnooze: () =>
                              _showSnoozeSheet(context, ref, rem.id),
                        );
                      },
                    ),
                  ),
                ];
              },
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (err, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: YbErrorState(
                      title: 'Unable to load reminders',
                      message: err.toString(),
                      onRetry: () {
                        ref.invalidate(remindersOverviewStatsProvider);
                        ref.invalidate(filteredRemindersProvider);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSummaryRow(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<ReminderOverviewStats> statsAsync,
    required String statusFilter,
  }) {
    final l10n = context.l10n;
    final stats = statsAsync.valueOrNull ?? const ReminderOverviewStats();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: l10n.remindersDueTodayCount,
              count: stats.dueToday,
              color: AppColors.warning,
              isSelected: statusFilter == 'today',
              onTap: () {
                ref.read(reminderStatusFilterProvider.notifier).state = 'today';
              },
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildMetricCard(
              title: l10n.remindersOverdueCount,
              count: stats.overdue,
              color: AppColors.error,
              isSelected: statusFilter == 'overdue',
              onTap: () {
                ref.read(reminderStatusFilterProvider.notifier).state =
                    'overdue';
              },
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildMetricCard(
              title: l10n.remindersUpcomingCount,
              count: stats.upcoming,
              color: AppColors.info,
              isSelected: statusFilter == 'upcoming',
              onTap: () {
                ref.read(reminderStatusFilterProvider.notifier).state =
                    'upcoming';
              },
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: _buildMetricCard(
              title: l10n.remindersCompletedCount,
              count: stats.completed,
              color: AppColors.success,
              isSelected: statusFilter == 'completed',
              onTap: () {
                ref.read(reminderStatusFilterProvider.notifier).state =
                    'completed';
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: YbEmptyState(
          icon: Icons.task_alt_outlined,
          title: l10n.remindersEmptyCaughtUpTitle,
          message: l10n.remindersEmptyCaughtUpSubtitle,
          actionLabel: l10n.remindersCreateShortcut,
          onAction: () => context.push('/reminders/create'),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primaryContainer.withValues(alpha: 0.5),
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.borderSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildSourceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.textPrimary,
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
    );
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref, String id) {
    final l10n = context.l10n;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.remindersCompleteDialogTitle),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            hintText: l10n.remindersCompleteNotesHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(reminderFormControllerProvider.notifier)
                  .completeReminder(
                    id,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.remindersCompleteSuccess)),
                );
              }
            },
            child: Text(l10n.remindersActionComplete),
          ),
        ],
      ),
    );
  }

  void _showSnoozeSheet(BuildContext context, WidgetRef ref, String id) {
    final l10n = context.l10n;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l10n.remindersSnoozeTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AppSpacing.gapV8,
              ListTile(
                leading: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.remindersSnoozeLaterToday),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _applySnooze(
                    context,
                    ref,
                    id,
                    now.add(const Duration(hours: 3)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppColors.warning,
                ),
                title: Text(l10n.remindersSnoozeTomorrow),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final tomorrow = DateTime(
                    now.year,
                    now.month,
                    now.day + 1,
                    9,
                    0,
                  );
                  await _applySnooze(context, ref, id, tomorrow);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.teal,
                ),
                title: Text(l10n.remindersSnoozeIn3Days),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final target = DateTime(
                    now.year,
                    now.month,
                    now.day + 3,
                    9,
                    0,
                  );
                  await _applySnooze(context, ref, id, target);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.next_plan_outlined,
                  color: Colors.purple,
                ),
                title: Text(l10n.remindersSnoozeNextWeek),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final target = DateTime(
                    now.year,
                    now.month,
                    now.day + 7,
                    9,
                    0,
                  );
                  await _applySnooze(context, ref, id, target);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_calendar_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(l10n.remindersSnoozeCustom),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (pickedDate == null || !context.mounted) return;
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (!context.mounted) return;
                  final finalDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime?.hour ?? 9,
                    pickedTime?.minute ?? 0,
                  );
                  await _applySnooze(context, ref, id, finalDateTime);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applySnooze(
    BuildContext context,
    WidgetRef ref,
    String id,
    DateTime snoozeUntil,
  ) async {
    final l10n = context.l10n;
    final success = await ref
        .read(reminderFormControllerProvider.notifier)
        .snoozeReminder(id, snoozeUntil);

    if (context.mounted && success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.remindersSnoozeSuccess)));
    }
  }
}
