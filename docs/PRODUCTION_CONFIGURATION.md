# Yaadibook — Production Configuration Checklist

This checklist inventories every migration, Edge Function, secret, and store configuration required to run Yaadibook in production. **No real secrets are stored in source control.**

## 1. Supabase Database Migrations (`supabase/migrations/`)
Apply all SQL migrations chronologically via `supabase db push` or Supabase SQL Editor:
1. `20261104170001_core_schema.sql`
2. `20261104170002_crm_and_services.sql`
3. `20261104170003_maintenance_and_amc.sql`
4. `20261104170004_reminders_and_communication.sql`
5. `20261104170005_storage_and_security.sql`
6. `20261105160001_add_customer_type.sql`
7. `20261105170001_service_management.sql`
8. `20261106170001_maintenance_and_amc_enhancements.sql`
9. `20261106180001_unified_reminders_and_notifications.sql`
10. `20261106200001_communication_and_campaigns.sql`
11. `20261112000001_maintenance_amc_rpc_and_reminder_fixes.sql`
12. `20261112100001_subscriptions_entitlements_and_deletion.sql`

## 2. Supabase Edge Functions & Required Secrets
Deploy functions (`supabase functions deploy <name>`):
- `whatsapp-cloud-api`
- `sms-gateway`
- `campaign-processor`
- `process-notifications`
- `verify-play-purchase`
- `request-account-deletion`

Required Edge Function Secrets (`supabase secrets set KEY=VALUE`):
| Secret Key | Purpose |
|---|---|
| `CRON_SECRET` | Authenticates internal cron calls to `process-notifications` & `campaign-processor` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Cloud Service Account JSON (`androidpublisher` API) for `verify-play-purchase` |
| `GOOGLE_PLAY_PACKAGE_NAME` | Defaults to `com.yaadibook.yaadibook` |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | Meta webhook handshake verify token |
| `META_APP_SECRET` | Validates Meta `X-Hub-Signature-256` webhooks |
| `WHATSAPP_CLOUD_API_TOKEN` | Meta WhatsApp Cloud API permanent access token |
| `DEFAULT_WHATSAPP_PHONE_NUMBER_ID` | Default Meta phone number ID (optional fallback) |
| `SMS_GATEWAY_API_KEY` | India DLT SMS provider API key |
| `SMS_GATEWAY_URL` | Provider REST endpoint |
| `DEFAULT_SMS_SENDER_ID` | Approved 6-char DLT Header (e.g. `YDBOOK`) |
| `DEFAULT_DLT_ENTITY_ID` | Approved TRAI DLT Principal Entity ID |
| `FCM_SERVICE_ACCOUNT_JSON` | Firebase Cloud Messaging v1 HTTP API service account credentials (for live push dispatch in `process-notifications`) |

## 3. Android & Firebase Configuration
- Place production `google-services.json` under `android/app/google-services.json`.
- Create `android/key.properties` from `android/key.properties.example` pointing to your upload `.jks` keystore.
- Verify Supabase Scheduled Cron (`pg_cron` or external scheduler) triggers `process-notifications` every 5 minutes with `x-cron-secret`.

