import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';
import '../../shared/repositories/notification_repository.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Can be invoked when app is completely terminated
  AppLogger.info('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService instance =
      PushNotificationService._internal();

  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isFirebaseInitialized = false;
  bool _isLocalNotificationsInitialized = false;
  String? _cachedFcmToken;
  void Function(String route, Map<String, dynamic>? data)? _onNotificationTap;

  bool get isFirebaseInitialized => _isFirebaseInitialized;
  String? get cachedFcmToken => _cachedFcmToken;

  /// Initializes local notifications and Firebase Cloud Messaging safely.
  Future<void> initialize({
    INotificationRepository? repository,
    void Function(String route, Map<String, dynamic>? data)? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;

    // Web does not support Android/iOS local notification channels or unconfigured FCM.
    // Skip before runApp() so web startup is never delayed or blocked.
    if (kIsWeb) {
      AppLogger.info(
        'PushNotificationService: Web platform detected, skipping native setup.',
      );
      return;
    }

    // 1. Initialize Flutter Local Notifications Plugin
    await _initLocalNotifications();

    // 2. Safely initialize Firebase and FCM
    await _initFirebase(repository: repository);
  }

  Future<void> _initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && _onNotificationTap != null) {
            _onNotificationTap!('/notifications', {'payload': payload});
          }
        },
      );

      // Create high-importance notification channel for Android
      const channel = AndroidNotificationChannel(
        'yaadibook_reminders',
        'Yaadibook Reminders & Alerts',
        description:
            'Channel used for business reminders, maintenance visits, and AMC renewal alerts.',
        importance: Importance.high,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      _isLocalNotificationsInitialized = true;
      AppLogger.info('Flutter local notifications initialized successfully');
    } catch (e) {
      AppLogger.warning('Failed to initialize local notifications: $e');
    }
  }

  Future<void> _initFirebase({INotificationRepository? repository}) async {
    try {
      // Attempt Firebase initialization
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseInitialized = true;

      // Register background messaging handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Retrieve FCM Token
      try {
        // ignore: deprecated_member_use
        _cachedFcmToken = await FirebaseMessaging.instance.getToken();
        if (_cachedFcmToken != null && repository != null) {
          await repository.registerDeviceToken(
            fcmToken: _cachedFcmToken!,
            platform: kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
          );
        }

        // Listen for token refresh
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _cachedFcmToken = newToken;
          if (repository != null) {
            repository.registerDeviceToken(
              fcmToken: newToken,
              platform: kIsWeb
                  ? 'web'
                  : (Platform.isAndroid ? 'android' : 'ios'),
            );
          }
        });
      } catch (tokenErr) {
        AppLogger.warning(
          'FCM token retrieval skipped: $tokenErr (normal in dev/emulator without Google Play Services)',
        );
      }

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showNotification(
            title: notification.title ?? 'Yaadibook Reminder',
            body: notification.body ?? '',
            payload: message.data.toString(),
          );
        }
      });

      // App opened from background via notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (_onNotificationTap != null) {
          _onNotificationTap!('/notifications', message.data);
        }
      });

      // Check if app was launched directly from terminated state via notification
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null && _onNotificationTap != null) {
        _onNotificationTap!('/notifications', initialMessage.data);
      }

      AppLogger.info('Firebase Cloud Messaging configured successfully');
    } catch (e) {
      _isFirebaseInitialized = false;
      AppLogger.info(
        'FCM push notification setup skipped: Firebase not configured or credentials pending (fallback to in-app notification center)',
      );
    }
  }

  /// Explicitly requests push notification permission from the owner.
  Future<bool> requestPermission() async {
    try {
      if (!_isFirebaseInitialized) return false;

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Displays an immediate local notification (e.g. for foreground events or alarms).
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_isLocalNotificationsInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'yaadibook_reminders',
        'Yaadibook Reminders & Alerts',
        channelDescription: 'Notifications for maintenance, AMC and tasks.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      AppLogger.warning('Failed to show local notification: $e');
    }
  }
}
