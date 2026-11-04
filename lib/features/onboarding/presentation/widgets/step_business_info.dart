import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/yb_dropdown.dart';
import '../../../../core/widgets/yb_text_input.dart';
import '../../providers/onboarding_controller.dart';

/// Step A: Business Information (Name, Category, Phone, Email).
class StepBusinessInfo extends ConsumerWidget {
  const StepBusinessInfo({super.key});

  String _getCategoryLabel(BuildContext context, String key) {
    final l10n = context.l10n;
    switch (key) {
      case BusinessCategories.cctv:
        return l10n.categoryCctv;
      case BusinessCategories.hvac:
        return l10n.categoryHvac;
      case BusinessCategories.ro:
        return l10n.categoryRo;
      case BusinessCategories.appliance:
        return l10n.categoryAppliance;
      case BusinessCategories.electrical:
        return l10n.categoryElectrical;
      case BusinessCategories.plumbing:
        return l10n.categoryPlumbing;
      case BusinessCategories.general:
        return l10n.categoryGeneral;
      case BusinessCategories.other:
        return l10n.categoryOther;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formState = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Subtitle
        Text(
          l10n.onboardingStep1Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        AppSpacing.gapV24,

        // Business Name
        YbTextInput(
          label: l10n.onboardingBusinessName,
          hint: l10n.onboardingBusinessNameHint,
          controller: TextEditingController(text: formState.businessName)
            ..selection = TextSelection.collapsed(
              offset: formState.businessName.length,
            ),
          onChanged: (val) => notifier.updateBusinessInfo(businessName: val),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(
            Icons.storefront_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        AppSpacing.gapV16,

        // Business Category
        YbDropdown<String>(
          label: l10n.onboardingCategory,
          hint: l10n.onboardingCategoryHint,
          value: formState.businessCategory,
          items: BusinessCategories.all.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(
                _getCategoryLabel(context, cat),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              notifier.updateBusinessInfo(businessCategory: val);
            }
          },
        ),
        AppSpacing.gapV16,

        // Custom Category if "Other" selected
        if (formState.businessCategory == BusinessCategories.other) ...[
          YbTextInput(
            label: l10n.onboardingCategoryOther,
            hint: l10n.onboardingCategoryOtherHint,
            controller: TextEditingController(text: formState.customCategory)
              ..selection = TextSelection.collapsed(
                offset: formState.customCategory.length,
              ),
            onChanged: (val) =>
                notifier.updateBusinessInfo(customCategory: val),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.category_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          AppSpacing.gapV16,
        ],

        // Business Phone Number (10 digits)
        YbTextInput(
          label: l10n.onboardingPhone,
          hint: l10n.onboardingPhoneHint,
          controller: TextEditingController(text: formState.phone)
            ..selection = TextSelection.collapsed(
              offset: formState.phone.length,
            ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: const Text(
              '+91',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          onChanged: (val) => notifier.updateBusinessInfo(phone: val),
        ),
        AppSpacing.gapV16,

        // Business Email (Optional)
        YbTextInput(
          label: l10n.onboardingEmail,
          hint: l10n.onboardingEmailHint,
          controller: TextEditingController(text: formState.email)
            ..selection = TextSelection.collapsed(
              offset: formState.email.length,
            ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(
            Icons.email_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
          onChanged: (val) => notifier.updateBusinessInfo(email: val),
        ),
        AppSpacing.gapV24,
      ],
    );
  }
}
