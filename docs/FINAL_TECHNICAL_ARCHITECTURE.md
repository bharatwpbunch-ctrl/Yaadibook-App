# Yaadibook — Final Technical Architecture

## 1. High-Level Stack
- **Frontend**: Flutter (`sdk: ^3.11.1`) + Dart + Material 3
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: `go_router` with root navigator modal stack and 4-branch stateful bottom shell
- **Backend / BaaS**: Supabase (PostgreSQL 15, Supabase Auth, Row-Level Security, Storage, Deno Edge Functions)
- **Local Offline Storage**: `drift` + `sqlite3_flutter_libs` (`HybridOfflineStore` with web/headless in-memory fallback)
- **Connectivity & Sync**: `connectivity_plus` + `SyncEngine` FIFO queue with UUID idempotency keys and timestamp conflict detection
- **Billing**: `in_app_purchase` (Google Play Billing v6+) + server-side Edge Function `verify-play-purchase`
- **Exports**: `pdf`, `printing`, `csv` (`8.0.0`), `share_plus`
- **Push Notifications**: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`

## 2. Layered Module Architecture
```
lib/
├── app/
│   ├── config/          # Environment settings (`AppConfig`)
│   ├── localization/    # `app_en.arb`, `app_gu.arb`, `app_hi.arb` + generated delegates
│   ├── router/          # `app_router.dart` route table & auth guard
│   └── theme/           # `AppColors`, `AppSpacing`, `AppRadii`, `AppTypography`
├── core/
│   ├── database/        # `DriftOfflineDatabase`, conditional IO/Web executors, `HybridOfflineStore`
│   ├── services/        # `SupabaseService`, `PushNotificationService`, `PlayBillingService`
│   ├── sync/            # `connectivity_plus` stream, `SyncEngine`, `SyncController`
│   └── widgets/         # Shared UI components & `OfflineStatusBanner`
├── features/
│   ├── auth/            # Login, Signup, Reset Password, `AuthController`
│   ├── dashboard/       # `TodayScreen`
│   ├── customers/       # Customer list, detail, create/edit
│   ├── services/        # Service workflows, statuses, attachments
│   ├── maintenance/     # Maintenance plans, occurrences, completion
│   ├── amc/             # AMC contracts, expiry tracking, renewals
│   ├── reminders/       # Unified reminders workspace & snoozing
│   ├── notifications/   # Notification Centre & preferences
│   ├── communications/  # Manual WhatsApp/SMS, logs, usage, API settings
│   ├── message_templates/
│   ├── bulk_messaging/  # Entitled campaigns & audience segmentation
│   ├── reports/         # Phase 10A KPIs, charts, PDF/CSV exports
│   ├── offline_sync/    # Phase 10B queue inspector & conflict resolution UI
│   ├── subscriptions/   # Phase 10C central entitlements & billing UI
│   └── settings/        # More hub, Business Profile editor, Legal & Account Deletion
└── shared/
    ├── models/          # Domain DTOs
    ├── providers/       # Riverpod providers
    └── repositories/    # Supabase repositories + Offline-aware decorators
```

## 3. Supabase Edge Functions (`supabase/functions/`)
- `_shared/security.ts`: Shared JWT owner authorization (`authorizeBusinessOrInternal`), server-side entitlement verification (`requireEntitlement`), Meta HMAC verification, and SHA-256 helpers.
- `whatsapp-cloud-api/index.ts`: Meta webhook verify + status updates + authorized/entitled outbound WhatsApp Cloud API dispatch.
- `sms-gateway/index.ts`: Authorized/entitled India DLT SMS dispatch.
- `campaign-processor/index.ts`: Batch bulk campaign dispatcher enforcing consent opt-outs & Pro entitlements.
- `process-notifications/index.ts`: Cron/service-role notification queue worker (live FCM dispatch awaiting `FCM_SERVICE_ACCOUNT_JSON`).
- `verify-play-purchase/index.ts`: Google Play Developer API v3 purchase token verifier & idempotent ledger writer.
- `request-account-deletion/index.ts`: Permanent account/storage purge & deletion audit recorder.

