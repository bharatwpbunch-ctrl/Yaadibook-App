-- ==============================================================================
-- Migration: 20261106180001_unified_reminders_and_notifications.sql
-- Description: Phase 8 Unified Reminders, In-App Notifications, Notification Queue & FCM Device Tokens
-- ==============================================================================

-- 1. ENHANCE PUBLIC.REMINDERS TABLE
-- Allow 'snoozed' in status check and add snoozing, priority, category & audit fields

-- Drop existing status check constraint to expand supported statuses
ALTER TABLE public.reminders DROP CONSTRAINT IF EXISTS reminders_status_check;
ALTER TABLE public.reminders ADD CONSTRAINT reminders_status_check
  CHECK (status IN ('scheduled', 'due', 'overdue', 'completed', 'snoozed', 'cancelled'));

-- Add new columns safely if they do not already exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'snoozed_until') THEN
    ALTER TABLE public.reminders ADD COLUMN snoozed_until TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'original_due_at') THEN
    ALTER TABLE public.reminders ADD COLUMN original_due_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'priority') THEN
    ALTER TABLE public.reminders ADD COLUMN priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'category') THEN
    ALTER TABLE public.reminders ADD COLUMN category TEXT NOT NULL DEFAULT 'general_task' CHECK (category IN ('customer_followup', 'call_customer', 'payment_followup', 'visit_customer', 'general_task', 'other'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'service_id') THEN
    ALTER TABLE public.reminders ADD COLUMN service_id UUID REFERENCES public.service_entries(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'completed_notes') THEN
    ALTER TABLE public.reminders ADD COLUMN completed_notes TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reminders' AND column_name = 'completed_by_user_id') THEN
    ALTER TABLE public.reminders ADD COLUMN completed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reminders_snoozed_until ON public.reminders(business_id, snoozed_until) WHERE snoozed_until IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reminders_priority ON public.reminders(business_id, priority);
CREATE INDEX IF NOT EXISTS idx_reminders_category ON public.reminders(business_id, category);


-- 2. ENHANCE PUBLIC.NOTIFICATION_PREFERENCES TABLE
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'push_notifications_enabled') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN push_notifications_enabled BOOLEAN NOT NULL DEFAULT true;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'general_notifications_enabled') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN general_notifications_enabled BOOLEAN NOT NULL DEFAULT true;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'maintenance_advance_days') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN maintenance_advance_days INTEGER[] NOT NULL DEFAULT '{7, 1, 0}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'amc_advance_days') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN amc_advance_days INTEGER[] NOT NULL DEFAULT '{30, 7, 1, 0}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'quiet_hours_enabled') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN quiet_hours_enabled BOOLEAN NOT NULL DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'quiet_hours_start') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN quiet_hours_start TIME NOT NULL DEFAULT '22:00:00';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notification_preferences' AND column_name = 'quiet_hours_end') THEN
    ALTER TABLE public.notification_preferences ADD COLUMN quiet_hours_end TIME NOT NULL DEFAULT '08:00:00';
  END IF;
END $$;


-- 3. DEVICE TOKENS TABLE (FCM registration for multi-device owners)
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'ios', 'web')),
  device_name TEXT,
  device_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_device_tokens_user_fcm UNIQUE (user_id, fcm_token)
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_device_tokens_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_device_tokens_business_active ON public.device_tokens(business_id, is_active);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_tokens(user_id);

CREATE POLICY "Users can view own device tokens"
  ON public.device_tokens
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() AND public.is_business_owner(business_id));

CREATE POLICY "Users can insert own device tokens"
  ON public.device_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid() AND public.is_business_owner(business_id));

CREATE POLICY "Users can update own device tokens"
  ON public.device_tokens
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid() AND public.is_business_owner(business_id))
  WITH CHECK (user_id = auth.uid() AND public.is_business_owner(business_id));

CREATE POLICY "Users can delete own device tokens"
  ON public.device_tokens
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() AND public.is_business_owner(business_id));


