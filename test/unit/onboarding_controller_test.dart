import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/features/onboarding/providers/onboarding_controller.dart';
import 'package:yaadibook/shared/models/business.dart';
import 'package:yaadibook/shared/models/user_profile.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import 'package:yaadibook/shared/repositories/repositories.dart';

class MockBusinessRepository implements IBusinessRepository {
  bool shouldFail = false;
  String? failureMessage;
  Business? mockBusiness;
  Map<String, dynamic>? lastCreatedWorkspaceParams;

  @override
  Future<Business?> getMyBusiness() async => mockBusiness;

  @override
  Future<String> createBusinessWorkspace({
    required String businessName,
    required String businessCategory,
    required String phone,
    required String addressLine1,
    required String city,
    required String postalCode,
    String state = 'Gujarat',
    String country = 'India',
    String currencyCode = 'INR',
    String timezone = 'Asia/Kolkata',
    String preferredLanguage = 'en',
  }) async {
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Database error creating business');
    }
    lastCreatedWorkspaceParams = {
      'businessName': businessName,
      'businessCategory': businessCategory,
      'phone': phone,
      'addressLine1': addressLine1,
      'city': city,
      'postalCode': postalCode,
      'state': state,
      'country': country,
      'currencyCode': currencyCode,
      'timezone': timezone,
      'preferredLanguage': preferredLanguage,
    };
    return 'new-workspace-uuid-12345';
  }

  @override
  Future<void> updateBusiness(Business business) async {
    mockBusiness = business;
  }
}

class MockProfileRepository implements IProfileRepository {
  String? updatedLanguage;

  @override
  Future<UserProfile?> getMyProfile() async => null;

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) async => profile;

  @override
  Future<void> updatePreferredLanguage(String languageCode) async {
    updatedLanguage = languageCode;
  }
}

