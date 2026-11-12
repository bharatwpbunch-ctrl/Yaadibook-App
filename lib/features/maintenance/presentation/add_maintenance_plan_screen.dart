import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/customer_repository.dart';
import '../../customers/providers/customer_providers.dart';
import '../../services/providers/service_providers.dart';
import '../providers/maintenance_providers.dart';

/// Screen allowing owners to schedule recurring or one-time maintenance for customers.
class AddMaintenancePlanScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;
  final String? initialEquipmentId;

  const AddMaintenancePlanScreen({
    super.key,
    this.initialCustomerId,
    this.initialEquipmentId,
  });

  @override
  ConsumerState<AddMaintenancePlanScreen> createState() =>
      _AddMaintenancePlanScreenState();
}

class _AddMaintenancePlanScreenState
    extends ConsumerState<AddMaintenancePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalValueController;
  late final TextEditingController _reminderDaysController;
  late final TextEditingController _notesController;
  bool _initializedCustomer = false;
  bool _initializedEquipment = false;

  @override
  void initState() {
    super.initState();
    _intervalValueController = TextEditingController(text: '1');
    _reminderDaysController = TextEditingController(text: '3');
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedCustomer && widget.initialCustomerId != null) {
      _initializedCustomer = true;
      Future.microtask(() async {
        final customer = await ref.read(
          customerDetailProvider(widget.initialCustomerId!).future,
        );
        if (customer != null && mounted) {
          ref
              .read(maintenancePlanFormControllerProvider(null).notifier)
              .setCustomer(customer);
        }
      });
    }
  }

  @override
  void dispose() {
    _intervalValueController.dispose();
    _reminderDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openCustomerSelector() async {
    final customers = await ref
        .read(customerRepositoryProvider)
        .getCustomers(filter: CustomerFilter.active);
    if (!mounted) return;

    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerSelectionSheet(customers: customers),
    );

    if (selected != null && mounted) {
      ref
          .read(maintenancePlanFormControllerProvider(null).notifier)
          .setCustomer(selected);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(
      maintenancePlanFormControllerProvider(null).notifier,
    );

    notifier.setNotes(_notesController.text.trim());
    final reminderDays = int.tryParse(_reminderDaysController.text.trim()) ?? 3;
    notifier.setReminderDaysBefore(reminderDays < 0 ? 0 : reminderDays);

    final formState = ref.read(maintenancePlanFormControllerProvider(null));
    if (formState.frequencyType != 'one_time') {
      final intervalVal =
          int.tryParse(_intervalValueController.text.trim()) ?? 1;
      notifier.setInterval(intervalVal, formState.intervalUnit);
    }

    final created = await notifier.submit();
    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.maintenanceCreateSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement('/maintenance/plans/${created.id}');
    } else {
      final err =
          ref.read(maintenancePlanFormControllerProvider(null)).errorMessage ??
          'Failed to schedule maintenance. Please check fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formState = ref.watch(maintenancePlanFormControllerProvider(null));
    final notifier = ref.read(
      maintenancePlanFormControllerProvider(null).notifier,
    );

    // Watch equipment list for the selected customer if any
    final equipmentAsync = formState.customer != null
        ? ref.watch(customerEquipmentListProvider(formState.customer!.id))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.maintenanceScheduleVisit,
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
      body: SafeArea(
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

              // 1. Customer Section
              _SectionHeader(title: l10n.serviceCustomerSection),
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                onTap: _openCustomerSelector,
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(
                      color: formState.customer != null
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: formState.customer != null
                              ? AppColors.primarySurface
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: formState.customer != null
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: formState.customer != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formState.customer!.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    formState.customer!.phone,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                l10n.serviceSelectCustomerPrompt,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Equipment Section (Optional)
              if (formState.customer != null) ...[
                _SectionHeader(title: l10n.serviceEquipmentSection),
                const SizedBox(height: AppSpacing.xs),
                equipmentAsync?.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => const SizedBox.shrink(),
                      data: (items) {
                        if (items.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              l10n.serviceNoEquipmentRegistered,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        }

                        if (!_initializedEquipment &&
                            widget.initialEquipmentId != null &&
                            formState.equipment == null) {
                          final match = items.where(
                            (e) => e.id == widget.initialEquipmentId,
                          );
                          if (match.isNotEmpty) {
                            _initializedEquipment = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) notifier.setEquipment(match.first);
                            });
                          }
                        }

                        return DropdownButtonFormField<Equipment?>(
                          initialValue: formState.equipment,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.input,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          hint: Text(l10n.serviceSelectEquipment),
                          items: [
                            const DropdownMenuItem<Equipment?>(
                              value: null,
                              child: Text('No equipment / General checkup'),
                            ),
                            ...items.map(
                              (eq) => DropdownMenuItem<Equipment?>(
                                value: eq,
                                child: Text(
                                  "${eq.name} (${eq.brand ?? 'Asset'})",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (eq) => notifier.setEquipment(eq),
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 3. Maintenance Type Selector
              _SectionHeader(title: l10n.maintenanceTypeLabel),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  _TypeChip(
                    label: l10n.maintenanceTypeRoutine,
                    selected: formState.maintenanceType == 'routine',
                    onTap: () => notifier.setMaintenanceType('routine'),
                  ),
                  _TypeChip(
                    label: l10n.maintenanceTypePeriodic,
                    selected: formState.maintenanceType == 'periodic',
                    onTap: () => notifier.setMaintenanceType('periodic'),
                  ),
                  _TypeChip(
                    label: l10n.maintenanceTypeSeasonal,
                    selected: formState.maintenanceType == 'seasonal',
                    onTap: () => notifier.setMaintenanceType('seasonal'),
                  ),
                  _TypeChip(
                    label: l10n.maintenanceTypeInspection,
                    selected: formState.maintenanceType == 'inspection',
                    onTap: () => notifier.setMaintenanceType('inspection'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Frequency Selector: One-Time or Recurring
              _SectionHeader(title: l10n.maintenanceFrequencyLabel),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _RadioSelectCard(
                      title: l10n.maintenanceFrequencyRecurring,
                      subtitle: 'Repeats periodically',
                      icon: Icons.repeat_rounded,
                      isSelected: formState.frequencyType != 'one_time',
                      onTap: () => notifier.setFrequencyType(
                        resolveMaintenanceFrequencyType(
                          isOneTime: false,
                          intervalValue: formState.intervalValue,
                          intervalUnit: formState.intervalUnit,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _RadioSelectCard(
                      title: l10n.maintenanceFrequencyOneTime,
                      subtitle: 'Single visit plan',
                      icon: Icons.event_available_rounded,
                      isSelected: formState.frequencyType == 'one_time',
                      onTap: () => notifier.setFrequencyType('one_time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // If Recurring: Intervals & Unit
              if (formState.frequencyType != 'one_time') ...[
                _SectionHeader(title: l10n.maintenanceIntervalLabel),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _IntervalPresetChip(
                      label: l10n.maintenanceIntervalMonthly,
                      isSelected:
                          formState.intervalValue == 1 &&
                          formState.intervalUnit == 'months',
                      onTap: () {
                        _intervalValueController.text = '1';
                        notifier.setInterval(1, 'months');
                      },
                    ),
                    _IntervalPresetChip(
                      label: l10n.maintenanceIntervalQuarterly,
                      isSelected:
                          formState.intervalValue == 3 &&
                          formState.intervalUnit == 'months',
                      onTap: () {
                        _intervalValueController.text = '3';
                        notifier.setInterval(3, 'months');
                      },
                    ),
                    _IntervalPresetChip(
                      label: l10n.maintenanceIntervalHalfYearly,
                      isSelected:
                          formState.intervalValue == 6 &&
                          formState.intervalUnit == 'months',
                      onTap: () {
                        _intervalValueController.text = '6';
                        notifier.setInterval(6, 'months');
                      },
                    ),
                    _IntervalPresetChip(
                      label: l10n.maintenanceIntervalYearly,
                      isSelected:
                          formState.intervalValue == 1 &&
                          formState.intervalUnit == 'years',
                      onTap: () {
                        _intervalValueController.text = '1';
                        notifier.setInterval(1, 'years');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Custom Interval values if needed
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _intervalValueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Interval',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        onChanged: (val) {
                          final v = int.tryParse(val) ?? 1;
                          notifier.setInterval(v, formState.intervalUnit);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: formState.intervalUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'days',
                            child: Text(l10n.maintenanceIntervalUnitDays),
                          ),
                          DropdownMenuItem(
                            value: 'weeks',
                            child: Text(l10n.maintenanceIntervalUnitWeeks),
                          ),
                          DropdownMenuItem(
                            value: 'months',
                            child: Text(l10n.maintenanceIntervalUnitMonths),
                          ),
                          DropdownMenuItem(
                            value: 'years',
                            child: Text(l10n.maintenanceIntervalUnitYears),
                          ),
                        ],
                        onChanged: (unit) {
                          if (unit != null) {
                            final v =
                                int.tryParse(
                                  _intervalValueController.text.trim(),
                                ) ??
                                1;
                            notifier.setInterval(v, unit);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 5. Dates Section
              Row(
                children: [
                  // First Due Date
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: formState.startDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          notifier.setStartDate(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppRadii.input),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.maintenanceStartDateLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormatter.formatDate(formState.startDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Optional End Date
                  if (formState.frequencyType != 'one_time') ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                formState.endDate ??
                                formState.startDate.add(
                                  const Duration(days: 365),
                                ),
                            firstDate: formState.startDate,
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            notifier.setEndDate(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.maintenanceEndDateLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (formState.endDate != null)
                                    GestureDetector(
                                      onTap: () => notifier.setEndDate(null),
                                      child: const Icon(
                                        Icons.clear_rounded,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_busy_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formState.endDate != null
                                        ? DateFormatter.formatDate(
                                            formState.endDate!,
                                          )
                                        : 'No End Date',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 6. Reminder Days Before Due Date
              _SectionHeader(title: l10n.maintenanceReminderDaysLabel),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [0, 1, 3, 7, 15].map((days) {
                  final selected = formState.reminderDaysBefore == days;
                  return _IntervalPresetChip(
                    label: days == 0 ? 'On due date' : '$days days before',
                    isSelected: selected,
                    onTap: () {
                      _reminderDaysController.text = days.toString();
                      notifier.setReminderDaysBefore(days);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _reminderDaysController,
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final d = int.tryParse(val.trim());
                  if (d != null && d >= 0) {
                    notifier.setReminderDaysBefore(d);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.maintenanceReminderDaysLabel,
                  helperText:
                      'Creates an alert & one-click message reminder ${formState.reminderDaysBefore} day(s) before due date.',
                  prefixIcon: const Icon(Icons.notifications_active_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 7. Notes & Checklist
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
                label: l10n.maintenanceScheduleVisit,
                isLoading: formState.isLoading,
                onPressed: formState.isLoading ? null : _handleSubmit,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surface,
      onSelected: (_) => onTap(),
    );
  }
}

class _RadioSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalPresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntervalPresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surface,
      onSelected: (_) => onTap(),
    );
  }
}

class _CustomerSelectionSheet extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSelectionSheet({required this.customers});

  @override
  State<_CustomerSelectionSheet> createState() =>
      _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState extends State<_CustomerSelectionSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers.where((c) {
      final q = _search.toLowerCase();
      return c.fullName.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customer by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final c = filtered[idx];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    c.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(c.phone),
                  onTap: () => Navigator.of(ctx).pop(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
