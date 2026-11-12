import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../shared/models/maintenance_occurrence.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';
import '../providers/maintenance_providers.dart';

/// Detail screen for a specific maintenance occurrence visit.
class MaintenanceOccurrenceDetailScreen extends ConsumerStatefulWidget {
  final String occurrenceId;

  const MaintenanceOccurrenceDetailScreen({
    super.key,
    required this.occurrenceId,
  });

  @override
  ConsumerState<MaintenanceOccurrenceDetailScreen> createState() =>
      _MaintenanceOccurrenceDetailScreenState();
}

class _MaintenanceOccurrenceDetailScreenState
    extends ConsumerState<MaintenanceOccurrenceDetailScreen> {
  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
                TextField(
                  controller: workController,
                  decoration: InputDecoration(
                    labelText: l10n.maintenanceWorkPerformedLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
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

        ref.invalidate(
          maintenanceOccurrenceDetailProvider(widget.occurrenceId),
        );
        ref.invalidate(maintenanceOccurrencesListProvider);
        ref.invalidate(maintenanceOverviewCountsProvider);

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
        title: Text(l10n.maintenanceSkipDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.maintenanceSkipDialogMessage),
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

        ref.invalidate(
          maintenanceOccurrenceDetailProvider(widget.occurrenceId),
        );
        ref.invalidate(maintenanceOccurrencesListProvider);
        ref.invalidate(maintenanceOverviewCountsProvider);

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

        ref.invalidate(
          maintenanceOccurrenceDetailProvider(widget.occurrenceId),
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
    final occAsync = ref.watch(
      maintenanceOccurrenceDetailProvider(widget.occurrenceId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.maintenanceOccurrenceDetails,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: occAsync.when(
        loading: () => const Center(child: YbLoadingState()),
        error: (err, _) => YbErrorState(
          title: 'Failed to load visit details',
          message: err.toString(),
          onRetry: () => ref.invalidate(
            maintenanceOccurrenceDetailProvider(widget.occurrenceId),
          ),
        ),
        data: (occ) {
          if (occ == null) {
            return const Center(child: Text('Visit not found'));
          }

          final customer = occ.customer;
          final equipment = occ.equipment;
          final plan = occ.plan;
          final effectiveStatus = occ.effectiveStatus;
          final isPending =
              effectiveStatus == 'due' ||
              effectiveStatus == 'overdue' ||
              effectiveStatus == 'upcoming' ||
              effectiveStatus == 'scheduled';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // 1. Visit Status & Due Date Header Card
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
                          "VISIT #${occ.occurrenceNumber}",
                          style: const TextStyle(
                            fontSize: 14,
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
                            color: effectiveStatus == 'completed'
                                ? AppColors.successBg
                                : effectiveStatus == 'overdue'
                                ? AppColors.errorBg
                                : effectiveStatus == 'due'
                                ? AppColors.warningBg
                                : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            effectiveStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: effectiveStatus == 'completed'
                                  ? AppColors.success
                                  : effectiveStatus == 'overdue'
                                  ? AppColors.error
                                  : effectiveStatus == 'due'
                                  ? AppColors.warning
                                  : AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Due: ${DateFormatter.formatDate(occ.dueDate)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (occ.originalDueDate != occ.dueDate) ...[
                      const SizedBox(height: 2),
                      Text(
                        "Rescheduled from ${DateFormatter.formatDate(occ.originalDueDate)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Customer Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
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
                              communicationComposerControllerProvider.notifier,
                            )
                            .sendOneClickReminder(
                              category: 'maintenance_reminder',
                              recipientPhone: customer.phone,
                              recipientName: customer.fullName,
                              customerId: customer.id,
                              maintenanceOccurrenceId: occ.id,
                              maintenanceDate: DateFormatter.formatDate(
                                occ.dueDate,
                              ),
                              title: equipment?.name ?? plan?.title,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.secondary,
                        ),
                        tooltip: 'Send Template Message (WhatsApp / SMS)',
                        onPressed: () => CommunicationComposerSheet.show(
                          context,
                          customer: customer,
                          phone: customer.phone,
                          name: customer.fullName,
                          maintenanceOccurrenceId: occ.id,
                          maintenanceDate: DateFormatter.formatDate(
                            occ.dueDate,
                          ),
                          serviceTitle: equipment?.name ?? plan?.title,
                          preferredCategory: 'maintenance_reminder',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Equipment Card (if linked)
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
                              "${equipment.brand ?? ''} ${equipment.modelNumber ?? ''}"
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

              // 4. Completed Visit Results (if completed)
              if (occ.status == 'completed') ...[
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
                        'Completed Work Report',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (occ.completedAt != null)
                        Text(
                          "Finished on ${DateFormatter.formatDate(occ.completedAt!)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (occ.workPerformed != null &&
                          occ.workPerformed!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Work Done: ${occ.workPerformed}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (occ.amount != null && occ.amount! > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Amount Charged: ${CurrencyFormatter.formatINR(occ.amount!)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (occ.notes != null && occ.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Notes: ${occ.notes}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 5. Skipped Reason (if skipped)
              if (occ.status == 'skipped') ...[
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
                        'Visit Skipped',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        occ.skipReason != null && occ.skipReason!.isNotEmpty
                            ? "Reason: ${occ.skipReason}"
                            : 'No specific skip reason provided.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 6. Parent Plan Link
              if (plan != null) ...[
                ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  leading: const Icon(
                    Icons.repeat_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    "Plan: ${plan.planNumber}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(plan.frequencyDisplay),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/maintenance/plans/${plan.id}'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 7. Pending Action Buttons
              if (isPending) ...[
                FilledButton.icon(
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    l10n.maintenanceActionComplete,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _showCompleteDialog(occ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: Text(l10n.maintenanceActionReschedule),
                        onPressed: () => _showRescheduleDialog(occ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.skip_next_rounded, size: 16),
                        label: Text(l10n.maintenanceActionSkip),
                        onPressed: () => _showSkipDialog(occ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
