import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

abstract class IAuthRepository {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'en',
  });

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  });

  Future<UserResponse> updatePassword({required String newPassword});

  Future<void> signOut();

  Future<void> signInWithOtp({required String phone});

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  });
}

class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient? _client;

  SupabaseAuthRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  User? get currentUser => _client?.auth.currentUser;

  @override
  Session? get currentSession => _client?.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange;
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'en',
  }) async {
    try {
      final response = await _safeClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'preferred_language': preferredLanguage},
      );
      return response;
    } on AuthException catch (e) {
      AppLogger.warning(
        'AuthRepository.signUpWithEmail auth exception: ${e.message}',
      );
      throw AppAuthException(e.message, e.statusCode);
    } catch (e, stack) {
      AppLogger.error('AuthRepository.signUpWithEmail failed', e, stack);
      throw AppAuthException('Failed to sign up: $e');
    }
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _safeClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      AppLogger.warning(
        'AuthRepository.signInWithEmail auth exception: ${e.message}',
      );
      throw AppAuthException(e.message, e.statusCode);
    } catch (e, stack) {
      AppLogger.error('AuthRepository.signInWithEmail failed', e, stack);
      throw AppAuthException('Failed to sign in: $e');
    }
  }

  @override
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _safeClient.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
    } on AuthException catch (e) {
      AppLogger.warning(
        'AuthRepository.resetPasswordForEmail auth exception: ${e.message}',
      );
      throw AppAuthException(e.message, e.statusCode);
    } catch (e, stack) {
      AppLogger.error('AuthRepository.resetPasswordForEmail failed', e, stack);
      throw AppAuthException('Failed to send password reset: $e');
    }
  }

  @override
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _safeClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } on AuthException catch (e) {
      AppLogger.warning(
        'AuthRepository.updatePassword auth exception: ${e.message}',
      );
      throw AppAuthException(e.message, e.statusCode);
    } catch (e, stack) {
      AppLogger.error('AuthRepository.updatePassword failed', e, stack);
      throw AppAuthException('Failed to update password: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _safeClient.auth.signOut();
    } catch (e, stack) {
      AppLogger.error('AuthRepository.signOut failed', e, stack);
      throw AppAuthException('Sign out failed: $e');
    }
  }

  @override
  Future<void> signInWithOtp({required String phone}) async {
    try {
      await _safeClient.auth.signInWithOtp(phone: phone);
    } catch (e, stack) {
      AppLogger.error('AuthRepository.signInWithOtp failed', e, stack);
      throw AppAuthException('Failed to send OTP to $phone: $e');
    }
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _safeClient.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      return response;
    } catch (e, stack) {
      AppLogger.error('AuthRepository.verifyOtp failed', e, stack);
      throw AppAuthException('Failed to verify OTP: $e');
    }
  }
}
