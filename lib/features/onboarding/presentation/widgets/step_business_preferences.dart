import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/localization/locale_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/yb_dropdown.dart';
import '../../providers/onboarding_controller.dart';

/// Step C: Business Preferences (Language, Date Format, Time Format, Timezone).
class StepBusinessPreferences extends ConsumerWidget {
  const StepBusinessPreferences({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formState = ref.watch(onboardingControllerProvider);
    final activeLocale = ref.watch(localeProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Subtitle
        Text(
          l10n.onboardingStep3Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        AppSpacing.gapV24,

        // Language Choice Label
        Text(
          l10n.onboardingAppLanguage,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapV8,

        // Segmented Language Options Cards
        Row(
          children: [
            _buildLanguageCard(
              context: context,
              label: 'English',
              code: 'en',
              isSelected: activeLocale.languageCode == 'en',
              onTap: () {
                ref.read(localeProvider.notifier).setByLanguageCode('en');
                notifier.updatePreferences(preferredLanguage: 'en');
              },
            ),
            AppSpacing.gapH8,
            _buildLanguageCard(
              context: context,
              label: 'ગુજરાતી',
              code: 'gu',
              isSelected: activeLocale.languageCode == 'gu',
              onTap: () {
                ref.read(localeProvider.notifier).setByLanguageCode('gu');
                notifier.updatePreferences(preferredLanguage: 'gu');
              },
            ),
            AppSpacing.gapH8,
            _buildLanguageCard(
              context: context,
              label: 'हिन्दी',
              code: 'hi',
              isSelected: activeLocale.languageCode == 'hi',
              onTap: () {
                ref.read(localeProvider.notifier).setByLanguageCode('hi');
                notifier.updatePreferences(preferredLanguage: 'hi');
              },
            ),
          ],
        ),
        AppSpacing.gapV20,

        // Date Format
        YbDropdown<String>(
          label: l10n.onboardingDateFormat,
          value: formState.dateFormat,
          items: const [
            DropdownMenuItem(
              value: 'DD/MM/YYYY',
              child: Text('DD/MM/YYYY (e.g. 04/11/2026)'),
            ),
            DropdownMenuItem(value: 'MM/DD/YYYY', child: Text('MM/DD/YYYY')),
            DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD')),
          ],
          onChanged: (val) {
            if (val != null) notifier.updatePreferences(dateFormat: val);
          },
        ),
        AppSpacing.gapV16,

        // Time Format
        YbDropdown<String>(
          label: l10n.onboardingTimeFormat,
          value: formState.timeFormat,
          items: const [
            DropdownMenuItem(
              value: '12-hour',
              child: Text('12-hour (e.g. 02:30 PM)'),
            ),
            DropdownMenuItem(
              value: '24-hour',
              child: Text('24-hour (e.g. 14:30)'),
            ),
          ],
          onChanged: (val) {
            if (val != null) notifier.updatePreferences(timeFormat: val);
          },
        ),
        AppSpacing.gapV16,

        // Timezone
        YbDropdown<String>(
          label: l10n.onboardingTimezone,
          value: formState.timezone,
          items: const [
            DropdownMenuItem(
              value: 'Asia/Kolkata',
              child: Text('Asia/Kolkata (IST - UTC+5:30)'),
            ),
          ],
          onChanged: (val) {
            if (val != null) notifier.updatePreferences(timezone: val);
          },
        ),
        AppSpacing.gapV24,
      ],
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapV4,
              Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
