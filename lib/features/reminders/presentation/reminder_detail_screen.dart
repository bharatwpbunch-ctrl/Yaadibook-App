import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/reminder.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';
import '../providers/reminder_providers.dart';

class ReminderDetailScreen extends ConsumerWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminderAsync = ref.watch(reminderDetailProvider(reminderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remindersDetailTitle),
        actions: [
          reminderAsync.when(
            data: (reminder) {
              if (reminder == null || reminder.isCompleted) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.remindersEditTitle,
                onPressed: () => context.push('/reminders/$reminderId/edit'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: reminderAsync.when(
        data: (reminder) {
          if (reminder == null) {
            return const Center(child: Text('Reminder not found'));
          }

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // 1. Status Banner Card
              _buildStatusBanner(context, reminder),
              AppSpacing.gapV16,

              // 2. Main Title & Description Card
              _buildDetailsCard(context, reminder),
              AppSpacing.gapV16,

              // 3. Linked Source Record Card (if applicable)
              if (reminder.maintenanceOccurrenceId != null ||
                  reminder.amcContractId != null ||
                  reminder.serviceId != null) ...[
                _buildSourceRecordCard(context, reminder),
                AppSpacing.gapV16,
              ],

              // 4. Linked Customer Card
              if (reminder.customerName != null) ...[
                _buildCustomerCard(context, ref, reminder),
                AppSpacing.gapV16,
              ],

              // 5. Completion or Snooze Info
              if (reminder.isCompleted || reminder.isSnoozed) ...[
                _buildAuditCard(context, reminder),
                AppSpacing.gapV16,
              ],

              // 6. Action Buttons
              if (!reminder.isCompleted && !reminder.isCancelled) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.snooze_outlined),
                        label: Text(l10n.remindersActionSnooze),
                        onPressed: () =>
                            _showSnoozeSheet(context, ref, reminder.id),
                      ),
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l10n.remindersActionComplete),
                        onPressed: () =>
                            _showCompleteDialog(context, ref, reminder.id),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV12,
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  label: Text(
                    l10n.remindersActionCancel,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  onPressed: () => _showCancelDialog(context, ref, reminder.id),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, Reminder reminder) {
    final l10n = context.l10n;
    final (color, icon, title, subtitle) = switch (reminder.effectiveStatus) {
      'completed' => (
        AppColors.success,
        Icons.check_circle,
        l10n.remindersCompletedCount,
        'This task has been completed.',
      ),
      'snoozed' => (
        Colors.blueGrey,
        Icons.snooze,
        'Snoozed',
        'Postponed until ${_formatDateTime(reminder.dueAt)}.',
      ),
      'overdue' => (
        AppColors.error,
        Icons.error_outline,
        l10n.remindersOverdueCount,
        'Due on ${_formatDateTime(reminder.dueAt)}.',
      ),
      'due' => (
        AppColors.warning,
        Icons.access_time_filled,
        l10n.remindersDueTodayCount,
        'Action required today.',
      ),
      _ => (
        AppColors.info,
        Icons.calendar_today,
        l10n.remindersUpcomingCount,
        'Scheduled for ${_formatDateTime(reminder.dueAt)}.',
      ),
    };

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          AppSpacing.gapH12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Reminder reminder) {
    final l10n = context.l10n;

    return Card(
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
              reminder.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (reminder.description != null &&
                reminder.description!.trim().isNotEmpty) ...[
              AppSpacing.gapV8,
              Text(
                reminder.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const Divider(height: 24, color: AppColors.borderSubtle),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.remindersDateLabel,
              value: _formatDateTime(reminder.dueAt),
            ),
            AppSpacing.gapV12,
            _buildDetailRow(
              icon: Icons.category_outlined,
              label: l10n.remindersCategoryLabel,
              value: reminder.category.replaceAll('_', ' ').toUpperCase(),
            ),
            AppSpacing.gapV12,
            _buildDetailRow(
              icon: Icons.flag_outlined,
              label: l10n.remindersPriorityLabel,
              value: reminder.priority.toUpperCase(),
              valueColor: reminder.priority == 'urgent'
                  ? AppColors.error
                  : (reminder.priority == 'high'
                        ? AppColors.warning
                        : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceRecordCard(BuildContext context, Reminder reminder) {
    final l10n = context.l10n;

    String sourceLabel = 'Linked Source';
    String route = '';
    IconData icon = Icons.link;

    if (reminder.maintenanceOccurrenceId != null) {
      sourceLabel = 'Maintenance Visit Record';
      route = '/maintenance/occurrences/${reminder.maintenanceOccurrenceId}';
      icon = Icons.build_outlined;
    } else if (reminder.amcContractId != null) {
      sourceLabel = 'AMC Contract Record';
      route = '/amc/${reminder.amcContractId}';
      icon = Icons.verified_outlined;
    } else if (reminder.serviceId != null) {
      sourceLabel = 'Service Entry Record';
      route = '/services/${reminder.serviceId}';
      icon = Icons.receipt_long_outlined;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          sourceLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(l10n.remindersSourceRecordLink),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push(route),
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) {
    return Card(
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
                  child: Text(
                    reminder.customerName!.isNotEmpty
                        ? reminder.customerName![0].toUpperCase()
                        : 'C',
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.customerName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reminder.customerPhone != null)
                        Text(
                          reminder.customerPhone!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (reminder.customerPhone != null &&
                    reminder.customerPhone!.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Call Customer',
                    onPressed: () => CommunicationService.makePhoneCall(
                      reminder.customerPhone!,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chat_outlined,
                      color: AppColors.success,
                    ),
                    tooltip: 'Send WhatsApp Reminder',
                    onPressed: () async {
                      final category = switch (reminder.reminderType) {
                        'maintenance' => 'maintenance_reminder',
                        'amc' => 'amc_renewal',
                        'service' => 'service_update',
                        _ => 'follow_up',
                      };
                      final ok = await ref
                          .read(
                            communicationComposerControllerProvider.notifier,
                          )
                          .sendOneClickReminder(
                            category: category,
                            recipientPhone: reminder.customerPhone!,
                            recipientName: reminder.customerName ?? '',
                            customerId: reminder.customerId,
                            maintenanceOccurrenceId:
                                reminder.maintenanceOccurrenceId,
                            maintenanceDate: DateFormatter.formatShort(
                              reminder.dueAt,
                            ),
                            amcContractId: reminder.amcContractId,
                            amcEndDate: DateFormatter.formatShort(
                              reminder.dueAt,
                            ),
                            title: reminder.title,
                          );
                      if (!ok && context.mounted) {
                        CommunicationService.openWhatsApp(
                          phoneNumber: reminder.customerPhone!,
                          message:
                              'Hello, regarding reminder: ${reminder.title}',
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sms_outlined, color: AppColors.info),
                    tooltip: 'Compose WhatsApp / SMS',
                    onPressed: () {
                      final category = switch (reminder.reminderType) {
                        'maintenance' => 'maintenance_reminder',
                        'amc' => 'amc_renewal',
                        'service' => 'service_update',
                        _ => 'follow_up',
                      };
                      CommunicationComposerSheet.show(
                        context,
                        phone: reminder.customerPhone,
                        name: reminder.customerName,
                        serviceId: reminder.serviceId,
                        serviceTitle: reminder.title,
                        maintenanceOccurrenceId:
                            reminder.maintenanceOccurrenceId,
                        maintenanceDate: DateFormatter.formatShort(
                          reminder.dueAt,
                        ),
                        amcContractId: reminder.amcContractId,
                        amcEndDate: DateFormatter.formatShort(reminder.dueAt),
                        preferredCategory: category,
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, Reminder reminder) {
    return Card(
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
            const Text(
              'Audit & History',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapV8,
            if (reminder.originalDueAt != null) ...[
              _buildDetailRow(
                icon: Icons.history,
                label: 'Original Due Date',
                value: _formatDateTime(reminder.originalDueAt!),
              ),
              AppSpacing.gapV8,
            ],
            if (reminder.completedAt != null) ...[
              _buildDetailRow(
                icon: Icons.done_all,
                label: 'Completed Timestamp',
                value: _formatDateTime(reminder.completedAt!),
              ),
              if (reminder.completedNotes != null) ...[
                AppSpacing.gapV8,
                _buildDetailRow(
                  icon: Icons.notes,
                  label: 'Completion Notes',
                  value: reminder.completedNotes!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        AppSpacing.gapH8,
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${DateFormatter.formatDate(dt)} at $timeStr';
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

  void _showCancelDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Reminder?'),
        content: const Text(
          'Are you sure you want to cancel this reminder task? You will not receive any further notifications for it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No, Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(reminderFormControllerProvider.notifier)
                  .cancelReminder(id);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder cancelled')),
                );
                context.pop();
              }
            },
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
  }
}
