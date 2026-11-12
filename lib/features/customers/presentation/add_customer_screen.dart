import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_text_input.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/customer_providers.dart';

/// Screen for adding a new customer manually or from imported contact details.
class AddCustomerScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialPhone;

  const AddCustomerScreen({super.key, this.initialName, this.initialPhone});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
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

  final FocusNode _phoneFocusNode = FocusNode();
  String _selectedCustomerType = 'individual';
  bool _addressExpanded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _altPhoneController = TextEditingController();
    _emailController = TextEditingController();
    _line1Controller = TextEditingController();
    _line2Controller = TextEditingController();
    _areaController = TextEditingController();
    _cityController = TextEditingController(text: 'Ahmedabad');
    _stateController = TextEditingController(text: 'Gujarat');
    _postalController = TextEditingController();
    _notesController = TextEditingController();

    // Initialize provider state if initial values provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(
        customerFormControllerProvider(null).notifier,
      );
      if (widget.initialName != null) {
        controller.updateFullName(widget.initialName!);
      }
      if (widget.initialPhone != null) {
        controller.updatePrimaryPhone(widget.initialPhone!);
      }
    });

    _phoneFocusNode.addListener(_onPhoneFocusChange);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onPhoneFocusChange);
    _phoneFocusNode.dispose();
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

  void _onPhoneFocusChange() async {
    if (!_phoneFocusNode.hasFocus &&
        _phoneController.text.trim().length >= 10) {
      final business = await ref.read(currentBusinessProvider.future);
      if (business != null && mounted) {
        final duplicate = await ref
            .read(customerFormControllerProvider(null).notifier)
            .checkDuplicate(business.id);
        if (duplicate != null && mounted) {
          _showDuplicateDialog(duplicate);
        }
      }
    }
  }

  Future<void> _showDuplicateDialog(Customer duplicate) async {
    final l10n = context.l10n;
    final proceedAnyway = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        title: Text(
          l10n.customerDuplicateWarningTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.customerDuplicateWarningMessage(
            duplicate.primaryPhone,
            duplicate.fullName,
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              context.push('/customers/${duplicate.id}');
            },
            child: Text(l10n.customerViewExisting),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.customerSaveAnyway),
          ),
        ],
      ),
    );

    if (proceedAnyway != true && mounted) {
      ref
          .read(customerFormControllerProvider(null).notifier)
          .clearDuplicateWarning();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final business = await ref.read(currentBusinessProvider.future);
    if (business == null) return;

    final controller = ref.read(customerFormControllerProvider(null).notifier);

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

    // Check duplicate if not already acknowledged
    final formState = ref.read(customerFormControllerProvider(null));
    if (formState.duplicateWarningCustomer == null) {
      final duplicate = await controller.checkDuplicate(business.id);
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

    final newCustomer = await controller.submitCreate(business.id);

    if (newCustomer != null && mounted) {
      ref.invalidate(customersListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.customerSaveSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate directly to the newly created customer profile
      context.pushReplacement('/customers/${newCustomer.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formState = ref.watch(customerFormControllerProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.addCustomerTitle,
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
              // Error banner if any
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

              // Section: Basic Info
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
                    // Customer Name
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

                    // Primary Phone
                    YbTextInput(
                      label: l10n.customerPrimaryPhone,
                      hint: l10n.customerPrimaryPhoneHint,
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
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

                    // Alternate Phone
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

                    // Email Address
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

                    // Customer Type Segmented Toggle
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
                            icon: const Icon(Icons.person_rounded, size: 18),
                          ),
                          ButtonSegment<String>(
                            value: 'business',
                            label: Text(l10n.customerTypeBusiness),
                            icon: const Icon(Icons.business_rounded, size: 18),
                          ),
                        ],
                        selected: {_selectedCustomerType},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _selectedCustomerType = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primaryContainer;
                            }
                            return AppColors.surface;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return AppColors.textSecondary;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapV16,

              // Section: Address (Collapsible)
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

              // Section: Notes
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

              // Submit Button
              YbPrimaryButton(
                label: l10n.actionSave,
                icon: const Icon(Icons.check_circle_outline_rounded),
                isLoading: formState.isLoading,
                onPressed: _handleSubmit,
              ),
              AppSpacing.gapV24,
            ],
          ),
        ),
      ),
    );
  }
}