-- 4. IN-APP NOTIFICATIONS TABLE (Notification Centre)
CREATE TABLE IF NOT EXISTS public.in_app_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_id UUID REFERENCES public.reminders(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('maintenance', 'amc', 'followup', 'general', 'system')),
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  provider_status TEXT NOT NULL DEFAULT 'queued' CHECK (provider_status IN ('queued', 'sent_to_provider', 'provider_accepted', 'delivered', 'failed')),
  provider_message_id TEXT,
  failure_reason TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.in_app_notifications ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_in_app_notifications_business_read ON public.in_app_notifications(business_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_in_app_notifications_reminder ON public.in_app_notifications(reminder_id);

CREATE POLICY "Owners can view own notifications"
  ON public.in_app_notifications
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own notifications"
  ON public.in_app_notifications
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own notifications"
  ON public.in_app_notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own notifications"
  ON public.in_app_notifications
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 5. NOTIFICATION QUEUE TABLE (Server-side scheduled processing engine)
CREATE TABLE IF NOT EXISTS public.notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_id UUID REFERENCES public.reminders(id) ON DELETE CASCADE,
  idempotency_key TEXT NOT NULL UNIQUE,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('maintenance', 'amc', 'followup', 'general')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  scheduled_for TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'sent', 'failed', 'cancelled', 'deferred_quiet_hours')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  last_attempt_at TIMESTAMPTZ,
  next_retry_at TIMESTAMPTZ,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_notification_queue_updated_at
  BEFORE UPDATE ON public.notification_queue
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_notification_queue_status_sched ON public.notification_queue(status, scheduled_for) WHERE status IN ('queued', 'failed', 'deferred_quiet_hours');
CREATE INDEX IF NOT EXISTS idx_notification_queue_reminder ON public.notification_queue(reminder_id);

CREATE POLICY "Owners can view own notification queue"
  ON public.notification_queue
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can manage own notification queue"
  ON public.notification_queue
  FOR ALL
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 6. STORED PROCEDURES & BUSINESS FUNCTIONS

