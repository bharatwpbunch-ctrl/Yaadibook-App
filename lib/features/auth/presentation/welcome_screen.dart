import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_secondary_button.dart';

/// Friendly welcome & introduction screen with instant language switcher.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activeLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenHorizontalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.gapV16,
              // Language Selector Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeLocale.languageCode,
                        icon: const Icon(
                          Icons.language_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી')),
                          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                        ],
                        onChanged: (code) {
                          if (code != null) {
                            ref
                                .read(localeProvider.notifier)
                                .setByLanguageCode(code);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Hero Brand Illustration / Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.handshake_rounded,
                          size: 38,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapV32,
              // Welcome Heading
              Text(
                l10n.welcomeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              AppSpacing.gapV12,
              // Description
              Text(
                l10n.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              // Primary CTA: Get Started (Register)
              YbPrimaryButton(
                label: l10n.welcomeGetStarted,
                onPressed: () => context.push('/register'),
              ),
              AppSpacing.gapV12,
              // Secondary CTA: Login
              YbSecondaryButton(
                label: l10n.welcomeAlreadyHaveAccount,
                onPressed: () => context.push('/login'),
              ),
              AppSpacing.gapV24,
            ],
          ),
        ),
      ),
    );
  }
}
