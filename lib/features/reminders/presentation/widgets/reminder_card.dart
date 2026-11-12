import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/communication_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/reminder.dart';
import '../../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../../communications/providers/communication_providers.dart';

class ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onComplete,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: reminder.isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : (reminder.isDueToday
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.borderSubtle),
          width: (reminder.isOverdue || reminder.isDueToday) ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category badge, priority badge & status chip
              Row(
                children: [
                  _buildCategoryBadge(context),
                  if (reminder.priority == 'high' ||
                      reminder.priority == 'urgent') ...[
                    AppSpacing.gapH8,
                    _buildPriorityBadge(),
                  ],
                  const Spacer(),
                  _buildStatusChip(context),
                ],
              ),
              AppSpacing.gapV8,

              // Title
              Text(
                reminder.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: reminder.isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: reminder.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),

              // Description if present
              if (reminder.description != null &&
                  reminder.description!.trim().isNotEmpty) ...[
                AppSpacing.gapV4,
                Text(
                  reminder.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              AppSpacing.gapV8,

              // Customer info & date row
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 14,
                    color: reminder.isOverdue
                        ? AppColors.error
                        : (reminder.isDueToday
                              ? AppColors.warning
                              : AppColors.textSecondary),
                  ),
                  AppSpacing.gapH4,
                  Text(
                    _formatDueDateTime(reminder.dueAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: reminder.isOverdue
                          ? AppColors.error
                          : (reminder.isDueToday
                                ? AppColors.warning
                                : AppColors.textSecondary),
                    ),
                  ),
                  if (reminder.customerName != null) ...[
                    AppSpacing.gapH12,
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapH4,
                    Expanded(
                      child: Text(
                        reminder.customerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Action buttons row if actionable
              if (!reminder.isCompleted && !reminder.isCancelled) ...[
                const Divider(height: 16, color: AppColors.borderSubtle),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (reminder.customerPhone != null &&
                          reminder.customerPhone!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.phone_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Call Customer',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  CommunicationService.makePhoneCall(
                                    reminder.customerPhone!,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chat_outlined,
                                size: 20,
                                color: AppColors.success,
                              ),
                              tooltip: 'Send WhatsApp Reminder',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                final ok = await ref
                                    .read(
                                      communicationComposerControllerProvider
                                          .notifier,
                                    )
                                    .sendOneClickReminder(
                                      category: _templateCategoryForReminder(
                                        reminder,
                                      ),
                                      recipientPhone: reminder.customerPhone!,
                                      recipientName:
                                          reminder.customerName ?? '',
                                      customerId: reminder.customerId,
                                      maintenanceOccurrenceId:
                                          reminder.maintenanceOccurrenceId,
                                      maintenanceDate:
                                          DateFormatter.formatShort(
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
                              icon: const Icon(
                                Icons.sms_outlined,
                                size: 20,
                                color: AppColors.info,
                              ),
                              tooltip: 'Compose WhatsApp / SMS',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => CommunicationComposerSheet.show(
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
                                amcEndDate: DateFormatter.formatShort(
                                  reminder.dueAt,
                                ),
                                preferredCategory: _templateCategoryForReminder(
                                  reminder,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.snooze_outlined, size: 16),
                            label: Text(l10n.remindersActionSnooze),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            onPressed: onSnooze,
                          ),
                          AppSpacing.gapH8,
                          FilledButton.icon(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: Text(l10n.remindersActionComplete),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            onPressed: onComplete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _templateCategoryForReminder(Reminder reminder) {
    switch (reminder.reminderType) {
      case 'maintenance':
        return 'maintenance_reminder';
      case 'amc':
        return 'amc_renewal';
      case 'service':
        return 'service_update';
      default:
        return 'follow_up';
    }
  }

  Widget _buildCategoryBadge(BuildContext context) {
    final l10n = context.l10n;
    final (label, icon, color) = switch (reminder.category) {
      'customer_followup' => (
        l10n.remindersCategoryFollowup,
        Icons.person_search_outlined,
        AppColors.info,
      ),
      'call_customer' => (
        l10n.remindersCategoryCall,
        Icons.phone_outlined,
        AppColors.primary,
      ),
      'payment_followup' => (
        l10n.remindersCategoryPayment,
        Icons.currency_rupee,
        AppColors.warning,
      ),
      'visit_customer' => (
        l10n.remindersCategoryVisit,
        Icons.location_on_outlined,
        Colors.teal,
      ),
      _ => switch (reminder.reminderType) {
        'maintenance' => (
          l10n.remindersSourceMaintenance,
          Icons.build_outlined,
          Colors.orange,
        ),
        'amc' => (
          l10n.remindersSourceAmc,
          Icons.verified_outlined,
          Colors.purple,
        ),
        _ => (
          l10n.remindersCategoryGeneral,
          Icons.task_alt_outlined,
          AppColors.textSecondary,
        ),
      },
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final isUrgent = reminder.priority == 'urgent';
    final color = isUrgent ? AppColors.error : AppColors.warning;
    final text = isUrgent ? 'URGENT' : 'HIGH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final l10n = context.l10n;
    if (reminder.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: BorderRadius.circular(AppRadii.badge),
        ),
        child: Text(
          l10n.remindersCompletedCount,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      );
    }

    if (reminder.isSnoozed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.badge),
        ),
        child: Text(
          l10n.remindersActionSnooze,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
      );
    }

    if (reminder.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.badge),
        ),
        child: Text(
          l10n.remindersOverdueCount,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      );
    }

    if (reminder.isDueToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(AppRadii.badge),
        ),
        child: Text(
          l10n.remindersDueTodayCount,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.warning,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        l10n.remindersUpcomingCount,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _formatDueDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (isToday) {
      return 'Today, $timeStr';
    }
    return '${DateFormatter.formatDate(dt)}, $timeStr';
  }
}
