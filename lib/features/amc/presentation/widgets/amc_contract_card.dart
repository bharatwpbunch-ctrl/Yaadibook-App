import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/amc_contract.dart';
import '../../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../../communications/providers/communication_providers.dart';

/// Card component presenting an Annual Maintenance Contract with validity, customer, and renewal status.
class AmcContractCard extends ConsumerWidget {
  final AmcContract contract;
  final VoidCallback? onTap;
  final VoidCallback? onRenew;

  const AmcContractCard({
    super.key,
    required this.contract,
    this.onTap,
    this.onRenew,
  });

  Color _getStatusColor() {
    final effective = contract.effectiveStatus;
    switch (effective) {
      case 'active':
        return AppColors.success;
      case 'expiring':
        return AppColors.warning;
      case 'expired':
        return AppColors.error;
      case 'renewed':
        return AppColors.info;
      case 'cancelled':
      default:
        return AppColors.textMuted;
    }
  }

  Color _getStatusBg() {
    final effective = contract.effectiveStatus;
    switch (effective) {
      case 'active':
        return AppColors.successBg;
      case 'expiring':
        return AppColors.warningBg;
      case 'expired':
        return AppColors.errorBg;
      case 'renewed':
        return AppColors.infoBg;
      case 'cancelled':
      default:
        return AppColors.surfaceVariant;
    }
  }

  String _getStatusLabel(BuildContext context) {
    final effective = contract.effectiveStatus;
    switch (effective) {
      case 'active':
        return 'ACTIVE';
      case 'expiring':
        return 'EXPIRING SOON';
      case 'expired':
        return 'EXPIRED';
      case 'renewed':
        return 'RENEWED';
      case 'cancelled':
      default:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = contract.customer;
    final equipment = contract.equipment;
    final effective = contract.effectiveStatus;
    final canRenew =
        effective == 'active' ||
        effective == 'expiring' ||
        effective == 'expired';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: effective == 'expiring'
              ? AppColors.warning.withValues(alpha: 0.5)
              : effective == 'expired'
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
          width: effective == 'expiring' || effective == 'expired' ? 1.5 : 1,
        ),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap ?? () => context.push('/amc/${contract.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Contract # and Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                        ),
                        child: Text(
                          contract.contractNumber != null &&
                                  contract.contractNumber!.isNotEmpty
                              ? contract.contractNumber!
                              : 'AMC',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        contract.expiryText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBg(),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      _getStatusLabel(context),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Title
              Text(
                contract.contractTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Customer
              Text(
                customer?.fullName ?? 'Unknown Customer',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (equipment != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.precision_manufacturing_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.xs),

              // Dates & Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${DateFormatter.formatDate(contract.startDate)} → ${DateFormatter.formatDate(contract.endDate)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (contract.numberOfVisits != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${contract.numberOfVisits} visits included",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatINR(contract.contractAmount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Quick 1-click reminder & renew actions
              if ((canRenew && customer != null && customer.phone.isNotEmpty) ||
                  ((effective == 'expiring' || effective == 'expired') &&
                      canRenew)) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (customer != null && customer.phone.isNotEmpty) ...[
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.chat_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        label: const Text(
                          '1-Click Remind',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.success.withValues(alpha: 0.4),
                          ),
                          backgroundColor: AppColors.successBg,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () async {
                          final ok = await ref
                              .read(
                                communicationComposerControllerProvider
                                    .notifier,
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
                              );
                          if (!context.mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open WhatsApp for this number.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.sms_outlined,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        tooltip: 'Choose Template / SMS',
                        visualDensity: VisualDensity.compact,
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
                    if (effective == 'expiring' || effective == 'expired')
                      FilledButton.icon(
                        icon: const Icon(Icons.autorenew_rounded, size: 16),
                        label: Text(
                          context.l10n.amcActionRenew,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed:
                            onRenew ??
                            () => context.push('/amc/${contract.id}/renew'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
