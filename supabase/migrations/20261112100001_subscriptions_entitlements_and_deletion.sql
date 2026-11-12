-- ==============================================================================
-- Migration: 20261112100001_subscriptions_entitlements_and_deletion.sql
-- Description: Phase 10 Subscriptions, Server-Side Entitlements, Usage Tracking,
--              Business Reports RPC, Account Deletion Audit & Perf Indexes
-- ==============================================================================

-- 1. SUBSCRIPTION PLANS TABLE
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  billing_period TEXT NOT NULL CHECK (billing_period IN ('free', 'monthly', 'yearly')),
  price_inr NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (price_inr >= 0),
  play_product_id TEXT UNIQUE,
  max_customers INTEGER, -- NULL = unlimited
  max_monthly_campaign_messages INTEGER NOT NULL DEFAULT 0 CHECK (max_monthly_campaign_messages >= 0),
  max_storage_bytes BIGINT NOT NULL DEFAULT 104857600 CHECK (max_storage_bytes > 0), -- 100 MB default
  can_export_advanced_reports BOOLEAN NOT NULL DEFAULT false,
  can_use_bulk_messaging BOOLEAN NOT NULL DEFAULT false,
  can_use_whatsapp_api BOOLEAN NOT NULL DEFAULT false,
  can_use_sms_api BOOLEAN NOT NULL DEFAULT false,
  features_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS set_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER set_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP POLICY IF EXISTS "Authenticated users can view active subscription plans" ON public.subscription_plans;
CREATE POLICY "Authenticated users can view active subscription plans"
  ON public.subscription_plans
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Seed canonical MVP plans (idempotent)
INSERT INTO public.subscription_plans (
  code, name, description, billing_period, price_inr, play_product_id,
  max_customers, max_monthly_campaign_messages, max_storage_bytes,
  can_export_advanced_reports, can_use_bulk_messaging, can_use_whatsapp_api, can_use_sms_api,
  features_json, sort_order
) VALUES
  (
    'free',
    'Yaadibook Free',
    'Essential customer, service, maintenance, AMC, and reminder tools for growing businesses.',
    'free',
    0.00,
    NULL,
    100,
    0,
    104857600, -- 100 MB
    false,
    false,
    false,
    false,
    '[
      "Up to 100 customers",
      "Services, Maintenance & AMC tracking",
      "Unified Reminders & Push Notifications",
      "Manual WhatsApp & SMS shortcuts",
      "Standard CSV & PDF overview export",
      "Offline access & auto sync"
    ]'::jsonb,
    1
  ),
  (
    'pro_monthly',
    'Yaadibook Pro (Monthly)',
    'Unlimited customers, advanced business reports, official WhatsApp & SMS APIs, and bulk messaging.',
    'monthly',
    299.00,
    'yaadibook_pro_monthly',
    NULL,
    1000,
    2147483648, -- 2 GB
    true,
    true,
    true,
    true,
    '[
      "Unlimited customers",
      "Full Customer, Service, Maintenance, AMC & Revenue reports",
      "Official WhatsApp Cloud API & SMS Gateway dispatch",
      "Bulk Messaging Campaigns (up to 1,000 messages/month)",
      "2 GB attachment & document storage",
      "Priority cloud backup & offline sync"
    ]'::jsonb,
    2
  ),
  (
    'pro_yearly',
    'Yaadibook Pro (Yearly)',
    'Full Pro suite billed annually with 2 months savings.',
    'yearly',
    2999.00,
    'yaadibook_pro_yearly',
    NULL,
    1500,
    5368709120, -- 5 GB
    true,
    true,
    true,
    true,
    '[
      "Everything in Pro Monthly",
      "1,500 monthly campaign messages included",
      "5 GB attachment & document storage",
      "2 months free on annual billing"
    ]'::jsonb,
    3
  )
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price_inr = EXCLUDED.price_inr,
  play_product_id = EXCLUDED.play_product_id,
  max_customers = EXCLUDED.max_customers,
  max_monthly_campaign_messages = EXCLUDED.max_monthly_campaign_messages,
  max_storage_bytes = EXCLUDED.max_storage_bytes,
  can_export_advanced_reports = EXCLUDED.can_export_advanced_reports,
  can_use_bulk_messaging = EXCLUDED.can_use_bulk_messaging,
  can_use_whatsapp_api = EXCLUDED.can_use_whatsapp_api,
  can_use_sms_api = EXCLUDED.can_use_sms_api,
  features_json = EXCLUDED.features_json,
  sort_order = EXCLUDED.sort_order;


