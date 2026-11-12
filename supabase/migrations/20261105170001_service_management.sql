-- ==============================================================================
-- Migration: 20261105170001_service_management.sql
-- Description: Phase 6 Service Management enhancements, reference numbers, charges,
--              attachments, and service activity timeline.
-- ==============================================================================

-- 1. BUSINESS SEQUENCES TABLE (Safe atomic reference numbers per business)
CREATE TABLE IF NOT EXISTS public.business_sequences (
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  sequence_type TEXT NOT NULL,
  current_val BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (business_id, sequence_type)
);

ALTER TABLE public.business_sequences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage own business sequences"
  ON public.business_sequences
  FOR ALL
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

-- Function to allocate atomic service sequence numbers
CREATE OR REPLACE FUNCTION public.next_service_number(p_business_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_val BIGINT;
BEGIN
  INSERT INTO public.business_sequences (business_id, sequence_type, current_val)
  VALUES (p_business_id, 'service', 1)
  ON CONFLICT (business_id, sequence_type)
  DO UPDATE SET current_val = business_sequences.current_val + 1
  RETURNING current_val INTO v_next_val;

  RETURN 'YB-SRV-' || LPAD(v_next_val::TEXT, 6, '0');
END;
$$;


-- 2. EXTEND SERVICE ENTRIES TABLE
ALTER TABLE public.service_entries
  ADD COLUMN IF NOT EXISTS service_number TEXT,
  ADD COLUMN IF NOT EXISTS work_performed TEXT,
  ADD COLUMN IF NOT EXISTS additional_charges NUMERIC(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_amount NUMERIC(12, 2);

-- Trigger to auto-generate service_number and compute total_amount if omitted
CREATE OR REPLACE FUNCTION public.handle_service_entry_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.service_number IS NULL OR NEW.service_number = '' THEN
    NEW.service_number := public.next_service_number(NEW.business_id);
  END IF;

  IF NEW.total_amount IS NULL AND NEW.service_amount IS NOT NULL THEN
    NEW.total_amount := GREATEST(0, (COALESCE(NEW.service_amount, 0) + COALESCE(NEW.additional_charges, 0) - COALESCE(NEW.discount_amount, 0)));
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_service_entry_number ON public.service_entries;
CREATE TRIGGER trg_set_service_entry_number
  BEFORE INSERT ON public.service_entries
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_service_entry_number();

CREATE INDEX IF NOT EXISTS idx_service_entries_service_number ON public.service_entries(business_id, service_number);


-- 3. SERVICE ATTACHMENTS TABLE
CREATE TABLE IF NOT EXISTS public.service_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.service_entries(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_service_attachments_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.service_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view own service attachments"
  ON public.service_attachments
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own service attachments"
  ON public.service_attachments
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own service attachments"
  ON public.service_attachments
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own service attachments"
  ON public.service_attachments
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE INDEX IF NOT EXISTS idx_service_attachments_service ON public.service_attachments(business_id, service_id);


-- 4. SERVICE ACTIVITIES TABLE (Audit / History Timeline)
CREATE TABLE IF NOT EXISTS public.service_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.service_entries(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('created', 'status_changed', 'details_updated', 'attachment_added', 'attachment_removed', 'completed', 'cancelled', 'resumed')),
  title TEXT NOT NULL,
  description TEXT,
  old_status TEXT,
  new_status TEXT,
  actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_service_activities_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.service_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view own service activities"
  ON public.service_activities
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own service activities"
  ON public.service_activities
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE INDEX IF NOT EXISTS idx_service_activities_service ON public.service_activities(business_id, service_id, created_at DESC);

