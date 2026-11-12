import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/service_entry.dart';
import '../../../../core/widgets/yb_error_state.dart';
import '../../../../core/widgets/yb_loading_state.dart';
import '../providers/service_providers.dart';

/// Screen allowing the business owner to edit an existing service entry.
class EditServiceScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const EditServiceScreen({super.key, required this.serviceId});

  @override
  ConsumerState<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends ConsumerState<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _workController;
  late TextEditingController _baseChargeController;
  late TextEditingController _additionalChargesController;
  late TextEditingController _discountController;
  late TextEditingController _notesController;

  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _workController.dispose();
    _baseChargeController.dispose();
    _additionalChargesController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initControllers(ServiceEntry service) {
    if (_isInitialized) return;

    _titleController = TextEditingController(text: service.title);
    _descController = TextEditingController(text: service.description ?? '');
    _workController = TextEditingController(text: service.workPerformed ?? '');
    _baseChargeController = TextEditingController(
      text: service.serviceAmount != null && service.serviceAmount! > 0
          ? service.serviceAmount!.toStringAsFixed(0)
          : '',
    );
    _additionalChargesController = TextEditingController(
      text: service.additionalCharges > 0
          ? service.additionalCharges.toStringAsFixed(0)
          : '',
    );
    _discountController = TextEditingController(
      text: service.discountAmount > 0
          ? service.discountAmount.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController(text: service.notes ?? '');

    _isInitialized = true;
  }

  void _invalidateAll(String serviceId, String customerId) {
    ref.invalidate(serviceDetailProvider(serviceId));
    ref.invalidate(serviceActivitiesProvider(serviceId));
    ref.invalidate(servicesListProvider);
    ref.invalidate(servicesSummaryProvider);
    ref.invalidate(pendingServicesListProvider);
    ref.invalidate(recentServicesProvider);
    ref.invalidate(customerServiceHistoryProvider(customerId));
    ref.invalidate(customerServiceCountsProvider(customerId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return serviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.editServiceTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(child: YbLoadingState()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.editServiceTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: YbErrorState(
          title: 'Could not load service',
          message: err.toString(),
          onRetry: () => ref.refresh(serviceDetailProvider(widget.serviceId)),
        ),
      ),
      data: (service) {
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.editServiceTitle)),
            body: const Center(child: Text('Service entry not found')),
          );
        }

        _initControllers(service);

        final formState = ref.watch(serviceFormControllerProvider(service));
        final formNotifier = ref.read(
          serviceFormControllerProvider(service).notifier,
        );

        final equipmentAsync = ref.watch(
          customerEquipmentListProvider(service.customerId),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              l10n.editServiceTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message banner if any
                  if (formState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          AppSpacing.gapH8,
                          Expanded(
                            child: Text(
                              formState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapV16,
                  ],

                  // Customer banner (Read-only for existing service)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            service.customer?.initials ?? 'C',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        AppSpacing.gapH12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.customer?.fullName ?? 'Customer',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              AppSpacing.gapV2,
                              Text(
                                service.customer?.primaryPhone ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (service.serviceNumber.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              service.serviceNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV16,

                  // Section: Service Details
                  _buildSectionHeader(l10n.serviceInfoSection),
                  AppSpacing.gapV8,

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: l10n.serviceTitleLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          onChanged: formNotifier.updateTitle,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Service title is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapV16,

                        // Service Type Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: formState.serviceType,
                          decoration: InputDecoration(
                            labelText: l10n.serviceTypeLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'installation',
                              child: Text(l10n.serviceTypeInstallation),
                            ),
                            DropdownMenuItem(
                              value: 'repair',
                              child: Text(l10n.serviceTypeRepair),
                            ),
                            DropdownMenuItem(
                              value: 'maintenance',
                              child: Text(l10n.serviceTypeMaintenance),
                            ),
                            DropdownMenuItem(
                              value: 'inspection',
                              child: Text(l10n.serviceTypeInspection),
                            ),
                            DropdownMenuItem(
                              value: 'general',
                              child: Text(l10n.serviceTypeGeneral),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text(l10n.serviceTypeOther),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              formNotifier.updateServiceType(val);
                            }
                          },
                        ),
                        AppSpacing.gapV16,

                        // Service Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: formState.serviceDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              formNotifier.updateServiceDate(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.serviceDateLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                              ),
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                              ),
                            ),
                            child: Text(
                              DateFormatter.formatShort(formState.serviceDate),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapV16,

                        // Status Segmented Button
                        const Text(
                          'Service Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapV8,
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'pending',
                              label: Text(l10n.serviceStatusPending),
                            ),
                            ButtonSegment(
                              value: 'in_progress',
                              label: Text(l10n.serviceStatusInProgress),
                            ),
                            ButtonSegment(
                              value: 'completed',
                              label: Text(l10n.serviceStatusCompleted),
                            ),
                            ButtonSegment(
                              value: 'cancelled',
                              label: Text(l10n.serviceStatusCancelled),
                            ),
                          ],
                          selected: {formState.status},
                          onSelectionChanged: (newSelection) {
                            formNotifier.updateStatus(newSelection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV16,

                  // Section: Equipment (Optional)
                  equipmentAsync.when(
                    data: (equipments) {
                      if (equipments.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(l10n.serviceEquipmentSection),
                          AppSpacing.gapV8,
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: DropdownButtonFormField<String?>(
                              initialValue: formState.equipmentId,
                              decoration: InputDecoration(
                                labelText: l10n.serviceSelectEquipment,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None (General Service)'),
                                ),
                                ...equipments.map(
                                  (eq) => DropdownMenuItem<String?>(
                                    value: eq.id,
                                    child: Text(eq.displayName),
                                  ),
                                ),
                              ],
                              onChanged: formNotifier.selectEquipment,
                            ),
                          ),
                          AppSpacing.gapV16,
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),

                  // Section: Work Details
                  _buildSectionHeader(l10n.serviceWorkDetailsSection),
                  AppSpacing.gapV8,

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.serviceDescriptionLabel,
                            hintText: l10n.serviceDescriptionHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          onChanged: formNotifier.updateDescription,
                        ),
                        AppSpacing.gapV16,
                        TextFormField(
                          controller: _workController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.serviceWorkPerformedLabel,
                            hintText: l10n.serviceWorkPerformedHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          onChanged: formNotifier.updateWorkPerformed,
                        ),
                        AppSpacing.gapV16,
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Internal Notes (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          onChanged: formNotifier.updateNotes,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV16,

                  // Section: Charges
                  _buildSectionHeader(l10n.serviceChargesSection),
                  AppSpacing.gapV8,

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _baseChargeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.serviceChargeBaseLabel,
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            formNotifier.updateServiceAmount(parsed);
                          },
                        ),
                        AppSpacing.gapV16,
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _additionalChargesController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.serviceAdditionalChargesLabel,
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  final parsed =
                                      double.tryParse(val.trim()) ?? 0.0;
                                  formNotifier.updateAdditionalCharges(parsed);
                                },
                              ),
                            ),
                            AppSpacing.gapH12,
                            Expanded(
                              child: TextFormField(
                                controller: _discountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.serviceDiscountLabel,
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  final parsed =
                                      double.tryParse(val.trim()) ?? 0.0;
                                  formNotifier.updateDiscountAmount(parsed);
                                },
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapV16,

                        // Live Total Amount Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.serviceTotalAmountLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  formState.computedTotal,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV24,

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      onPressed: formState.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final updated = await formNotifier.submitUpdate(
                                  service,
                                );
                                if (updated != null && context.mounted) {
                                  _invalidateAll(
                                    service.id,
                                    service.customerId,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.serviceUpdateSuccess),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  context.pop();
                                }
                              }
                            },
                      child: formState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.actionSave,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  AppSpacing.gapV32,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
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
