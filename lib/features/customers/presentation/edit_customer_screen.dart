import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_text_input.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/customer_providers.dart';

/// Screen for editing an existing customer's information.
class EditCustomerScreen extends ConsumerStatefulWidget {
  final String customerId;

  const EditCustomerScreen({super.key, required this.customerId});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _altPhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _areaController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalController;
  late final TextEditingController _notesController;

  String _selectedCustomerType = 'individual';
  bool _addressExpanded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _altPhoneController = TextEditingController();
    _emailController = TextEditingController();
    _line1Controller = TextEditingController();
    _line2Controller = TextEditingController();
    _areaController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initFields(Customer customer) {
    if (_isInitialized) return;
    _nameController.text = customer.fullName;
    _phoneController.text = customer.primaryPhone;
    _altPhoneController.text = customer.alternatePhone ?? '';
    _emailController.text = customer.email ?? '';
    _selectedCustomerType = customer.customerType;
    _line1Controller.text = customer.primaryAddress?.addressLine1 ?? '';
    _line2Controller.text = customer.primaryAddress?.addressLine2 ?? '';
    _areaController.text = customer.primaryAddress?.area ?? '';
    _cityController.text = customer.primaryAddress?.city ?? 'Ahmedabad';
    _stateController.text = customer.primaryAddress?.state ?? 'Gujarat';
    _postalController.text = customer.primaryAddress?.postalCode ?? '';
    _notesController.text = customer.notes ?? '';
    _addressExpanded =
        customer.primaryAddress != null &&
        (customer.primaryAddress!.addressLine1.isNotEmpty ||
            customer.primaryAddress!.area.isNotEmpty);
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(Customer customer) async {
    if (!_formKey.currentState!.validate()) return;

    final business = await ref.read(currentBusinessProvider.future);
    if (business == null) return;

    final controller = ref.read(
      customerFormControllerProvider(customer).notifier,
    );

    // Sync all controller values to state
    controller.updateFullName(_nameController.text);
    controller.updatePrimaryPhone(_phoneController.text);
    controller.updateAlternatePhone(_altPhoneController.text);
    controller.updateEmail(_emailController.text);
    controller.updateCustomerType(_selectedCustomerType);
    controller.updateAddressLine1(_line1Controller.text);
    controller.updateAddressLine2(_line2Controller.text);
    controller.updateArea(_areaController.text);
    controller.updateCity(_cityController.text);
    controller.updateState(_stateController.text);
    controller.updatePostalCode(_postalController.text);
    controller.updateNotes(_notesController.text);

    // If phone changed, check duplicate excluding current customer
    if (_phoneController.text.trim() != customer.primaryPhone.trim()) {
      final duplicate = await controller.checkDuplicate(
        business.id,
        excludeCustomerId: customer.id,
      );
      if (duplicate != null && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            title: Text(
              context.l10n.customerDuplicateWarningTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              context.l10n.customerDuplicateWarningMessage(
                duplicate.primaryPhone,
                duplicate.fullName,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx, false);
                  context.push('/customers/${duplicate.id}');
                },
                child: Text(context.l10n.customerViewExisting),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.customerSaveAnyway),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    final updated = await controller.submitUpdate(customer);

    if (updated != null && mounted) {
      ref.invalidate(customerDetailProvider(widget.customerId));
      ref.invalidate(customersListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.customerUpdateSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));

    return customerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.editCustomerTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(child: YbLoadingState()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.editCustomerTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: YbErrorState(
          title: 'Could not load customer',
          message: err.toString(),
          onRetry: () => ref.refresh(customerDetailProvider(widget.customerId)),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.editCustomerTitle)),
            body: const Center(child: Text('Customer not found')),
          );
        }

        _initFields(customer);
        final formState = ref.watch(customerFormControllerProvider(customer));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              l10n.editCustomerTitle,
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
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapV16,
                  ],

                  // Basic Info Card
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
                        YbTextInput(
                          label: l10n.customerFullName,
                          hint: l10n.customerFullNameHint,
                          controller: _nameController,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textMuted,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.customerFullName;
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapV16,

                        YbTextInput(
                          label: l10n.customerPrimaryPhone,
                          hint: l10n.customerPrimaryPhoneHint,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          maxLength: 10,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.customerPrimaryPhone;
                            }
                            final clean = val.replaceAll(RegExp(r'\D'), '');
                            if (clean.length < 10) {
                              return 'Please enter valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapV8,

                        YbTextInput(
                          label: l10n.customerAlternatePhone,
                          hint: l10n.customerAlternatePhoneHint,
                          controller: _altPhoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.textMuted,
                          ),
                          maxLength: 10,
                        ),
                        AppSpacing.gapV8,

                        YbTextInput(
                          label: l10n.customerEmail,
                          hint: l10n.customerEmailHint,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textMuted,
                          ),
                        ),
                        AppSpacing.gapV16,

                        // Customer Type Toggle
                        Text(
                          l10n.customerType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapV8,
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment<String>(
                                value: 'individual',
                                label: Text(l10n.customerTypeIndividual),
                                icon: const Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                ),
                              ),
                              ButtonSegment<String>(
                                value: 'business',
                                label: Text(l10n.customerTypeBusiness),
                                icon: const Icon(
                                  Icons.business_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                            selected: {_selectedCustomerType},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _selectedCustomerType = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV16,

                  // Address Card (Collapsible)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _addressExpanded,
                        onExpansionChanged: (val) =>
                            setState(() => _addressExpanded = val),
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          l10n.customerAddressHeader,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: Column(
                              children: [
                                YbTextInput(
                                  label: l10n.customerAddressLine1,
                                  hint: l10n.customerAddressLine1Hint,
                                  controller: _line1Controller,
                                ),
                                AppSpacing.gapV12,
                                YbTextInput(
                                  label: l10n.customerAddressLine2,
                                  hint: l10n.customerAddressLine2Hint,
                                  controller: _line2Controller,
                                ),
                                AppSpacing.gapV12,
                                Row(
                                  children: [
                                    Expanded(
                                      child: YbTextInput(
                                        label: l10n.customerArea,
                                        hint: l10n.customerAreaHint,
                                        controller: _areaController,
                                      ),
                                    ),
                                    AppSpacing.gapH12,
                                    Expanded(
                                      child: YbTextInput(
                                        label: l10n.customerCity,
                                        hint: l10n.customerCityHint,
                                        controller: _cityController,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapV12,
                                Row(
                                  children: [
                                    Expanded(
                                      child: YbTextInput(
                                        label: l10n.customerState,
                                        controller: _stateController,
                                      ),
                                    ),
                                    AppSpacing.gapH12,
                                    Expanded(
                                      child: YbTextInput(
                                        label: l10n.customerPinCode,
                                        hint: l10n.customerPinCodeHint,
                                        controller: _postalController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapV16,

                  // Notes Card
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
                        YbTextInput(
                          label: l10n.customerNotes,
                          hint: l10n.customerNotesHint,
                          controller: _notesController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV24,

                  // Save Changes Button
                  YbPrimaryButton(
                    label: l10n.actionSave,
                    icon: const Icon(Icons.check_rounded),
                    isLoading: formState.isLoading,
                    onPressed: () => _handleSubmit(customer),
                  ),
                  AppSpacing.gapV24,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
