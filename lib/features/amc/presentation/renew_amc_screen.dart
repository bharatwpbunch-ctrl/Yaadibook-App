import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../shared/models/amc_contract.dart';
import '../providers/amc_providers.dart';

/// Screen allowing owners to renew an expiring or expired AMC contract into a fresh contract.
class RenewAmcScreen extends ConsumerStatefulWidget {
  final String contractId;

  const RenewAmcScreen({super.key, required this.contractId});

  @override
  ConsumerState<RenewAmcScreen> createState() => _RenewAmcScreenState();
}

class _RenewAmcScreenState extends ConsumerState<RenewAmcScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _visitsController;
  late final TextEditingController _notesController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _visitsController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initFields(AmcContract previousContract) {
    if (!_isInitialized) {
      _isInitialized = true;
      _titleController.text = previousContract.contractTitle;
      _amountController.text = previousContract.contractAmount.toString();
      _visitsController.text =
          previousContract.numberOfVisits?.toString() ?? '';
      _notesController.text = "Renewed from ${previousContract.contractNumber}";

      // Compute recommended renewal start & end dates:
      // Start date: day after previous end_date (or today if already well past)
      final now = DateTime.now();
      final dayAfterPrevEnd = previousContract.endDate.add(
        const Duration(days: 1),
      );
      final renewalStart =
          dayAfterPrevEnd.isBefore(now.subtract(const Duration(days: 60)))
          ? DateTime(now.year, now.month, now.day)
          : dayAfterPrevEnd;
      final renewalEnd = DateTime(
        renewalStart.year + 1,
        renewalStart.month,
        renewalStart.day,
      );

      final notifier = ref.read(
        amcFormControllerProvider(previousContract).notifier,
      );
      notifier.setStartDate(renewalStart);
      notifier.setEndDate(renewalEnd);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _visitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleRenew(AmcContract previousContract) async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(
      amcFormControllerProvider(previousContract).notifier,
    );

    notifier.setContractTitle(_titleController.text.trim());
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    notifier.setContractAmount(amount);

    final visits = int.tryParse(_visitsController.text.trim());
    notifier.setNumberOfVisits(visits);
    notifier.setNotes(_notesController.text.trim());

    final newContractId = await notifier.submitRenewal(
      previousContractId: previousContract.id,
    );

    if (newContractId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.amcRenewSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement('/amc/$newContractId');
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
          l10n.amcRenewContract,
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
        data: (previousContract) {
          if (previousContract == null) {
            return const Center(child: Text('Previous contract not found'));
          }

          _initFields(previousContract);

          final formState = ref.watch(
            amcFormControllerProvider(previousContract),
          );
          final notifier = ref.read(
            amcFormControllerProvider(previousContract).notifier,
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

                  // Notice Box explaining non-destructive renewal
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.amcRenewDialogMessage,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Previous Contract Summary
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
                          "Renewing: ${previousContract.contractNumber}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          previousContract.customer?.fullName ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Previous period: ${DateFormatter.formatDate(previousContract.startDate)} → ${DateFormatter.formatDate(previousContract.endDate)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          "Previous amount: ${CurrencyFormatter.formatINR(previousContract.contractAmount)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // New Contract Title
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

                  // New Period Dates
                  Row(
                    children: [
                      // New Start Date
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
                                const Text(
                                  'Renewal Start',
                                  style: TextStyle(
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

                      // New End Date
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
                                const Text(
                                  'Renewal Expiry',
                                  style: TextStyle(
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
                  const SizedBox(height: AppSpacing.md),

                  // Renewal Amount & Visits
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Renewal Amount (₹)',
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
                          decoration: const InputDecoration(
                            labelText: 'Visits Included',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Renewal Notes (Optional)',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit Renewal
                  YbPrimaryButton(
                    label: l10n.amcActionRenew,
                    isLoading: formState.isLoading,
                    onPressed: formState.isLoading
                        ? null
                        : () => _handleRenew(previousContract),
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
