import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/auth_repository.dart';
import '../../../shared/repositories/profile_repository.dart';

/// Form and action state for Authentication.
class AuthFormState {
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  const AuthFormState({
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  AuthFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

/// State notifier for Authentication operations.
class AuthController extends StateNotifier<AuthFormState> {
  final IAuthRepository _authRepo;
  final IProfileRepository _profileRepo;
  final Ref _ref;

  AuthController({
    required IAuthRepository authRepo,
    required IProfileRepository profileRepo,
    required Ref ref,
  }) : _authRepo = authRepo,
       _profileRepo = profileRepo,
       _ref = ref,
       super(const AuthFormState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearInfo() {
    state = state.copyWith(clearInfo: true);
  }

  /// Sign in with email and password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final response = await _authRepo.signInWithEmail(
        email: email.trim(),
        password: password,
      );

      // Check if user email is unconfirmed
      final user = response.user;
      if (user != null &&
          user.emailConfirmedAt == null &&
          user.confirmationSentAt != null) {
        // Warning: Email might still require verification
        AppLogger.info(
          'User logged in with pending confirmation: ${user.email}',
        );
      }

      // Invalidate profile & business providers so they refresh immediately
      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(currentBusinessProvider);

      state = state.copyWith(isLoading: false);
      return true;
    } on AppAuthException catch (e) {
      AppLogger.warning('AuthController: sign in failed - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      AppLogger.error('AuthController: sign in unexpected error', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  /// Sign up with email, password, full name, and preferred language.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String preferredLanguage,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final response = await _authRepo.signUpWithEmail(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        preferredLanguage: preferredLanguage,
      );

      final user = response.user;
      if (user != null) {
        // Idempotently ensure profile exists in public.profiles
        try {
          await _profileRepo.upsertProfile(
            UserProfile(
              id: user.id,
              fullName: fullName.trim(),
              email: email.trim(),
              preferredLanguage: preferredLanguage,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        } catch (profileError) {
          AppLogger.warning(
            'AuthController: profile upsert deferred: $profileError',
          );
        }
      }

      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(currentBusinessProvider);

      state = state.copyWith(
        isLoading: false,
        infoMessage: response.session == null
            ? 'Account created! Please check your email for confirmation.'
            : null,
      );
      return true;
    } on AppAuthException catch (e) {
      AppLogger.warning('AuthController: sign up failed - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      AppLogger.error('AuthController: sign up unexpected error', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Registration failed. Please check your details and try again.',
      );
      return false;
    }
  }

  /// Request password reset link for registered email.
  Future<bool> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      await _authRepo.resetPasswordForEmail(
        email: email.trim(),
        redirectTo: redirectTo,
      );
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'We have sent a password reset link to your email.',
      );
      return true;
    } on AppAuthException catch (e) {
      AppLogger.warning('AuthController: reset password failed - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send reset link. Please try again.',
      );
      return false;
    }
  }

  /// Update password (e.g. from password recovery screen).
  Future<bool> updatePassword({required String newPassword}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      await _authRepo.updatePassword(newPassword: newPassword);
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Your password has been changed successfully.',
      );
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update password. Please try again.',
      );
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepo.signOut();
      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(currentBusinessProvider);
    } catch (e) {
      AppLogger.error('AuthController: signOut failed', e);
    } finally {
      state = const AuthFormState();
    }
  }

  /// Map raw backend error messages to user-friendly messages.
  String _mapAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credential') ||
        lower.contains('wrong password')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already exists') ||
        lower.contains('already in use')) {
      return 'This email is already registered. Please log in.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }
    if (lower.contains('weak password') ||
        lower.contains('at least 6 characters')) {
      return 'Password is too weak. Please choose a stronger password.';
    }
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lower.contains('user not found')) {
      return 'No account found with this email.';
    }
    return raw.isNotEmpty ? raw : 'Authentication error. Please try again.';
  }
}

/// Provider for AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFormState>((ref) {
      final authRepo = ref.watch(authRepositoryProvider);
      final profileRepo = ref.watch(profileRepositoryProvider);
      return AuthController(
        authRepo: authRepo,
        profileRepo: profileRepo,
        ref: ref,
      );
    });