-- 2. BUSINESS SUBSCRIPTIONS TABLE (Server-managed; read-only to business owner)
CREATE TABLE IF NOT EXISTS public.business_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  plan_code TEXT NOT NULL DEFAULT 'free' REFERENCES public.subscription_plans(code),
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('trial', 'active', 'pending', 'grace_period', 'expired', 'cancelled', 'revoked')
  ),
  store_provider TEXT NOT NULL DEFAULT 'system' CHECK (
    store_provider IN ('system', 'google_play', 'app_store', 'admin_grant')
  ),
  product_id TEXT,
  purchase_token_hash TEXT,
  order_id TEXT,
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  current_period_end TIMESTAMPTZ,
  grace_period_end TIMESTAMPTZ,
  auto_renew BOOLEAN NOT NULL DEFAULT false,
  cancelled_at TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_business_subscriptions_business UNIQUE (business_id)
);

ALTER TABLE public.business_subscriptions ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS set_business_subscriptions_updated_at ON public.business_subscriptions;
CREATE TRIGGER set_business_subscriptions_updated_at
  BEFORE UPDATE ON public.business_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_business_subscriptions_status
  ON public.business_subscriptions(status, current_period_end);

-- Strictly SELECT-only for owners. Clients MUST NEVER forge active subscriptions.
DROP POLICY IF EXISTS "Owners can view own business subscription" ON public.business_subscriptions;
CREATE POLICY "Owners can view own business subscription"
  ON public.business_subscriptions
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 3. SUBSCRIPTION TRANSACTIONS LEDGER (Immutable audit ledger; owner read-only)
CREATE TABLE IF NOT EXISTS public.subscription_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.business_subscriptions(id) ON DELETE SET NULL,
  plan_code TEXT NOT NULL REFERENCES public.subscription_plans(code),
  transaction_type TEXT NOT NULL CHECK (
    transaction_type IN ('purchase', 'renewal', 'upgrade', 'cancellation', 'refund', 'revocation', 'restore', 'trial_start')
  ),
  store_provider TEXT NOT NULL DEFAULT 'google_play',
  product_id TEXT,
  external_transaction_id TEXT UNIQUE, -- Replay protection
  purchase_token_hash TEXT,
  amount_inr NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (amount_inr >= 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  status TEXT NOT NULL DEFAULT 'verified' CHECK (
    status IN ('pending', 'verified', 'failed', 'refunded', 'revoked')
  ),
  verified_at TIMESTAMPTZ,
  raw_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.subscription_transactions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_subscription_tx_business_created
  ON public.subscription_transactions(business_id, created_at DESC);

DROP POLICY IF EXISTS "Owners can view own subscription transactions" ON public.subscription_transactions;
CREATE POLICY "Owners can view own subscription transactions"
  ON public.subscription_transactions
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 4. ACCOUNT DELETION REQUESTS TABLE (Audit trail + Play Store compliance)
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  business_id UUID,
  email TEXT,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'requested' CHECK (
    status IN ('requested', 'processing', 'completed', 'cancelled', 'failed')
  ),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  scheduled_purge_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_account_deletion_user
  ON public.account_deletion_requests(user_id, requested_at DESC);

DROP POLICY IF EXISTS "Users can view own account deletion requests" ON public.account_deletion_requests;
CREATE POLICY "Users can view own account deletion requests"
  ON public.account_deletion_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);


