import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/communication_service.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/providers/backend_providers.dart';

class CustomerListCard extends ConsumerWidget {
  final Customer customer;

  const CustomerListCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final business = ref.watch(currentBusinessProvider).value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: customer.isArchived
                  ? AppColors.textMuted.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with initials
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: customer.isArchived
                        ? AppColors.surfaceVariant
                        : AppColors.primaryContainer,
                    child: Text(
                      customer.initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: customer.isArchived
                            ? AppColors.textMuted
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  AppSpacing.gapH12,
                  // Customer details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                customer.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: customer.isArchived
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (customer.isBusiness) ...[
                              AppSpacing.gapH6,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.customerCardTagBusiness,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                            if (customer.isArchived) ...[
                              AppSpacing.gapH6,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.customersFilterArchived,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.gapV4,
                        Text(
                          customer.primaryPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (customer.locationSummary.isNotEmpty) ...[
                          AppSpacing.gapV2,
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              AppSpacing.gapH4,
                              Expanded(
                                child: Text(
                                  customer.locationSummary,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
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
              AppSpacing.gapV12,
              const Divider(height: 1, color: AppColors.borderSubtle),
              AppSpacing.gapV8,
              // Communication Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Call button
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (business != null) {
                        ref
                            .read(customerRepositoryProvider)
                            .logCommunication(
                              businessId: business.id,
                              customerId: customer.id,
                              channel: 'call',
                              status: 'initiated',
                            );
                      }
                      final ok = await CommunicationService.makePhoneCall(
                        customer.primaryPhone,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.commDialerError)),
                        );
                      }
                    },
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: Text(l10n.customerActionCall),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                  AppSpacing.gapH8,
                  // WhatsApp button
                  FilledButton.icon(
                    onPressed: () async {
                      final greeting = l10n.commWhatsAppGreeting(
                        customer.fullName,
                        business?.businessName ?? 'Yaadibook',
                      );
                      if (business != null) {
                        ref
                            .read(customerRepositoryProvider)
                            .logCommunication(
                              businessId: business.id,
                              customerId: customer.id,
                              channel: 'whatsapp',
                              messageContent: greeting,
                              status: 'opened',
                            );
                      }
                      final ok = await CommunicationService.openWhatsApp(
                        phoneNumber: customer.primaryPhone,
                        message: greeting,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.commWhatsAppError)),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: Text(l10n.customerActionWhatsApp),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.whatsApp,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
