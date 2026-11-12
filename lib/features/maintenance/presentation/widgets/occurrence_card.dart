import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/maintenance_occurrence.dart';
import '../../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../../communications/providers/communication_providers.dart';

/// Interactive card presenting a scheduled, due, or completed maintenance visit.
class OccurrenceCard extends ConsumerWidget {
  final MaintenanceOccurrence occurrence;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onReschedule;

  const OccurrenceCard({
    super.key,
    required this.occurrence,
    this.onComplete,
    this.onSkip,
    this.onReschedule,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return AppColors.error;
      case 'due':
        return AppColors.warning;
      case 'upcoming':
      case 'scheduled':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'skipped':
      case 'cancelled':
      default:
        return AppColors.textMuted;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return AppColors.errorBg;
      case 'due':
        return AppColors.warningBg;
      case 'upcoming':
      case 'scheduled':
        return AppColors.infoBg;
      case 'completed':
        return AppColors.successBg;
      case 'skipped':
      case 'cancelled':
      default:
        return AppColors.surfaceVariant;
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    final l10n = context.l10n;
    switch (status.toLowerCase()) {
      case 'overdue':
        return l10n.maintenanceOverdue;
      case 'due':
        return l10n.maintenanceDueToday;
      case 'upcoming':
      case 'scheduled':
        return l10n.maintenanceUpcoming;
      case 'completed':
        return l10n.maintenanceCompleted;
      case 'skipped':
        return l10n.maintenanceSkipped;
      case 'cancelled':
        return l10n.maintenanceCancelled;
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = occurrence.customer;
    final equipment = occurrence.equipment;
    final plan = occurrence.plan;
    final effectiveStatus = occurrence.effectiveStatus;
    final isPending =
        effectiveStatus == 'due' ||
        effectiveStatus == 'overdue' ||
        effectiveStatus == 'upcoming' ||
        effectiveStatus == 'scheduled';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: effectiveStatus == 'overdue'
              ? AppColors.error.withValues(alpha: 0.3)
              : effectiveStatus == 'due'
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
          width: effectiveStatus == 'overdue' || effectiveStatus == 'due'
              ? 1.5
              : 1,
        ),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => context.push('/maintenance/occurrences/${occurrence.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Due Date & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _getStatusColor(effectiveStatus),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        DateFormatter.formatDate(occurrence.dueDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(effectiveStatus),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBg(effectiveStatus),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      _getStatusLabel(context, effectiveStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(effectiveStatus),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Customer info & Contact
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer?.fullName ?? 'Unknown Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer?.phone != null &&
                            customer!.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (customer != null && customer.phone.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending) ...[
                          TextButton.icon(
                            icon: const Icon(
                              Icons.chat_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            label: const Text(
                              'Remind',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.successBg,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onPressed: () async {
                              final ok = await ref
                                  .read(
                                    communicationComposerControllerProvider
                                        .notifier,
                                  )
                                  .sendOneClickReminder(
                                    category: 'maintenance_reminder',
                                    recipientPhone: customer.phone,
                                    recipientName: customer.fullName,
                                    customerId: customer.id,
                                    maintenanceOccurrenceId: occurrence.id,
                                    maintenanceDate: DateFormatter.formatDate(
                                      occurrence.dueDate,
                                    ),
                                    title: equipment?.name ?? plan?.title,
                                  );
                              if (!context.mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open WhatsApp for this number.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.sms_outlined,
                              color: AppColors.secondary,
                              size: 19,
                            ),
                            tooltip: 'Edit Message / SMS',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => CommunicationComposerSheet.show(
                              context,
                              customer: customer,
                              phone: customer.phone,
                              name: customer.fullName,
                              maintenanceOccurrenceId: occurrence.id,
                              maintenanceDate: DateFormatter.formatDate(
                                occurrence.dueDate,
                              ),
                              serviceTitle: equipment?.name ?? plan?.title,
                              preferredCategory: 'maintenance_reminder',
                            ),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _makeCall(customer.phone),
                        ),
                      ],
                    ),
                ],
              ),

              // Equipment or Plan reference badge
              if (equipment != null || plan != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    if (equipment != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.precision_manufacturing_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              equipment.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (plan != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          "${plan.planNumber} • ${plan.frequencyDisplay}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // Quick Action Buttons if Pending
              if (isPending) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReschedule != null)
                      TextButton.icon(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: Text(
                          context.l10n.maintenanceActionReschedule,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: onReschedule,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (onSkip != null)
                      TextButton.icon(
                        icon: const Icon(Icons.skip_next_rounded, size: 16),
                        label: Text(
                          context.l10n.maintenanceActionSkip,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (onComplete != null)
                      FilledButton.icon(
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          context.l10n.maintenanceActionComplete,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: onComplete,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
