-- ==============================================================================
-- Migration: 20261106200001_communication_and_campaigns.sql
-- Description: Phase 9 Customer Communication, Message Templates, Consent,
--              Provider Configurations, Bulk Messaging Campaigns & Usage Tracking
-- ==============================================================================

-- 1. UPGRADE COMMUNICATION LOGS TABLE
-- Safely add missing columns to existing communication_logs
ALTER TABLE public.communication_logs
  ADD COLUMN IF NOT EXISTS service_id UUID REFERENCES public.service_entries(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS maintenance_occurrence_id UUID REFERENCES public.maintenance_occurrences(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS amc_contract_id UUID REFERENCES public.amc_contracts(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS template_id UUID,
  ADD COLUMN IF NOT EXISTS recipient_phone TEXT,
  ADD COLUMN IF NOT EXISTS recipient_name TEXT,
  ADD COLUMN IF NOT EXISTS provider_response JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS cost NUMERIC(10,4) NOT NULL DEFAULT 0.0000,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

-- Update status constraint safely
ALTER TABLE public.communication_logs DROP CONSTRAINT IF EXISTS communication_logs_status_check;
ALTER TABLE public.communication_logs ADD CONSTRAINT communication_logs_status_check
  CHECK (status IN (
    'draft', 'opened_in_app', 'queued', 'submitted', 'accepted',
    'delivered', 'read', 'failed', 'cancelled',
    -- Legacy compatibility
    'initiated', 'opened', 'sent', 'unknown'
  ));

CREATE INDEX IF NOT EXISTS idx_communication_logs_service ON public.communication_logs(service_id);
CREATE INDEX IF NOT EXISTS idx_communication_logs_maint ON public.communication_logs(maintenance_occurrence_id);
CREATE INDEX IF NOT EXISTS idx_communication_logs_amc ON public.communication_logs(amc_contract_id);
CREATE INDEX IF NOT EXISTS idx_communication_logs_channel_status ON public.communication_logs(business_id, channel, status);


-- 2. MESSAGE TEMPLATES TABLE
CREATE TABLE IF NOT EXISTS public.message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'general', 'customer_greeting', 'service_update', 'installation_confirmation',
    'repair_update', 'service_completion', 'maintenance_reminder', 'amc_renewal',
    'payment_followup', 'thank_you', 'custom'
  )),
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp_manual', 'whatsapp_api', 'sms_manual', 'sms_api')),
  language TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'gu', 'hi')),
  content TEXT NOT NULL,
  variable_definitions JSONB NOT NULL DEFAULT '[]'::jsonb,
  provider_template_id TEXT,
  provider_status TEXT NOT NULL DEFAULT 'not_submitted' CHECK (provider_status IN ('not_submitted', 'pending', 'approved', 'rejected')),
  is_system BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_template_name_per_business UNIQUE (business_id, name, channel)
);

ALTER TABLE public.message_templates ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_message_templates_updated_at
  BEFORE UPDATE ON public.message_templates
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_message_templates_biz ON public.message_templates(business_id);
CREATE INDEX IF NOT EXISTS idx_message_templates_cat ON public.message_templates(business_id, category);
CREATE INDEX IF NOT EXISTS idx_message_templates_channel ON public.message_templates(business_id, channel);
CREATE INDEX IF NOT EXISTS idx_message_templates_active ON public.message_templates(business_id, is_archived);

-- RLS: Message Templates
CREATE POLICY "Owners can view own templates"
  ON public.message_templates FOR SELECT TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own templates"
  ON public.message_templates FOR INSERT TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own templates"
  ON public.message_templates FOR UPDATE TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own templates"
  ON public.message_templates FOR DELETE TO authenticated
  USING (public.is_business_owner(business_id));


-- 3. CUSTOMER MESSAGING PREFERENCES & CONSENT TABLE
CREATE TABLE IF NOT EXISTS public.customer_messaging_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  whatsapp_opt_in BOOLEAN NOT NULL DEFAULT true,
  sms_opt_in BOOLEAN NOT NULL DEFAULT true,
  marketing_consent BOOLEAN NOT NULL DEFAULT false,
  consent_source TEXT NOT NULL DEFAULT 'manual_entry' CHECK (consent_source IN (
    'manual_entry', 'verbal', 'written', 'digital_opt_in', 'service_agreement', 'imported'
  )),
  consent_timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  is_opted_out BOOLEAN NOT NULL DEFAULT false,
  opted_out_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_customer_messaging_prefs UNIQUE (business_id, customer_id)
);

ALTER TABLE public.customer_messaging_preferences ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_customer_messaging_preferences_updated_at
  BEFORE UPDATE ON public.customer_messaging_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_cust_msg_prefs_biz ON public.customer_messaging_preferences(business_id);
CREATE INDEX IF NOT EXISTS idx_cust_msg_prefs_cust ON public.customer_messaging_preferences(customer_id);
CREATE INDEX IF NOT EXISTS idx_cust_msg_prefs_optout ON public.customer_messaging_preferences(business_id, is_opted_out);

-- RLS: Customer Messaging Preferences
CREATE POLICY "Owners can view own customer preferences"
  ON public.customer_messaging_preferences FOR SELECT TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own customer preferences"
  ON public.customer_messaging_preferences FOR INSERT TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own customer preferences"
  ON public.customer_messaging_preferences FOR UPDATE TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 4. PROVIDER CONFIGURATIONS TABLE (Safe non-secret configuration)
