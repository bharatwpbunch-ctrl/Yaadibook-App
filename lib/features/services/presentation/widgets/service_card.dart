import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/service_entry.dart';

/// Reusable mobile-first card representing a service entry.
class ServiceCard extends StatelessWidget {
  final ServiceEntry service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  Color _getStatusColor() {
    switch (service.status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.info;
      case 'cancelled':
        return AppColors.textMuted;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  Color _getStatusBg() {
    switch (service.status.toLowerCase()) {
      case 'completed':
        return AppColors.successBg;
      case 'in_progress':
        return AppColors.infoBg;
      case 'cancelled':
        return AppColors.surfaceVariant;
      case 'pending':
      default:
        return AppColors.warningBg;
    }
  }

  String _getStatusLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (service.status.toLowerCase()) {
      case 'completed':
        return l10n.serviceStatusCompleted;
      case 'in_progress':
        return l10n.serviceStatusInProgress;
      case 'cancelled':
        return l10n.serviceStatusCancelled;
      case 'pending':
      default:
        return l10n.serviceStatusPending;
    }
  }

  String _getServiceTypeLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (service.serviceType.toLowerCase()) {
      case 'installation':
        return l10n.serviceTypeInstallation;
      case 'repair':
        return l10n.serviceTypeRepair;
      case 'maintenance':
        return l10n.serviceTypeMaintenance;
      case 'inspection':
        return l10n.serviceTypeInspection;
      case 'general':
        return l10n.serviceTypeGeneral;
      default:
        return l10n.serviceTypeOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusBg = _getStatusBg();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push('/services/${service.id}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Service Number / Type & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (service.serviceNumber.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            service.serviceNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        AppSpacing.gapH8,
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          _getServiceTypeLabel(context),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppSpacing.gapH6,
                        Text(
                          _getStatusLabel(context),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapV8,

              // Service Title
              Text(
                service.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.gapV4,

              // Customer Name & Location
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapH6,
                  Expanded(
                    child: Text(
                      service.customer?.fullName ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Description if available
              if (service.description != null &&
                  service.description!.trim().isNotEmpty) ...[
                AppSpacing.gapV4,
                Text(
                  service.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              AppSpacing.gapV12,

              const Divider(height: 1, color: AppColors.borderSubtle),
              AppSpacing.gapV8,

              // Bottom Row: Date & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      AppSpacing.gapH6,
                      Text(
                        DateFormatter.formatShort(service.serviceDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (service.computedTotal > 0 ||
                      service.serviceAmount != null)
                    Text(
                      CurrencyFormatter.format(service.computedTotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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
