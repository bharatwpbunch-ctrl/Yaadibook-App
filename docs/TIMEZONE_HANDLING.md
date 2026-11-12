# Yaadibook — Timezone Handling & Quiet Hours Architecture

## 1. Context & Standard

Yaadibook is tailored for local service businesses across India.
- **Canonical Database Timezone**: UTC (`TIMESTAMPTZ`). All timestamps are stored and indexed in UTC.
- **Canonical Business Timezone**: Indian Standard Time (`Asia/Kolkata`, UTC+05:30).
- No Daylight Saving Time (DST) exists in India, which simplifies calculation, but boundary math across midnight (e.g. 22:00 to 08:00) requires precise handling.

---

## 2. Quiet Hours Specification

Quiet Hours silence notifications during nighttime to respect business owners' rest periods.

### Default Quiet Hours Configuration
- **Start**: `22:00:00` (10:00 PM IST)
- **End**: `08:00:00` (08:00 AM IST)
- **Enabled**: `true` by default

Because `22:00:00` is greater than `08:00:00`, the window crosses midnight.

### Stored Procedure: `public.is_in_quiet_hours`
```sql
CREATE OR REPLACE FUNCTION public.is_in_quiet_hours(p_business_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_prefs public.notification_preferences;
    v_now_ist TIME;
BEGIN
    SELECT * INTO v_prefs FROM public.notification_preferences WHERE business_id = p_business_id;
    IF NOT FOUND OR NOT v_prefs.quietHoursEnabled THEN
        RETURN FALSE;
    END IF;

    -- Current time converted to Asia/Kolkata timezone
    v_now_ist := (now() AT TIME ZONE 'Asia/Kolkata')::time;

    -- If quiet hours window crosses midnight (e.g. 22:00 to 08:00)
    IF v_prefs.quietHoursStart > v_prefs.quietHoursEnd THEN
        IF v_now_ist >= v_prefs.quietHoursStart OR v_now_ist < v_prefs.quietHoursEnd THEN
            RETURN TRUE;
        END IF;
    ELSE
        -- Same day quiet hours window (e.g. 13:00 to 15:00)
        IF v_now_ist >= v_prefs.quietHoursStart AND v_now_ist < v_prefs.quietHoursEnd THEN
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;
END;
$$;
```

---

## 3. Quiet Hours Deferral Strategy

When a scheduled notification becomes eligible during Quiet Hours:
1. The Edge Function runs `is_in_quiet_hours(business_id)`.
2. If `TRUE`:
   - The notification is **not** discarded or marked failed.
   - The notification's `scheduled_for` timestamp is shifted forward to the end of quiet hours (today/tomorrow at `quiet_hours_end` in IST, converted to UTC).
   - Status remains `queued`.
3. At `08:00:00` IST, the morning dispatch job runs and delivers all deferred alerts cleanly.

---

## 4. Client-Side Timezone Display

In the Flutter application:
- `intl` package formats all timestamps using the device's local timezone (or Indian Standard Time).
- Time pickers for reminders default to 09:00 AM IST for new reminders.
- Snooze shortcuts ("Tomorrow 9:00 AM") construct explicit `DateTime(now.year, now.month, now.day + 1, 9, 0)`.

