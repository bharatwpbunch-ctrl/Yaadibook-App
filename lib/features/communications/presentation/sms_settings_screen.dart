import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/models/provider_configuration.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/communication_providers.dart';

class SmsSettingsScreen extends ConsumerStatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  ConsumerState<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends ConsumerState<SmsSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entityIdController = TextEditingController();
  final _senderIdController = TextEditingController();

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
    final smsConfig = configs.firstWhere(
      (c) => c.isSms,
      orElse: () => ProviderConfiguration(
        id: '',
        businessId: business.id,
        providerType: 'sms_gateway_dlt',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (mounted) {
      setState(() {
        _entityIdController.text = smsConfig.smsEntityId ?? '';
        _senderIdController.text = smsConfig.smsSenderId ?? 'YADIBK';
      });
    }
  }

  @override
  void dispose() {
    _entityIdController.dispose();
    _senderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indian SMS Gateway & DLT Settings')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.sms_outlined,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TRAI DLT Compliance (India)',
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
                      'All commercial SMS in India requires DLT (Distributed Ledger Technology) registration with telecom operators (e.g. Jio, Airtel, Vodafone Idea, BSNL). Enter your approved Entity ID and 6-character Header.',
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

              // Principal Entity ID
              TextFormField(
                controller: _entityIdController,
                decoration: InputDecoration(
                  labelText: 'Principal Entity ID (PE ID)',
                  hintText: 'e.g. 170115982736452',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),
              AppSpacing.gapV16,

              // Sender ID / Header
              TextFormField(
                controller: _senderIdController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Approved Header / Sender ID (6 Alphabetic Chars)',
                  hintText: 'e.g. YADIBK or BHRCCT',
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
                  label: const Text('Save DLT Settings'),
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
        providerType: 'sms_gateway_dlt',
        smsEntityId: _entityIdController.text.trim().isNotEmpty
            ? _entityIdController.text.trim()
            : null,
        smsSenderId: _senderIdController.text.trim().isNotEmpty
            ? _senderIdController.text.trim().toUpperCase()
            : 'YADIBK',
        connectionStatus: _entityIdController.text.trim().isNotEmpty
            ? 'connected'
            : 'disconnected',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveProviderConfiguration(config);
      ref.invalidate(providerConfigurationsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS settings saved successfully!')),
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
