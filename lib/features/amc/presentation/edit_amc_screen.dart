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
import '../../../shared/models/amc_contract.dart';
import '../providers/amc_providers.dart';

/// Screen allowing owners to edit an existing AMC contract's details.
class EditAmcScreen extends ConsumerStatefulWidget {
  final String contractId;

  const EditAmcScreen({super.key, required this.contractId});

  @override
  ConsumerState<EditAmcScreen> createState() => _EditAmcScreenState();
}

class _EditAmcScreenState extends ConsumerState<EditAmcScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _visitsController;
  late final TextEditingController _includedController;
  late final TextEditingController _excludedController;
  late final TextEditingController _specialTermsController;
  late final TextEditingController _notesController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _visitsController = TextEditingController();
    _includedController = TextEditingController();
    _excludedController = TextEditingController();
    _specialTermsController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initFields(AmcContract contract) {
    if (!_isInitialized) {
      _isInitialized = true;
      _titleController.text = contract.contractTitle;
      _amountController.text = contract.contractAmount.toString();
      _visitsController.text = contract.numberOfVisits?.toString() ?? '';
      _includedController.text = contract.includedServices ?? '';
      _excludedController.text = contract.excludedServices ?? '';
      _specialTermsController.text = contract.specialTerms ?? '';
      _notesController.text = contract.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _visitsController.dispose();
    _includedController.dispose();
    _excludedController.dispose();
    _specialTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(AmcContract contract) async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(amcFormControllerProvider(contract).notifier);

    notifier.setContractTitle(_titleController.text.trim());
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    notifier.setContractAmount(amount);

    final visits = int.tryParse(_visitsController.text.trim());
    notifier.setNumberOfVisits(visits);

    notifier.setIncludedServices(_includedController.text.trim());
    notifier.setExcludedServices(_excludedController.text.trim());
    notifier.setSpecialTerms(_specialTermsController.text.trim());
    notifier.setNotes(_notesController.text.trim());

    final updated = await notifier.submit(existingContract: contract);
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.amcUpdateSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final contractAsync = ref.watch(
      amcContractDetailProvider(widget.contractId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.amcEditContract,
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
      body: contractAsync.when(
        loading: () => const Center(child: YbLoadingState()),
        error: (err, _) => YbErrorState(
          title: 'Failed to load contract',
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(amcContractDetailProvider(widget.contractId)),
        ),
        data: (contract) {
          if (contract == null) {
            return const Center(child: Text('Contract not found'));
          }

          _initFields(contract);

          final formState = ref.watch(amcFormControllerProvider(contract));
          final notifier = ref.read(
            amcFormControllerProvider(contract).notifier,
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

                  // Contract # & Customer
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
                          contract.contractNumber ?? 'AMC',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contract.customer?.fullName ?? 'Customer',
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

                  // Title & Value
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.amcContractTitleLabel,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
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
                            filled: true,
                            fillColor: AppColors.surface,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: formState.startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              notifier.setStartDate(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadii.input,
                              ),
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
                                Text(
                                  DateFormatter.formatDate(formState.startDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadii.input,
                              ),
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
                                Text(
                                  DateFormatter.formatDate(formState.endDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Scope & Terms
                  TextFormField(
                    controller: _includedController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.amcIncludedServicesLabel,
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
                      filled: true,
                      fillColor: AppColors.surface,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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

                  YbPrimaryButton(
                    label: l10n.actionSave,
                    isLoading: formState.isLoading,
                    onPressed: formState.isLoading
                        ? null
                        : () => _handleSave(contract),
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
