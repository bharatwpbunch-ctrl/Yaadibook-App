import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/yb_text_input.dart';
import '../../providers/onboarding_controller.dart';

/// Step B: Business Address (Street, City, State, PIN code, Country).
class StepBusinessAddress extends ConsumerWidget {
  const StepBusinessAddress({super.key});

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
          l10n.onboardingStep2Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        AppSpacing.gapV24,

        // Address Line 1
        YbTextInput(
          label: l10n.onboardingAddress1,
          hint: l10n.onboardingAddress1Hint,
          controller: TextEditingController(text: formState.addressLine1)
            ..selection = TextSelection.collapsed(
              offset: formState.addressLine1.length,
            ),
          onChanged: (val) => notifier.updateAddress(addressLine1: val),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        AppSpacing.gapV16,

        // Address Line 2 / Area (Optional)
        YbTextInput(
          label: l10n.onboardingAddress2,
          hint: l10n.onboardingAddress2Hint,
          controller: TextEditingController(text: formState.addressLine2)
            ..selection = TextSelection.collapsed(
              offset: formState.addressLine2.length,
            ),
          onChanged: (val) => notifier.updateAddress(addressLine2: val),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(
            Icons.map_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        AppSpacing.gapV16,

        // Row for City & PIN Code
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City
            Expanded(
              flex: 3,
              child: YbTextInput(
                label: l10n.onboardingCity,
                hint: l10n.onboardingCityHint,
                controller: TextEditingController(text: formState.city)
                  ..selection = TextSelection.collapsed(
                    offset: formState.city.length,
                  ),
                onChanged: (val) => notifier.updateAddress(city: val),
                textInputAction: TextInputAction.next,
              ),
            ),
            AppSpacing.gapH12,
            // PIN Code
            Expanded(
              flex: 2,
              child: YbTextInput(
                label: l10n.onboardingPinCode,
                hint: l10n.onboardingPinCodeHint,
                controller: TextEditingController(text: formState.postalCode)
                  ..selection = TextSelection.collapsed(
                    offset: formState.postalCode.length,
                  ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 6,
                onChanged: (val) => notifier.updateAddress(postalCode: val),
              ),
            ),
          ],
        ),
        AppSpacing.gapV16,

        // Row for State & Country
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State
            Expanded(
              child: YbTextInput(
                label: l10n.onboardingState,
                hint: 'Gujarat',
                controller: TextEditingController(text: formState.state)
                  ..selection = TextSelection.collapsed(
                    offset: formState.state.length,
                  ),
                onChanged: (val) => notifier.updateAddress(stateRegion: val),
                textInputAction: TextInputAction.next,
              ),
            ),
            AppSpacing.gapH12,
            // Country
            Expanded(
              child: YbTextInput(
                label: l10n.onboardingCountry,
                hint: 'India',
                enabled: false,
                controller: TextEditingController(text: formState.country),
              ),
            ),
          ],
        ),
        AppSpacing.gapV24,
      ],
    );
  }
}
