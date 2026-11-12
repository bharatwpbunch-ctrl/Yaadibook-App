import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/features/notifications/presentation/notification_centre_screen.dart';
import 'package:yaadibook/features/notifications/presentation/notification_preferences_screen.dart';
import 'package:yaadibook/features/notifications/providers/notification_providers.dart';
import 'package:yaadibook/shared/models/models.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';
import 'package:yaadibook/shared/repositories/notification_repository.dart';

class _FakeNotificationRepository implements INotificationRepository {
  final List<InAppNotification> _notifications;
  NotificationPreferences _prefs;

  _FakeNotificationRepository(this._notifications, this._prefs);

  @override
  Future<List<InAppNotification>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    if (unreadOnly) {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  @override
  Future<int> getUnreadCount() async {
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<int> markAllAsRead() async {
    return 1;
  }

  @override
  Future<NotificationPreferences?> getPreferences() async {
    return _prefs;
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences prefs,
  ) async {
    _prefs = prefs;
    return prefs;
  }

  @override
  Future<void> registerDeviceToken({
    required String fcmToken,
    String platform = 'android',
    String? deviceName,
    String? deviceId,
  }) async {}
}

Widget _wrapWithApp(
  Widget child, {
  List<InAppNotification>? notifications,
  NotificationPreferences? prefs,
}) {
  final now = DateTime.now();
  final defaultPrefs =
      prefs ??
      NotificationPreferences(
        id: 'pref-1',
        businessId: 'biz-1',
        pushNotificationsEnabled: true,
        maintenanceNotificationsEnabled: true,
        amcNotificationsEnabled: true,
        followupNotificationsEnabled: true,
        generalNotificationsEnabled: true,
        quietHoursEnabled: true,
        quietHoursStart: '22:00:00',
        quietHoursEnd: '08:00:00',
        preferredNotificationTime: '09:00:00',
        createdAt: now,
        updatedAt: now,
      );

  final repo = _FakeNotificationRepository(notifications ?? [], defaultPrefs);

  return ProviderScope(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      inAppNotificationsProvider.overrideWith(
        (_) => Future.value(notifications ?? []),
      ),
      unreadNotificationCountProvider.overrideWith(
        (_) =>
            Future.value((notifications ?? []).where((n) => !n.isRead).length),
      ),
      notificationPreferencesProvider.overrideWith(
        (_) => Future.value(defaultPrefs),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('Notification Centre & Preferences Widget Tests', () {
    final now = DateTime.now();

    final testNotifications = [
      InAppNotification(
        id: 'notif-1',
        businessId: 'biz-1',
        title: 'Maintenance due tomorrow',
        body: 'RO Purifier checkup for Rahul Shah',
        category: 'maintenance',
        isRead: false,
        createdAt: now,
      ),
      InAppNotification(
        id: 'notif-2',
        businessId: 'biz-1',
        title: 'AMC Contract Expiring Soon',
        body: 'CCTV Annual Contract for Priya Mehta expires in 7 days',
        category: 'amc',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ];

    testWidgets(
      'NotificationCentreScreen renders notifications list and unread count',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            const NotificationCentreScreen(),
            notifications: testNotifications,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Maintenance due tomorrow'), findsOneWidget);
        expect(find.text('AMC Contract Expiring Soon'), findsOneWidget);
        expect(find.text('Mark All as Read'), findsOneWidget);
      },
    );

    testWidgets(
      'NotificationPreferencesScreen renders push toggle and quiet hours',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(const NotificationPreferencesScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Notification Preferences'), findsOneWidget);
        expect(find.text('Push Notifications'), findsOneWidget);

        // Scroll to reveal Quiet Hours card
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('Quiet Hours'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );
  });
}
