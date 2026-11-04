import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';

enum YbStatusType { active, pending, completed, cancelled, overdue, info }

/// Compact status indicator badge.
class YbStatusBadge extends StatelessWidget {
  final String label;
  final YbStatusType statusType;
  final bool showDot;

  const YbStatusBadge({
    super.key,
    required this.label,
    this.statusType = YbStatusType.pending,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, text, dot) = switch (statusType) {
      YbStatusType.active => (
        AppColors.successBg,
        AppColors.successText,
        AppColors.success,
      ),
      YbStatusType.completed => (
        AppColors.successBg,
        AppColors.successText,
        AppColors.success,
      ),
      YbStatusType.pending => (
        AppColors.warningBg,
        AppColors.warningText,
        AppColors.warning,
      ),
      YbStatusType.overdue => (
        AppColors.errorBg,
        AppColors.errorText,
        AppColors.error,
      ),
      YbStatusType.cancelled => (
        AppColors.surfaceVariant,
        AppColors.textSecondary,
        AppColors.textMuted,
      ),
      YbStatusType.info => (
        AppColors.infoBg,
        AppColors.infoText,
        AppColors.info,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.borderPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            AppSpacing.gapH4,
          ],
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
