import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../utils/currency_formatter.dart';
import 'yb_status_badge.dart';

/// Service record summary card.
class YbServiceCard extends StatelessWidget {
  final String serviceTitle;
  final String customerName;
  final String dateText;
  final num? amount;
  final String statusLabel;
  final YbStatusType statusType;
  final VoidCallback? onTap;

  const YbServiceCard({
    super.key,
    required this.serviceTitle,
    required this.customerName,
    required this.dateText,
    this.amount,
    required this.statusLabel,
    this.statusType = YbStatusType.completed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderMd,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapV4,
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH8,
                YbStatusBadge(label: statusLabel, statusType: statusType),
              ],
            ),
            AppSpacing.gapV12,
            const Divider(height: 1, color: AppColors.borderSubtle),
            AppSpacing.gapV12,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (amount != null)
                  Text(
                    CurrencyFormatter.format(amount!),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
