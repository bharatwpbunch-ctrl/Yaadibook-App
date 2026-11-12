# Yaadibook — Known Limitations & External Dependencies

## 1. Items Awaiting External Credentials / Store Setup
1. **Google Play Console Purchase Settlement**: `PlayBillingService` and `verify-play-purchase` are implemented end-to-end, but live checkout and server verification require:
   - Publishing an AAB to Play Console Internal Testing track with products `yaadibook_pro_monthly` & `yaadibook_pro_yearly`.
   - Uploading `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` to Supabase Edge Function Secrets (otherwise `verify-play-purchase` returns `503 AWAITING_PLAY_CONSOLE_CREDENTIALS`).
2. **Android Push Notification Delivery (`FCM`)**: Client device token registration and local notifications are implemented (`PushNotificationService`), but `process-notifications` Edge Function currently simulates FCM message IDs (`fcm_msg_*`) because live `FCM_SERVICE_ACCOUNT_JSON` credentials and `android/app/google-services.json` belong to the operator's Firebase project.
3. **Official WhatsApp Cloud API & India DLT SMS Gateway**: Server-side authentication, entitlement checks, and Meta/DLT HTTP dispatch logic are implemented, returning `503 AWAITING_WHATSAPP_CREDENTIALS` / `503 AWAITING_SMS_CREDENTIALS` until live tokens/DLT approvals are added. Manual WhatsApp/SMS prefill works immediately without provider API keys.
4. **Release Upload Keystore**: `android/app/build.gradle.kts` reads `android/key.properties` when present, falling back to debug signing ONLY when `android/key.properties` is absent for unsigned local CI builds. Production Play Store uploads MUST provide `android/key.properties` and a real upload `.jks`.
5. **Hosted Privacy Policy / Account Deletion URLs**: Draft policies live under `docs/PRIVACY_POLICY_DRAFT.md`, `docs/TERMS_OF_SERVICE_DRAFT.md`, and `docs/ACCOUNT_DELETION_POLICY.md`; legal contact email and public web URLs must be hosted before Play Console submission.

## 2. Architectural & Scope Limitations (By Design)
- **Web Offline Fallback**: Chrome Web (`kIsWeb`) uses `InMemoryOfflineStore` instead of native SQLite, whereas Android builds use persistent on-disk `DriftOfflineDatabase` (`sqlite3_flutter_libs`).
- **Offline Subset**: AMC renewals, subscription billing, and bulk campaigns intentionally require internet connectivity to preserve transactional integrity.
- **Database Migration Push**: `supabase/migrations/20261112100001_subscriptions_entitlements_and_deletion.sql` must be applied to the live Supabase project before invoking Phase 10 RPCs (`get_business_entitlements`, `get_reports_summary`, `check_business_entitlement`).
- **Owner-Only MVP**: Multi-user staff/technician roles and GST invoice generation remain out of MVP scope.

