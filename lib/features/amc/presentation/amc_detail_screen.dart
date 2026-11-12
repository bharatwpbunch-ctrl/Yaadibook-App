import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../shared/models/amc_contract.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';
import '../providers/amc_providers.dart';

/// Screen displaying the full details of an Annual Maintenance Contract.
class AmcDetailScreen extends ConsumerWidget {
  final String contractId;

  const AmcDetailScreen({super.key, required this.contractId});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _cancelContract(
    BuildContext context,
    WidgetRef ref,
    AmcContract contract,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.amcCancelConfirmTitle),
        content: Text(l10n.amcCancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.amcActionCancel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(amcRepositoryProvider);
        await repo.cancelAmcContract(contract.id);
        ref.invalidate(amcContractDetailProvider(contract.id));
        ref.invalidate(amcContractsListProvider);
        ref.invalidate(amcOverviewCountsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AMC contract cancelled'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final contractAsync = ref.watch(amcContractDetailProvider(contractId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.amcContractDetails,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          contractAsync.whenOrNull(
                data: (contract) => contract != null
                    ? IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        tooltip: l10n.amcEditContract,
                        onPressed: () =>
                            context.push('/amc/${contract.id}/edit'),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: contractAsync.when(
        loading: () => const Center(child: YbLoadingState()),
        error: (err, _) => YbErrorState(
          title: 'Failed to load AMC contract',
          message: err.toString(),
          onRetry: () => ref.invalidate(amcContractDetailProvider(contractId)),
        ),
        data: (contract) {
          if (contract == null) {
            return const Center(child: Text('AMC contract not found'));
          }

          final customer = contract.customer;
          final equipment = contract.equipment;
          final effective = contract.effectiveStatus;
          final canRenew =
              effective == 'active' ||
              effective == 'expiring' ||
              effective == 'expired';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // 1. Contract Overview Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contract.contractNumber != null &&
                                  contract.contractNumber!.isNotEmpty
                              ? contract.contractNumber!
                              : 'AMC CONTRACT',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: effective == 'active'
                                ? AppColors.successBg
                                : effective == 'expiring'
                                ? AppColors.warningBg
                                : effective == 'expired'
                                ? AppColors.errorBg
                                : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            effective.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: effective == 'active'
                                  ? AppColors.success
                                  : effective == 'expiring'
                                  ? AppColors.warning
                                  : effective == 'expired'
                                  ? AppColors.error
                                  : AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      contract.contractTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contract.expiryText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: effective == 'expiring'
                            ? AppColors.warning
                            : effective == 'expired'
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contract Value',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatINR(
                                contract.contractAmount,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (contract.numberOfVisits != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Visits Included',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                "${contract.numberOfVisits} Visits",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Customer Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        customer?.fullName.isNotEmpty == true
                            ? customer!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer?.fullName ?? 'Unknown Customer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (customer?.phone != null &&
                              customer!.phone.isNotEmpty)
                            Text(
                              customer.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (customer != null && customer.phone.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.phone_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _makeCall(customer.phone),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.success,
                        ),
                        tooltip: '1-Click WhatsApp Reminder',
                        onPressed: () => ref
                            .read(
                              communicationComposerControllerProvider.notifier,
                            )
                            .sendOneClickReminder(
                              category: 'amc_renewal',
                              recipientPhone: customer.phone,
                              recipientName: customer.fullName,
                              customerId: customer.id,
                              amcContractId: contract.id,
                              amcEndDate: DateFormatter.formatDate(
                                contract.endDate,
                              ),
                              title: contract.contractTitle,
                              amount: contract.contractAmount.toStringAsFixed(
                                0,
                              ),
                            ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.secondary,
                        ),
                        tooltip: 'Send Renewal Notice (Templates / SMS)',
                        onPressed: () => CommunicationComposerSheet.show(
                          context,
                          customer: customer,
                          phone: customer.phone,
                          name: customer.fullName,
                          amcContractId: contract.id,
                          amcEndDate: DateFormatter.formatDate(
                            contract.endDate,
                          ),
                          serviceTitle: contract.contractTitle,
                          amount: contract.contractAmount.toStringAsFixed(0),
                          preferredCategory: 'amc_renewal',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Equipment (if linked)
              if (equipment != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.precision_manufacturing_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "${equipment.brand ?? ''} ${equipment.modelNumber ?? ''}"
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 4. Validity Details
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Validity Period',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'Start Date',
                      value: DateFormatter.formatDate(contract.startDate),
                    ),
                    _DetailRow(
                      label: 'End Date',
                      value: DateFormatter.formatDate(contract.endDate),
                    ),
                    if (contract.includedServices != null &&
                        contract.includedServices!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Included Services:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(contract.includedServices!),
                    ],
                    if (contract.excludedServices != null &&
                        contract.excludedServices!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Excluded Services:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(contract.excludedServices!),
                    ],
                    if (contract.specialTerms != null &&
                        contract.specialTerms!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Terms & Warranty:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(contract.specialTerms!),
                    ],
                    if (contract.notes != null &&
                        contract.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Internal Notes:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(contract.notes!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Actions: Renew and Cancel
              if (canRenew) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: Text(
                    l10n.amcActionRenew,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => context.push('/amc/${contract.id}/renew'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (contract.status != 'cancelled')
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  label: Text(
                    l10n.amcActionCancel,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onPressed: () => _cancelContract(context, ref, contract),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
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
}
