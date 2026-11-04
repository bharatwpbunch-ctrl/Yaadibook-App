import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/widgets.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            l10n.remindersSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV16,

          // Overdue section
          YbSectionHeader(
            title: l10n.statusOverdue,
            subtitle: 'Immediate follow-up required',
          ),
          AppSpacing.gapV8,
          YbReminderCard(
            title: 'Quarterly RO Filter Replacement Due',
            customerName: 'Shreeji Restaurant',
            dueDateText: DateFormatter.formatShort(
              now.subtract(const Duration(days: 2)),
            ),
            isOverdue: true,
            typeBadge: 'RO Purifier',
            onTap: () {},
            onComplete: () {},
          ),
          AppSpacing.gapV16,

          // Upcoming section
          YbSectionHeader(title: 'Upcoming This Week'),
          AppSpacing.gapV8,
          YbReminderCard(
            title: l10n.sampleReminderNote,
            customerName: l10n.sampleCustomerName,
            dueDateText: DateFormatter.formatShort(
              now.add(const Duration(days: 3)),
            ),
            isOverdue: false,
            typeBadge: 'AMC Service',
            onTap: () {},
            onComplete: () {},
          ),
          AppSpacing.gapV12,
          YbReminderCard(
            title: 'Annual Security AMC Contract Renewal',
            customerName: 'Kailash Electronics',
            dueDateText: DateFormatter.formatShort(
              now.add(const Duration(days: 5)),
            ),
            isOverdue: false,
            typeBadge: 'Renewal',
            onTap: () {},
            onComplete: () {},
          ),
          AppSpacing.gapV24,
        ],
      ),
    );
  }
}
