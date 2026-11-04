import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_config.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);
    final config = AppConfig.current;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Business Profile Header Card
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  child: const Icon(
                    Icons.store_mall_directory_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                AppSpacing.gapH16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maruti AC & CCTV Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapV4,
                      Text(
                        '+91 98250 12345 • Ahmedabad',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapV24,

          // Language Section
          YbSectionHeader(
            title: l10n.language,
            subtitle: l10n.settingsLanguageSubtitle,
          ),
          AppSpacing.gapV8,
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildLanguageTile(
                  title: l10n.languageEnglish,
                  subtitle: 'English',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(AppLocales.english);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                _buildLanguageTile(
                  title: l10n.languageGujarati,
                  subtitle: 'Gujarati',
                  isSelected: currentLocale.languageCode == 'gu',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(AppLocales.gujarati);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                _buildLanguageTile(
                  title: l10n.languageHindi,
                  subtitle: 'Hindi',
                  isSelected: currentLocale.languageCode == 'hi',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(AppLocales.hindi);
                  },
                ),
              ],
            ),
          ),
          AppSpacing.gapV24,

          // App Information Section
          YbSectionHeader(title: l10n.settingsAbout),
          AppSpacing.gapV8,
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildInfoRow(l10n.appName, 'Yaadibook Mobile'),
                AppSpacing.gapV12,
                _buildInfoRow(
                  l10n.settingsVersion,
                  '0.1.0 (Phase 1 Foundation)',
                ),
                AppSpacing.gapV12,
                _buildInfoRow(
                  'Environment',
                  config.environment.name.toUpperCase(),
                ),
                AppSpacing.gapV12,
                _buildInfoRow('Backend Target', 'Supabase PostgreSQL'),
              ],
            ),
          ),
          AppSpacing.gapV24,
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.circle_outlined, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
