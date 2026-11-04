import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import 'yb_status_badge.dart';

/// Reminder & follow-up card.
class YbReminderCard extends StatelessWidget {
  final String title;
  final String customerName;
  final String dueDateText;
  final bool isOverdue;
  final String? typeBadge;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const YbReminderCard({
    super.key,
    required this.title,
    required this.customerName,
    required this.dueDateText,
    this.isOverdue = false,
    this.typeBadge,
    this.onTap,
    this.onComplete,
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
          border: Border.all(
            color: isOverdue
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (typeBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: AppRadii.borderXs,
                    ),
                    child: Text(
                      typeBadge!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  AppSpacing.gapH8,
                ],
                const Spacer(),
                YbStatusBadge(
                  label: isOverdue ? 'Overdue' : 'Due Soon',
                  statusType: isOverdue
                      ? YbStatusType.overdue
                      : YbStatusType.pending,
                ),
              ],
            ),
            AppSpacing.gapV8,
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
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
            AppSpacing.gapV12,
            const Divider(height: 1, color: AppColors.borderSubtle),
            AppSpacing.gapV8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 15,
                      color: isOverdue ? AppColors.error : AppColors.textMuted,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      dueDateText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (onComplete != null)
                  TextButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: const Size(0, 32),
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