-- 6.1 Check Quiet Hours Helper Function
CREATE OR REPLACE FUNCTION public.is_in_quiet_hours(
  p_business_id UUID,
  p_target_time TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prefs RECORD;
  v_local_time TIME;
BEGIN
  SELECT * INTO v_prefs FROM public.notification_preferences WHERE business_id = p_business_id;
  IF NOT FOUND OR NOT v_prefs.quiet_hours_enabled THEN
    RETURN FALSE;
  END IF;

  -- Convert UTC timestamp to Asia/Kolkata local time for quiet hours check
  v_local_time := (p_target_time AT TIME ZONE 'Asia/Kolkata')::TIME;

  IF v_prefs.quiet_hours_start < v_prefs.quiet_hours_end THEN
    -- e.g. 01:00 to 07:00
    RETURN (v_local_time >= v_prefs.quiet_hours_start AND v_local_time <= v_prefs.quiet_hours_end);
  ELSE
    -- e.g. 22:00 to 08:00 (spans midnight)
    RETURN (v_local_time >= v_prefs.quiet_hours_start OR v_local_time <= v_prefs.quiet_hours_end);
  END IF;
END;
$$;


-- 6.2 Snooze Reminder Procedure
CREATE OR REPLACE FUNCTION public.snooze_reminder(
  p_reminder_id UUID,
  p_snooze_until TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rem RECORD;
BEGIN
  SELECT * INTO v_rem FROM public.reminders WHERE id = p_reminder_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reminder % not found', p_reminder_id;
  END IF;

  -- Verify caller ownership
  IF NOT public.is_business_owner(v_rem.business_id) THEN
    RAISE EXCEPTION 'Unauthorized to snooze reminder';
  END IF;

  UPDATE public.reminders
  SET status = 'snoozed',
      snoozed_until = p_snooze_until,
      original_due_at = COALESCE(original_due_at, due_at),
      due_at = p_snooze_until,
      updated_at = NOW()
  WHERE id = p_reminder_id;

  -- Reconcile notification queue: cancel existing pending queue items and queue new snoozed delivery
  UPDATE public.notification_queue
  SET status = 'cancelled', updated_at = NOW()
  WHERE reminder_id = p_reminder_id AND status = 'queued';

  INSERT INTO public.notification_queue (
    business_id,
    user_id,
    reminder_id,
    idempotency_key,
    notification_type,
    title,
    body,
    scheduled_for,
    payload
  ) VALUES (
    v_rem.business_id,
    auth.uid(),
    p_reminder_id,
    'rem_' || p_reminder_id::text || '_snooze_' || EXTRACT(EPOCH FROM p_snooze_until)::text,
    v_rem.reminder_type,
    v_rem.title,
    COALESCE(v_rem.description, 'Snoozed reminder due now'),
    p_snooze_until,
    jsonb_build_object('reminder_id', p_reminder_id, 'is_snoozed', true)
  )
  ON CONFLICT (idempotency_key) DO UPDATE
  SET scheduled_for = p_snooze_until, status = 'queued', updated_at = NOW();
END;
$$;


-- 6.3 Complete Reminder Procedure
CREATE OR REPLACE FUNCTION public.complete_reminder(
  p_reminder_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rem RECORD;
BEGIN
  SELECT * INTO v_rem FROM public.reminders WHERE id = p_reminder_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reminder % not found', p_reminder_id;
  END IF;

  IF NOT public.is_business_owner(v_rem.business_id) THEN
    RAISE EXCEPTION 'Unauthorized to complete reminder';
  END IF;

  UPDATE public.reminders
  SET status = 'completed',
      completed_at = NOW(),
      completed_notes = p_notes,
      completed_by_user_id = auth.uid(),
      updated_at = NOW()
  WHERE id = p_reminder_id;

  -- Cancel future pending notification queue items for this reminder
  UPDATE public.notification_queue
  SET status = 'cancelled', updated_at = NOW()
  WHERE reminder_id = p_reminder_id AND status = 'queued';
END;
$$;


-- 6.4 Reconcile Maintenance Occurrence Reminder
CREATE OR REPLACE FUNCTION public.reconcile_maintenance_occurrence_reminder(
  p_occurrence_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_occ RECORD;
  v_plan RECORD;
  v_cust RECORD;
  v_prefs RECORD;
  v_reminder_id UUID;
  v_due_timestamp TIMESTAMPTZ;
  v_offset INTEGER;
  v_sched_time TIMESTAMPTZ;
  v_title TEXT;
  v_body TEXT;
BEGIN
  SELECT * INTO v_occ FROM public.maintenance_occurrences WHERE id = p_occurrence_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_plan FROM public.maintenance_plans WHERE id = v_occ.maintenance_plan_id;
  SELECT * INTO v_cust FROM public.customers WHERE id = v_occ.customer_id;
  SELECT * INTO v_prefs FROM public.notification_preferences WHERE business_id = v_occ.business_id;

  -- If occurrence is completed, skipped or cancelled, resolve reminder
  IF v_occ.status IN ('completed', 'skipped', 'cancelled') THEN
    UPDATE public.reminders
    SET status = CASE WHEN v_occ.status = 'completed' THEN 'completed' ELSE 'cancelled' END,
        completed_at = CASE WHEN v_occ.status = 'completed' THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE maintenance_occurrence_id = p_occurrence_id AND status NOT IN ('completed', 'cancelled');

    UPDATE public.notification_queue
    SET status = 'cancelled', updated_at = NOW()
    WHERE reminder_id IN (SELECT id FROM public.reminders WHERE maintenance_occurrence_id = p_occurrence_id)
      AND status = 'queued';

    RETURN NULL;
  END IF;

  -- Calculate due timestamp at business notification time (default 09:00:00 Asia/Kolkata)
  v_due_timestamp := (v_occ.due_date::text || ' ' || COALESCE(v_prefs.preferred_notification_time, '09:00:00'::TIME)::text)::timestamp AT TIME ZONE 'Asia/Kolkata';

  v_title := 'Maintenance Due: ' || COALESCE(v_plan.title, 'Scheduled Service');
  v_body := 'Maintenance service due for ' || COALESCE(v_cust.full_name, 'customer') || ' on ' || v_occ.due_date::text;

  -- Upsert single actionable reminder linked to this occurrence
  SELECT id INTO v_reminder_id FROM public.reminders WHERE maintenance_occurrence_id = p_occurrence_id;

  IF v_reminder_id IS NULL THEN
    INSERT INTO public.reminders (
      business_id,
      customer_id,
      maintenance_occurrence_id,
      title,
      description,
      reminder_type,
      priority,
      category,
      due_at,
      status
    ) VALUES (
      v_occ.business_id,
      v_occ.customer_id,
      p_occurrence_id,
      v_title,
      v_body,
      'maintenance',
      'high',
      'visit_customer',
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

  -- Queue notifications based on owner's configured advance offsets (e.g. 7 days, 1 day, 0 days)
  FOREACH v_offset IN ARRAY COALESCE(v_prefs.maintenance_advance_days, ARRAY[7, 1, 0])
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
        v_occ.business_id,
        v_reminder_id,
        'maint_' || p_occurrence_id::text || '_offset_' || v_offset::text || '_' || v_occ.due_date::text,
        'maintenance',
        CASE WHEN v_offset = 0 THEN 'Maintenance Due Today' ELSE 'Upcoming Maintenance in ' || v_offset || ' Days' END,
        v_body,
        v_sched_time,
        jsonb_build_object('occurrence_id', p_occurrence_id, 'offset_days', v_offset, 'due_date', v_occ.due_date)
      )
      ON CONFLICT (idempotency_key) DO UPDATE
      SET scheduled_for = v_sched_time, status = 'queued', updated_at = NOW();
    END IF;
  END LOOP;

  RETURN v_reminder_id;
END;
$$;


-- 6.5 Reconcile AMC Contract Reminders
CREATE OR REPLACE FUNCTION public.reconcile_amc_contract_reminders(
  p_contract_id UUID
)
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
  v_offset INTEGER;
  v_sched_time TIMESTAMPTZ;
  v_title TEXT;
  v_body TEXT;
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

  SELECT id INTO v_reminder_id FROM public.reminders WHERE amc_contract_id = p_contract_id;

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

  -- Queue notifications based on owner's configured AMC advance offsets (e.g. 30, 7, 1, 0 days)
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


-- 6.6 Register Device Token
CREATE OR REPLACE FUNCTION public.register_device_token(
  p_fcm_token TEXT,
  p_platform TEXT DEFAULT 'android',
  p_device_name TEXT DEFAULT NULL,
  p_device_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_biz_id UUID;
  v_token_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_biz_id FROM public.businesses WHERE owner_user_id = auth.uid() LIMIT 1;
  IF v_biz_id IS NULL THEN
    RAISE EXCEPTION 'User does not have an active business workspace';
  END IF;

  INSERT INTO public.device_tokens (
    user_id,
    business_id,
    fcm_token,
    platform,
    device_name,
    device_id,
    is_active,
    last_seen_at
  ) VALUES (
    auth.uid(),
    v_biz_id,
    p_fcm_token,
    p_platform,
    p_device_name,
    p_device_id,
    true,
    NOW()
  )
  ON CONFLICT (user_id, fcm_token) DO UPDATE
  SET is_active = true,
      last_seen_at = NOW(),
      device_name = COALESCE(p_device_name, device_tokens.device_name),
      device_id = COALESCE(p_device_id, device_tokens.device_id),
      updated_at = NOW()
  RETURNING id INTO v_token_id;

  RETURN v_token_id;
END;
$$;


-- 6.7 Mark All In-App Notifications As Read
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(
  p_business_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  IF NOT public.is_business_owner(p_business_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE public.in_app_notifications
  SET is_read = true, read_at = NOW()
  WHERE business_id = p_business_id AND is_read = false;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

