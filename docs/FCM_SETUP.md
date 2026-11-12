# Yaadibook — Firebase Cloud Messaging (FCM) Setup Guide

## 1. Prerequisites

To enable live Android push notifications on devices:
1. A Google Firebase project (e.g. `yaadibook-app`).
2. An Android application registered in Firebase with package name:
   ```
   com.yaadibook.app
   ```
3. SHA-1 / SHA-256 fingerprints added to Firebase project settings.
4. Downloaded `google-services.json` configuration file.

---

## 2. Android Project Configuration

Yaadibook is pre-configured with graceful Firebase bootstrapping:
- If `google-services.json` is present in `android/app/`, Gradle automatically applies the Google Services plugin:
  ```kotlin
  // android/app/build.gradle.kts
  if (file("google-services.json").exists()) {
      apply(plugin = "com.google.gms.google-services")
  }
  ```
- If the file is not yet placed, the app builds cleanly and runs in fallback mode without crashing.

### File Placement
Place the downloaded file at:
```
android/app/google-services.json
```

---

## 3. Android Permissions & Channels

The Android manifest (`android/app/src/main/AndroidManifest.xml`) includes:
- `<uses-permission android:name="android.permission.INTERNET"/>`
- `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (Android 13+ runtime permission)
- `<uses-permission android:name="android.permission.VIBRATE"/>`
- `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`

### Default Notification Channel
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="yaadibook_reminders" />
```

Channel Details:
- **ID**: `yaadibook_reminders`
- **Name**: `Reminders & Follow-ups`
- **Description**: `Operational alerts for maintenance, AMC contracts, and follow-ups.`
- **Importance**: High (`Importance.high`)
- **Sound & Vibration**: Enabled with default notification alert.

---

## 4. Client Lifecycle & Token Registration

### Token Lifecycle Flow
1. App initializes `PushNotificationService.instance.initialize()` during startup (`lib/main.dart`).
2. If push is enabled in `NotificationPreferences`, the service requests permission (`requestPermission()`).
3. Upon grant, FCM token is retrieved:
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   ```
4. Token is registered into `public.device_tokens` table via Supabase RPC `register_device_token`:
   ```sql
   SELECT public.register_device_token(
       p_fcm_token := '...',
       p_platform := 'android',
       p_device_name := 'Samsung Galaxy M32'
   );
   ```
5. `FirebaseMessaging.instance.onTokenRefresh` listens for token rotations and re-registers the updated token immediately.

---

## 5. Token Deactivation on Invalidation

When Supabase Edge Function dispatches a push message to FCM:
- If FCM responds with `UNREGISTERED` or `INVALID_ARGUMENT`:
  The Edge Function immediately runs:
  ```sql
  UPDATE public.device_tokens 
  SET is_active = FALSE, updated_at = now()
  WHERE fcm_token = '...';
  ```
- This prevents repeated failed dispatches and saves server bandwidth.

