import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/in_app_notification.dart';
import '../../../shared/models/notification_preferences.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/notification_repository.dart';

/// Provider for list of recent in-app notifications
final inAppNotificationsProvider = FutureProvider<List<InAppNotification>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications(limit: 50);
});

/// Provider for unread notification count badge in App Bar
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

/// Provider for notification preferences
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences?>((ref) async {
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.getPreferences();
    });

/// Controller for marking notifications read and updating preferences
class NotificationController extends StateNotifier<AsyncValue<void>> {
  final INotificationRepository _repository;
  final Ref _ref;

  NotificationController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      _ref.invalidate(inAppNotificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _ref.invalidate(inAppNotificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updatePreferences(NotificationPreferences prefs) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePreferences(prefs);
      state = const AsyncValue.data(null);
      _ref.invalidate(notificationPreferencesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
      final repo = ref.watch(notificationRepositoryProvider);
      return NotificationController(repo, ref);
    });
