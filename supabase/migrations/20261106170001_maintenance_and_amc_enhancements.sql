-- ==============================================================================
-- Migration: 20261106170001_maintenance_and_amc_enhancements.sql
-- Description: Phase 7 Maintenance Plans, Occurrences, AMC Contracts enhancements,
--              reference numbers, recurrence generation, and renewal workflows.
-- ==============================================================================

-- 1. REFERENCE NUMBER GENERATORS (Using public.business_sequences)
CREATE OR REPLACE FUNCTION public.next_maintenance_plan_number(p_business_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_val BIGINT;
BEGIN
  INSERT INTO public.business_sequences (business_id, sequence_type, current_val)
  VALUES (p_business_id, 'maintenance_plan', 1)
  ON CONFLICT (business_id, sequence_type)
  DO UPDATE SET current_val = business_sequences.current_val + 1
  RETURNING current_val INTO v_next_val;

  RETURN 'YB-MP-' || LPAD(v_next_val::TEXT, 6, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.next_amc_contract_number(p_business_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_val BIGINT;
BEGIN
  INSERT INTO public.business_sequences (business_id, sequence_type, current_val)
  VALUES (p_business_id, 'amc_contract', 1)
  ON CONFLICT (business_id, sequence_type)
  DO UPDATE SET current_val = business_sequences.current_val + 1
  RETURNING current_val INTO v_next_val;

  RETURN 'YB-AMC-' || LPAD(v_next_val::TEXT, 6, '0');
END;
$$;


-- 2. EXTEND MAINTENANCE PLANS TABLE
ALTER TABLE public.maintenance_plans
  ADD COLUMN IF NOT EXISTS plan_number TEXT,
  ADD COLUMN IF NOT EXISTS maintenance_type TEXT NOT NULL DEFAULT 'general',
  ADD COLUMN IF NOT EXISTS interval_unit TEXT NOT NULL DEFAULT 'months' CHECK (interval_unit IN ('days', 'weeks', 'months', 'years')),
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS anchor_day INTEGER;

-- Trigger to auto-generate plan_number and extract anchor_day if omitted
CREATE OR REPLACE FUNCTION public.handle_maintenance_plan_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.plan_number IS NULL OR NEW.plan_number = '' THEN
    NEW.plan_number := public.next_maintenance_plan_number(NEW.business_id);
  END IF;

  IF NEW.anchor_day IS NULL THEN
    NEW.anchor_day := EXTRACT(DAY FROM NEW.start_date);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_maintenance_plan_number ON public.maintenance_plans;
CREATE TRIGGER trg_set_maintenance_plan_number
  BEFORE INSERT ON public.maintenance_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_maintenance_plan_number();

CREATE INDEX IF NOT EXISTS idx_maintenance_plans_plan_number ON public.maintenance_plans(business_id, plan_number);


-- 3. EXTEND MAINTENANCE OCCURRENCES TABLE
ALTER TABLE public.maintenance_occurrences
  ADD COLUMN IF NOT EXISTS occurrence_number INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS original_due_date DATE,
  ADD COLUMN IF NOT EXISTS work_performed TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS skip_reason TEXT,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2);

-- Update status check constraint to support all Phase 7 occurrence statuses
ALTER TABLE public.maintenance_occurrences
  DROP CONSTRAINT IF EXISTS maintenance_occurrences_status_check;

ALTER TABLE public.maintenance_occurrences
  ADD CONSTRAINT maintenance_occurrences_status_check
  CHECK (status IN ('scheduled', 'upcoming', 'due', 'overdue', 'completed', 'skipped', 'cancelled'));

-- Trigger to set original_due_date on insert
CREATE OR REPLACE FUNCTION public.handle_maintenance_occurrence_defaults()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.original_due_date IS NULL THEN
    NEW.original_due_date := NEW.due_date;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_maintenance_occurrence_defaults ON public.maintenance_occurrences;
CREATE TRIGGER trg_set_maintenance_occurrence_defaults
  BEFORE INSERT ON public.maintenance_occurrences
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_maintenance_occurrence_defaults();


-- 4. EXTEND AMC CONTRACTS TABLE
ALTER TABLE public.amc_contracts
  ADD COLUMN IF NOT EXISTS number_of_visits INTEGER DEFAULT 4,
  ADD COLUMN IF NOT EXISTS included_services TEXT,
  ADD COLUMN IF NOT EXISTS excluded_services TEXT,
  ADD COLUMN IF NOT EXISTS special_terms TEXT,
  ADD COLUMN IF NOT EXISTS renewal_terms TEXT,
  ADD COLUMN IF NOT EXISTS renewal_date DATE;

-- Trigger to auto-generate contract_number if omitted
CREATE OR REPLACE FUNCTION public.handle_amc_contract_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.contract_number IS NULL OR NEW.contract_number = '' THEN
    NEW.contract_number := public.next_amc_contract_number(NEW.business_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_amc_contract_number ON public.amc_contracts;
CREATE TRIGGER trg_set_amc_contract_number
  BEFORE INSERT ON public.amc_contracts
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_amc_contract_number();

CREATE INDEX IF NOT EXISTS idx_amc_contracts_contract_number ON public.amc_contracts(business_id, contract_number);
CREATE INDEX IF NOT EXISTS idx_amc_contracts_renewed_from ON public.amc_contracts(business_id, renewed_from_contract_id);


-- 5. PURE RECURRENCE CALCULATION FUNCTION (Predictable month-end & leap-year handling)
CREATE OR REPLACE FUNCTION public.calculate_next_maintenance_date(
  p_base_date DATE,
  p_frequency_type TEXT,
  p_interval_value INTEGER,
  p_interval_unit TEXT,
  p_anchor_day INTEGER DEFAULT NULL
)
RETURNS DATE
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_months_to_add INTEGER := 0;
  v_candidate DATE;
  v_anchor INTEGER;
  v_last_day_of_month INTEGER;
BEGIN
  v_anchor := COALESCE(p_anchor_day, EXTRACT(DAY FROM p_base_date)::INTEGER);

  IF p_frequency_type = 'monthly' THEN
    v_months_to_add := 1;
  ELSIF p_frequency_type = 'quarterly' THEN
    v_months_to_add := 3;
  ELSIF p_frequency_type = 'half_yearly' THEN
    v_months_to_add := 6;
  ELSIF p_frequency_type = 'yearly' THEN
    v_months_to_add := 12;
  ELSIF p_frequency_type = 'custom' THEN
    IF p_interval_unit = 'days' THEN
      RETURN p_base_date + (COALESCE(p_interval_value, 30) * INTERVAL '1 day')::INTERVAL;
    ELSIF p_interval_unit = 'weeks' THEN
      RETURN p_base_date + (COALESCE(p_interval_value, 4) * 7 * INTERVAL '1 day')::INTERVAL;
    ELSIF p_interval_unit = 'years' THEN
      v_months_to_add := COALESCE(p_interval_value, 1) * 12;
    ELSE -- 'months'
      v_months_to_add := COALESCE(p_interval_value, 1);
    END IF;
  ELSE
    RETURN NULL;
  END IF;

  -- Add months cleanly
  v_candidate := p_base_date + (v_months_to_add || ' months')::INTERVAL;

  -- Restore anchor day if clamped by a shorter intermediate month
  -- e.g. Jan 31 -> Feb 28 -> Mar 31
  v_last_day_of_month := EXTRACT(DAY FROM (DATE_TRUNC('month', v_candidate) + INTERVAL '1 month - 1 day'))::INTEGER;
  IF v_anchor > EXTRACT(DAY FROM v_candidate) AND v_anchor <= v_last_day_of_month THEN
    v_candidate := DATE_TRUNC('month', v_candidate)::DATE + (v_anchor - 1);
  END IF;

  RETURN v_candidate;
END;
$$;


-- 6. ATOMIC STORED PROCEDURE: COMPLETE MAINTENANCE OCCURRENCE & GENERATE NEXT
CREATE OR REPLACE FUNCTION public.complete_maintenance_occurrence(
  p_occurrence_id UUID,
  p_completion_date DATE,
  p_work_performed TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_amount NUMERIC DEFAULT NULL,
  p_service_entry_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_occ RECORD;
  v_plan RECORD;
  v_next_date DATE;
  v_new_occ_id UUID;
  v_next_occ_number INTEGER;
BEGIN
  -- 1. Fetch occurrence and verify caller ownership
  SELECT * INTO v_occ
  FROM public.maintenance_occurrences
  WHERE id = p_occurrence_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Occurrence % not found', p_occurrence_id;
  END IF;

  IF NOT public.is_business_owner(v_occ.business_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 2. Fetch parent plan
  SELECT * INTO v_plan
  FROM public.maintenance_plans
  WHERE id = v_occ.maintenance_plan_id;

  -- 3. Mark current occurrence completed
  UPDATE public.maintenance_occurrences
  SET
    status = 'completed',
    completed_at = COALESCE(p_completion_date::TIMESTAMPTZ, timezone('utc'::text, now())),
    work_performed = p_work_performed,
    notes = p_notes,
    amount = p_amount,
    completed_service_entry_id = p_service_entry_id,
    updated_at = timezone('utc'::text, now())
  WHERE id = p_occurrence_id;

  -- 4. If plan is one-time, mark plan completed
  IF v_plan.frequency_type = 'one_time' THEN
    UPDATE public.maintenance_plans
    SET status = 'completed', updated_at = timezone('utc'::text, now())
    WHERE id = v_plan.id;

    RETURN jsonb_build_object(
      'status', 'completed',
      'plan_completed', true,
      'next_occurrence_id', null
    );
  END IF;

  -- 5. If plan is paused or cancelled, do not generate next occurrence
  IF v_plan.status IN ('paused', 'cancelled', 'completed') THEN
    RETURN jsonb_build_object(
      'status', 'completed',
      'plan_status', v_plan.status,
      'next_occurrence_id', null
    );
  END IF;

  -- 6. Calculate next due date from scheduled due date
  v_next_date := public.calculate_next_maintenance_date(
    v_occ.due_date,
    v_plan.frequency_type,
    v_plan.interval_value,
    v_plan.interval_unit,
    v_plan.anchor_day
  );

  -- 7. Check if next date exceeds plan end date
  IF v_plan.end_date IS NOT NULL AND v_next_date > v_plan.end_date THEN
    UPDATE public.maintenance_plans
    SET status = 'completed', updated_at = timezone('utc'::text, now())
    WHERE id = v_plan.id;

    RETURN jsonb_build_object(
      'status', 'completed',
      'plan_completed', true,
      'next_occurrence_id', null
    );
  END IF;

  -- 8. Generate next occurrence idempotently
  v_next_occ_number := v_occ.occurrence_number + 1;

  INSERT INTO public.maintenance_occurrences (
    business_id,
    maintenance_plan_id,
    customer_id,
    equipment_id,
    due_date,
    original_due_date,
    reminder_trigger_date,
    occurrence_number,
    status
  )
  VALUES (
    v_plan.business_id,
    v_plan.id,
    v_plan.customer_id,
    v_plan.equipment_id,
    v_next_date,
    v_next_date,
    v_next_date - (v_plan.reminder_days_before || ' days')::INTERVAL,
    v_next_occ_number,
    'scheduled'
  )
  ON CONFLICT (maintenance_plan_id, due_date) DO NOTHING
  RETURNING id INTO v_new_occ_id;

  -- 9. Update plan next_due_date
  UPDATE public.maintenance_plans
  SET next_due_date = v_next_date, updated_at = timezone('utc'::text, now())
  WHERE id = v_plan.id;

  RETURN jsonb_build_object(
    'status', 'completed',
    'plan_completed', false,
    'next_due_date', v_next_date,
    'next_occurrence_id', v_new_occ_id
  );
END;
$$;


-- 7. ATOMIC STORED PROCEDURE: SKIP MAINTENANCE OCCURRENCE & GENERATE NEXT
CREATE OR REPLACE FUNCTION public.skip_maintenance_occurrence(
  p_occurrence_id UUID,
  p_skip_reason TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_occ RECORD;
  v_plan RECORD;
  v_next_date DATE;
  v_new_occ_id UUID;
  v_next_occ_number INTEGER;
BEGIN
  SELECT * INTO v_occ
  FROM public.maintenance_occurrences
  WHERE id = p_occurrence_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Occurrence % not found', p_occurrence_id;
  END IF;

  IF NOT public.is_business_owner(v_occ.business_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT * INTO v_plan
  FROM public.maintenance_plans
  WHERE id = v_occ.maintenance_plan_id;

  -- Mark current occurrence as skipped
  UPDATE public.maintenance_occurrences
  SET
    status = 'skipped',
    skip_reason = p_skip_reason,
    updated_at = timezone('utc'::text, now())
  WHERE id = p_occurrence_id;

  IF v_plan.frequency_type = 'one_time' THEN
    UPDATE public.maintenance_plans
    SET status = 'completed', updated_at = timezone('utc'::text, now())
    WHERE id = v_plan.id;

    RETURN jsonb_build_object('status', 'skipped', 'plan_completed', true, 'next_occurrence_id', null);
  END IF;

  IF v_plan.status IN ('paused', 'cancelled', 'completed') THEN
    RETURN jsonb_build_object('status', 'skipped', 'plan_status', v_plan.status, 'next_occurrence_id', null);
  END IF;

  v_next_date := public.calculate_next_maintenance_date(
    v_occ.due_date,
    v_plan.frequency_type,
    v_plan.interval_value,
    v_plan.interval_unit,
    v_plan.anchor_day
  );

  IF v_plan.end_date IS NOT NULL AND v_next_date > v_plan.end_date THEN
    UPDATE public.maintenance_plans
    SET status = 'completed', updated_at = timezone('utc'::text, now())
    WHERE id = v_plan.id;

    RETURN jsonb_build_object('status', 'skipped', 'plan_completed', true, 'next_occurrence_id', null);
  END IF;

  v_next_occ_number := v_occ.occurrence_number + 1;

  INSERT INTO public.maintenance_occurrences (
    business_id,
    maintenance_plan_id,
    customer_id,
    equipment_id,
    due_date,
    original_due_date,
    reminder_trigger_date,
    occurrence_number,
    status
  )
  VALUES (
    v_plan.business_id,
    v_plan.id,
    v_plan.customer_id,
    v_plan.equipment_id,
    v_next_date,
    v_next_date,
    v_next_date - (v_plan.reminder_days_before || ' days')::INTERVAL,
    v_next_occ_number,
    'scheduled'
  )
  ON CONFLICT (maintenance_plan_id, due_date) DO NOTHING
  RETURNING id INTO v_new_occ_id;

  UPDATE public.maintenance_plans
  SET next_due_date = v_next_date, updated_at = timezone('utc'::text, now())
  WHERE id = v_plan.id;

  RETURN jsonb_build_object(
    'status', 'skipped',
    'plan_completed', false,
    'next_due_date', v_next_date,
    'next_occurrence_id', v_new_occ_id
  );
END;
$$;


-- 8. ATOMIC STORED PROCEDURE: RENEW AMC CONTRACT
CREATE OR REPLACE FUNCTION public.renew_amc_contract(
  p_previous_contract_id UUID,
  p_new_start_date DATE,
  p_new_end_date DATE,
  p_contract_amount NUMERIC DEFAULT 0,
  p_contract_title TEXT DEFAULT NULL,
  p_coverage_details TEXT DEFAULT NULL,
  p_number_of_visits INTEGER DEFAULT NULL,
  p_included_services TEXT DEFAULT NULL,
  p_excluded_services TEXT DEFAULT NULL,
  p_special_terms TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prev RECORD;
  v_new_id UUID;
  v_new_contract_number TEXT;
BEGIN
  -- 1. Fetch previous contract and verify ownership
  SELECT * INTO v_prev
  FROM public.amc_contracts
  WHERE id = p_previous_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Previous contract % not found', p_previous_contract_id;
  END IF;

  IF NOT public.is_business_owner(v_prev.business_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 2. Validate dates
  IF p_new_end_date < p_new_start_date THEN
    RAISE EXCEPTION 'Contract end date must be on or after start date';
  END IF;

  -- 3. Mark previous contract as renewed
  UPDATE public.amc_contracts
  SET
    status = 'renewed',
    renewal_date = CURRENT_DATE,
    updated_at = timezone('utc'::text, now())
  WHERE id = p_previous_contract_id;

  -- 4. Generate next contract number
  v_new_contract_number := public.next_amc_contract_number(v_prev.business_id);

  -- 5. Insert new renewed contract
  INSERT INTO public.amc_contracts (
    business_id,
    customer_id,
    equipment_id,
    contract_title,
    contract_number,
    description,
    start_date,
    end_date,
    contract_amount,
    status,
    coverage_details,
    number_of_visits,
    included_services,
    excluded_services,
    special_terms,
    notes,
    renewed_from_contract_id
  )
  VALUES (
    v_prev.business_id,
    v_prev.customer_id,
    v_prev.equipment_id,
    COALESCE(p_contract_title, v_prev.contract_title),
    v_new_contract_number,
    v_prev.description,
    p_new_start_date,
    p_new_end_date,
    COALESCE(p_contract_amount, v_prev.contract_amount),
    'active',
    COALESCE(p_coverage_details, v_prev.coverage_details),
    COALESCE(p_number_of_visits, v_prev.number_of_visits),
    COALESCE(p_included_services, v_prev.included_services),
    COALESCE(p_excluded_services, v_prev.excluded_services),
    COALESCE(p_special_terms, v_prev.special_terms),
    COALESCE(p_notes, v_prev.notes),
    p_previous_contract_id
  )
  RETURNING id INTO v_new_id;

  RETURN v_new_id;
END;
$$;

