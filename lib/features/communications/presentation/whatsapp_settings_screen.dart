import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/models/provider_configuration.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/communication_providers.dart';

class WhatsAppSettingsScreen extends ConsumerStatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  ConsumerState<WhatsAppSettingsScreen> createState() =>
      _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState
    extends ConsumerState<WhatsAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wabaIdController = TextEditingController();
  final _phoneIdController = TextEditingController();
  final _webhookUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _isInit = true;
      _loadConfig();
    }
  }

  Future<void> _loadConfig() async {
    final business = ref.read(currentBusinessProvider).valueOrNull;
    if (business == null) return;

    final repo = ref.read(bulkMessagingRepositoryProvider);
    final configs = await repo.getProviderConfigurations(business.id);
    final waConfig = configs.firstWhere(
      (c) => c.isWhatsApp,
      orElse: () => ProviderConfiguration(
        id: '',
        businessId: business.id,
        providerType: 'whatsapp_cloud_api',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (mounted) {
      setState(() {
        _wabaIdController.text = waConfig.wabaId ?? '';
        _phoneIdController.text = waConfig.phoneNumberId ?? '';
        _webhookUrlController.text =
            waConfig.webhookUrl ??
            'https://<project-ref>.supabase.co/functions/v1/whatsapp-cloud-api';
      });
    }
  }

  @override
  void dispose() {
    _wabaIdController.dispose();
    _phoneIdController.dispose();
    _webhookUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp Cloud API Settings')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Setup Guide Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Official Meta Cloud API Setup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapV8,
                    const Text(
                      'Configure your Meta Business Manager WhatsApp Cloud API credentials to enable automated messaging and official status delivery receipts.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapV16,

              // Form Fields
              TextFormField(
                controller: _wabaIdController,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Business Account ID (WABA ID)',
                  hintText: 'e.g. 109283746501928',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),
              AppSpacing.gapV16,

              TextFormField(
                controller: _phoneIdController,
                decoration: InputDecoration(
                  labelText: 'Phone Number ID',
                  hintText: 'e.g. 102938475610293',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),
              AppSpacing.gapV16,

              TextFormField(
                controller: _webhookUrlController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Meta Webhook Callback URL',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Webhook URL copied!')),
                      );
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),
              AppSpacing.gapV24,

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
                  label: const Text('Save Configuration'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _saveConfig,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    final business = ref.read(currentBusinessProvider).valueOrNull;
    if (business == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(bulkMessagingRepositoryProvider);
      final config = ProviderConfiguration(
        id: '',
        businessId: business.id,
        providerType: 'whatsapp_cloud_api',
        wabaId: _wabaIdController.text.trim().isNotEmpty
            ? _wabaIdController.text.trim()
            : null,
        phoneNumberId: _phoneIdController.text.trim().isNotEmpty
            ? _phoneIdController.text.trim()
            : null,
        webhookUrl: _webhookUrlController.text.trim(),
        connectionStatus: _phoneIdController.text.trim().isNotEmpty
            ? 'connected'
            : 'disconnected',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveProviderConfiguration(config);
      ref.invalidate(providerConfigurationsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp settings saved successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
