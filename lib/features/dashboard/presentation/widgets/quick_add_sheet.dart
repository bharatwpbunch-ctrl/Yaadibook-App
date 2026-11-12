import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.gapV16,
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.quickAddSheetTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              AppSpacing.gapV8,
              const Divider(height: 1, color: AppColors.borderSubtle),
              AppSpacing.gapV8,
              // Action 1: Add Customer
              _QuickActionItem(
                icon: Icons.person_add_outlined,
                iconColor: AppColors.primary,
                title: l10n.quickAddCustomer,
                subtitle: l10n.quickAddCustomerDesc,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/customers/add');
                },
              ),
              // Action 2: Add Service
              _QuickActionItem(
                icon: Icons.build_circle_outlined,
                iconColor: AppColors.secondary,
                title: l10n.quickAddService,
                subtitle: l10n.quickAddServiceDesc,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/services/add');
                },
              ),
              // Action 3: Create Reminder
              _QuickActionItem(
                icon: Icons.notification_add_outlined,
                iconColor: AppColors.warningText,
                title: l10n.quickAddReminder,
                subtitle: l10n.quickAddReminderDesc,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/reminders/create');
                },
              ),
              // Action 4: Schedule Maintenance
              _QuickActionItem(
                icon: Icons.event_repeat_outlined,
                iconColor: AppColors.error,
                title: l10n.quickAddMaintenance,
                subtitle: l10n.quickAddMaintenanceDesc,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/maintenance/add');
                },
              ),
              // Action 5: Create AMC
              _QuickActionItem(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.primaryDark,
                title: l10n.quickAddAmc,
                subtitle: l10n.quickAddAmcDesc,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/amc/create');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
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
    );
  }
}
