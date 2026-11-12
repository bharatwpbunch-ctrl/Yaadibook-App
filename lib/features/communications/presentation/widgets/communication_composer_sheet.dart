import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/message_template.dart';
import '../../../../shared/providers/backend_providers.dart';
import '../../../customers/providers/customer_providers.dart';
import '../../providers/communication_providers.dart';

class CommunicationComposerSheet extends ConsumerStatefulWidget {
  final Customer? prefilledCustomer;
  final String? initialPhone;
  final String? initialName;
  final String? serviceId;
  final String? serviceReference;
  final String? serviceTitle;
  final String? serviceStatus;
  final String? maintenanceOccurrenceId;
  final String? maintenanceDate;
  final String? amcContractId;
  final String? amcEndDate;
  final String? amount;
  final String? preferredCategory;

  const CommunicationComposerSheet({
    super.key,
    this.prefilledCustomer,
    this.initialPhone,
    this.initialName,
    this.serviceId,
    this.serviceReference,
    this.serviceTitle,
    this.serviceStatus,
    this.maintenanceOccurrenceId,
    this.maintenanceDate,
    this.amcContractId,
    this.amcEndDate,
    this.amount,
    this.preferredCategory,
  });

  static Future<void> show(
    BuildContext context, {
    Customer? customer,
    String? phone,
    String? name,
    String? serviceId,
    String? serviceReference,
    String? serviceTitle,
    String? serviceStatus,
    String? maintenanceOccurrenceId,
    String? maintenanceDate,
    String? amcContractId,
    String? amcEndDate,
    String? amount,
    String? preferredCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommunicationComposerSheet(
          prefilledCustomer: customer,
          initialPhone: phone,
          initialName: name,
          serviceId: serviceId,
          serviceReference: serviceReference,
          serviceTitle: serviceTitle,
          serviceStatus: serviceStatus,
          maintenanceOccurrenceId: maintenanceOccurrenceId,
          maintenanceDate: maintenanceDate,
          amcContractId: amcContractId,
          amcEndDate: amcEndDate,
          amount: amount,
          preferredCategory: preferredCategory,
        ),
      ),
    );
  }

  @override
  ConsumerState<CommunicationComposerSheet> createState() =>
      _CommunicationComposerSheetState();
}

