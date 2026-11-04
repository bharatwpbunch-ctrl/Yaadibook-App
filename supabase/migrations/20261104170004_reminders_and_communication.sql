-- ==============================================================================
-- Migration: 20261104170004_reminders_and_communication.sql
-- Description: Reminders, Communication Logs, Settings, Notification Prefs & Audit Logs
-- ==============================================================================

-- 1. REMINDERS TABLE (Unified follow-up & reminder foundation)
CREATE TABLE public.reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID,
  maintenance_occurrence_id UUID,
  amc_contract_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('maintenance', 'amc', 'follow_up', 'general')),
  due_at TIMESTAMPTZ NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  notification_enabled BOOLEAN NOT NULL DEFAULT true,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'due', 'overdue', 'completed', 'cancelled')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_reminders_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_reminders_maintenance
    FOREIGN KEY (business_id, maintenance_occurrence_id)
    REFERENCES public.maintenance_occurrences(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_reminders_amc
    FOREIGN KEY (business_id, amc_contract_id)
    REFERENCES public.amc_contracts(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT uq_reminders_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_reminders_updated_at
  BEFORE UPDATE ON public.reminders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_reminders_business ON public.reminders(business_id);
CREATE INDEX idx_reminders_customer ON public.reminders(business_id, customer_id);
CREATE INDEX idx_reminders_due_at ON public.reminders(business_id, due_at);
CREATE INDEX idx_reminders_status ON public.reminders(business_id, status);

-- Reminders RLS
CREATE POLICY "Owners can view own reminders"
  ON public.reminders
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own reminders"
  ON public.reminders
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own reminders"
  ON public.reminders
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own reminders"
  ON public.reminders
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 2. COMMUNICATION LOGS TABLE
CREATE TABLE public.communication_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  reminder_id UUID,
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'sms', 'call', 'other')),
  direction TEXT NOT NULL DEFAULT 'outgoing' CHECK (direction IN ('outgoing', 'incoming')),
  message_type TEXT NOT NULL DEFAULT 'manual',
  message_content TEXT,
  provider_message_id TEXT,
  status TEXT NOT NULL DEFAULT 'initiated' CHECK (status IN ('initiated', 'opened', 'sent', 'delivered', 'failed', 'unknown')),
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_communication_logs_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_communication_logs_reminder
    FOREIGN KEY (business_id, reminder_id)
    REFERENCES public.reminders(business_id, id)
    ON DELETE SET NULL
);

ALTER TABLE public.communication_logs ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_communication_logs_business ON public.communication_logs(business_id);
CREATE INDEX idx_communication_logs_customer ON public.communication_logs(business_id, customer_id);
CREATE INDEX idx_communication_logs_created_at ON public.communication_logs(business_id, created_at DESC);

-- Communication Logs RLS
CREATE POLICY "Owners can view own communication logs"
  ON public.communication_logs
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own communication logs"
  ON public.communication_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));


-- 3. NOTIFICATION PREFERENCES TABLE
CREATE TABLE public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL UNIQUE REFERENCES public.businesses(id) ON DELETE CASCADE,
  reminder_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  maintenance_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  amc_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  followup_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  preferred_notification_time TIME NOT NULL DEFAULT '09:00:00',
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_notification_preferences_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Notification Preferences RLS
CREATE POLICY "Owners can view own notification preferences"
  ON public.notification_preferences
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own notification preferences"
  ON public.notification_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own notification preferences"
  ON public.notification_preferences
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 4. BUSINESS SETTINGS TABLE
CREATE TABLE public.business_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL UNIQUE REFERENCES public.businesses(id) ON DELETE CASCADE,
  date_format TEXT NOT NULL DEFAULT 'dd/MM/yyyy',
  time_format TEXT NOT NULL DEFAULT '12h' CHECK (time_format IN ('12h', '24h')),
  preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'gu', 'hi')),
  currency_code TEXT NOT NULL DEFAULT 'INR',
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.business_settings ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_business_settings_updated_at
  BEFORE UPDATE ON public.business_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Business Settings RLS
CREATE POLICY "Owners can view own business settings"
  ON public.business_settings
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own business settings"
  ON public.business_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own business settings"
  ON public.business_settings
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 5. AUDIT LOGS TABLE (Lightweight business activity audit)
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_audit_logs_business ON public.audit_logs(business_id, created_at DESC);

-- Audit Logs RLS: Owners can view, insert allowed for authenticated actor, no client updates or deletes (immutable)
CREATE POLICY "Owners can view own audit logs"
  ON public.audit_logs
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Authenticated users can append audit logs"
  ON public.audit_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    actor_user_id = auth.uid() AND
    public.is_business_owner(business_id)
  );


-- 6. ATOMIC BUSINESS CREATION RPC
CREATE OR REPLACE FUNCTION public.create_business_workspace(
  p_business_name TEXT,
  p_business_category TEXT,
  p_phone TEXT,
  p_address_line_1 TEXT,
  p_city TEXT,
  p_postal_code TEXT,
  p_state TEXT DEFAULT 'Gujarat',
  p_country TEXT DEFAULT 'India',
  p_currency_code TEXT DEFAULT 'INR',
  p_timezone TEXT DEFAULT 'Asia/Kolkata',
  p_preferred_language TEXT DEFAULT 'en'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_business_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to create a business workspace';
  END IF;

  -- Enforce business rule: One owner can create only one business in MVP
  IF EXISTS (SELECT 1 FROM public.businesses WHERE owner_user_id = v_user_id) THEN
    RAISE EXCEPTION 'An owner can only create one business workspace';
  END IF;

  INSERT INTO public.businesses (
    owner_user_id,
    business_name,
    business_category,
    phone,
    address_line_1,
    city,
    state,
    postal_code,
    country,
    currency_code,
    timezone,
    preferred_language
  ) VALUES (
    v_user_id,
    p_business_name,
    p_business_category,
    p_phone,
    p_address_line_1,
    p_city,
    p_state,
    p_postal_code,
    p_country,
    p_currency_code,
    p_timezone,
    p_preferred_language
  )
  RETURNING id INTO v_business_id;

  -- Automatically initialize default business settings
  INSERT INTO public.business_settings (
    business_id,
    preferred_language,
    currency_code,
    timezone
  ) VALUES (
    v_business_id,
    p_preferred_language,
    p_currency_code,
    p_timezone
  );

  -- Automatically initialize default notification preferences
  INSERT INTO public.notification_preferences (
    business_id
  ) VALUES (
    v_business_id
  );

  -- Log creation event in audit trail
  INSERT INTO public.audit_logs (
    business_id,
    actor_user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    v_business_id,
    v_user_id,
    'business.created',
    'businesses',
    v_business_id,
    jsonb_build_object(
      'business_name', p_business_name,
      'category', p_business_category
    )
  );

  RETURN v_business_id;
END;
$$;

