import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/communication_campaign.dart';
import '../../../shared/models/message_template.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../communications/providers/communication_providers.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  int _currentStep = 0;
  final _titleController = TextEditingController();

  String _channel = 'whatsapp'; // 'whatsapp', 'sms'
  String _category = 'festive_offer';
  String _audienceFilter =
      'all'; // 'all', 'residential', 'commercial', 'industrial'

  MessageTemplate? _selectedTemplate;
  List<Map<String, dynamic>> _eligibleAudience = [];
  bool _isLoadingAudience = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchAudience();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _fetchAudience() async {
    final business = ref.read(currentBusinessProvider).valueOrNull;
    if (business == null) return;

    setState(() => _isLoadingAudience = true);
    final repo = ref.read(bulkMessagingRepositoryProvider);
    final audience = await repo.previewAudience(
      businessId: business.id,
      filterCategory: _audienceFilter,
      marketingOnly: true,
    );

    if (mounted) {
      setState(() {
        _eligibleAudience = audience;
        _isLoadingAudience = false;
      });
    }
  }

  double get _unitCost => _channel == 'whatsapp' ? 0.85 : 0.20;
  double get _estimatedTotalCost => _eligibleAudience.length * _unitCost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final templatesAsync = ref.watch(messageTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commCreateCampaignAction)),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _currentStep > 0
            ? () => setState(() => _currentStep -= 1)
            : null,
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : details.onStepContinue,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isLast
                                ? l10n.commLaunchCampaignAction
                                : l10n.actionNext,
                          ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  AppSpacing.gapH12,
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : details.onStepCancel,
                    child: Text(l10n.actionBack),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Basics
          Step(
            title: const Text('Basics'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Campaign Title *',
                    hintText: 'e.g. Diwali Maintenance Offer 2026',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                  ),
                ),
                AppSpacing.gapV16,
                const Text(
                  'Dispatch Channel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                AppSpacing.gapV8,
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text('WhatsApp'),
                        selected: _channel == 'whatsapp',
                        onSelected: (val) {
                          if (val) setState(() => _channel = 'whatsapp');
                        },
                      ),
                    ),
                    AppSpacing.gapH8,
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.sms_outlined, size: 16),
                        label: const Text('SMS'),
                        selected: _channel == 'sms',
                        onSelected: (val) {
                          if (val) setState(() => _channel = 'sms');
                        },
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV16,
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'festive_offer',
                      child: Text('Festive Offer & Promotion'),
                    ),
                    DropdownMenuItem(
                      value: 'service_update',
                      child: Text('Service Announcement'),
                    ),
                    DropdownMenuItem(
                      value: 'amc_renewal',
                      child: Text('AMC Renewal Drive'),
                    ),
                    DropdownMenuItem(
                      value: 'general_announcement',
                      child: Text('General Announcement'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ],
            ),
          ),

          // Step 2: Template
          Step(
            title: const Text('Message'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Message Template',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                AppSpacing.gapV8,
                templatesAsync.when(
                  data: (templates) {
                    if (templates.isEmpty) {
                      return const Text('No templates available.');
                    }
                    return Column(
                      children: templates.map((tpl) {
                        final isSelected = _selectedTemplate?.id == tpl.id;
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderSubtle,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            title: Text(tpl.name),
                            subtitle: Text(
                              tpl.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () =>
                                setState(() => _selectedTemplate = tpl),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),

          // Step 3: Audience
          Step(
            title: const Text('Audience'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Customer Segment',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                AppSpacing.gapV8,
                DropdownButtonFormField<String>(
                  initialValue: _audienceFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Customers (Marketing Consented)'),
                    ),
                    DropdownMenuItem(
                      value: 'residential',
                      child: Text('Residential Customers'),
                    ),
                    DropdownMenuItem(
                      value: 'commercial',
                      child: Text('Commercial Customers'),
                    ),
                    DropdownMenuItem(
                      value: 'industrial',
                      child: Text('Industrial Customers'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _audienceFilter = val);
                      _fetchAudience();
                    }
                  },
                ),
                AppSpacing.gapV12,

                // Compliance Notice
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      AppSpacing.gapH8,
                      const Expanded(
                        child: Text(
                          'Strict compliance: Excludes all opted-out customers. Only delivers to contacts with marketing consent.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapV16,

                // Live Preview Counter
                if (_isLoadingAudience)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Row(
                    children: [
                      Text(
                        'Eligible Recipients: ${_eligibleAudience.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapV8,
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderSubtle),
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _eligibleAudience.length,
                      separatorBuilder: (_, _) => const Divider(height: 8),
                      itemBuilder: (context, idx) {
                        final rec = _eligibleAudience[idx];
                        return Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            AppSpacing.gapH6,
                            Text(
                              rec['customer_name'] ?? 'Customer',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              rec['customer_phone'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Step 4: Cost Estimation & Review
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Campaign Title', _titleController.text.trim()),
                _buildReviewRow('Channel', _channel.toUpperCase()),
                _buildReviewRow('Template', _selectedTemplate?.name ?? '-'),
                _buildReviewRow(
                  'Total Recipients',
                  '${_eligibleAudience.length}',
                ),
                _buildReviewRow(
                  'Rate per Message',
                  '₹${_unitCost.toStringAsFixed(2)}',
                ),
                const Divider(height: 20, color: AppColors.borderSubtle),
                Row(
                  children: [
                    const Text(
                      'Estimated Total Cost:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(_estimatedTotalCost),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter campaign title')),
        );
        return;
      }
      setState(() => _currentStep += 1);
    } else if (_currentStep == 1) {
      if (_selectedTemplate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a message template')),
        );
        return;
      }
      setState(() => _currentStep += 1);
    } else if (_currentStep == 2) {
      if (_eligibleAudience.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No eligible consented recipients found for this filter',
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep += 1);
    } else if (_currentStep == 3) {
      _launchCampaign();
    }
  }

  Future<void> _launchCampaign() async {
    final business = ref.read(currentBusinessProvider).valueOrNull;
    if (business == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(bulkMessagingRepositoryProvider);

      final campaign = CommunicationCampaign(
        id: '',
        businessId: business.id,
        templateId: _selectedTemplate?.id,
        title: _titleController.text.trim(),
        channel: _channel,
        category: _category,
        status: 'completed', // Simulated completion for dev
        totalRecipients: _eligibleAudience.length,
        successfulCount: _eligibleAudience.length,
        failedCount: 0,
        estimatedCostInr: _estimatedTotalCost,
        actualCostInr: _estimatedTotalCost,
        filterCriteria: {'segment': _audienceFilter},
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final recipients = _eligibleAudience.map((r) {
        return CampaignRecipient(
          id: '',
          campaignId: '',
          customerId: r['customer_id'],
          customerName: r['customer_name'],
          customerPhone: r['customer_phone'],
          submissionStatus: 'delivered',
          providerMessageId: 'sim_cmp_${DateTime.now().millisecondsSinceEpoch}',
          dispatchedAt: DateTime.now(),
        );
      }).toList();

      final created = await repo.createCampaign(campaign, recipients);
      ref.invalidate(campaignsListProvider);
      ref.invalidate(communicationStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign dispatched successfully!')),
        );
        context.pushReplacement('/communications/campaigns/${created.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch campaign: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
