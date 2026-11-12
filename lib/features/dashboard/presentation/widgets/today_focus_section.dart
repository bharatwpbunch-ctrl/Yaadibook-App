import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/communication_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../models/today_focus_item.dart';

class TodayFocusSection extends StatelessWidget {
  final List<TodayFocusItem> items;
  final bool isLoading;

  const TodayFocusSection({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.todayFocusTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.gapV12,
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: YbLoadingState(),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                AppSpacing.gapV12,
                Text(
                  l10n.todayFocusEmptyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapV4,
                Text(
                  l10n.todayFocusEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => AppSpacing.gapV8,
            itemBuilder: (context, index) {
              final item = items[index];
              return _FocusItemCard(item: item);
            },
          ),
      ],
    );
  }
}

class _FocusItemCard extends StatelessWidget {
  final TodayFocusItem item;

  const _FocusItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (item.source) {
      case TodayFocusSource.maintenance:
        badgeBg = AppColors.warningBg;
        badgeText = AppColors.warningText;
        badgeLabel = l10n.sourceMaintenance;
        break;
      case TodayFocusSource.amc:
        badgeBg = AppColors.secondaryContainer;
        badgeText = AppColors.secondary;
        badgeLabel = l10n.sourceAmc;
        break;
      case TodayFocusSource.service:
        badgeBg = AppColors.primaryContainer;
        badgeText = AppColors.primaryDark;
        badgeLabel = l10n.sourceService;
        break;
      case TodayFocusSource.followup:
        badgeBg = AppColors.surfaceVariant;
        badgeText = AppColors.textSecondary;
        badgeLabel = l10n.sourceFollowup;
        break;
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(item.targetRoute),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isOverdue
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.dueOverdue,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      else
                        Text(
                          DateFormatter.formatShort(item.dueDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      AppSpacing.gapH4,
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.gapV8,
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (item.customerName != null ||
                  (item.customerPhone != null &&
                      item.customerPhone!.isNotEmpty)) ...[
                AppSpacing.gapV8,
                Row(
                  children: [
                    if (item.customerName != null) ...[
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      AppSpacing.gapH4,
                      Expanded(
                        child: Text(
                          item.customerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (item.amount != null && item.amount! > 0) ...[
                      AppSpacing.gapH8,
                      Text(
                        CurrencyFormatter.format(item.amount!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (item.customerPhone != null &&
                        item.customerPhone!.isNotEmpty) ...[
                      AppSpacing.gapH8,
                      IconButton(
                        icon: const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Call Customer',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => CommunicationService.makePhoneCall(
                          item.customerPhone!,
                        ),
                      ),
                      AppSpacing.gapH4,
                      IconButton(
                        icon: const Icon(
                          Icons.chat_outlined,
                          size: 18,
                          color: AppColors.success,
                        ),
                        tooltip: 'Send Reminder Message',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => CommunicationComposerSheet.show(
                          context,
                          phone: item.customerPhone,
                          name: item.customerName,
                          serviceId: item.serviceId,
                          serviceTitle: item.title,
                          maintenanceOccurrenceId: item.maintenanceOccurrenceId,
                          maintenanceDate: DateFormatter.formatShort(
                            item.dueDate,
                          ),
                          amcContractId: item.amcContractId,
                          amcEndDate: DateFormatter.formatShort(item.dueDate),
                          amount: item.amount != null && item.amount! > 0
                              ? item.amount!.toStringAsFixed(0)
                              : null,
                          preferredCategory: item.templateCategory,
                        ),
                      ),
                    ],
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
