import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_confirm_dialog.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../services/presentation/widgets/service_card.dart';
import '../../services/providers/service_providers.dart';
import '../../maintenance/providers/maintenance_providers.dart';
import '../../maintenance/presentation/widgets/maintenance_plan_card.dart';
import '../../amc/providers/amc_providers.dart';
import '../../amc/presentation/widgets/amc_contract_card.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../../reminders/presentation/widgets/reminder_card.dart';
import '../models/customer_activity_item.dart';
import '../providers/customer_providers.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';

/// Customer metric card for the 2x2 service & reminder overview grid.
class _CustomerMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _CustomerMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          AppSpacing.gapV4,
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _makeCall(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
    String phoneNumber,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errText = context.l10n.commDialerError;
    final business = await ref.read(currentBusinessProvider.future);
    final repo = ref.read(customerRepositoryProvider);
    final success = await CommunicationService.makePhoneCall(phoneNumber);

    if (success && business != null) {
      await repo.logCommunication(
        businessId: business.id,
        customerId: customer.id,
        channel: 'call',
        status: 'initiated',
      );
      ref.invalidate(customerActivityProvider(customer));
    } else if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text(errText), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
    String phoneNumber,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final errText = l10n.commWhatsAppError;
    final business = await ref.read(currentBusinessProvider.future);
    final businessName = business?.businessName ?? 'Yaadibook';
    final repo = ref.read(customerRepositoryProvider);

    final greeting = l10n.commWhatsAppGreeting(customer.fullName, businessName);

    final success = await CommunicationService.openWhatsApp(
      phoneNumber: phoneNumber,
      message: greeting,
    );

    if (success && business != null) {
      await repo.logCommunication(
        businessId: business.id,
        customerId: customer.id,
        channel: 'whatsapp',
        status: 'opened',
        messageContent: greeting,
      );
      ref.invalidate(customerActivityProvider(customer));
    } else if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text(errText), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _handleArchiveToggle(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(customerRepositoryProvider);

    if (customer.isArchived) {
      // Restore
      await repo.restoreCustomer(customer.id);
      ref.invalidate(customerDetailProvider(customer.id));
      ref.invalidate(customersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.customerRestoredSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Archive with confirmation
      final confirmed = await YbConfirmDialog.show(
        context,
        title: l10n.customerArchiveConfirmTitle,
        message: l10n.customerArchiveConfirmMessage,
        confirmLabel: l10n.customerActionArchive,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
      );

      if (confirmed == true && context.mounted) {
        await repo.archiveCustomer(customer.id);
        ref.invalidate(customerDetailProvider(customer.id));
        ref.invalidate(customersListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.customerArchivedSuccess),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return customerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.customerDetailTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(child: YbLoadingState()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.customerDetailTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: YbErrorState(
          title: 'Could not load customer',
          message: err.toString(),
          onRetry: () => ref.refresh(customerDetailProvider(customerId)),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.customerDetailTitle)),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final activityAsync = ref.watch(customerActivityProvider(customer));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              l10n.customerDetailTitle,
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
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                tooltip: l10n.actionEdit,
                onPressed: () => context.push('/customers/${customer.id}/edit'),
              ),
              // More options menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (val) {
                  if (val == 'archive_toggle') {
                    _handleArchiveToggle(context, ref, customer);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'archive_toggle',
                    child: Row(
                      children: [
                        Icon(
                          customer.isArchived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                          size: 20,
                          color: customer.isArchived
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        AppSpacing.gapH8,
                        Text(
                          customer.isArchived
                              ? l10n.customerActionRestore
                              : l10n.customerActionArchive,
                          style: TextStyle(
                            color: customer.isArchived
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerDetailProvider(customer.id));
              ref.invalidate(customerActivityProvider(customer));
              ref.invalidate(customerServiceCountsProvider(customer.id));
              ref.invalidate(customerServiceHistoryProvider(customer.id));
              ref.invalidate(customerMaintenancePlansProvider(customer.id));
              ref.invalidate(customerAmcListProvider(customer.id));
              ref.invalidate(customerRemindersProvider(customer.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Top Customer Identity Card
                _buildIdentityCard(context, ref, customer),
                AppSpacing.gapV16,

                // Quick Communication Bar
                _buildCommunicationBar(context, ref, customer),
                AppSpacing.gapV16,

                // Section: Messaging Consent & Communication Logs
                _buildMessagingConsentAndHistoryCard(context, ref, customer),
                AppSpacing.gapV16,

                // Section: Address & Notes
                _buildAddressAndNotesCard(context, customer),
                AppSpacing.gapV16,

                // Section: Service & Maintenance Overview
                _buildServiceOverviewCard(context, ref, customer),
                AppSpacing.gapV16,

                // Section: Service History
                _buildServiceHistoryCard(context, ref, customer),
                AppSpacing.gapV16,

                // Section: Maintenance Plans
                _buildMaintenanceSection(context, ref, customer),
                AppSpacing.gapV16,

                // Section: AMC Contracts
                _buildAmcSection(context, ref, customer),
                AppSpacing.gapV16,

                // Section: Follow-ups & Reminders
                _buildFollowupsSection(context, ref, customer),
                AppSpacing.gapV16,

                // Section: Activity Timeline
                _buildActivityTimelineCard(context, activityAsync),
                AppSpacing.gapV24,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityCard(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Initials
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              customer.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          AppSpacing.gapH16,

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (customer.isArchived)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          l10n.customersFilterArchived,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapV4,

                // Customer Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: customer.isBusiness
                        ? AppColors.secondaryContainer
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    customer.isBusiness
                        ? l10n.customerTypeBusiness
                        : l10n.customerTypeIndividual,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: customer.isBusiness
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                AppSpacing.gapV8,

                // Primary Phone
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      customer.primaryPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // Alternate Phone
                if (customer.alternatePhone != null &&
                    customer.alternatePhone!.isNotEmpty) ...[
                  AppSpacing.gapV4,
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_iphone_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      AppSpacing.gapH8,
                      Text(
                        customer.alternatePhone!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Email
                if (customer.email != null && customer.email!.isNotEmpty) ...[
                  AppSpacing.gapV4,
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      AppSpacing.gapH8,
                      Expanded(
                        child: Text(
                          customer.email!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationBar(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;

    return Row(
      children: [
        // Call Action Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text(
              l10n.customerActionCall,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () =>
                _makeCall(context, ref, customer, customer.primaryPhone),
          ),
        ),
        AppSpacing.gapH8,

        // WhatsApp Action Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsApp,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text(
              l10n.customerActionWhatsApp,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () =>
                _openWhatsApp(context, ref, customer, customer.primaryPhone),
          ),
        ),
        AppSpacing.gapH8,

        // Message / Template Composer
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text(
              'Message',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () =>
                CommunicationComposerSheet.show(context, customer: customer),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagingConsentAndHistoryCard(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final consentAsync = ref.watch(customerConsentProvider(customer.id));
    final logsAsync = ref.watch(customerCommunicationLogsProvider(customer.id));

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
            children: [
              const Icon(
                Icons.mark_chat_read_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              const Text(
                'Messaging Consent & Preferences',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.send_outlined, size: 14),
                label: const Text(
                  'Send Message',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => CommunicationComposerSheet.show(
                  context,
                  customer: customer,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),

          consentAsync.when(
            data: (pref) {
              if (pref.isOptedOut) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block, size: 18, color: AppColors.error),
                      AppSpacing.gapH8,
                      Expanded(
                        child: Text(
                          'Customer has opted out of communications (${pref.optOutReason ?? "User request"}).',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(customerConsentControllerProvider.notifier)
                              .updateConsent(
                                preference: pref.copyWith(
                                  isOptedOut: false,
                                  whatsappOptIn: true,
                                  smsOptIn: true,
                                ),
                              );
                        },
                        child: const Text('Re-enable'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('WhatsApp Service Updates'),
                    subtitle: const Text(
                      'Transactional service, maintenance & AMC alerts',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: pref.whatsappOptIn,
                    onChanged: (val) {
                      ref
                          .read(customerConsentControllerProvider.notifier)
                          .updateConsent(
                            preference: pref.copyWith(whatsappOptIn: val),
                          );
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('SMS Notifications'),
                    subtitle: const Text(
                      'Transactional alerts via DLT-approved SMS gateway',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: pref.smsOptIn,
                    onChanged: (val) {
                      ref
                          .read(customerConsentControllerProvider.notifier)
                          .updateConsent(
                            preference: pref.copyWith(smsOptIn: val),
                          );
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Promotional & Marketing Messages'),
                    subtitle: const Text(
                      'Required for bulk campaigns & offers (TRAI compliant)',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: pref.marketingConsent,
                    onChanged: (val) {
                      ref
                          .read(customerConsentControllerProvider.notifier)
                          .updateConsent(
                            preference: pref.copyWith(marketingConsent: val),
                          );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(
                        Icons.do_not_disturb_on_outlined,
                        size: 14,
                      ),
                      label: const Text(
                        'Record Opt-Out',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                      onPressed: () => _confirmOptOut(context, ref, customer),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Consent error: $e'),
          ),

          // Recent Communications with this customer
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  const Text(
                    'Recent Communications',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapV8,
                  ...logs.take(3).map((l) {
                    final isWa = l.isWhatsApp;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            isWa ? Icons.chat_outlined : Icons.sms_outlined,
                            size: 14,
                            color: isWa ? AppColors.success : AppColors.info,
                          ),
                          AppSpacing.gapH6,
                          Expanded(
                            child: Text(
                              l.messageBody,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          AppSpacing.gapH6,
                          Text(
                            l.wasOpenedInApp ? 'Opened' : l.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOptOut(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Opt-Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will stop all promotional and automated messages to this customer.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            AppSpacing.gapV12,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Opt-Out',
                hintText: 'e.g. Customer requested stop',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Opt-Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim().isNotEmpty
          ? reasonController.text.trim()
          : 'Customer requested';
      await ref
          .read(customerConsentControllerProvider.notifier)
          .recordOptOut(
            customerId: customer.id,
            businessId: customer.businessId,
            reason: reason,
          );
    }
  }

  Widget _buildAddressAndNotesCard(BuildContext context, Customer customer) {
    final l10n = context.l10n;
    final address = customer.primaryAddress;
    final hasAddress =
        address != null &&
        (address.addressLine1.isNotEmpty ||
            address.area.isNotEmpty ||
            address.city.isNotEmpty);

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
          // Address Sub-section
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.customerAddressHeader,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            hasAddress
                ? address.formattedAddress
                : 'No address recorded for this customer.',
            style: TextStyle(
              fontSize: 13,
              color: hasAddress ? AppColors.textPrimary : AppColors.textMuted,
              height: 1.4,
            ),
          ),
          AppSpacing.gapV16,
          const Divider(height: 1, color: AppColors.borderSubtle),
          AppSpacing.gapV16,

          // Notes Sub-section
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.customerNotesHeader,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            customer.notes != null && customer.notes!.trim().isNotEmpty
                ? customer.notes!
                : l10n.customerNotesEmpty,
            style: TextStyle(
              fontSize: 13,
              color: customer.notes != null && customer.notes!.trim().isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOverviewCard(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;
    final countsAsync = ref.watch(customerServiceCountsProvider(customer.id));

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
            children: [
              const Icon(
                Icons.dashboard_outlined,
                size: 20,
                color: AppColors.secondary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.customerOverviewHeader,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          countsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, stack) => _buildMetricsGrid(context, 0, 0, 0, 0),
            data: (counts) {
              final total = counts.totalServices;
              final pending = counts.pending;
              final completed = counts.completed;
              const reminders = 0;
              return _buildMetricsGrid(
                context,
                total,
                pending,
                completed,
                reminders,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    int total,
    int pending,
    int completed,
    int reminders,
  ) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CustomerMetricItem(
                label: l10n.customerOverviewTotalServices,
                value: '$total',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.primary,
              ),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: _CustomerMetricItem(
                label: l10n.customerOverviewPendingServices,
                value: '$pending',
                icon: Icons.hourglass_empty_rounded,
                iconColor: AppColors.warning,
              ),
            ),
          ],
        ),
        AppSpacing.gapV12,
        Row(
          children: [
            Expanded(
              child: _CustomerMetricItem(
                label: l10n.customerOverviewCompletedServices,
                value: '$completed',
                icon: Icons.check_circle_outlined,
                iconColor: AppColors.success,
              ),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: _CustomerMetricItem(
                label: l10n.customerOverviewReminders,
                value: '$reminders',
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceHistoryCard(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(customerServiceHistoryProvider(customer.id));

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
              Row(
                children: [
                  const Icon(
                    Icons.handyman_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    l10n.serviceHistoryTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/services/add?customerId=${customer.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.addServiceTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Could not load service history',
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
            data: (services) {
              if (services.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        const Text(
                          'No service records found for this customer yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        AppSpacing.gapV8,
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l10n.addServiceTitle),
                          onPressed: () => context.push(
                            '/services/add?customerId=${customer.id}',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length > 3 ? 3 : services.length,
                    separatorBuilder: (_, index) => AppSpacing.gapV8,
                    itemBuilder: (ctx, index) {
                      final item = services[index];
                      return ServiceCard(
                        service: item,
                        onTap: () => context.push('/services/${item.id}'),
                      );
                    },
                  ),
                  if (services.length > 3) ...[
                    AppSpacing.gapV8,
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/services/list'),
                        child: Text(
                          '${l10n.serviceViewAll} (${services.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;
    final plansAsync = ref.watch(customerMaintenancePlansProvider(customer.id));

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
              Row(
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 20,
                    color: AppColors.error,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    l10n.maintenancePlans,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/maintenance/add?customerId=${customer.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.maintenanceScheduleVisit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          plansAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Could not load maintenance plans',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No active maintenance plans for this customer.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return Column(
                children: plans
                    .map((p) => MaintenancePlanCard(plan: p))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmcSection(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;
    final amcAsync = ref.watch(customerAmcListProvider(customer.id));

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
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    l10n.amcContracts,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/amc/create?customerId=${customer.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.amcCreateContract,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          amcAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Could not load AMC contracts',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
            data: (contracts) {
              if (contracts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No AMC contracts registered for this customer.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return Column(
                children: contracts
                    .map((c) => AmcContractCard(contract: c))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupsSection(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final l10n = context.l10n;
    final remindersAsync = ref.watch(customerRemindersProvider(customer.id));

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
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    l10n.remindersOverviewTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  '/reminders/create?customerId=${customer.id}&category=customer_followup',
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.remindersCreateFollowupShortcut,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          remindersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Could not load reminders',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
            data: (reminders) {
              if (reminders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No follow-up reminders scheduled for this customer.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                );
              }

              return Column(
                children: reminders
                    .take(5)
                    .map(
                      (r) => ReminderCard(
                        reminder: r,
                        onTap: () => context.push('/reminders/${r.id}'),
                        onComplete: () async {
                          await ref
                              .read(reminderFormControllerProvider.notifier)
                              .completeReminder(r.id);
                        },
                        onSnooze: () async {
                          final tomorrow = DateTime.now().add(
                            const Duration(days: 1),
                          );
                          await ref
                              .read(reminderFormControllerProvider.notifier)
                              .snoozeReminder(r.id, tomorrow);
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard(
    BuildContext context,
    AsyncValue<List<CustomerActivityItem>> activityAsync,
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
            children: [
              const Icon(
                Icons.history_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.customerActivityHeader,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          activityAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Text(
              'Could not load activity: $err',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    l10n.customerActivityEmpty,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (ctx, i) =>
                    const Divider(height: 16, color: AppColors.borderSubtle),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  IconData icon;
                  Color iconColor;

                  switch (item.type) {
                    case CustomerActivityType.created:
                      icon = Icons.person_add_outlined;
                      iconColor = AppColors.success;
                      break;
                    case CustomerActivityType.updated:
                      icon = Icons.edit_note_rounded;
                      iconColor = AppColors.primary;
                      break;
                    case CustomerActivityType.call:
                      icon = Icons.call_outlined;
                      iconColor = AppColors.secondary;
                      break;
                    case CustomerActivityType.whatsapp:
                      icon = Icons.chat_bubble_outline;
                      iconColor = AppColors.whatsApp;
                      break;
                    case CustomerActivityType.archived:
                      icon = Icons.archive_outlined;
                      iconColor = AppColors.warning;
                      break;
                    case CustomerActivityType.restored:
                      icon = Icons.unarchive_outlined;
                      iconColor = AppColors.success;
                      break;
                    default:
                      icon = Icons.event_note_outlined;
                      iconColor = AppColors.primary;
                      break;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 16, color: iconColor),
                      ),
                      AppSpacing.gapH12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (item.subtitle != null) ...[
                              AppSpacing.gapV2,
                              Text(
                                item.subtitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppSpacing.gapH8,
                      Text(
                        DateFormatter.formatRelative(item.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