-- 5. AUTO-PROVISION FREE SUBSCRIPTION ON NEW BUSINESS + BACKFILL EXISTING
CREATE OR REPLACE FUNCTION public.handle_new_business_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.business_subscriptions (
    business_id,
    plan_code,
    status,
    store_provider,
    current_period_start,
    auto_renew
  ) VALUES (
    NEW.id,
    'free',
    'active',
    'system',
    timezone('utc'::text, now()),
    false
  )
  ON CONFLICT (business_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_business_created_provision_subscription ON public.businesses;
CREATE TRIGGER on_business_created_provision_subscription
  AFTER INSERT ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_business_subscription();

-- Backfill any existing businesses missing a subscription row
INSERT INTO public.business_subscriptions (
  business_id, plan_code, status, store_provider, current_period_start, auto_renew
)
SELECT
  b.id,
  'free',
  'active',
  'system',
  timezone('utc'::text, now()),
  false
FROM public.businesses b
LEFT JOIN public.business_subscriptions bs ON bs.business_id = b.id
WHERE bs.id IS NULL
ON CONFLICT (business_id) DO NOTHING;


-- 6. SERVER-SIDE ENTITLEMENTS & USAGE SNAPSHOT RPC
CREATE OR REPLACE FUNCTION public.get_business_entitlements(p_business_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
  v_effective_plan_code TEXT := 'free';
  v_plan RECORD;
  v_now TIMESTAMPTZ := timezone('utc'::text, now());
  v_customers_count INTEGER := 0;
  v_services_count INTEGER := 0;
  v_monthly_api_messages INTEGER := 0;
  v_storage_bytes BIGINT := 0;
  v_month_start TIMESTAMPTZ := date_trunc('month', timezone('Asia/Kolkata', v_now)) AT TIME ZONE 'Asia/Kolkata';
BEGIN
  -- Authorization check: allow business owner OR service_role (when auth.uid() IS NULL)
  IF auth.uid() IS NOT NULL AND NOT public.is_business_owner(p_business_id) THEN
    RAISE EXCEPTION 'Access denied for business %', p_business_id USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_sub
  FROM public.business_subscriptions
  WHERE business_id = p_business_id;

  -- Determine whether paid plan entitlements are still valid
  IF v_sub.id IS NOT NULL AND v_sub.plan_code != 'free' THEN
    IF v_sub.status IN ('trial', 'active') THEN
      IF v_sub.current_period_end IS NULL OR v_sub.current_period_end > v_now THEN
        v_effective_plan_code := v_sub.plan_code;
      END IF;
    ELSIF v_sub.status = 'grace_period' THEN
      IF COALESCE(v_sub.grace_period_end, v_sub.current_period_end) > v_now THEN
        v_effective_plan_code := v_sub.plan_code;
      END IF;
    ELSIF v_sub.status = 'cancelled' THEN
      -- Preserve access until paid period ends
      IF v_sub.current_period_end IS NOT NULL AND v_sub.current_period_end > v_now THEN
        v_effective_plan_code := v_sub.plan_code;
      END IF;
    END IF;
  END IF;

  SELECT *
  INTO v_plan
  FROM public.subscription_plans
  WHERE code = v_effective_plan_code;

  -- Live business usage metrics
  SELECT COUNT(*)::INTEGER
  INTO v_customers_count
  FROM public.customers
  WHERE business_id = p_business_id
    AND archived_at IS NULL;

  SELECT COUNT(*)::INTEGER
  INTO v_services_count
  FROM public.service_entries
  WHERE business_id = p_business_id;

  SELECT COUNT(*)::INTEGER
  INTO v_monthly_api_messages
  FROM public.communication_logs
  WHERE business_id = p_business_id
    AND message_type IN ('cloud_api', 'sms_api', 'bulk_campaign')
    AND created_at >= v_month_start
    AND status != 'failed';

  -- Compute storage usage safely from storage.objects folder prefix
  SELECT COALESCE(SUM(COALESCE((metadata->>'size')::BIGINT, 0)), 0)
  INTO v_storage_bytes
  FROM storage.objects
  WHERE (storage.foldername(name))[1] = p_business_id::TEXT;

  RETURN jsonb_build_object(
    'business_id', p_business_id,
    'effective_plan_code', v_plan.code,
    'plan_name', v_plan.name,
    'billing_period', v_plan.billing_period,
    'price_inr', v_plan.price_inr,
    'subscription_status', COALESCE(v_sub.status, 'active'),
    'raw_plan_code', COALESCE(v_sub.plan_code, 'free'),
    'store_provider', COALESCE(v_sub.store_provider, 'system'),
    'product_id', v_sub.product_id,
    'current_period_start', v_sub.current_period_start,
    'current_period_end', v_sub.current_period_end,
    'grace_period_end', v_sub.grace_period_end,
    'auto_renew', COALESCE(v_sub.auto_renew, false),
    'cancelled_at', v_sub.cancelled_at,
    'entitlements', jsonb_build_object(
      'max_customers', v_plan.max_customers,
      'max_monthly_campaign_messages', v_plan.max_monthly_campaign_messages,
      'max_storage_bytes', v_plan.max_storage_bytes,
      'can_export_advanced_reports', v_plan.can_export_advanced_reports,
      'can_use_bulk_messaging', v_plan.can_use_bulk_messaging,
      'can_use_whatsapp_api', v_plan.can_use_whatsapp_api,
      'can_use_sms_api', v_plan.can_use_sms_api
    ),
    'usage', jsonb_build_object(
      'customers_count', v_customers_count,
      'services_count', v_services_count,
      'monthly_api_messages_count', v_monthly_api_messages,
      'storage_bytes_used', v_storage_bytes
    ),
    'evaluated_at', v_now
  );
END;
$$;


-- 7. FEATURE ENTITLEMENT CHECK RPC (Used by Edge Functions before dispatching paid APIs)
CREATE OR REPLACE FUNCTION public.check_business_entitlement(
  p_business_id UUID,
  p_feature_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_snap JSONB;
  v_ent JSONB;
  v_usage JSONB;
  v_allowed BOOLEAN := false;
  v_reason TEXT := 'Subscription upgrade required.';
  v_limit INTEGER;
  v_used INTEGER;
BEGIN
  v_snap := public.get_business_entitlements(p_business_id);
  v_ent := v_snap->'entitlements';
  v_usage := v_snap->'usage';

  IF p_feature_key = 'can_export_advanced_reports' THEN
    v_allowed := COALESCE((v_ent->>'can_export_advanced_reports')::BOOLEAN, false);
    IF v_allowed THEN v_reason := 'ok'; ELSE v_reason := 'Advanced exports require Yaadibook Pro.'; END IF;
  ELSIF p_feature_key = 'can_use_bulk_messaging' THEN
    v_allowed := COALESCE((v_ent->>'can_use_bulk_messaging')::BOOLEAN, false);
    v_limit := COALESCE((v_ent->>'max_monthly_campaign_messages')::INTEGER, 0);
    v_used := COALESCE((v_usage->>'monthly_api_messages_count')::INTEGER, 0);
    IF NOT v_allowed THEN
      v_reason := 'Bulk messaging requires Yaadibook Pro.';
    ELSIF v_used >= v_limit THEN
      v_allowed := false;
      v_reason := format('Monthly campaign message limit (%s) reached.', v_limit);
    ELSE
      v_reason := 'ok';
    END IF;
  ELSIF p_feature_key = 'can_use_whatsapp_api' THEN
    v_allowed := COALESCE((v_ent->>'can_use_whatsapp_api')::BOOLEAN, false);
    v_limit := COALESCE((v_ent->>'max_monthly_campaign_messages')::INTEGER, 0);
    v_used := COALESCE((v_usage->>'monthly_api_messages_count')::INTEGER, 0);
    IF NOT v_allowed THEN
      v_reason := 'Official WhatsApp API requires Yaadibook Pro.';
    ELSIF v_used >= v_limit THEN
      v_allowed := false;
      v_reason := format('Monthly API message limit (%s) reached.', v_limit);
    ELSE
      v_reason := 'ok';
    END IF;
  ELSIF p_feature_key = 'can_use_sms_api' THEN
    v_allowed := COALESCE((v_ent->>'can_use_sms_api')::BOOLEAN, false);
    v_limit := COALESCE((v_ent->>'max_monthly_campaign_messages')::INTEGER, 0);
    v_used := COALESCE((v_usage->>'monthly_api_messages_count')::INTEGER, 0);
    IF NOT v_allowed THEN
      v_reason := 'SMS Gateway API requires Yaadibook Pro.';
    ELSIF v_used >= v_limit THEN
      v_allowed := false;
      v_reason := format('Monthly API message limit (%s) reached.', v_limit);
    ELSE
      v_reason := 'ok';
    END IF;
  ELSIF p_feature_key = 'create_customer' THEN
    IF (v_ent->>'max_customers') IS NULL THEN
      v_allowed := true;
      v_reason := 'ok';
    ELSE
      v_limit := (v_ent->>'max_customers')::INTEGER;
      v_used := COALESCE((v_usage->>'customers_count')::INTEGER, 0);
      v_allowed := v_used < v_limit;
      IF v_allowed THEN
        v_reason := 'ok';
      ELSE
        v_reason := format('Free plan limit of %s active customers reached. Upgrade to Pro for unlimited customers.', v_limit);
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'reason', v_reason,
    'effective_plan_code', v_snap->>'effective_plan_code',
    'subscription_status', v_snap->>'subscription_status'
  );
END;
$$;


-- 8. BUSINESS REPORTS AGGREGATION RPC
-- Excludes cancelled services from revenue/completed totals and clearly separates
-- recorded service amounts vs collected (paid) amounts vs pending collection amounts.
CREATE OR REPLACE FUNCTION public.get_reports_summary(
  p_business_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tz TEXT := 'Asia/Kolkata';
  v_today DATE;
  v_total_customers INTEGER := 0;
  v_new_customers INTEGER := 0;
  v_repeat_customers INTEGER := 0;
  v_customers_with_amc INTEGER := 0;
  v_services_total INTEGER := 0;
  v_services_completed INTEGER := 0;
  v_services_pending INTEGER := 0;
  v_services_cancelled INTEGER := 0;
  v_services_recorded_amount NUMERIC(14, 2) := 0;
  v_services_paid_amount NUMERIC(14, 2) := 0;
  v_services_unpaid_amount NUMERIC(14, 2) := 0;
  v_maint_total INTEGER := 0;
  v_maint_completed INTEGER := 0;
  v_maint_upcoming INTEGER := 0;
  v_maint_overdue INTEGER := 0;
  v_amc_active INTEGER := 0;
  v_amc_expiring_30d INTEGER := 0;
  v_amc_expired INTEGER := 0;
  v_amc_renewed_in_range INTEGER := 0;
  v_amc_total_value NUMERIC(14, 2) := 0;
  v_followup_completed INTEGER := 0;
  v_followup_pending INTEGER := 0;
  v_followup_overdue INTEGER := 0;
  v_comm_whatsapp INTEGER := 0;
  v_comm_sms INTEGER := 0;
  v_comm_cost NUMERIC(12, 2) := 0;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_business_owner(p_business_id) THEN
    RAISE EXCEPTION 'Access denied for business %', p_business_id USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(NULLIF(timezone, ''), 'Asia/Kolkata')
  INTO v_tz
  FROM public.businesses
  WHERE id = p_business_id;

  v_today := (timezone(v_tz, now()))::DATE;

  -- Customer metrics
  SELECT COUNT(*)::INTEGER INTO v_total_customers
  FROM public.customers
  WHERE business_id = p_business_id AND archived_at IS NULL;

  SELECT COUNT(*)::INTEGER INTO v_new_customers
  FROM public.customers
  WHERE business_id = p_business_id
    AND archived_at IS NULL
    AND (timezone(v_tz, created_at))::DATE BETWEEN p_start_date AND p_end_date;

  SELECT COUNT(*)::INTEGER INTO v_repeat_customers
  FROM (
    SELECT customer_id
    FROM public.service_entries
    WHERE business_id = p_business_id AND status != 'cancelled'
    GROUP BY customer_id
    HAVING COUNT(*) > 1
  ) rc;

  SELECT COUNT(DISTINCT customer_id)::INTEGER INTO v_customers_with_amc
  FROM public.amc_contracts
  WHERE business_id = p_business_id
    AND status IN ('active', 'expiring');

  -- Service metrics (date-filtered)
  SELECT
    COUNT(*) FILTER (WHERE status != 'cancelled')::INTEGER,
    COUNT(*) FILTER (WHERE status = 'completed')::INTEGER,
    COUNT(*) FILTER (WHERE status IN ('pending', 'in_progress'))::INTEGER,
    COUNT(*) FILTER (WHERE status = 'cancelled')::INTEGER,
    COALESCE(SUM(service_amount) FILTER (WHERE status != 'cancelled'), 0),
    COALESCE(SUM(service_amount) FILTER (WHERE status != 'cancelled' AND payment_status = 'paid'), 0),
    COALESCE(SUM(service_amount) FILTER (WHERE status != 'cancelled' AND COALESCE(payment_status, 'unpaid') IN ('unpaid', 'partially_paid')), 0)
  INTO
    v_services_total,
    v_services_completed,
    v_services_pending,
    v_services_cancelled,
    v_services_recorded_amount,
    v_services_paid_amount,
    v_services_unpaid_amount
  FROM public.service_entries
  WHERE business_id = p_business_id
    AND service_date BETWEEN p_start_date AND p_end_date;

  -- Maintenance occurrences metrics
  SELECT
    COUNT(*)::INTEGER,
    COUNT(*) FILTER (WHERE status = 'completed')::INTEGER,
    COUNT(*) FILTER (WHERE status IN ('scheduled', 'due') AND due_date >= v_today)::INTEGER,
    COUNT(*) FILTER (WHERE status = 'overdue' OR (status IN ('scheduled', 'due') AND due_date < v_today))::INTEGER
  INTO
    v_maint_total,
    v_maint_completed,
    v_maint_upcoming,
    v_maint_overdue
  FROM public.maintenance_occurrences
  WHERE business_id = p_business_id
    AND due_date BETWEEN p_start_date AND p_end_date;

  -- AMC portfolio snapshot + renewals within range
  SELECT
    COUNT(*) FILTER (WHERE status IN ('active', 'expiring'))::INTEGER,
    COUNT(*) FILTER (WHERE status IN ('active', 'expiring') AND end_date BETWEEN v_today AND (v_today + 30))::INTEGER,
    COUNT(*) FILTER (WHERE status = 'expired' OR (status IN ('active', 'expiring') AND end_date < v_today))::INTEGER,
    COALESCE(SUM(contract_amount) FILTER (WHERE status IN ('active', 'expiring', 'renewed')), 0)
  INTO
    v_amc_active,
    v_amc_expiring_30d,
    v_amc_expired,
    v_amc_total_value
  FROM public.amc_contracts
  WHERE business_id = p_business_id;

  SELECT COUNT(*)::INTEGER INTO v_amc_renewed_in_range
  FROM public.amc_contracts
  WHERE business_id = p_business_id
    AND renewed_from_contract_id IS NOT NULL
    AND start_date BETWEEN p_start_date AND p_end_date;

  -- Follow-ups & reminders metrics
  SELECT
    COUNT(*) FILTER (WHERE status = 'completed')::INTEGER,
    COUNT(*) FILTER (WHERE status IN ('scheduled', 'due', 'snoozed') AND (timezone(v_tz, due_at))::DATE >= v_today)::INTEGER,
    COUNT(*) FILTER (WHERE status = 'overdue' OR (status IN ('scheduled', 'due') AND (timezone(v_tz, due_at))::DATE < v_today))::INTEGER
  INTO
    v_followup_completed,
    v_followup_pending,
    v_followup_overdue
  FROM public.reminders
  WHERE business_id = p_business_id
    AND (timezone(v_tz, due_at))::DATE BETWEEN p_start_date AND p_end_date;

  -- Communication activity metrics
  SELECT
    COUNT(*) FILTER (WHERE channel = 'whatsapp')::INTEGER,
    COUNT(*) FILTER (WHERE channel = 'sms')::INTEGER,
    COALESCE(SUM(cost), 0)
  INTO
    v_comm_whatsapp,
    v_comm_sms,
    v_comm_cost
  FROM public.communication_logs
  WHERE business_id = p_business_id
    AND (timezone(v_tz, created_at))::DATE BETWEEN p_start_date AND p_end_date;

  RETURN jsonb_build_object(
    'start_date', p_start_date,
    'end_date', p_end_date,
    'timezone', v_tz,
    'customers', jsonb_build_object(
      'total_active', v_total_customers,
      'new_in_period', v_new_customers,
      'repeat_customers', v_repeat_customers,
      'with_active_amc', v_customers_with_amc
    ),
    'services', jsonb_build_object(
      'total_active_count', v_services_total,
      'completed_count', v_services_completed,
      'pending_count', v_services_pending,
      'cancelled_count', v_services_cancelled,
      'recorded_amount_inr', v_services_recorded_amount,
      'paid_amount_inr', v_services_paid_amount,
      'pending_amount_inr', v_services_unpaid_amount
    ),
    'maintenance', jsonb_build_object(
      'total_in_period', v_maint_total,
      'completed_count', v_maint_completed,
      'upcoming_count', v_maint_upcoming,
      'overdue_count', v_maint_overdue
    ),
    'amc', jsonb_build_object(
      'active_count', v_amc_active,
      'expiring_within_30_days', v_amc_expiring_30d,
      'expired_count', v_amc_expired,
      'renewed_in_period', v_amc_renewed_in_range,
      'portfolio_contract_value_inr', v_amc_total_value
    ),
    'followups', jsonb_build_object(
      'completed_count', v_followup_completed,
      'pending_count', v_followup_pending,
      'overdue_count', v_followup_overdue
    ),
    'communications', jsonb_build_object(
      'whatsapp_count', v_comm_whatsapp,
      'sms_count', v_comm_sms,
      'recorded_cost_inr', v_comm_cost
    )
  );
END;
$$;


-- 9. ADDITIONAL COMPOSITE INDEXES FOR REPORTS & PAGINATION PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_service_entries_business_date_status
  ON public.service_entries(business_id, service_date DESC, status);

CREATE INDEX IF NOT EXISTS idx_maint_occ_business_due_status
  ON public.maintenance_occurrences(business_id, due_date DESC, status);

CREATE INDEX IF NOT EXISTS idx_amc_contracts_business_end_status
  ON public.amc_contracts(business_id, end_date ASC, status);

CREATE INDEX IF NOT EXISTS idx_reminders_business_due_status
  ON public.reminders(business_id, due_at ASC, status);

CREATE INDEX IF NOT EXISTS idx_comm_logs_business_created
  ON public.communication_logs(business_id, created_at DESC);

