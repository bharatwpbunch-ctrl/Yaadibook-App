import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_secondary_button.dart';
import '../providers/onboarding_controller.dart';
import 'widgets/onboarding_step_indicator.dart';
import 'widgets/step_business_address.dart';
import 'widgets/step_business_info.dart';
import 'widgets/step_business_preferences.dart';

/// Single-business onboarding wizard for small-business owners.
class BusinessOnboardingScreen extends ConsumerWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formState = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    // Watch for completion to navigate to dashboard
    ref.listen<OnboardingFormState>(onboardingControllerProvider, (prev, next) {
      if (next.isCompleted && !(prev?.isCompleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onboardingSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/today');
      }
    });

    final currentStep = formState.currentStep;

    String getStepTitle() {
      switch (currentStep) {
        case 0:
          return l10n.onboardingStep1Title;
        case 1:
          return l10n.onboardingStep2Title;
        case 2:
          return l10n.onboardingStep3Title;
        default:
          return l10n.onboardingTitle;
      }
    }

    Widget getStepWidget() {
      switch (currentStep) {
        case 0:
          return const StepBusinessInfo();
        case 1:
          return const StepBusinessAddress();
        case 2:
          return const StepBusinessPreferences();
        default:
          return const StepBusinessInfo();
      }
    }

    void handleNext() {
      if (currentStep == 0) {
        if (notifier.validateStep0()) {
          notifier.setStep(1);
        }
      } else if (currentStep == 1) {
        if (notifier.validateStep1()) {
          notifier.setStep(2);
        }
      } else if (currentStep == 2) {
        notifier.completeOnboarding();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.onboardingTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar & Step Tracker
            Padding(
              padding: AppSpacing.screenHorizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.gapV8,
                  OnboardingStepIndicator(currentStep: currentStep),
                  AppSpacing.gapV12,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getStepTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        l10n.onboardingStep(currentStep + 1, 3),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapV12,
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error Banner
                    if (formState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            AppSpacing.gapH8,
                            Expanded(
                              child: Text(
                                formState.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapV16,
                    ],

                    // Current Step Content
                    getStepWidget(),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: AppSpacing.screenPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: YbSecondaryButton(
                        label: l10n.actionBack,
                        onPressed: formState.isLoading
                            ? null
                            : () => notifier.setStep(currentStep - 1),
                      ),
                    ),
                    AppSpacing.gapH12,
                  ],
                  Expanded(
                    flex: 2,
                    child: YbPrimaryButton(
                      label: currentStep == 2
                          ? l10n.onboardingCreateBusiness
                          : l10n.actionNext,
                      isLoading: formState.isLoading,
                      onPressed: handleNext,
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
