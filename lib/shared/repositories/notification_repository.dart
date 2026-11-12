import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/in_app_notification.dart';
import '../models/notification_preferences.dart';

abstract class INotificationRepository {
  Future<List<InAppNotification>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  });
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<int> markAllAsRead();
  Future<NotificationPreferences?> getPreferences();
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences prefs,
  );
  Future<void> registerDeviceToken({
    required String fcmToken,
    String platform = 'android',
    String? deviceName,
    String? deviceId,
  });
}

class SupabaseNotificationRepository implements INotificationRepository {
  final SupabaseClient? _client;

  SupabaseNotificationRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<InAppNotification>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      dynamic query = _safeClient.from('in_app_notifications').select();

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List<dynamic>)
          .map(
            (item) => InAppNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'NotificationRepository.getNotifications failed',
        e,
        stack,
      );
      return [];
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final res = await _safeClient
          .from('in_app_notifications')
          .select('id')
          .eq('is_read', false);

      return (res as List<dynamic>).length;
    } catch (e, stack) {
      AppLogger.error('NotificationRepository.getUnreadCount failed', e, stack);
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _safeClient
          .from('in_app_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e, stack) {
      AppLogger.error('NotificationRepository.markAsRead failed', e, stack);
      throw AppStorageException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      final user = _safeClient.auth.currentUser;
      if (user == null) return 0;

      // Try RPC first
      try {
        final biz = await _safeClient
            .from('businesses')
            .select('id')
            .eq('owner_user_id', user.id)
            .maybeSingle();

        if (biz != null) {
          final res = await _safeClient.rpc(
            'mark_all_notifications_read',
            params: {'p_business_id': biz['id']},
          );
          return (res as num?)?.toInt() ?? 0;
        }
      } catch (_) {
        // Fallback to table update
      }

      await _safeClient
          .from('in_app_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('is_read', false);

      return 1;
    } catch (e, stack) {
      AppLogger.error('NotificationRepository.markAllAsRead failed', e, stack);
      throw AppStorageException('Failed to mark all as read: $e');
    }
  }

  @override
  Future<NotificationPreferences?> getPreferences() async {
    try {
      final user = _safeClient.auth.currentUser;
      if (user == null) return null;

      final biz = await _safeClient
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (biz == null) return null;

      final data = await _safeClient
          .from('notification_preferences')
          .select()
          .eq('business_id', biz['id'])
          .maybeSingle();

      if (data == null) {
        // Provision default preferences
        final inserted = await _safeClient
            .from('notification_preferences')
            .insert({'business_id': biz['id']})
            .select()
            .single();
        return NotificationPreferences.fromJson(inserted);
      }

      return NotificationPreferences.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('NotificationRepository.getPreferences failed', e, stack);
      return null;
    }
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      final map = prefs.toJson();
      map['updated_at'] = DateTime.now().toIso8601String();

      final data = await _safeClient
          .from('notification_preferences')
          .update(map)
          .eq('id', prefs.id)
          .select()
          .single();

      return NotificationPreferences.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'NotificationRepository.updatePreferences failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to update notification settings: $e');
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String fcmToken,
    String platform = 'android',
    String? deviceName,
    String? deviceId,
  }) async {
    try {
      final user = _safeClient.auth.currentUser;
      if (user == null) return;

      final biz = await _safeClient
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (biz == null) return;

      // Try RPC first
      try {
        await _safeClient.rpc(
          'register_device_token',
          params: {
            'p_fcm_token': fcmToken,
            'p_platform': platform,
            'p_device_name': deviceName,
            'p_device_id': deviceId,
          },
        );
        return;
      } catch (_) {
        // Fallback to table upsert
      }

      await _safeClient.from('device_tokens').upsert({
        'user_id': user.id,
        'business_id': biz['id'],
        'fcm_token': fcmToken,
        'platform': platform,
        'device_name': deviceName,
        'device_id': deviceId,
        'is_active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');
    } catch (e, stack) {
      AppLogger.error(
        'NotificationRepository.registerDeviceToken failed',
        e,
        stack,
      );
    }
  }
}
