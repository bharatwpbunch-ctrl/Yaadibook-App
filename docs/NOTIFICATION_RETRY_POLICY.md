# Yaadibook — Notification Retry Policy & Error Handling

## 1. Principles of Reliable Delivery

Push notifications rely on external infrastructure (network carriers, Firebase Cloud Messaging, device power-management systems). To guarantee that notifications are not lost during network blips while preventing notification storms, Yaadibook enforces a clear retry policy.

---

## 2. Queue Item Status Progression

```
                   ┌────────────┐
                   │   queued   │◄──────────────┐
                   └─────┬──────┘               │
                         │                      │
             ┌───────────┴───────────┐          │
             ▼                       ▼          │
  ┌────────────────────┐   ┌──────────────────┐ │ Transient Error
  │  sent_to_provider  │   │      failed      │ │ (retry_count < 3)
  └──────────┬─────────┘   │ (Terminal error) │ │
             │             └──────────────────┘ │
             ▼                                  │
  ┌────────────────────┐                        │
  │ provider_accepted  │                        │
  └──────────┬─────────┘                        │
             │ (Network transient)              │
             └──────────────────────────────────┘
```

---

## 3. Retry Schedule & Exponential Backoff

| Attempt | Delay from Previous Failure | Action |
|---|---|---|
| Initial | Immediate / `scheduled_for` | Send to FCM endpoint. |
| Retry 1 | $+5$ minutes ($2^0 \times 5$ min) | Retry dispatch. |
| Retry 2 | $+10$ minutes ($2^1 \times 5$ min) | Retry dispatch. |
| Retry 3 | $+20$ minutes ($2^2 \times 5$ min) | Final retry attempt. |
| Exhausted | N/A | Status transitions to `failed`; error logged in `last_error`. |

---

## 4. Idempotency & Deduplication

To prevent duplicate push alerts for the same business event (e.g. if a cron runs twice or a job overlaps), each queue item enforces a unique constraint on `deduplication_key`:

### Deduplication Key Formats
- **Maintenance Advance Reminder**:
  `remind:maint:<occurrence_id>:<advance_days>d`
  *Example*: `remind:maint:e8b9f123-4567-89ab-cdef-0123456789ab:3d`
- **AMC Renewal Advance Reminder**:
  `remind:amc:<contract_id>:<advance_days>d`
  *Example*: `remind:amc:f9c0e234-5678-90bc-def0-123456789abc:15d`
- **Manual Reminder Due Date**:
  `remind:manual:<reminder_id>:<due_timestamp_utc>`
  *Example*: `remind:manual:a1b2c3d4-e5f6-7890-abcd-ef0123456789:20261107T033000Z`

Any attempt to insert a duplicate key is rejected by PostgreSQL via `ON CONFLICT (deduplication_key) DO NOTHING`.

---

## 5. Token Invalidation & Cleanup

When FCM rejects a dispatch with error code:
- `messaging/registration-token-not-registered`
- `UNREGISTERED`
- `INVALID_ARGUMENT`

The Edge Function immediately sets:
```sql
UPDATE public.device_tokens 
SET is_active = FALSE, updated_at = timezone('utc', now())
WHERE fcm_token = $fcm_token;
```
This ensures dead tokens do not generate repeated retries or cloud egress charges.

