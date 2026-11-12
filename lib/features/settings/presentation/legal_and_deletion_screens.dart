import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../auth/providers/auth_controller.dart';
import '../../subscriptions/providers/subscription_providers.dart';

class LegalOverviewScreen extends StatelessWidget {
  const LegalOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreLegalTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: const [
          _LegalSectionCard(
            title: 'Privacy Policy Summary',
            body:
                'Yaadibook collects business profile details, customer records, service logs, maintenance schedules, AMC agreements, and optional messaging preferences solely to provide your business workspace.\n\n'
                '• Data Isolation: Every record is isolated per authenticated business owner via PostgreSQL Row-Level Security (RLS).\n'
                '• Device Permissions: Contacts, notifications, and file/photo attachments are strictly optional and used only when you initiate them.\n'
                '• Data Exports & Deletion: You can export your reports as PDF/CSV anytime and permanently delete your account from Settings.',
          ),
          SizedBox(height: 12),
          _LegalSectionCard(
            title: 'Terms of Service Summary',
            body:
                'Yaadibook is a business operations and customer follow-up assistant for service businesses.\n\n'
                '• Operational Records Disclaimer: Amounts entered on services and AMCs are operational business records and do not replace certified accounting software or GST filing platforms.\n'
                '• Messaging Compliance: Business owners are responsible for obtaining customer consent and complying with applicable WhatsApp/Meta and India TRAI DLT rules.\n'
                '• Subscriptions: Paid features are billed via Google Play and governed by Google Play billing and refund policies.',
          ),
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          AppSpacing.gapV8,
          Text(body, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _phraseController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _phraseController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDeletion() async {
    final phrase = _phraseController.text.trim();
    if (phrase != 'DELETE MY ACCOUNT') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type DELETE MY ACCOUNT exactly to confirm.'),
        ),
      );
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .requestAccountDeletion(
            confirmationPhrase: phrase,
            reason: _reasonController.text.trim(),
          );
      await ref.read(offlineStoreProvider).clearAllData();
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deletion failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userEmail =
        ref.watch(currentUserProfileProvider).valueOrNull?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Permanent Account & Data Deletion',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV8,
                Text(
                  l10n.deleteAccountWarning,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
                if (userEmail.isNotEmpty) ...[
                  AppSpacing.gapV8,
                  Text(
                    'Signed-in account: $userEmail',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapV20,
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Optional reason for leaving',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          AppSpacing.gapV16,
          TextField(
            controller: _phraseController,
            decoration: const InputDecoration(
              labelText: 'Type DELETE MY ACCOUNT to confirm',
              hintText: 'DELETE MY ACCOUNT',
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.gapV20,
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _isDeleting ? null : _submitDeletion,
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Permanently Delete Account'),
          ),
        ],
      ),
    );
  }
}
