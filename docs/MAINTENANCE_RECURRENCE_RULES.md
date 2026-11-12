# Yaadibook — Maintenance Recurrence & Calendar Rules

## 1. Problem Statement: Month-End Drift

A critical defect in recurring schedule engines is calendar date drift when intervals involve months of variable length (28, 29, 30, and 31 days).

For example, consider a customer maintenance plan scheduled on the **31st of January**:
- If naively adding 1 month:
  - January 31 + 1 month -> February 28 (or 29 in leap years).
- If subsequent months are calculated from the previous date:
  - February 28 + 1 month -> **March 28** (loss of 3 days!).
  - March 28 + 1 month -> **April 28**.
  - May 28, June 28...

The customer's schedule permanently drifts from the 31st to the 28th.

---

## 2. The Anchor Day Solution

Yaadibook solves month-end drift by storing an immutable `anchor_day` integer on the `maintenance_plans` table:

```sql
anchor_day INTEGER NOT NULL CHECK (anchor_day BETWEEN 1 AND 31)
```

When calculating the next occurrence date:
1. Pure calendar month addition is performed.
2. The day is clamped to the target month's maximum day (e.g. 28 for February).
3. If the subsequent target month has more days (e.g. 31 for March), the date is restored up to `anchor_day`.

### Verification Table

| Schedule Start | Frequency | Anchor Day | Occurrence #1 | Occurrence #2 | Occurrence #3 | Occurrence #4 |
|:---|:---|:---:|:---|:---|:---|:---|
| 31 Jan 2026 | Monthly | 31 | 31 Jan 2026 | 28 Feb 2026 *(clamped)* | **31 Mar 2026** *(restored)* | 30 Apr 2026 *(clamped)* |
| 31 Jan 2028 *(Leap)* | Monthly | 31 | 31 Jan 2028 | 29 Feb 2028 *(clamped)* | **31 Mar 2028** *(restored)* | 30 Apr 2028 *(clamped)* |
| 30 Aug 2026 | Quarterly | 30 | 30 Aug 2026 | 30 Nov 2026 | 28 Feb 2027 *(clamped)* | **30 May 2027** *(restored)* |
| 15 Jan 2026 | Half-Yearly | 15 | 15 Jan 2026 | 15 Jul 2026 | 15 Jan 2027 | 15 Jul 2027 |

---

## 3. Database Implementation: Pure Immutable Function

The calculation is implemented as a PostgreSQL stored procedure in `supabase/migrations/20261106170001_maintenance_and_amc_enhancements.sql`:

```sql
CREATE OR REPLACE FUNCTION public.calculate_next_maintenance_date(
  p_base_date DATE,
  p_frequency_type TEXT,
  p_interval_value INTEGER DEFAULT 1,
  p_interval_unit TEXT DEFAULT 'months',
  p_anchor_day INTEGER DEFAULT NULL
)
RETURNS DATE
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_months_to_add INTEGER;
  v_anchor INTEGER;
  v_candidate DATE;
  v_last_day_of_month INTEGER;
BEGIN
  IF p_frequency_type = 'one_time' THEN
    RETURN p_base_date;
  END IF;

  IF p_frequency_type = 'custom' AND p_interval_unit = 'days' THEN
    RETURN p_base_date + (COALESCE(p_interval_value, 1) || ' days')::INTERVAL;
  ELSIF p_frequency_type = 'custom' AND p_interval_unit = 'weeks' THEN
    RETURN p_base_date + ((COALESCE(p_interval_value, 1) * 7) || ' days')::INTERVAL;
  END IF;

  v_anchor := COALESCE(p_anchor_day, EXTRACT(DAY FROM p_base_date)::INTEGER);

  IF p_frequency_type = 'monthly' THEN
    v_months_to_add := 1;
  ELSIF p_frequency_type = 'quarterly' THEN
    v_months_to_add := 3;
  ELSIF p_frequency_type = 'half_yearly' THEN
    v_months_to_add := 6;
  ELSIF p_frequency_type = 'yearly' THEN
    v_months_to_add := 12;
  ELSIF p_frequency_type = 'custom' AND p_interval_unit = 'years' THEN
    v_months_to_add := COALESCE(p_interval_value, 1) * 12;
  ELSIF p_frequency_type = 'custom' AND p_interval_unit = 'months' THEN
    v_months_to_add := COALESCE(p_interval_value, 1);
  ELSE
    RETURN NULL;
  END IF;

  -- Add months cleanly
  v_candidate := p_base_date + (v_months_to_add || ' months')::INTERVAL;

  -- Restore anchor day if clamped by a shorter intermediate month
  v_last_day_of_month := EXTRACT(DAY FROM (DATE_TRUNC('month', v_candidate) + INTERVAL '1 month - 1 day'))::INTEGER;
  IF v_anchor > EXTRACT(DAY FROM v_candidate) AND v_anchor <= v_last_day_of_month THEN
    v_candidate := DATE_TRUNC('month', v_candidate)::DATE + (v_anchor - 1);
  END IF;

  RETURN v_candidate;
END;
$$;
```

---

## 4. Automatic Next Occurrence Generation

When an occurrence is completed or skipped:
1. `complete_maintenance_occurrence` or `skip_maintenance_occurrence` stored procedure is invoked transactionally.
2. If `frequency_type == 'one_time'` or `plan.status != 'active'`, the plan is marked completed without generating next visits.
3. If `end_date` is specified and `next_date > end_date`, the plan transitions to `completed`.
4. Otherwise, the next occurrence is inserted idempotently with `ON CONFLICT (maintenance_plan_id, due_date) DO NOTHING`.
5. The plan's `next_due_date` is updated to the newly generated visit date.

