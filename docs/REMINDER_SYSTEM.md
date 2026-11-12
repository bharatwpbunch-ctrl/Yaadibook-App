# Yaadibook — Unified Reminders Architecture

## 1. Executive Summary

In Yaadibook, business owners need a simple, single, unified inbox for all actionable tasks and alerts. Small service businesses in India cannot afford to juggle separate calendars, contract reminder apps, and follow-up notepads. 

The **Unified Reminders System** aggregates all operational obligations into a clean, searchable, filterable workspace (`/reminders`), while maintaining strict data integrity with source records.

---

## 2. Core Architectural Principles

### Rule 1: One Unified Reminder Workspace
Regardless of where a task originates — whether generated from a periodic maintenance visit, an AMC contract expiry, a customer follow-up, or a general note — every item surfaces in the central **Reminders** view.
Owners can filter items by:
- **Status**: `All`, `Due Today`, `Upcoming`, `Overdue`, `Completed`.
- **Source / Category**: `All Sources`, `Maintenance`, `AMC Renewal`, `Follow-ups`, `General Tasks`.
- **Customer**: Filtered by specific customer.

### Rule 2: Source Records are the Canonical Source of Truth
- **Maintenance Reminders** link to `maintenance_occurrences`. Completing a maintenance reminder marks the reminder completed, but completing the underlying technical visit requires updating the occurrence record or creating a service entry.
- **AMC Reminders** link to `amc_contracts`. An AMC renewal reminder alerts the owner to contact the customer; renewing the contract creates a new contract version, automatically updating the reminder state.
- **Customer Follow-up Reminders** link to `customers` (and optionally `services`).

### Rule 3: Reminders are Business Tasks; Notifications are Alerts
- A **reminder** is a persistent, actionable business task.
- A **notification** (push notification or in-app bell notification) is a delivery channel alerting the owner that a reminder is due.
- *Crucially*, receiving or dismissing a notification **does not** mark a reminder completed. Reminders remain pending or overdue until explicitly acted upon by the business owner.

### Rule 4: Server-Side Scheduling Engine
Reminders and notifications are scheduled, reconciled, and queued server-side in Supabase (PostgreSQL stored procedures + Edge Functions). They do not depend on the mobile app running in the foreground or background.

### Rule 5: No False Delivery Statuses
Notification delivery statuses accurately reflect real network progress:
- `queued`: Generated and awaiting processing.
- `sent_to_provider`: Dispatched to Firebase Cloud Messaging (FCM).
- `provider_accepted`: Confirmed accepted by FCM.
- `delivered`: Device receipt acknowledgment.
- `failed`: Provider rejection or network failure with backoff error log.

---

## 3. Data Schema & Relationships

### `public.reminders`
```sql
CREATE TABLE public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    service_id UUID REFERENCES services(id) ON DELETE SET NULL,
    source_type VARCHAR(50) NOT NULL, -- 'manual', 'maintenance_occurrence', 'amc_contract', 'service_followup'
    source_id UUID,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_at TIMESTAMPTZ NOT NULL,
    original_due_at TIMESTAMPTZ,
    snoozed_until TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'snoozed', 'completed', 'cancelled'
    priority VARCHAR(20) NOT NULL DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
    category VARCHAR(50) NOT NULL DEFAULT 'general', -- 'maintenance', 'amc', 'followup', 'payment', 'call', 'visit', 'general'
    action_type VARCHAR(50) DEFAULT 'general_task',
    action_payload JSONB DEFAULT '{}'::jsonb,
    is_auto_generated BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    completed_by_user_id UUID REFERENCES auth.users(id),
    completed_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);
```

---

## 4. Reminder Categories & Priorities

| Category | Icon / Visual Indicator | Description |
|---|---|---|
| `maintenance` | Wrench / Blue | Periodic maintenance checkups generated from recurrence rules. |
| `amc` | Shield / Amber | Annual maintenance contracts nearing expiration or requiring renewal follow-ups. |
| `followup` | Phone / Green | General customer follow-ups (service feedback, quotation check). |
| `payment` | Rupee / Violet | Payment collection reminders. |
| `call` | Phone / Teal | Scheduled call tasks. |
| `visit` | Pin / Orange | Scheduled customer site visits. |
| `general` | Checkmark / Grey | General business errands and personal tasks. |

### Priority Matrix
- **Urgent**: High contrast red badge. Appears at top of Today dashboard and focus items.
- **High**: Orange badge.
- **Normal**: Neutral slate badge.
- **Low**: Subtle grey badge.

---

## 5. Mobile User Experience

- **Reminders Screen (`/reminders`)**:
  - Top summary cards: Due Today, Upcoming, Overdue, Completed.
  - Search bar with instant debounced filtering.
  - Category and status filter chips.
  - Actionable card: One-tap call, WhatsApp message, Snooze sheet, and Mark Complete modal.
  - Deep-link button to underlying source record (e.g., "View Linked AMC Contract" or "View Linked Customer").
- **Quick Add Sheet**:
  - "Create Reminder" option accessible from the global bottom navigation center button.
- **Customer Detail Screen**:
  - Direct "Follow-ups & Reminders" tab with quick "+ Add Follow-up" shortcut pre-filling customer information.
- **Service Detail Screen**:
  - "Schedule Follow-up" shortcut pre-filling customer and service context.

