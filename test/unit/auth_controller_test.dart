import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yaadibook/core/errors/app_exception.dart';
import 'package:yaadibook/features/auth/providers/auth_controller.dart';
import 'package:yaadibook/shared/models/user_profile.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import 'package:yaadibook/shared/repositories/repositories.dart';

class MockAuthRepository implements IAuthRepository {
  bool shouldFail = false;
  String? failureMessage;
  User? mockUser;
  Session? mockSession;

  @override
  User? get currentUser => mockUser;

  @override
  Session? get currentSession => mockSession;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw AppAuthException(failureMessage ?? 'Invalid login credentials');
    }
    return AuthResponse(
      session: Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: const User(
          id: 'test_user_id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-11-04T00:00:00.000Z',
        ),
      ),
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'en',
  }) async {
    if (shouldFail) {
      throw AppAuthException(failureMessage ?? 'User already registered');
    }
    mockUser = const User(
      id: 'new_user_id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-11-04T00:00:00.000Z',
    );
    return AuthResponse(user: mockUser);
  }

  @override
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    if (shouldFail) {
      throw AppAuthException('User not found');
    }
  }

  @override
  Future<UserResponse> updatePassword({required String newPassword}) async {
    if (shouldFail) {
      throw const AppAuthException('Password is too weak');
    }
    return UserResponse.fromJson({
      'user': {
        'id': 'test_user_id',
        'aud': 'authenticated',
        'created_at': '2026-11-04T00:00:00.000Z',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
      },
    });
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
    mockSession = null;
  }

  @override
  Future<void> signInWithOtp({required String phone}) async {}

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return AuthResponse();
  }
}

class MockProfileRepository implements IProfileRepository {
  UserProfile? savedProfile;

  @override
  Future<UserProfile?> getMyProfile() async => savedProfile;

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    savedProfile = profile;
    return profile;
  }

  @override
  Future<void> updatePreferredLanguage(String languageCode) async {
    if (savedProfile != null) {
      savedProfile = UserProfile(
        id: savedProfile!.id,
        fullName: savedProfile!.fullName,
        email: savedProfile!.email,
        preferredLanguage: languageCode,
        createdAt: savedProfile!.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }
}

void main() {
  group('AuthController Unit Tests', () {
    late MockAuthRepository mockAuth;
    late MockProfileRepository mockProfile;
    late ProviderContainer container;

    setUp(() {
      mockAuth = MockAuthRepository();
      mockProfile = MockProfileRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle without loading or errors', () {
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.infoMessage, isNull);
    });

    test('signInWithEmail successfully authenticates user', () async {
      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.signInWithEmail(
        email: 'owner@yaadibook.com',
        password: 'Password123!',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test(
      'signInWithEmail maps invalid credentials to user-friendly message',
      () async {
        mockAuth.shouldFail = true;
        mockAuth.failureMessage = 'Invalid login credentials';

        final controller = container.read(authControllerProvider.notifier);
        final success = await controller.signInWithEmail(
          email: 'wrong@yaadibook.com',
          password: 'wrongpassword',
        );

        expect(success, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.isLoading, isFalse);
        expect(
          state.errorMessage,
          'Invalid email or password. Please try again.',
        );
      },
    );

    test(
      'signUpWithEmail creates user and idempotently provisions profile',
      () async {
        final controller = container.read(authControllerProvider.notifier);
        final success = await controller.signUpWithEmail(
          email: 'rajesh@patelsecurity.com',
          password: 'Password123!',
          fullName: 'Rajesh Patel',
          preferredLanguage: 'gu',
        );

        expect(success, isTrue);
        expect(mockProfile.savedProfile, isNotNull);
        expect(mockProfile.savedProfile!.fullName, 'Rajesh Patel');
        expect(mockProfile.savedProfile!.preferredLanguage, 'gu');
      },
    );

    test('signUpWithEmail maps duplicate email error clearly', () async {
      mockAuth.shouldFail = true;
      mockAuth.failureMessage = 'User already registered';

      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.signUpWithEmail(
        email: 'existing@yaadibook.com',
        password: 'Password123!',
        fullName: 'Existing Owner',
        preferredLanguage: 'en',
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(
        state.errorMessage,
        'This email is already registered. Please log in.',
      );
    });

    test('resetPasswordForEmail sets confirmation info message', () async {
      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.resetPasswordForEmail(
        email: 'owner@yaadibook.com',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.infoMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });

    test('updatePassword updates password successfully', () async {
      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.updatePassword(
        newPassword: 'NewStrongPassword123!',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.infoMessage, 'Your password has been changed successfully.');
    });

    test('signOut clears state and revokes session', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(mockAuth.currentUser, isNull);
    });
  });
}