CREATE TABLE IF NOT EXISTS public.provider_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  provider_type TEXT NOT NULL CHECK (provider_type IN ('meta_whatsapp_cloud', 'sms_india_dlt')),
  connection_status TEXT NOT NULL DEFAULT 'not_connected' CHECK (connection_status IN (
    'not_connected', 'setup_required', 'pending_verification', 'connected', 'configuration_error'
  )),
  waba_id TEXT,
  phone_number_id TEXT,
  display_phone_number TEXT,
  sender_id TEXT,
  entity_id TEXT,
  last_verified_at TIMESTAMPTZ,
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_business_provider_config UNIQUE (business_id, provider_type)
);

ALTER TABLE public.provider_configurations ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_provider_configurations_updated_at
  BEFORE UPDATE ON public.provider_configurations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_provider_configs_biz ON public.provider_configurations(business_id);

-- RLS: Provider Configurations
CREATE POLICY "Owners can view own provider configs"
  ON public.provider_configurations FOR SELECT TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own provider configs"
  ON public.provider_configurations FOR INSERT TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own provider configs"
  ON public.provider_configurations FOR UPDATE TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 5. COMMUNICATION CAMPAIGNS TABLE (Bulk Messaging)
CREATE TABLE IF NOT EXISTS public.communication_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES public.message_templates(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp_api', 'sms_api')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'validating', 'queued', 'processing',
    'partially_completed', 'completed', 'failed', 'cancelled'
  )),
  total_recipients INTEGER NOT NULL DEFAULT 0,
  eligible_recipients INTEGER NOT NULL DEFAULT 0,
  submitted_count INTEGER NOT NULL DEFAULT 0,
  delivered_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  skipped_count INTEGER NOT NULL DEFAULT 0,
  estimated_cost NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  actual_cost NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.communication_campaigns ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_communication_campaigns_updated_at
  BEFORE UPDATE ON public.communication_campaigns
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_comm_campaigns_biz ON public.communication_campaigns(business_id);
CREATE INDEX IF NOT EXISTS idx_comm_campaigns_status ON public.communication_campaigns(business_id, status);

-- RLS: Communication Campaigns
CREATE POLICY "Owners can view own campaigns"
  ON public.communication_campaigns FOR SELECT TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own campaigns"
  ON public.communication_campaigns FOR INSERT TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own campaigns"
  ON public.communication_campaigns FOR UPDATE TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 6. CAMPAIGN RECIPIENTS TABLE
CREATE TABLE IF NOT EXISTS public.campaign_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.communication_campaigns(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  recipient_phone TEXT NOT NULL,
  recipient_name TEXT,
  eligibility_status TEXT NOT NULL DEFAULT 'eligible' CHECK (eligibility_status IN (
    'eligible', 'opted_out', 'invalid_phone', 'missing_consent', 'excluded'
  )),
  submission_status TEXT NOT NULL DEFAULT 'pending' CHECK (submission_status IN (
    'pending', 'submitted', 'delivered', 'failed', 'skipped'
  )),
  provider_message_id TEXT,
  failure_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_campaign_recipient_phone UNIQUE (campaign_id, recipient_phone)
);

ALTER TABLE public.campaign_recipients ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_campaign_recipients_updated_at
  BEFORE UPDATE ON public.campaign_recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_campaign_recipients_camp ON public.campaign_recipients(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_recipients_biz ON public.campaign_recipients(business_id);
CREATE INDEX IF NOT EXISTS idx_campaign_recipients_status ON public.campaign_recipients(campaign_id, submission_status);

-- RLS: Campaign Recipients
CREATE POLICY "Owners can view own campaign recipients"
  ON public.campaign_recipients FOR SELECT TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own campaign recipients"
  ON public.campaign_recipients FOR INSERT TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own campaign recipients"
  ON public.campaign_recipients FOR UPDATE TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));


-- 7. COMMUNICATION USAGE TABLE
CREATE TABLE IF NOT EXISTS public.communication_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp_api', 'sms_api', 'whatsapp_manual', 'sms_manual')),
  provider TEXT NOT NULL DEFAULT 'manual',
  message_category TEXT NOT NULL DEFAULT 'service',
  message_count INTEGER NOT NULL DEFAULT 1,
  estimated_cost NUMERIC(10,4) NOT NULL DEFAULT 0.0000,
  actual_cost NUMERIC(10,4) NOT NULL DEFAULT 0.0000,
  currency TEXT NOT NULL DEFAULT 'INR',
  campaign_id UUID REFERENCES public.communication_campaigns(id) ON DELETE SET NULL,
  communication_log_id UUID REFERENCES public.communication_logs(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.communication_usage ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_comm_usage_biz ON public.communication_usage(business_id);
CREATE INDEX IF NOT EXISTS idx_comm_usage_channel ON public.communication_usage(business_id, channel);
CREATE INDEX IF NOT EXISTS idx_comm_usage_created ON public.communication_usage(business_id, created_at DESC);

-- RLS: Communication Usage
CREATE POLICY "Owners can view own communication usage"
  ON public.communication_usage FOR SELECT TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own communication usage"
  ON public.communication_usage FOR INSERT TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

