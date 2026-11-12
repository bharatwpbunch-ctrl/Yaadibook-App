-- ==============================================================================
-- Migration: 20261112000001_maintenance_amc_rpc_and_reminder_fixes.sql
-- Description: Ensures sequence helper RPCs exist and fixes reconcile_amc_contract_reminders
--              to reference contract_title instead of nonexistent plan_name.
-- ==============================================================================

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

CREATE OR REPLACE FUNCTION public.reconcile_amc_contract_reminders(p_contract_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_amc RECORD;
  v_cust RECORD;
  v_prefs RECORD;
  v_reminder_id UUID;
  v_due_timestamp TIMESTAMPTZ;
  v_title TEXT;
  v_body TEXT;
  v_offset INTEGER;
  v_sched_time TIMESTAMPTZ;
BEGIN
  SELECT * INTO v_amc FROM public.amc_contracts WHERE id = p_contract_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- If contract is cancelled or superseded by renewal, cancel pending reminders
  IF v_amc.status IN ('renewed', 'cancelled') THEN
    UPDATE public.reminders
    SET status = 'cancelled', updated_at = NOW()
    WHERE amc_contract_id = p_contract_id AND status NOT IN ('completed', 'cancelled');

    UPDATE public.notification_queue
    SET status = 'cancelled', updated_at = NOW()
    WHERE reminder_id IN (SELECT id FROM public.reminders WHERE amc_contract_id = p_contract_id)
      AND status = 'queued';

    RETURN NULL;
  END IF;

  SELECT * INTO v_cust FROM public.customers WHERE id = v_amc.customer_id;
  SELECT * INTO v_prefs FROM public.notification_preferences WHERE business_id = v_amc.business_id;

  v_due_timestamp := (v_amc.end_date::text || ' ' || COALESCE(v_prefs.preferred_notification_time, '09:00:00'::TIME)::text)::timestamp AT TIME ZONE 'Asia/Kolkata';

  v_title := 'AMC Expiry: ' || COALESCE(v_amc.contract_title, 'Annual Contract');
  v_body := 'AMC contract for ' || COALESCE(v_cust.full_name, 'customer') || ' expires on ' || v_amc.end_date::text || '. Follow up for renewal.';

  SELECT id INTO v_reminder_id FROM public.reminders WHERE amc_contract_id = p_contract_id LIMIT 1;

  IF v_reminder_id IS NULL THEN
    INSERT INTO public.reminders (
      business_id,
      customer_id,
      amc_contract_id,
      title,
      description,
      reminder_type,
      priority,
      category,
      due_at,
      status
    ) VALUES (
      v_amc.business_id,
      v_amc.customer_id,
      p_contract_id,
      v_title,
      v_body,
      'amc',
      'high',
      'customer_followup',
      v_due_timestamp,
      'scheduled'
    ) RETURNING id INTO v_reminder_id;
  ELSE
    UPDATE public.reminders
    SET due_at = v_due_timestamp,
        title = v_title,
        description = v_body,
        status = 'scheduled',
        updated_at = NOW()
    WHERE id = v_reminder_id;
  END IF;

  FOREACH v_offset IN ARRAY COALESCE(v_prefs.amc_advance_days, ARRAY[30, 7, 1, 0])
  LOOP
    v_sched_time := v_due_timestamp - (v_offset || ' days')::INTERVAL;
    IF v_sched_time >= NOW() - INTERVAL '1 hour' THEN
      INSERT INTO public.notification_queue (
        business_id,
        reminder_id,
        idempotency_key,
        notification_type,
        title,
        body,
        scheduled_for,
        payload
      ) VALUES (
        v_amc.business_id,
        v_reminder_id,
        'amc_' || p_contract_id::text || '_offset_' || v_offset::text || '_' || v_amc.end_date::text,
        'amc',
        CASE WHEN v_offset = 0 THEN 'AMC Contract Expires Today' ELSE 'AMC Contract Expiring in ' || v_offset || ' Days' END,
        v_body,
        v_sched_time,
        jsonb_build_object('contract_id', p_contract_id, 'offset_days', v_offset, 'end_date', v_amc.end_date)
      )
      ON CONFLICT (idempotency_key) DO UPDATE
      SET scheduled_for = v_sched_time, status = 'queued', updated_at = NOW();
    END IF;
  END LOOP;

  RETURN v_reminder_id;
END;
$$;

