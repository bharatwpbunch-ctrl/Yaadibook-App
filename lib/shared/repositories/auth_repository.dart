import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

abstract class IAuthRepository {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  Future<void> signInWithOtp({required String phone});
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  });
  Future<void> signOut();
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

  @override
  Future<void> signOut() async {
    try {
      await _safeClient.auth.signOut();
    } catch (e, stack) {
      AppLogger.error('AuthRepository.signOut failed', e, stack);
      throw AppAuthException('Sign out failed: $e');
    }
  }
}
