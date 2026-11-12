import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../shared/models/maintenance_plan.dart';
import '../providers/maintenance_providers.dart';

/// Screen allowing owners to edit an existing maintenance plan.
class EditMaintenancePlanScreen extends ConsumerStatefulWidget {
  final String planId;

  const EditMaintenancePlanScreen({super.key, required this.planId});

  @override
  ConsumerState<EditMaintenancePlanScreen> createState() =>
      _EditMaintenancePlanScreenState();
}

class _EditMaintenancePlanScreenState
    extends ConsumerState<EditMaintenancePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalValueController;
  late final TextEditingController _reminderDaysController;
  late final TextEditingController _notesController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _intervalValueController = TextEditingController();
    _reminderDaysController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initFields(MaintenancePlan plan) {
    if (!_isInitialized) {
      _isInitialized = true;
      _intervalValueController.text = (plan.intervalValue ?? 1).toString();
      _reminderDaysController.text = plan.reminderDaysBefore.toString();
      _notesController.text = plan.notes ?? '';
    }
  }

  @override
  void dispose() {
    _intervalValueController.dispose();
    _reminderDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(MaintenancePlan existingPlan) async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(
      maintenancePlanFormControllerProvider(existingPlan).notifier,
    );

    notifier.setNotes(_notesController.text.trim());
    final reminderDays = int.tryParse(_reminderDaysController.text.trim()) ?? 3;
    notifier.setReminderDaysBefore(reminderDays);

    final formState = ref.read(
      maintenancePlanFormControllerProvider(existingPlan),
    );
    if (formState.frequencyType != 'one_time') {
      final intervalVal =
          int.tryParse(_intervalValueController.text.trim()) ?? 1;
      notifier.setInterval(intervalVal, formState.intervalUnit);
    }

    final updated = await notifier.submit(existingPlan: existingPlan);
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.maintenanceUpdateSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final planAsync = ref.watch(maintenancePlanDetailProvider(widget.planId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.maintenanceEditPlan,
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
      body: planAsync.when(
        loading: () => const Center(child: YbLoadingState()),
        error: (err, _) => YbErrorState(
          title: 'Failed to load plan',
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(maintenancePlanDetailProvider(widget.planId)),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Plan not found'));
          }

          _initFields(plan);

          final formState = ref.watch(
            maintenancePlanFormControllerProvider(plan),
          );
          final notifier = ref.read(
            maintenancePlanFormControllerProvider(plan).notifier,
          );

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (formState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        formState.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Plan Number & Customer reference
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
                        Text(
                          plan.planNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.customer?.fullName ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Maintenance Type
                  const Text(
                    'Maintenance Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.maintenanceTypeRoutine),
                        selected: formState.maintenanceType == 'routine',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: formState.maintenanceType == 'routine'
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) =>
                            notifier.setMaintenanceType('routine'),
                      ),
                      ChoiceChip(
                        label: Text(l10n.maintenanceTypePeriodic),
                        selected: formState.maintenanceType == 'periodic',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: formState.maintenanceType == 'periodic'
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) =>
                            notifier.setMaintenanceType('periodic'),
                      ),
                      ChoiceChip(
                        label: Text(l10n.maintenanceTypeSeasonal),
                        selected: formState.maintenanceType == 'seasonal',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: formState.maintenanceType == 'seasonal'
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) =>
                            notifier.setMaintenanceType('seasonal'),
                      ),
                      ChoiceChip(
                        label: Text(l10n.maintenanceTypeInspection),
                        selected: formState.maintenanceType == 'inspection',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: formState.maintenanceType == 'inspection'
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) =>
                            notifier.setMaintenanceType('inspection'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // End Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            formState.endDate ??
                            formState.startDate.add(const Duration(days: 365)),
                        firstDate: formState.startDate,
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        notifier.setEndDate(picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppRadii.input),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.maintenanceEndDateLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formState.endDate != null
                                    ? DateFormatter.formatDate(
                                        formState.endDate!,
                                      )
                                    : 'Indefinitely Recurring (No End Date)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: formState.endDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (formState.endDate != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => notifier.setEndDate(null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Reminder days before
                  TextFormField(
                    controller: _reminderDaysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.maintenanceReminderDaysLabel,
                      prefixIcon: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.maintenanceNotesLabel,
                      hintText: l10n.maintenanceNotesHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save Button
                  YbPrimaryButton(
                    label: l10n.actionSave,
                    isLoading: formState.isLoading,
                    onPressed: formState.isLoading
                        ? null
                        : () => _handleSave(plan),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
