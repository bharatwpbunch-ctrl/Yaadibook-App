# Yaadibook — Server-Side Scheduling & Edge Functions

## 1. Overview

Yaadibook's notification and reminder engine runs server-side on Supabase. This guarantees that reminders fire, advance notices are queued, and push notifications are delivered regardless of whether the business owner has the app open, suspended, or closed.

---

## 2. Server Architecture

```
                    ┌───────────────────────────┐
                    │  pg_cron / External Ping  │
                    │   (Every 5 or 15 minutes) │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │   process-notifications   │
                    │   Supabase Edge Function  │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┴───────────────────────┐
          ▼                                               ▼
┌──────────────────────────┐                    ┌───────────────────────────┐
│ 1. Eligible Reminders    │                    │ 2. Queue Dispatcher       │
│ - Check advance days     │                    │ - Verify Quiet Hours      │
│ - Enqueue to queue table │                    │ - Insert in_app_notifs    │
│ - Skip duplicate keys    │                    │ - Dispatch FCM push       │
└──────────────────────────┘                    └───────────────────────────┘
```

---

## 3. Edge Function: `process-notifications`

Located at:
`supabase/functions/process-notifications/index.ts`

### Execution Steps
1. **Queue Candidate Selection**:
   Queries `public.notification_queue` where:
   - `status = 'queued'`
   - `scheduled_for <= timezone('utc', now())`
   - `retry_count < max_retries`
   Ordered by `scheduled_for ASC` with `LIMIT 50`.

2. **Preference Verification**:
   - Fetches `notification_preferences` for the item's `business_id`.
   - Checks if category notifications are enabled (`maintenance_notifications_enabled`, etc.).
   - Checks if push notifications are enabled.

3. **Quiet Hours Evaluation**:
   - Calls `public.is_in_quiet_hours(business_id)`.
   - If currently in quiet hours (e.g., 22:30 IST), the item's `scheduled_for` is deferred to the end of quiet hours (e.g., tomorrow 08:00 AM IST) and kept in `queued` status.

4. **In-App Notification Record**:
   - Inserts row into `public.in_app_notifications` with `is_read = FALSE`.

5. **FCM Push Dispatch**:
   - Queries active device tokens from `public.device_tokens` for the business.
   - Dispatches FCM HTTP v1 JSON payload containing `notification` and `data` objects.
   - Upon success, marks queue item as `provider_accepted` or `sent_to_provider` with `sent_at = now()`.
   - Upon invalid token error (`UNREGISTERED`), deactivates token (`is_active = FALSE`).

6. **Error Handling & Backoff**:
   - On transient failure, increments `retry_count` and reschedules using exponential backoff:
     $$\Delta t = 2^{\text{retry\_count}} \times 5\text{ minutes}$$
   - On reaching `max_retries`, marks status as `failed`.

---

## 4. Scheduling Options

### Option A: Supabase `pg_cron` (Self-hosted or Pro)
```sql
-- Enqueue advance reminder notices every hour
SELECT cron.schedule(
    'generate-advance-reminders',
    '0 * * * *',
    $$
    -- Call stored procedure to enqueue advance reminders
    SELECT public.reconcile_all_pending_reminders();
    $$
);

-- Trigger notification dispatcher every 5 minutes
SELECT cron.schedule(
    'dispatch-notification-queue',
    '*/5 * * * *',
    $$
    SELECT
      net.http_post(
          url := 'https://<project-ref>.supabase.co/functions/v1/process-notifications',
          headers := jsonb_build_object(
              'Content-Type', 'application/json',
              'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
          ),
          body := '{}'::jsonb
      );
    $$
);
```

### Option B: External Cron (GitHub Actions / Cloud Scheduler)
Make an HTTP POST request to:
```bash
POST https://<project-ref>.supabase.co/functions/v1/process-notifications
Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
Content-Type: application/json
```
Schedule frequency: Every 5 or 15 minutes.

