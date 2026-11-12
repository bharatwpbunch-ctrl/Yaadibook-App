import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers/backend_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../providers/dashboard_providers.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final businessAsync = ref.watch(currentBusinessProvider);
    final now = DateTime.now();

    final profile = userProfileAsync.value;
    final business = businessAsync.value;

    final rawName = profile?.fullName.trim();
    final firstName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(' ').first
        : 'Owner';

    final period = getGreetingPeriod(now);
    final String greetingText;
    switch (period) {
      case GreetingPeriod.morning:
        greetingText = l10n.greetingMorning(firstName);
        break;
      case GreetingPeriod.afternoon:
        greetingText = l10n.greetingAfternoon(firstName);
        break;
      case GreetingPeriod.evening:
        greetingText = l10n.greetingEvening(firstName);
        break;
    }

    final dateText = DateFormatter.formatShort(
      now,
      locale: context.currentLocale.languageCode,
    );

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with settings shortcut
              InkWell(
                onTap: () => context.go('/more'),
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'Y',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH12,
              // Greeting & Business Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV2,
                    Text(
                      (business?.businessName != null &&
                              business!.businessName.isNotEmpty)
                          ? business.businessName
                          : l10n.appName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Notification Bell Icon with real unread badge
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount =
                      ref.watch(unreadNotificationCountProvider).value ?? 0;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text('$unreadCount'),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: AppColors.textPrimary,
                        size: 26,
                      ),
                    ),
                    tooltip: l10n.notificationsTitle,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => context.push('/notifications'),
                  );
                },
              ),
            ],
          ),
          AppSpacing.gapV12,
          const Divider(height: 1, color: AppColors.borderSubtle),
          AppSpacing.gapV8,
          Row(
            children: [
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              AppSpacing.gapH8,
              const Text('•', style: TextStyle(color: AppColors.textMuted)),
              AppSpacing.gapH8,
              Expanded(
                child: Text(
                  l10n.dashboardAttentionSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
