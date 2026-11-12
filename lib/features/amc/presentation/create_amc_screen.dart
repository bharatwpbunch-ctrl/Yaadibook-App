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
import '../providers/amc_providers.dart';

/// Screen allowing owners to register a new Annual Maintenance Contract (AMC).
class CreateAmcScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;
  final String? initialEquipmentId;

  const CreateAmcScreen({
    super.key,
    this.initialCustomerId,
    this.initialEquipmentId,
  });

  @override
  ConsumerState<CreateAmcScreen> createState() => _CreateAmcScreenState();
}

class _CreateAmcScreenState extends ConsumerState<CreateAmcScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _visitsController;
  late final TextEditingController _reminderDaysController;
  late final TextEditingController _includedController;
  late final TextEditingController _excludedController;
  late final TextEditingController _specialTermsController;
  late final TextEditingController _renewalTermsController;
  late final TextEditingController _notesController;
  bool _initializedCustomer = false;
  bool _initializedEquipment = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _visitsController = TextEditingController();
    _reminderDaysController = TextEditingController(text: '15');
    _includedController = TextEditingController();
    _excludedController = TextEditingController();
    _specialTermsController = TextEditingController();
    _renewalTermsController = TextEditingController();
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
              .read(amcFormControllerProvider(null).notifier)
              .setCustomer(customer);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _visitsController.dispose();
    _reminderDaysController.dispose();
    _includedController.dispose();
    _excludedController.dispose();
    _specialTermsController.dispose();
    _renewalTermsController.dispose();
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
      ref.read(amcFormControllerProvider(null).notifier).setCustomer(selected);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(amcFormControllerProvider(null).notifier);

    notifier.setContractTitle(_titleController.text.trim());
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    notifier.setContractAmount(amount);

    final visits = int.tryParse(_visitsController.text.trim());
    notifier.setNumberOfVisits(visits);

    final reminderDays =
        int.tryParse(_reminderDaysController.text.trim()) ?? 15;
    notifier.setReminderDaysBefore(reminderDays);

    notifier.setIncludedServices(_includedController.text.trim());
    notifier.setExcludedServices(_excludedController.text.trim());
    notifier.setSpecialTerms(_specialTermsController.text.trim());
    notifier.setRenewalTerms(_renewalTermsController.text.trim());
    notifier.setNotes(_notesController.text.trim());

    final created = await notifier.submit();
    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.amcCreateSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement('/amc/${created.id}');
    } else {
      final err =
          ref.read(amcFormControllerProvider(null)).errorMessage ??
          'Failed to create AMC contract. Please check fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formState = ref.watch(amcFormControllerProvider(null));
    final notifier = ref.read(amcFormControllerProvider(null).notifier);

    final equipmentAsync = formState.customer != null
        ? ref.watch(customerEquipmentListProvider(formState.customer!.id))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.amcCreateContract,
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
                              child: Text('No equipment / Whole unit'),
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

              // 3. Contract Title & Value
              _SectionHeader(title: 'Contract Information'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.amcContractTitleLabel,
                  hintText: l10n.amcContractTitleHint,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter contract title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.amcContractAmountLabel,
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _visitsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.amcNumberOfVisitsLabel,
                        hintText: 'e.g. 4',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Contract Validity Dates
              _SectionHeader(title: 'Contract Validity'),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  // Start Date
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: formState.startDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
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
                              l10n.amcStartDateLabel,
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
                  const SizedBox(width: AppSpacing.sm),

                  // End Date
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: formState.endDate,
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
                            Text(
                              l10n.amcEndDateLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_busy_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormatter.formatDate(formState.endDate),
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
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Expiry Reminder Lead Time
              const _SectionHeader(title: 'Renewal Reminder Before End Date'),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [30, 15, 7, 3, 0].map((days) {
                  final selected = formState.reminderDaysBefore == days;
                  return ChoiceChip(
                    label: Text(
                      days == 0 ? 'On end date' : '$days days before',
                    ),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
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
                  labelText: 'Remind Before Ending Date (Days)',
                  helperText:
                      'Creates a renewal alert & one-click message reminder ${formState.reminderDaysBefore} day(s) before end date.',
                  prefixIcon: const Icon(Icons.notifications_active_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Coverage Details (Included & Excluded)
              _SectionHeader(title: 'Coverage & Scope (Optional)'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _includedController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.amcIncludedServicesLabel,
                  hintText: l10n.amcIncludedServicesHint,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _excludedController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.amcExcludedServicesLabel,
                  hintText: l10n.amcExcludedServicesHint,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Terms & Notes
              _SectionHeader(title: 'Terms & Notes (Optional)'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _specialTermsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.amcSpecialTermsLabel,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.amcNotesLabel,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              YbPrimaryButton(
                label: l10n.amcCreateContract,
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
