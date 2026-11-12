import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_text_input.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../customers/providers/customer_providers.dart';
import '../providers/service_providers.dart';

/// Screen for creating a new service entry.
class AddServiceScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;

  const AddServiceScreen({super.key, this.initialCustomerId});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _workPerformedController;
  late final TextEditingController _baseChargeController;
  late final TextEditingController _additionalChargesController;
  late final TextEditingController _discountController;
  late final TextEditingController _notesController;

  final ImagePicker _picker = ImagePicker();
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _workPerformedController = TextEditingController();
    _baseChargeController = TextEditingController();
    _additionalChargesController = TextEditingController();
    _discountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.initialCustomerId != null) {
      _isInit = true;
      Future.microtask(() async {
        final customer = await ref.read(
          customerDetailProvider(widget.initialCustomerId!).future,
        );
        if (customer != null && mounted) {
          ref
              .read(serviceFormControllerProvider(null).notifier)
              .selectCustomer(customer);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _workPerformedController.dispose();
    _baseChargeController.dispose();
    _additionalChargesController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final attachment = PendingAttachment(
        fileName: file.name,
        bytes: bytes,
        mimeType: file.mimeType ?? 'image/jpeg',
        localPath: file.path,
      );

      ref
          .read(serviceFormControllerProvider(null).notifier)
          .addPendingAttachment(attachment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick photo: $e')));
      }
    }
  }

  void _showAttachmentSourceSheet() {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.serviceTakePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.secondary,
                ),
                title: Text(l10n.serviceChooseGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCustomerSelector() async {
    final customers = await ref.read(customersListProvider.future);
    if (!mounted) return;

    showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerSelectionSheet(customers: customers),
    ).then((selected) {
      if (selected != null && mounted) {
        ref
            .read(serviceFormControllerProvider(null).notifier)
            .selectCustomer(selected);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final business = await ref.read(currentBusinessProvider.future);
    if (business == null) return;

    final controller = ref.read(serviceFormControllerProvider(null).notifier);

    // Sync input values to state
    controller.updateTitle(_titleController.text);
    controller.updateDescription(_descriptionController.text);
    controller.updateWorkPerformed(_workPerformedController.text);
    controller.updateNotes(_notesController.text);

    final base = double.tryParse(_baseChargeController.text.trim());
    final add =
        double.tryParse(_additionalChargesController.text.trim()) ?? 0.0;
    final disc = double.tryParse(_discountController.text.trim()) ?? 0.0;

    controller.updateServiceAmount(base);
    controller.updateAdditionalCharges(add);
    controller.updateDiscountAmount(disc);

    final created = await controller.submitCreate(business.id);

    if (created != null && mounted) {
      ref.invalidate(servicesListProvider);
      ref.invalidate(servicesSummaryProvider);
      ref.invalidate(recentServicesProvider);
      ref.invalidate(pendingServicesListProvider);
      if (created.customerId.isNotEmpty) {
        ref.invalidate(customerServiceHistoryProvider(created.customerId));
        ref.invalidate(customerServiceCountsProvider(created.customerId));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.serviceSaveSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pushReplacement('/services/${created.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formState = ref.watch(serviceFormControllerProvider(null));
    final controller = ref.read(serviceFormControllerProvider(null).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.addServiceTitle,
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
              // Error Banner
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

              // Section A: Customer Selection
              _buildCustomerCard(context, formState),
              AppSpacing.gapV16,

              // Section B: Service Information
              _buildServiceInfoCard(context, formState, controller),
              AppSpacing.gapV16,

              // Section C: Equipment (Optional)
              if (formState.selectedCustomer != null) ...[
                _buildEquipmentCard(context, formState, controller),
                AppSpacing.gapV16,
              ],

              // Section D: Work Details
              _buildWorkDetailsCard(context),
              AppSpacing.gapV16,

              // Section E: Status
              _buildStatusCard(context, formState, controller),
              AppSpacing.gapV16,

              // Section F: Charges
              _buildChargesCard(context, formState),
              AppSpacing.gapV16,

              // Section G: Attachments
              _buildAttachmentsCard(context, formState, controller),
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

  Widget _buildCustomerCard(BuildContext context, ServiceFormState state) {
    final l10n = context.l10n;
    final customer = state.selectedCustomer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.serviceCustomerSection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (customer != null)
                TextButton(
                  onPressed: _openCustomerSelector,
                  child: const Text('Change'),
                ),
            ],
          ),
          AppSpacing.gapV8,
          if (customer == null)
            InkWell(
              onTap: _openCustomerSelector,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_search_outlined,
                      color: AppColors.primary,
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: Text(
                        l10n.serviceSelectCustomerPrompt,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    customer.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                        customer.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapV2,
                      Text(
                        customer.primaryPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (customer.locationSummary.isNotEmpty) ...[
                        AppSpacing.gapV2,
                        Text(
                          customer.locationSummary,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard(
    BuildContext context,
    ServiceFormState state,
    ServiceFormController controller,
  ) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serviceInfoSection,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV16,

          // Service Title
          YbTextInput(
            label: l10n.serviceTitleLabel,
            hint: l10n.serviceTitleHint,
            controller: _titleController,
            prefixIcon: const Icon(
              Icons.title_rounded,
              color: AppColors.textMuted,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return l10n.serviceTitleLabel;
              }
              return null;
            },
          ),
          AppSpacing.gapV16,

          // Service Type
          Text(
            l10n.serviceTypeLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV8,
          DropdownButtonFormField<String>(
            initialValue: state.serviceType,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.border),
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
              if (val != null) controller.updateServiceType(val);
            },
          ),
          AppSpacing.gapV16,

          // Service Date Picker
          Text(
            l10n.serviceDateLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV8,
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.serviceDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                controller.updateServiceDate(picked);
              }
            },
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapH12,
                  Text(
                    DateFormatter.formatShort(state.serviceDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    ServiceFormState state,
    ServiceFormController controller,
  ) {
    final l10n = context.l10n;
    final equipmentAsync = ref.watch(
      customerEquipmentListProvider(state.selectedCustomer!.id),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serviceEquipmentSection,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV12,
          equipmentAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, stack) => const SizedBox.shrink(),
            data: (equipmentList) {
              if (equipmentList.isEmpty) {
                return Text(
                  l10n.serviceNoEquipmentRegistered,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                );
              }

              return DropdownButtonFormField<String?>(
                initialValue: state.equipmentId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                hint: Text(l10n.serviceSelectEquipment),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None (General service)'),
                  ),
                  ...equipmentList.map(
                    (eq) => DropdownMenuItem<String?>(
                      value: eq.id,
                      child: Text(eq.displayName),
                    ),
                  ),
                ],
                onChanged: (val) => controller.selectEquipment(val),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetailsCard(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serviceWorkDetailsSection,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV16,
          YbTextInput(
            label: l10n.serviceDescriptionLabel,
            hint: l10n.serviceDescriptionHint,
            controller: _descriptionController,
            maxLines: 2,
          ),
          AppSpacing.gapV12,
          YbTextInput(
            label: l10n.serviceWorkPerformedLabel,
            hint: l10n.serviceWorkPerformedHint,
            controller: _workPerformedController,
            maxLines: 2,
          ),
          AppSpacing.gapV12,
          YbTextInput(
            label: l10n.customerNotes,
            hint: l10n.customerNotesHint,
            controller: _notesController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    ServiceFormState state,
    ServiceFormController controller,
  ) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Initial Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV12,
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
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
              ],
              selected: {state.status},
              onSelectionChanged: (val) => controller.updateStatus(val.first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesCard(BuildContext context, ServiceFormState state) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serviceChargesSection,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV16,

          // Base Service Charge
          YbTextInput(
            label: l10n.serviceChargeBaseLabel,
            hint: l10n.serviceChargeBaseHint,
            controller: _baseChargeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              setState(() {});
            },
          ),
          AppSpacing.gapV12,

          Row(
            children: [
              Expanded(
                child: YbTextInput(
                  label: l10n.serviceAdditionalChargesLabel,
                  hint: '0.00',
                  controller: _additionalChargesController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              AppSpacing.gapH12,
              Expanded(
                child: YbTextInput(
                  label: l10n.serviceDiscountLabel,
                  hint: '0.00',
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ),
          AppSpacing.gapV16,

          // Live Total Preview Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.serviceTotalAmountLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(_calculateLiveTotal()),
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
    );
  }

  double _calculateLiveTotal() {
    final base = double.tryParse(_baseChargeController.text.trim()) ?? 0.0;
    final add =
        double.tryParse(_additionalChargesController.text.trim()) ?? 0.0;
    final disc = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final total = base + add - disc;
    return total < 0 ? 0.0 : total;
  }

  Widget _buildAttachmentsCard(
    BuildContext context,
    ServiceFormState state,
    ServiceFormController controller,
  ) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.serviceAttachmentsSection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: Text(l10n.serviceAddPhoto),
                onPressed: _showAttachmentSourceSheet,
              ),
            ],
          ),
          if (state.pendingAttachments.isEmpty) ...[
            AppSpacing.gapV8,
            const Text(
              'No photos attached yet.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ] else ...[
            AppSpacing.gapV12,
            ...state.pendingAttachments.asMap().entries.map((entry) {
              final idx = entry.key;
              final att = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    AppSpacing.gapH8,
                    Expanded(
                      child: Text(
                        att.fileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => controller.removePendingAttachment(idx),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet for selecting an existing customer.
class _CustomerSelectionSheet extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSelectionSheet({required this.customers});

  @override
  State<_CustomerSelectionSheet> createState() =>
      _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState extends State<_CustomerSelectionSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.fullName.toLowerCase().contains(q) || c.primaryPhone.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No customers found matching search.'),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(height: 1, color: AppColors.borderSubtle),
                    itemBuilder: (ctx, i) {
                      final customer = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            customer.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        title: Text(customer.fullName),
                        subtitle: Text(customer.primaryPhone),
                        onTap: () => Navigator.pop(ctx, customer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