void main() {
  group('OnboardingController Unit Tests', () {
    late MockBusinessRepository mockBusinessRepo;
    late MockProfileRepository mockProfileRepo;
    late ProviderContainer container;

    setUp(() {
      mockBusinessRepo = MockBusinessRepository();
      mockProfileRepo = MockProfileRepository();
      container = ProviderContainer(
        overrides: [
          businessRepositoryProvider.overrideWithValue(mockBusinessRepo),
          profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial onboarding form state defaults are correct', () {
      final state = container.read(onboardingControllerProvider);
      expect(state.currentStep, 0);
      expect(state.isLoading, isFalse);
      expect(state.isCompleted, isFalse);
      expect(state.state, 'Gujarat');
      expect(state.country, 'India');
      expect(state.currencyCode, 'INR');
      expect(state.timezone, 'Asia/Kolkata');
      expect(state.preferredLanguage, 'en');
    });

    test(
      'Step 0 validation enforces business name and valid 10-digit phone',
      () {
        final notifier = container.read(onboardingControllerProvider.notifier);

        // Empty business name
        expect(notifier.validateStep0(), isFalse);
        expect(
          container.read(onboardingControllerProvider).errorMessage,
          'Please enter your business name',
        );

        // Business name set, but invalid phone
        notifier.updateBusinessInfo(
          businessName: 'Maruti Security Systems',
          phone: '12345',
        );
        expect(notifier.validateStep0(), isFalse);
        expect(
          container.read(onboardingControllerProvider).errorMessage,
          'Please enter a valid 10-digit mobile number',
        );

        // Valid phone
        notifier.updateBusinessInfo(phone: '9825012345');
        expect(notifier.validateStep0(), isTrue);
        expect(
          container.read(onboardingControllerProvider).errorMessage,
          isNull,
        );
      },
    );

    test('Custom category is required when Other is selected', () {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateBusinessInfo(
        businessName: 'Solar Tech Solutions',
        businessCategory: BusinessCategories.other,
        phone: '9825012345',
      );

      expect(notifier.validateStep0(), isFalse);
      expect(
        container.read(onboardingControllerProvider).errorMessage,
        'Please enter your custom business category',
      );

      notifier.updateBusinessInfo(customCategory: 'Solar Panel Maintenance');
      expect(notifier.validateStep0(), isTrue);
      expect(
        container.read(onboardingControllerProvider).effectiveCategory,
        'Solar Panel Maintenance',
      );
    });

    test('Step 1 validation enforces address, city, and 6-digit PIN code', () {
      final notifier = container.read(onboardingControllerProvider.notifier);

      // Missing address line 1
      expect(notifier.validateStep1(), isFalse);
      expect(
        container.read(onboardingControllerProvider).errorMessage,
        'Please enter your business address',
      );

      // Missing city
      notifier.updateAddress(addressLine1: 'Shop 4, Raj Complex');
      expect(notifier.validateStep1(), isFalse);
      expect(
        container.read(onboardingControllerProvider).errorMessage,
        'Please enter your city',
      );

      // Invalid PIN
      notifier.updateAddress(city: 'Ahmedabad', postalCode: '3800');
      expect(notifier.validateStep1(), isFalse);
      expect(
        container.read(onboardingControllerProvider).errorMessage,
        'Please enter a valid 6-digit PIN code',
      );

      // Valid 6-digit PIN
      notifier.updateAddress(postalCode: '380009');
      expect(notifier.validateStep1(), isTrue);
      expect(container.read(onboardingControllerProvider).errorMessage, isNull);
    });

    test('Step 2 preferences updates state properly', () {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updatePreferences(
        preferredLanguage: 'gu',
        dateFormat: 'DD/MM/YYYY',
        timeFormat: '12-hour',
      );

      final state = container.read(onboardingControllerProvider);
      expect(state.preferredLanguage, 'gu');
      expect(state.dateFormat, 'DD/MM/YYYY');
      expect(state.timeFormat, '12-hour');
    });

    test('completeOnboarding submits atomic RPC and completes flow', () async {
      final notifier = container.read(onboardingControllerProvider.notifier);

      // Fill in Step 0
      notifier.updateBusinessInfo(
        businessName: 'Shree Ram CCTV Services',
        businessCategory: BusinessCategories.cctv,
        phone: '9825012345',
        email: 'info@shreeramcctv.com',
      );

      // Fill in Step 1
      notifier.updateAddress(
        addressLine1: 'G-12, Titanium City Center',
        addressLine2: 'Prahladnagar',
        city: 'Ahmedabad',
        stateRegion: 'Gujarat',
        postalCode: '380015',
        country: 'India',
      );

      // Fill in Step 2
      notifier.updatePreferences(preferredLanguage: 'gu');

      final success = await notifier.completeOnboarding();
      expect(success, isTrue);

      final state = container.read(onboardingControllerProvider);
      expect(state.isCompleted, isTrue);
      expect(state.isLoading, isFalse);

      // Verify RPC params
      expect(mockBusinessRepo.lastCreatedWorkspaceParams, isNotNull);
      expect(
        mockBusinessRepo.lastCreatedWorkspaceParams!['businessName'],
        'Shree Ram CCTV Services',
      );
      expect(
        mockBusinessRepo.lastCreatedWorkspaceParams!['phone'],
        '+919825012345',
      );
      expect(mockProfileRepo.updatedLanguage, 'gu');
    });

    test(
      'completeOnboarding preserves form fields on failure and shows clear error',
      () async {
        mockBusinessRepo.shouldFail = true;
        mockBusinessRepo.failureMessage = 'Network connection interrupted';

        final notifier = container.read(onboardingControllerProvider.notifier);
        notifier.updateBusinessInfo(
          businessName: 'Test Business',
          phone: '9825012345',
        );
        notifier.updateAddress(
          addressLine1: '123 Test St',
          city: 'Surat',
          postalCode: '395001',
        );

        final success = await notifier.completeOnboarding();
        expect(success, isFalse);

        final state = container.read(onboardingControllerProvider);
        expect(state.isCompleted, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNotNull);
        // Preserved fields
        expect(state.businessName, 'Test Business');
        expect(state.city, 'Surat');
      },
    );
  });
}
