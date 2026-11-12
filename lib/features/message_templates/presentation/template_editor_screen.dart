import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/communication_service.dart';
import '../../../shared/models/message_template.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../communications/providers/communication_providers.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const TemplateEditorScreen({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _dltController = TextEditingController();

  String _category = 'service_update';
  String _channel = 'both';
  String _language = 'en';
  bool _isLoading = false;
  bool _isInit = false;

  final List<String> _commonVariables = [
    'customer_name',
    'business_name',
    'business_phone',
    'service_reference',
    'service_status',
    'maintenance_date',
    'amc_end_date',
    'amount',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.templateId != null) {
      _isInit = true;
      _loadTemplate();
    }
  }

  Future<void> _loadTemplate() async {
    final repo = ref.read(messageTemplateRepositoryProvider);
    final tpl = await repo.getTemplateById(widget.templateId!);
    if (tpl != null && mounted) {
      setState(() {
        _nameController.text = tpl.name;
        _contentController.text = tpl.content;
        _dltController.text = tpl.dltTemplateId ?? '';
        _category = tpl.category;
        _channel = tpl.channel;
        _language = tpl.language;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _dltController.dispose();
    super.dispose();
  }

  void _insertVariable(String variable) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final placeholder = '{{$variable}}';

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        placeholder,
      );
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + placeholder.length,
        ),
      );
    } else {
      _contentController.text = '$text$placeholder';
    }
    setState(() {});
  }

  String _renderPreview() {
    final sampleData = {
      'customer_name': 'Ramesh Kumar',
      'business_name': 'Bharat CCTV Solutions',
      'business_phone': '+91 98250 12345',
      'service_reference': 'SRV-2026-089',
      'service_status': 'Completed',
      'maintenance_date': '10 Nov 2026',
      'amc_end_date': '31 Dec 2026',
      'amount': '2,500',
    };
    return CommunicationService.replaceVariables(
      _contentController.text.isEmpty
          ? 'Preview will appear here as you type...'
          : _contentController.text,
      sampleData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.templateId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.commEditTemplateTitle : l10n.commCreateTemplateTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${l10n.commTemplateNameLabel} *',
                  hintText: 'e.g. CCTV Maintenance Reminder',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter template name'
                    : null,
              ),
              AppSpacing.gapV16,

              // Category & Channel Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'service_update',
                          child: Text(l10n.commCategoryServiceUpdate),
                        ),
                        DropdownMenuItem(
                          value: 'amc_renewal',
                          child: Text(l10n.commCategoryAmcRenewal),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance_reminder',
                          child: Text(l10n.commCategoryMaintenance),
                        ),
                        DropdownMenuItem(
                          value: 'payment_reminder',
                          child: Text(l10n.commCategoryPayment),
                        ),
                        const DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom / Other'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                  AppSpacing.gapH12,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી')),
                        DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _language = val);
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.gapV16,

              // DLT Template ID (for SMS Gateway compliance in India)
              TextFormField(
                controller: _dltController,
                decoration: InputDecoration(
                  labelText: 'DLT Template ID (Optional for Indian SMS)',
                  hintText: 'e.g. 1107161829384910293',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),
              AppSpacing.gapV16,

              // Variable Placeholder Insertion Chips
              Text(
                l10n.commInsertVariableLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapV4,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _commonVariables.map((v) {
                  return ActionChip(
                    label: Text('+ {{$v}}'),
                    avatar: const Icon(Icons.add, size: 14),
                    onPressed: () => _insertVariable(v),
                  );
                }).toList(),
              ),
              AppSpacing.gapV16,

              // Content TextArea
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '${l10n.commContentLabel} *',
                  hintText:
                      'Type message content and click variable buttons above to insert dynamic values...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter template content'
                    : null,
              ),
              AppSpacing.gapV16,

              // Live Preview Box
              Text(
                l10n.commLivePreviewTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapV4,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  _renderPreview(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AppSpacing.gapV24,

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.commSaveTemplateAction),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _saveTemplate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final business = ref.read(currentBusinessProvider).valueOrNull;
    if (business == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(messageTemplateRepositoryProvider);
      final rawContent = _contentController.text.trim();
      final variables = CommunicationService.extractVariables(rawContent);

      final template = MessageTemplate(
        id: widget.templateId ?? '',
        businessId: business.id,
        name: _nameController.text.trim(),
        category: _category,
        channel: _channel,
        language: _language,
        content: rawContent,
        variables: variables,
        dltTemplateId: _dltController.text.trim().isNotEmpty
            ? _dltController.text.trim()
            : null,
        providerStatus: 'approved',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.templateId != null) {
        await repo.updateTemplate(template);
      } else {
        await repo.createTemplate(template);
      }

      ref.invalidate(messageTemplatesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save template: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