class _CommunicationComposerSheetState
    extends ConsumerState<CommunicationComposerSheet> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  Customer? _selectedCustomer;
  MessageTemplate? _selectedTemplate;
  bool _isCustomMessage = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.prefilledCustomer;
    _phoneController.text =
        widget.prefilledCustomer?.primaryPhone ?? widget.initialPhone ?? '';
    _nameController.text =
        widget.prefilledCustomer?.fullName ?? widget.initialName ?? '';

    if (widget.preferredCategory != null) {
      final business = ref.read(currentBusinessProvider).valueOrNull;
      _messageController.text =
          CommunicationComposerController.buildDefaultReminderMessage(
            category: widget.preferredCategory!,
            customerName: _nameController.text,
            businessName: business?.businessName,
            businessPhone: business?.phone,
            title: widget.serviceTitle,
            maintenanceDate: widget.maintenanceDate,
            amcEndDate: widget.amcEndDate,
            amount: widget.amount,
          );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildVariableData() {
    final business = ref.read(currentBusinessProvider).valueOrNull;

    return {
      'customer_name': _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Valued Customer',
      'business_name': business?.businessName ?? 'Yaadibook Service',
      'business_phone': business?.phone ?? '',
      'service_title': widget.serviceTitle ?? 'Service Work',
      'service_reference': widget.serviceReference ?? 'SRV-001',
      'service_status': widget.serviceStatus ?? 'In Progress',
      'maintenance_date': widget.maintenanceDate ?? 'Upcoming',
      'amc_end_date': widget.amcEndDate ?? 'Soon',
      'amount': widget.amount ?? '0',
    };
  }

  void _applyTemplate(MessageTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _isCustomMessage = false;
      _messageController.text = template.render(_buildVariableData());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final templatesAsync = ref.watch(messageTemplatesProvider);
    final customersAsync = ref.watch(customersListProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.bottomSheet,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle & Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                AppSpacing.gapH8,
                Text(
                  l10n.commComposeAction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.borderSubtle),

            // Customer Selector (if not prefilled)
            if (_selectedCustomer == null) ...[
              Text(
                l10n.remindersCustomerLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapV4,
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: InputDecoration(
                    hintText: 'Select an existing customer (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: customers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.fullName} (${c.primaryPhone})'),
                        ),
                      )
                      .toList(),
                  onChanged: (c) {
                    if (c != null) {
                      setState(() {
                        _selectedCustomer = c;
                        _phoneController.text = c.primaryPhone;
                        _nameController.text = c.fullName;
                        if (_selectedTemplate != null) {
                          _messageController.text = _selectedTemplate!.render(
                            _buildVariableData(),
                          );
                        }
                      });
                    }
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              AppSpacing.gapV12,
            ],

            // Recipient Phone & Name Inputs
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapH8,
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) {
                      if (_selectedTemplate != null && !_isCustomMessage) {
                        _messageController.text = _selectedTemplate!.render(
                          _buildVariableData(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.gapV16,

            // Template Selector Row
            Text(
              l10n.commTemplatesNavTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapV4,
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) return const SizedBox.shrink();

                // Auto-select preferred category template if available
                if (_selectedTemplate == null &&
                    !_isCustomMessage &&
                    widget.preferredCategory != null) {
                  final matches = templates.where(
                    (t) => t.category == widget.preferredCategory,
                  );
                  if (matches.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_isCustomMessage) {
                        _applyTemplate(matches.first);
                      }
                    });
                  }
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: templates.map((tpl) {
                      final isSelected = _selectedTemplate?.id == tpl.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(tpl.name),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) _applyTemplate(tpl);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            AppSpacing.gapV12,

            // Message Body / Live Preview
            Text(
              l10n.commMessagePreviewLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapV4,
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              onChanged: (_) => _isCustomMessage = true,
              decoration: InputDecoration(
                hintText: 'Type your message or pick a template above...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            AppSpacing.gapV8,

            // Clarification Note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.badge),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapH6,
                  Expanded(
                    child: Text(
                      l10n.commTruthfulLoggingNotice,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapV16,

            // Action Buttons: Open in WhatsApp & Open in SMS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.sms_outlined,
                      size: 18,
                      color: AppColors.info,
                    ),
                    label: Text(l10n.commActionOpenSms),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _handleDispatch(channel: 'sms'),
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(
                      Icons.chat_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(l10n.commActionOpenWhatsApp),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _handleDispatch(channel: 'whatsapp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDispatch({required String channel}) async {
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();
    final business = ref.read(currentBusinessProvider).valueOrNull;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message or choose a template'),
        ),
      );
      return;
    }

    final controller = ref.read(
      communicationComposerControllerProvider.notifier,
    );

    Navigator.of(context).pop();

    if (channel == 'whatsapp') {
      await controller.sendOrOpenWhatsApp(
        businessId: business?.id ?? '',
        customerId: _selectedCustomer?.id,
        serviceId: widget.serviceId,
        maintenanceOccurrenceId: widget.maintenanceOccurrenceId,
        amcContractId: widget.amcContractId,
        templateId: _selectedTemplate?.id,
        recipientPhone: phone,
        recipientName: _nameController.text.trim(),
        messageBody: message,
      );
    } else {
      await controller.sendOrOpenSms(
        businessId: business?.id ?? '',
        customerId: _selectedCustomer?.id,
        serviceId: widget.serviceId,
        maintenanceOccurrenceId: widget.maintenanceOccurrenceId,
        amcContractId: widget.amcContractId,
        templateId: _selectedTemplate?.id,
        recipientPhone: phone,
        recipientName: _nameController.text.trim(),
        messageBody: message,
      );
    }
  }
}
