import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_config.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../auth/providers/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);
    final config = AppConfig.current;
    final businessAsync = ref.watch(currentBusinessProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    final biz = businessAsync.value;
    final profile = profileAsync.value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Business Profile Header Card
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    biz?.businessName.isNotEmpty == true
                        ? biz!.businessName[0].toUpperCase()
                        : 'Y',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        biz?.businessName ?? 'Yaadibook Business',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapV2,
                      Text(
                        profile?.fullName != null
                            ? 'Owner: ${profile!.fullName}'
                            : (biz?.businessCategory ?? 'Service Business'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (biz?.phone != null) ...[
                        AppSpacing.gapV2,
                        Text(
                          '${biz!.phone} • ${biz.city}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapV24,

          // Category A: Business Management
          YbSectionHeader(title: l10n.moreCategoryBusiness),
          AppSpacing.gapV8,
          _buildSettingsGroup([
            _SettingsTile(
              icon: Icons.storefront_outlined,
              title: l10n.moreBusinessProfile,
              subtitle: biz?.businessName ?? 'Edit business name & contact',
              onTap: () => context.push('/settings/business-profile'),
            ),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              title: l10n.moreAddressDetails,
              subtitle: biz != null
                  ? '${biz.city}, ${biz.state}'
                  : 'Update business address & phone',
              onTap: () =>
                  context.push('/settings/business-profile?section=address'),
            ),
            _SettingsTile(
              icon: Icons.access_time_outlined,
              title: l10n.moreOperatingHours,
              subtitle: 'Weekly shop hours & working days',
              onTap: () => context.push('/settings/operating-hours'),
            ),
          ]),
          AppSpacing.gapV24,

          // Category B: Customer Communication
          YbSectionHeader(title: l10n.moreCategoryCommunication),
          AppSpacing.gapV8,
          _buildSettingsGroup([
            _SettingsTile(
              icon: Icons.chat_outlined,
              title: l10n.moreWhatsappTemplates,
              subtitle: 'Message templates, history & communications',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.push('/communications'),
            ),
            _SettingsTile(
              icon: Icons.campaign_outlined,
              title: 'Bulk Messaging Campaigns',
              subtitle: 'Targeted broadcast campaigns & reports',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.push('/communications/campaigns'),
            ),
          ]),
          AppSpacing.gapV24,

          // Category C: Business Tools
          YbSectionHeader(title: l10n.moreCategoryTools),
          AppSpacing.gapV8,
          _buildSettingsGroup([
            _SettingsTile(
              icon: Icons.miscellaneous_services_outlined,
              title: l10n.servicesOverviewTitle,
              subtitle: 'Manage installations, repairs & work records',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.push('/services'),
            ),
            _SettingsTile(
              icon: Icons.build_circle_outlined,
              title: l10n.maintenanceOverview,
              subtitle: 'Manage recurring schedules & visits',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.push('/maintenance'),
            ),
            _SettingsTile(
              icon: Icons.assignment_outlined,
              title: l10n.amcOverview,
              subtitle: 'Manage AMC contracts & renewals',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.push('/amc'),
            ),
            _SettingsTile(
              icon: Icons.category_outlined,
              title: l10n.moreServiceCategories,
              subtitle: 'Manage installation, repair & AMC categories',
              onTap: () => context.push('/settings/service-categories'),
            ),
          ]),
          AppSpacing.gapV24,

          // Category D: App Settings
          YbSectionHeader(title: l10n.moreCategorySettings),
          AppSpacing.gapV8,
          _buildSettingsGroup([
            // Language Selection Tile
            _SettingsTile(
              icon: Icons.language_outlined,
              title: l10n.language,
              subtitle: _getCurrentLanguageLabel(currentLocale.languageCode),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => _showLanguageDialog(context, ref, currentLocale),
            ),
            // Theme Mode Tile
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: l10n.moreThemeMode,
              subtitle: l10n.moreThemeLight,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Light theme is enabled for clear daytime readability.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            // Notification Preferences Tile
            _SettingsTile(
              icon: Icons.notifications_none_outlined,
              title: l10n.moreNotifications,
              subtitle: 'Push alerts, quiet hours & reminder times',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.push('/settings/notifications'),
            ),
            // Business Reports Tile
            _SettingsTile(
              icon: Icons.bar_chart_outlined,
              title: l10n.moreReportsTitle,
              onTap: () => context.push('/reports'),
            ),
            // Subscription & Plan Tile
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: l10n.moreSubscriptionTitle,
              onTap: () => context.push('/settings/subscription'),
            ),
            // Offline Sync & Storage Tile
            _SettingsTile(
              icon: Icons.storage_outlined,
              title: l10n.moreOfflineSyncTitle,
              onTap: () => context.push('/settings/offline-sync'),
            ),
            // Privacy & Terms Tile
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: l10n.moreLegalTitle,
              onTap: () => context.push('/settings/legal'),
            ),
            // Delete Account & Data Tile
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: l10n.moreDeleteAccountTitle,
              onTap: () => context.push('/settings/delete-account'),
            ),
          ]),
          AppSpacing.gapV24,

          // About Section
          YbSectionHeader(title: l10n.settingsAbout),
          AppSpacing.gapV8,
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildInfoRow(l10n.appName, 'Yaadibook Mobile'),
                AppSpacing.gapV12,
                _buildInfoRow(l10n.settingsVersion, '1.0.0'),
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

          // Log Out Button
          YbSecondaryButton(
            label: l10n.authLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            textColor: AppColors.error,
            borderColor: AppColors.error.withValues(alpha: 0.5),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.moreLogoutConfirmTitle),
                  content: Text(l10n.moreLogoutConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.actionCancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.authLogout),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
          AppSpacing.gapV32,
        ],
      ),
    );
  }

  static Widget _buildSettingsGroup(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              const Divider(height: 1, color: AppColors.borderSubtle),
          ],
        ],
      ),
    );
  }

  static String _getCurrentLanguageLabel(String code) {
    switch (code) {
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          _buildLanguageDialogOption(
            title: l10n.languageEnglish,
            isSelected: currentLocale.languageCode == 'en',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(AppLocales.english);
              Navigator.pop(ctx);
            },
          ),
          _buildLanguageDialogOption(
            title: l10n.languageGujarati,
            isSelected: currentLocale.languageCode == 'gu',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(AppLocales.gujarati);
              Navigator.pop(ctx);
            },
          ),
          _buildLanguageDialogOption(
            title: l10n.languageHindi,
            isSelected: currentLocale.languageCode == 'hi',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(AppLocales.hindi);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildLanguageDialogOption({
    required String title,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
