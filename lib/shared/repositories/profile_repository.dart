import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/user_profile.dart';

abstract class IProfileRepository {
  Future<UserProfile?> getMyProfile();
  Future<UserProfile> upsertProfile(UserProfile profile);
  Future<void> updatePreferredLanguage(String languageCode);
}

class SupabaseProfileRepository implements IProfileRepository {
  final SupabaseClient? _client;

  SupabaseProfileRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<UserProfile?> getMyProfile() async {
    try {
      final user = _safeClient.auth.currentUser;
      if (user == null) return null;

      final data = await _safeClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ProfileRepository.getMyProfile failed', e, stack);
      throw AppStorageException('Failed to load user profile: $e');
    }
  }

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    try {
      final data = await _safeClient
          .from('profiles')
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ProfileRepository.upsertProfile failed', e, stack);
      throw AppStorageException('Failed to save profile: $e');
    }
  }

  @override
  Future<void> updatePreferredLanguage(String languageCode) async {
    try {
      final user = _safeClient.auth.currentUser;
      if (user == null) return;

      await _safeClient
          .from('profiles')
          .update({'preferred_language': languageCode})
          .eq('id', user.id);
    } catch (e, stack) {
      AppLogger.error(
        'ProfileRepository.updatePreferredLanguage failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to update preferred language: $e');
    }
  }
}
