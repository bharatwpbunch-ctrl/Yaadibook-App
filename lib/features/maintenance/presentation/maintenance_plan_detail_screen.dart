import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../shared/models/maintenance_plan.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';
import '../providers/maintenance_providers.dart';

/// Screen displaying complete details of a customer maintenance plan and its visits.
class MaintenancePlanDetailScreen extends ConsumerWidget {
  final String planId;

  const MaintenancePlanDetailScreen({super.key, required this.planId});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _togglePlanStatus(
    BuildContext context,
    WidgetRef ref,
    MaintenancePlan plan,
  ) async {
    final newStatus = plan.status == 'active' ? 'paused' : 'active';
    try {
      final repo = ref.read(maintenanceRepositoryProvider);
      await repo.updatePlanStatus(plan.id, newStatus);
      ref.invalidate(maintenancePlanDetailProvider(plan.id));
      ref.invalidate(maintenancePlansListProvider);
      ref.invalidate(maintenanceOverviewCountsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan status changed to $newStatus'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelPlan(
    BuildContext context,
    WidgetRef ref,
    MaintenancePlan plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Maintenance Plan?'),
        content: const Text(
          'Are you sure you want to cancel this plan? Past visits and completed records will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep Active'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel Plan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(maintenanceRepositoryProvider);
        await repo.updatePlanStatus(plan.id, 'cancelled');
        ref.invalidate(maintenancePlanDetailProvider(plan.id));
        ref.invalidate(maintenancePlansListProvider);
        ref.invalidate(maintenanceOverviewCountsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maintenance plan cancelled'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final planAsync = ref.watch(maintenancePlanDetailProvider(planId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.maintenancePlanDetails,
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
          planAsync.whenOrNull(
                data: (plan) => plan != null
                    ? IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        tooltip: l10n.maintenanceEditPlan,
                        onPressed: () =>
                            context.push('/maintenance/plans/${plan.id}/edit'),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: YbLoadingState()),
        error: (err, _) => YbErrorState(
          title: 'Failed to load plan',
          message: err.toString(),
          onRetry: () => ref.invalidate(maintenancePlanDetailProvider(planId)),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Maintenance plan not found'));
          }

          final customer = plan.customer;
          final equipment = plan.equipment;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // 1. Plan Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plan.planNumber.isNotEmpty
                              ? plan.planNumber
                              : 'PLAN DETAILS',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: plan.status == 'active'
                                ? AppColors.successBg
                                : plan.status == 'paused'
                                ? AppColors.warningBg
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            plan.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: plan.status == 'active'
                                  ? AppColors.success
                                  : plan.status == 'paused'
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      plan.typeDisplay,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          plan.frequencyDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Next Due: ${DateFormatter.formatDate(plan.nextDueDate)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Customer Section Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            customer?.fullName.isNotEmpty == true
                                ? customer!.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer?.fullName ?? 'Unknown Customer',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (customer?.phone != null &&
                                  customer!.phone.isNotEmpty)
                                Text(
                                  customer.phone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (customer != null && customer.phone.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.phone_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _makeCall(customer.phone),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.success,
                            ),
                            tooltip: '1-Click WhatsApp Reminder',
                            onPressed: () => ref
                                .read(
                                  communicationComposerControllerProvider
                                      .notifier,
                                )
                                .sendOneClickReminder(
                                  category: 'maintenance_reminder',
                                  recipientPhone: customer.phone,
                                  recipientName: customer.fullName,
                                  customerId: customer.id,
                                  maintenanceDate: DateFormatter.formatDate(
                                    plan.nextDueDate,
                                  ),
                                  title: equipment?.name ?? plan.title,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.secondary,
                            ),
                            tooltip: 'Send Reminder (Templates / SMS)',
                            onPressed: () => CommunicationComposerSheet.show(
                              context,
                              customer: customer,
                              phone: customer.phone,
                              name: customer.fullName,
                              maintenanceDate: DateFormatter.formatDate(
                                plan.nextDueDate,
                              ),
                              serviceTitle: equipment?.name ?? plan.title,
                              preferredCategory: 'maintenance_reminder',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Equipment Section Card (if linked)
              if (equipment != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.precision_manufacturing_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "${equipment.brand ?? ''} ${equipment.modelNumber ?? ''} ${equipment.serialNumber != null ? '• S/N: ${equipment.serialNumber}' : ''}"
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 4. Plan Schedule Specification
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'Start Date',
                      value: DateFormatter.formatDate(plan.startDate),
                    ),
                    _DetailRow(
                      label: 'End Date',
                      value: plan.endDate != null
                          ? DateFormatter.formatDate(plan.endDate!)
                          : 'Indefinitely Recurring',
                    ),
                    _DetailRow(
                      label: 'Remind Before',
                      value: "${plan.reminderDaysBefore} days prior",
                    ),
                    if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Notes & Checklist:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Plan State Toggle & Cancellation Actions
              Row(
                children: [
                  if (plan.status == 'active' || plan.status == 'paused') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          plan.status == 'active'
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                        ),
                        label: Text(
                          plan.status == 'active'
                              ? l10n.maintenanceActionPausePlan
                              : l10n.maintenanceActionResumePlan,
                        ),
                        onPressed: () => _togglePlanStatus(context, ref, plan),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                        ),
                        label: Text(
                          l10n.maintenanceActionCancelPlan,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        onPressed: () => _cancelPlan(context, ref, plan),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
