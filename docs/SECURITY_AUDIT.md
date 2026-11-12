# Yaadibook — Phase 10 Security Audit

## 1. Pre-Phase 10 Vulnerabilities Identified & Fixed
1. **Unauthenticated Edge Functions (CRITICAL — FIXED)**
   - **Finding**: Prior to Phase 10, `whatsapp-cloud-api`, `sms-gateway`, `campaign-processor`, and `process-notifications` created Supabase service-role clients without verifying the caller's JWT or confirming `businesses.owner_user_id = auth.uid()` (or internal `CRON_SECRET`).
   - **Remediation**: Created `supabase/functions/_shared/security.ts` (`authorizeBusinessOrInternal`, `requireEntitlement`, `verifyMetaWebhookSignature`). Updated all 4 Edge Functions and both new Edge Functions (`verify-play-purchase`, `request-account-deletion`) to strictly validate JWT + ownership or `CRON_SECRET`/`SUPABASE_SERVICE_ROLE_KEY`.
2. **Client-Side Subscription Flag Hardcoding (HIGH — FIXED)**
   - **Finding**: `isBulkMessagingEntitledProvider` in `lib/shared/providers/backend_providers.dart` previously returned hardcoded `true`.
   - **Remediation**: Replaced with server-authoritative `entitlementsProvider` (`get_business_entitlements` RPC) + server-side `check_business_entitlement` checks inside `whatsapp-cloud-api`, `sms-gateway`, and `campaign-processor`.
3. **Insecure Webhook Defaults (HIGH — FIXED)**
   - **Finding**: `whatsapp-cloud-api` had a literal fallback verify token (`"yaadibook_wa_verify"`) and skipped `X-Hub-Signature-256` verification.
   - **Remediation**: Removed hardcoded verify token fallback (returns 503 if `WHATSAPP_WEBHOOK_VERIFY_TOKEN` is unset) and added timing-safe HMAC-SHA256 `X-Hub-Signature-256` verification.
4. **Subscription Table Tampering Risk (HIGH — MITIGATED)**
   - **Design**: `business_subscriptions` and `subscription_transactions` expose `SELECT`-only RLS policies to authenticated owners. Zero `INSERT`/`UPDATE`/`DELETE` policies exist for client tokens; all subscription grants go through `verify-play-purchase` using `SUPABASE_SERVICE_ROLE_KEY` and `external_transaction_id` uniqueness replay protection.
5. **CSV Formula Injection (MEDIUM — FIXED)**
   - **Remediation**: `ReportExportService.sanitizeCsvCell` prefixes values beginning with `=`, `+`, `-`, `@`, `\t`, or `\r` with `'`.

## 2. Multi-Tenant & Local Storage Security Controls
- **Supabase RLS**: Enabled on every application table and storage bucket (`is_business_owner(business_id)`).
- **Offline SQLite / Cache Isolation**: Every cached entity and pending sync operation stores `business_id` in its primary/index key.
- **Session Teardown Cleanup**: `offlineStoreProvider` listens to `authStateProvider` and automatically wipes local cache (`clearAllData()`) on sign-out, expiry, or account deletion.
- **Public Client Config**: Only Supabase public URL & anon key live in `AppConfig`; service-role keys, Play Store private keys, WhatsApp tokens, SMS keys, and release keystore passwords are excluded from source control (`.gitignore` updated with `android/key.properties`, `*.jks`, `*.keystore`, `.env*`).

## 3. Residual Risk / External Configuration Dependencies
- Live Meta Cloud API, India DLT SMS, Firebase Service Account (`FCM_SERVICE_ACCOUNT_JSON`), and Google Play Service Account (`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`) secrets must be configured in Supabase Edge Function Secrets before enabling those live flows in production.
- Upload signing keystore must be generated securely offline and configured via `android/key.properties` before Play Console release.

