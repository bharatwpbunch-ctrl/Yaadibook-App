import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/business_repository.dart';
import '../../../shared/repositories/profile_repository.dart';

/// Pre-defined standard business categories.
class BusinessCategories {
  static const String cctv = 'CCTV & Security Systems';
  static const String hvac = 'AC & HVAC Services';
  static const String ro = 'RO & Water Purifier';
  static const String appliance = 'Appliance Repair';
  static const String electrical = 'Electrical Services';
  static const String plumbing = 'Plumbing Services';
  static const String general = 'General Maintenance';
  static const String other = 'Other';

  static const List<String> all = [
    cctv,
    hvac,
    ro,
    appliance,
    electrical,
    plumbing,
    general,
    other,
  ];
}

/// State holding the 3-step onboarding form data.
class OnboardingFormState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  // Step 0: Business Info
  final String businessName;
  final String businessCategory;
  final String customCategory;
  final String phone;
  final String email;

  // Step 1: Address
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  // Step 2: Preferences
  final String preferredLanguage;
  final String currencyCode;
  final String timezone;
  final String dateFormat;
  final String timeFormat;

  const OnboardingFormState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
    this.businessName = '',
    this.businessCategory = BusinessCategories.cctv,
    this.customCategory = '',
    this.phone = '',
    this.email = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.state = 'Gujarat',
    this.postalCode = '',
    this.country = 'India',
    this.preferredLanguage = 'en',
    this.currencyCode = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.dateFormat = 'DD/MM/YYYY',
    this.timeFormat = '12-hour',
  });

  String get effectiveCategory =>
      businessCategory == BusinessCategories.other && customCategory.isNotEmpty
      ? customCategory
      : businessCategory;

  OnboardingFormState copyWith({
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
    String? businessName,
    String? businessCategory,
    String? customCategory,
    String? phone,
    String? email,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? preferredLanguage,
    String? currencyCode,
    String? timezone,
    String? dateFormat,
    String? timeFormat,
    bool clearError = false,
  }) {
    return OnboardingFormState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCompleted: isCompleted ?? this.isCompleted,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      customCategory: customCategory ?? this.customCategory,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      currencyCode: currencyCode ?? this.currencyCode,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}

/// State notifier managing single-business onboarding flow.
class OnboardingController extends StateNotifier<OnboardingFormState> {
  final IBusinessRepository _businessRepo;
  final IProfileRepository _profileRepo;
  final Ref _ref;

  OnboardingController({
    required IBusinessRepository businessRepo,
    required IProfileRepository profileRepo,
    required Ref ref,
  }) : _businessRepo = businessRepo,
       _profileRepo = profileRepo,
       _ref = ref,
       super(const OnboardingFormState());

  void setStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void updateBusinessInfo({
    String? businessName,
    String? businessCategory,
    String? customCategory,
    String? phone,
    String? email,
  }) {
    state = state.copyWith(
      businessName: businessName,
      businessCategory: businessCategory,
      customCategory: customCategory,
      phone: phone,
      email: email,
      clearError: true,
    );
  }

  void updateAddress({
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? stateRegion,
    String? postalCode,
    String? country,
  }) {
    state = state.copyWith(
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: stateRegion,
      postalCode: postalCode,
      country: country,
      clearError: true,
    );
  }

  void updatePreferences({
    String? preferredLanguage,
    String? currencyCode,
    String? timezone,
    String? dateFormat,
    String? timeFormat,
  }) {
    state = state.copyWith(
      preferredLanguage: preferredLanguage,
      currencyCode: currencyCode,
      timezone: timezone,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      clearError: true,
    );
  }

  bool validateStep0() {
    if (state.businessName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your business name');
      return false;
    }
    if (state.businessCategory == BusinessCategories.other &&
        state.customCategory.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter your custom business category',
      );
      return false;
    }
    final cleanPhone = state.phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length != 10) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10-digit mobile number',
      );
      return false;
    }
    state = state.copyWith(clearError: true);
    return true;
  }

  bool validateStep1() {
    if (state.addressLine1.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter your business address',
      );
      return false;
    }
    if (state.city.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your city');
      return false;
    }
    final cleanPin = state.postalCode.replaceAll(RegExp(r'\D'), '');
    if (cleanPin.length != 6) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 6-digit PIN code',
      );
      return false;
    }
    state = state.copyWith(clearError: true);
    return true;
  }

  /// Submits the onboarding wizard and executes atomic create_business_workspace RPC.
  Future<bool> completeOnboarding() async {
    if (!validateStep0() || !validateStep1()) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final cleanPhone = state.phone.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = cleanPhone.length == 10
          ? '+91$cleanPhone'
          : state.phone;

      await _businessRepo.createBusinessWorkspace(
        businessName: state.businessName.trim(),
        businessCategory: state.effectiveCategory.trim(),
        phone: formattedPhone,
        addressLine1: state.addressLine1.trim(),
        city: state.city.trim(),
        postalCode: state.postalCode.trim(),
        state: state.state.trim().isEmpty ? 'Gujarat' : state.state.trim(),
        country: state.country.trim().isEmpty ? 'India' : state.country.trim(),
        currencyCode: state.currencyCode,
        timezone: state.timezone,
        preferredLanguage: state.preferredLanguage,
      );

      // Update preferred language on the owner profile
      try {
        await _profileRepo.updatePreferredLanguage(state.preferredLanguage);
      } catch (e) {
        AppLogger.warning(
          'OnboardingController: profile language update warning: $e',
        );
      }

      // Refresh cached business in Riverpod
      _ref.invalidate(currentBusinessProvider);
      _ref.invalidate(currentUserProfileProvider);

      state = state.copyWith(isLoading: false, isCompleted: true);
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'OnboardingController: completeOnboarding failed',
        e,
        stack,
      );
      final errorMsg = e.toString().contains('already create one business')
          ? 'A business workspace already exists for your account.'
          : 'Failed to create business workspace. Please verify your details and try again.';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }
}

/// Provider for OnboardingController.
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingFormState>((ref) {
      final businessRepo = ref.watch(businessRepositoryProvider);
      final profileRepo = ref.watch(profileRepositoryProvider);
      return OnboardingController(
        businessRepo: businessRepo,
        profileRepo: profileRepo,
        ref: ref,
      );
    });
