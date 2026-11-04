import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/app_config.dart';
import '../utils/logger.dart';

/// Architecture preparation for Supabase backend.
///
/// **IMPORTANT**:
/// In Phase 1, the production database is not active. This service encapsulates
/// the client initialization logic so that in Phase 2 it can connect with zero
/// architecture changes.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  /// Safely prepares Supabase integration.
  /// If placeholder keys are supplied, logs a warning and skips live connection.
  static Future<void> initialize(AppConfig config) async {
    final url = config.supabaseUrl;
    final anonKey = config.supabaseAnonKey;

    if (url.contains('placeholder') || anonKey.contains('placeholder')) {
      AppLogger.info(
        'SupabaseService: Running in mock/offline mode with placeholder credentials. Live backend calls are disabled in Phase 1.',
      );
      return;
    }

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      );
      _initialized = true;
      AppLogger.info(
        'SupabaseService: Successfully initialized Supabase client.',
      );
    } catch (e, stack) {
      AppLogger.error(
        'SupabaseService: Failed to initialize Supabase client',
        e,
        stack,
      );
    }
  }
}
