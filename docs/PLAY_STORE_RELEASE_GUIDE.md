# Yaadibook — Google Play Store Release Guide

## 1. Pre-Configured Android Application Settings
- **Application ID / Package**: `com.yaadibook.yaadibook` (`android/app/build.gradle.kts`)
- **App Display Name**: `Yaadibook` (`android/app/src/main/AndroidManifest.xml`)
- **App Version**: Configured in `pubspec.yaml` (`1.0.0+1`)
- **Min SDK**: `maxOf(flutter.minSdkVersion, 23)` (Android 6.0+)
- **Release Optimization**: `isMinifyEnabled = true`, `isShrinkResources = true`, `android/app/proguard-rules.pro`
- **Declared Permissions**:
  - `INTERNET` (Supabase APIs, FCM, Play Billing)
  - `POST_NOTIFICATIONS` (Android 13+ reminder alerts)
  - `VIBRATE`, `RECEIVE_BOOT_COMPLETED` (local/push notifications)
  - `READ_CONTACTS` (optional user-initiated customer import)

## 2. Production Signing Setup (Required Before Upload)
Release signing reads `android/key.properties` (excluded from Git).
1. Generate an upload keystore securely on your build machine:
   ```powershell
   keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties` and enter your real keystore password, key alias, and relative keystore path (`../upload-keystore.jks`).
3. **Never commit** `android/key.properties` or `*.jks` files to version control.

## 3. Building the Play Store App Bundle (.aab)
```powershell
flutter build appbundle --release
```
Output bundle path: `build/app/outputs/bundle/release/app-release.aab`

## 4. Play Console Checklist (External Owner Steps)
- [ ] Configure Google Play App Signing and upload AAB to **Internal Testing** track first.
- [ ] Add `android/app/google-services.json` from Firebase Console (package `com.yaadibook.yaadibook`) and upload `FCM_SERVICE_ACCOUNT_JSON` to Supabase Secrets.
- [ ] Create subscription products `yaadibook_pro_monthly` (₹299/mo) and `yaadibook_pro_yearly` (₹2,999/yr) in Play Console Monetize -> Subscriptions.
- [ ] Grant a Google Cloud Service Account `androidpublisher` access in Play Console API Access and store JSON in Supabase Secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
- [ ] Publish live Privacy Policy & Account Deletion web URLs in Play Console Store Listing & Data Safety form.
- [ ] Complete Play Console Data Safety declaration (Personal Info: Name/Email/Phone; App Activity; Optional Contacts on user action; Photos/Files if uploaded; Encrypted in transit via HTTPS/TLS; Account deletion link/in-app path provided).

