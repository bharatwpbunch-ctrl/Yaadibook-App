# Yaadibook — Notification System Architecture

## 1. Overview

The Yaadibook Notification System provides reliable delivery of alerts to business owners across two complementary surfaces:
1. **In-App Notification Centre (`/notifications`)**: Persistent notification log inside the app with unread tracking, category badges, and mark-as-read actions.
2. **Push Notifications (Android FCM)**: System-tray push alerts via Firebase Cloud Messaging so owners receive timely alerts even when the app is completely closed.

---

## 2. Notification Pipeline & Architecture

```
┌─────────────────────────────────┐
│     Reminders / Occurrences     │
│   (Due / Expiring / Follow-up)  │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│   Notification Queue (Postgres) │
│    status = 'queued', eligible  │
└────────────────┬────────────────┘
                 │
                 ▼ (Scheduled Cron / Webhook)
┌─────────────────────────────────┐
│     Supabase Edge Function      │
│     "process-notifications"     │
└────────┬───────────────┬────────┘
         │               │
         ▼               ▼
┌─────────────────┐  ┌──────────────────────┐
│ In-App Notifs   │  │ Firebase Cloud Msg   │
│ (PostgreSQL)    │  │ (FCM HTTP v1 API)    │
└─────────────────┘  └──────────┬───────────┘
                                │
                                ▼
                     ┌──────────────────────┐
                     │ Owner Android Device │
                     └──────────────────────┘
```

---

## 3. Database Schema

### `public.device_tokens`
Stores FCM device tokens registered by the mobile client:
```sql
CREATE TABLE public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL DEFAULT 'android',
    device_name VARCHAR(100),
    device_id VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_device_token UNIQUE (business_id, fcm_token)
);
```

### `public.in_app_notifications`
Persistent in-app notification records surfaced in Notification Centre:
```sql
CREATE TABLE public.in_app_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    reminder_id UUID REFERENCES reminders(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    payload JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);
```

### `public.notification_queue`
Server-side dispatch queue with delivery tracking:
```sql
CREATE TABLE public.notification_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    reminder_id UUID REFERENCES reminders(id) ON DELETE CASCADE,
    device_token_id UUID REFERENCES device_tokens(id) ON DELETE SET NULL,
    notification_type VARCHAR(50) NOT NULL, -- 'push', 'in_app'
    status VARCHAR(50) NOT NULL DEFAULT 'queued', 
    scheduled_for TIMESTAMPTZ NOT NULL,
    retry_count INT NOT NULL DEFAULT 0,
    max_retries INT NOT NULL DEFAULT 3,
    last_error TEXT,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    deduplication_key VARCHAR(150),
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_notification_dedup UNIQUE (deduplication_key)
);
```

### `public.notification_preferences`
Business-level notification controls and quiet hours:
```sql
CREATE TABLE public.notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE UNIQUE,
    push_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    maintenance_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    amc_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    followup_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    general_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    maintenance_advance_days INT[] NOT NULL DEFAULT ARRAY[7, 3, 1, 0],
    amc_advance_days INT[] NOT NULL DEFAULT ARRAY[30, 15, 7, 1, 0],
    quiet_hours_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_start TIME NOT NULL DEFAULT '22:00:00',
    quiet_hours_end TIME NOT NULL DEFAULT '08:00:00',
    preferred_notification_time TIME NOT NULL DEFAULT '09:00:00',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);
```

---

## 4. Delivery Statuses (No False Success)

Status progressions:
- `queued`: Record written to queue, scheduled for future dispatch or eligible immediately.
- `sent_to_provider`: Payload dispatched over network to FCM HTTP API.
- `provider_accepted`: FCM responded with 200 OK and message ID.
- `delivered`: Device receipt acknowledgment (reported via app callback).
- `failed`: Terminal failure or max retries exhausted.
- `cancelled`: Linked reminder completed or cancelled before dispatch.

---

## 5. Notification Preferences Screen (`/settings/notifications`)

Owners have complete control over:
- Master switch: Push Notifications.
- Category switches: Maintenance, AMC, Follow-ups, General Tasks.
- Multi-select chips for advance reminder offsets (e.g. 7 days before, 1 day before, day of visit).
- Quiet Hours: Night silence period with customizable start and end times (default 10:00 PM to 08:00 AM IST).

