-- ==============================================================================
-- Migration: 20261104170001_core_schema.sql
-- Description: Core Schema Foundation (Extensions, Profiles, Businesses & RLS)
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. COMMON TRIGGER FOR updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$;

-- 3. PROFILES TABLE
-- Stores application owner profiles referencing auth.users.
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'gu', 'hi')),
  avatar_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Profiles RLS: Users can only read and update their own profile
CREATE POLICY "Users can read own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 4. BUSINESSES TABLE
-- Stores business workspaces. In MVP, one owner can own at most ONE business workspace.
CREATE TABLE public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
  business_name TEXT NOT NULL,
  business_category TEXT NOT NULL,
  business_description TEXT,
  phone TEXT NOT NULL,
  email TEXT,
  address_line_1 TEXT NOT NULL,
  address_line_2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL DEFAULT 'Gujarat',
  postal_code TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'India',
  logo_path TEXT,
  currency_code TEXT NOT NULL DEFAULT 'INR',
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'gu', 'hi')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  -- Composite unique key to enable composite foreign keys in child tenant tables
  CONSTRAINT uq_businesses_id_owner UNIQUE (id, owner_user_id)
);

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- 5. SECURITY HELPER FUNCTIONS
-- Checks whether current authenticated user is the owner of target business.
CREATE OR REPLACE FUNCTION public.is_business_owner(target_business_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.businesses
    WHERE id = target_business_id
      AND owner_user_id = auth.uid()
  );
$$;

-- Returns the business ID owned by current authenticated user.
CREATE OR REPLACE FUNCTION public.get_my_business_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.businesses
  WHERE owner_user_id = auth.uid()
  LIMIT 1;
$$;

-- Businesses RLS: Only the owner can view, update their business workspace
CREATE POLICY "Owners can view own business"
  ON public.businesses
  FOR SELECT
  TO authenticated
  USING (owner_user_id = auth.uid());

CREATE POLICY "Owners can create own business"
  ON public.businesses
  FOR INSERT
  TO authenticated
  WITH CHECK (owner_user_id = auth.uid());

CREATE POLICY "Owners can update own business"
  ON public.businesses
  FOR UPDATE
  TO authenticated
  USING (owner_user_id = auth.uid())
  WITH CHECK (owner_user_id = auth.uid());

-- ==============================================================================
-- Migration: 20261104170002_crm_and_services.sql
-- Description: Customers, Addresses, Equipment & Service Entries with Strict RLS
-- ==============================================================================

-- 1. CUSTOMERS TABLE
CREATE TABLE public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  primary_phone TEXT NOT NULL,
  alternate_phone TEXT,
  email TEXT,
  notes TEXT,
  source TEXT,
  archived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  -- Composite unique key to enforce tenant boundary on child records
  CONSTRAINT uq_customers_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Customers Indexes
CREATE INDEX idx_customers_business_id ON public.customers(business_id);
CREATE INDEX idx_customers_business_phone ON public.customers(business_id, primary_phone);
CREATE INDEX idx_customers_business_name ON public.customers(business_id, full_name);
CREATE INDEX idx_customers_archived ON public.customers(business_id, archived_at);

-- Customers RLS Policies
CREATE POLICY "Owners can view own customers"
  ON public.customers
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own customers"
  ON public.customers
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own customers"
  ON public.customers
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own customers"
  ON public.customers
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 2. CUSTOMER ADDRESSES TABLE
CREATE TABLE public.customer_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  address_label TEXT NOT NULL DEFAULT 'Main',
  address_line_1 TEXT NOT NULL,
  address_line_2 TEXT,
  area TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL DEFAULT 'Gujarat',
  postal_code TEXT NOT NULL,
  landmark TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  -- Composite foreign key guarantees customer belongs to the exact same business
  CONSTRAINT fk_customer_addresses_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT uq_customer_addresses_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_customer_addresses_updated_at
  BEFORE UPDATE ON public.customer_addresses
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_customer_addresses_customer ON public.customer_addresses(business_id, customer_id);

-- Customer Addresses RLS
CREATE POLICY "Owners can view own customer addresses"
  ON public.customer_addresses
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own customer addresses"
  ON public.customer_addresses
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own customer addresses"
  ON public.customer_addresses
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own customer addresses"
  ON public.customer_addresses
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 3. EQUIPMENT TABLE (Optional Device Tracking)
CREATE TABLE public.equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  customer_address_id UUID,
  equipment_name TEXT NOT NULL,
  category TEXT NOT NULL,
  brand TEXT,
  model_number TEXT,
  serial_number TEXT,
  installation_date DATE,
  warranty_start_date DATE,
  warranty_end_date DATE,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_equipment_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_equipment_address
    FOREIGN KEY (business_id, customer_address_id)
    REFERENCES public.customer_addresses(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT chk_equipment_warranty
    CHECK (warranty_end_date IS NULL OR warranty_start_date IS NULL OR warranty_end_date >= warranty_start_date),
  CONSTRAINT uq_equipment_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_equipment_updated_at
  BEFORE UPDATE ON public.equipment
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_equipment_customer ON public.equipment(business_id, customer_id);
CREATE INDEX idx_equipment_status ON public.equipment(business_id, status);

-- Equipment RLS
CREATE POLICY "Owners can view own equipment"
  ON public.equipment
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own equipment"
  ON public.equipment
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own equipment"
  ON public.equipment
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own equipment"
  ON public.equipment
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 4. SERVICE ENTRIES TABLE
CREATE TABLE public.service_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  customer_address_id UUID,
  equipment_id UUID,
  service_type TEXT NOT NULL CHECK (service_type IN ('installation', 'repair', 'maintenance', 'inspection', 'general', 'other')),
  title TEXT NOT NULL,
  description TEXT,
  service_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  service_amount NUMERIC(12, 2) CHECK (service_amount IS NULL OR service_amount >= 0),
  payment_status TEXT CHECK (payment_status IS NULL OR payment_status IN ('unpaid', 'partially_paid', 'paid', 'waived')),
  notes TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_service_entries_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_service_entries_address
    FOREIGN KEY (business_id, customer_address_id)
    REFERENCES public.customer_addresses(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_service_entries_equipment
    FOREIGN KEY (business_id, equipment_id)
    REFERENCES public.equipment(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT uq_service_entries_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.service_entries ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_service_entries_updated_at
  BEFORE UPDATE ON public.service_entries
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Service Entries Indexes
CREATE INDEX idx_service_entries_business_id ON public.service_entries(business_id);
CREATE INDEX idx_service_entries_customer ON public.service_entries(business_id, customer_id);
CREATE INDEX idx_service_entries_date ON public.service_entries(business_id, service_date);
CREATE INDEX idx_service_entries_status ON public.service_entries(business_id, status);

-- Service Entries RLS
CREATE POLICY "Owners can view own service entries"
  ON public.service_entries
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own service entries"
  ON public.service_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own service entries"
  ON public.service_entries
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own service entries"
  ON public.service_entries
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));

-- ==============================================================================
-- Migration: 20261104170003_maintenance_and_amc.sql
-- Description: Maintenance Plans, Occurrences, AMC Contracts & Reminder Schedules
-- ==============================================================================

-- 1. MAINTENANCE PLANS TABLE
CREATE TABLE public.maintenance_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  equipment_id UUID,
  service_entry_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  frequency_type TEXT NOT NULL CHECK (frequency_type IN ('one_time', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'custom')),
  interval_value INTEGER CHECK (interval_value IS NULL OR interval_value > 0),
  start_date DATE NOT NULL,
  next_due_date DATE NOT NULL,
  reminder_days_before INTEGER NOT NULL DEFAULT 7 CHECK (reminder_days_before >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'completed')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_maintenance_plans_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_maintenance_plans_equipment
    FOREIGN KEY (business_id, equipment_id)
    REFERENCES public.equipment(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_maintenance_plans_service
    FOREIGN KEY (business_id, service_entry_id)
    REFERENCES public.service_entries(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT chk_custom_frequency_interval
    CHECK (frequency_type != 'custom' OR (interval_value IS NOT NULL AND interval_value > 0)),
  CONSTRAINT uq_maintenance_plans_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.maintenance_plans ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_maintenance_plans_updated_at
  BEFORE UPDATE ON public.maintenance_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_maintenance_plans_business ON public.maintenance_plans(business_id);
CREATE INDEX idx_maintenance_plans_customer ON public.maintenance_plans(business_id, customer_id);
CREATE INDEX idx_maintenance_plans_next_due ON public.maintenance_plans(business_id, next_due_date);
CREATE INDEX idx_maintenance_plans_status ON public.maintenance_plans(business_id, status);

-- Maintenance Plans RLS
CREATE POLICY "Owners can view own maintenance plans"
  ON public.maintenance_plans
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own maintenance plans"
  ON public.maintenance_plans
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own maintenance plans"
  ON public.maintenance_plans
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own maintenance plans"
  ON public.maintenance_plans
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 2. MAINTENANCE OCCURRENCES TABLE
CREATE TABLE public.maintenance_occurrences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  maintenance_plan_id UUID NOT NULL,
  customer_id UUID NOT NULL,
  equipment_id UUID,
  due_date DATE NOT NULL,
  reminder_trigger_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'due', 'overdue', 'completed', 'cancelled')),
  completed_service_entry_id UUID,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_maintenance_occurrences_plan
    FOREIGN KEY (business_id, maintenance_plan_id)
    REFERENCES public.maintenance_plans(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_maintenance_occurrences_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_maintenance_occurrences_equipment
    FOREIGN KEY (business_id, equipment_id)
    REFERENCES public.equipment(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_maintenance_occurrences_service
    FOREIGN KEY (business_id, completed_service_entry_id)
    REFERENCES public.service_entries(business_id, id)
    ON DELETE SET NULL,
  -- Rule: Prevent duplicate occurrences for the same plan & due date
  CONSTRAINT uq_plan_due_date UNIQUE (maintenance_plan_id, due_date),
  CONSTRAINT uq_maintenance_occurrences_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.maintenance_occurrences ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_maintenance_occurrences_updated_at
  BEFORE UPDATE ON public.maintenance_occurrences
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_maintenance_occurrences_business ON public.maintenance_occurrences(business_id);
CREATE INDEX idx_maintenance_occurrences_due_date ON public.maintenance_occurrences(business_id, due_date);
CREATE INDEX idx_maintenance_occurrences_reminder ON public.maintenance_occurrences(business_id, reminder_trigger_date);
CREATE INDEX idx_maintenance_occurrences_status ON public.maintenance_occurrences(business_id, status);

-- Maintenance Occurrences RLS
CREATE POLICY "Owners can view own maintenance occurrences"
  ON public.maintenance_occurrences
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own maintenance occurrences"
  ON public.maintenance_occurrences
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own maintenance occurrences"
  ON public.maintenance_occurrences
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own maintenance occurrences"
  ON public.maintenance_occurrences
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 3. AMC CONTRACTS TABLE
CREATE TABLE public.amc_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  equipment_id UUID,
  contract_title TEXT NOT NULL,
  contract_number TEXT,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  contract_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (contract_amount >= 0),
  payment_status TEXT CHECK (payment_status IS NULL OR payment_status IN ('unpaid', 'partially_paid', 'paid')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'expiring', 'expired', 'renewed', 'cancelled')),
  coverage_details TEXT,
  document_path TEXT,
  notes TEXT,
  renewed_from_contract_id UUID REFERENCES public.amc_contracts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_amc_contracts_customer
    FOREIGN KEY (business_id, customer_id)
    REFERENCES public.customers(business_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_amc_contracts_equipment
    FOREIGN KEY (business_id, equipment_id)
    REFERENCES public.equipment(business_id, id)
    ON DELETE SET NULL,
  CONSTRAINT chk_amc_contract_dates CHECK (end_date >= start_date),
  CONSTRAINT uq_amc_contracts_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.amc_contracts ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_amc_contracts_updated_at
  BEFORE UPDATE ON public.amc_contracts
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_amc_contracts_business ON public.amc_contracts(business_id);
CREATE INDEX idx_amc_contracts_customer ON public.amc_contracts(business_id, customer_id);
CREATE INDEX idx_amc_contracts_end_date ON public.amc_contracts(business_id, end_date);
CREATE INDEX idx_amc_contracts_status ON public.amc_contracts(business_id, status);

-- AMC Contracts RLS
CREATE POLICY "Owners can view own AMC contracts"
  ON public.amc_contracts
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own AMC contracts"
  ON public.amc_contracts
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own AMC contracts"
  ON public.amc_contracts
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own AMC contracts"
  ON public.amc_contracts
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));


-- 4. AMC REMINDER SCHEDULES TABLE
CREATE TABLE public.amc_reminder_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  amc_contract_id UUID NOT NULL,
  days_before_expiry INTEGER NOT NULL CHECK (days_before_expiry >= 0),
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT fk_amc_reminder_schedules_contract
    FOREIGN KEY (business_id, amc_contract_id)
    REFERENCES public.amc_contracts(business_id, id)
    ON DELETE CASCADE,
  -- Rule: Prevent duplicate reminder offsets for the same AMC contract
  CONSTRAINT uq_amc_contract_offset UNIQUE (amc_contract_id, days_before_expiry),
  CONSTRAINT uq_amc_reminder_schedules_business_id_id UNIQUE (business_id, id)
);

ALTER TABLE public.amc_reminder_schedules ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER set_amc_reminder_schedules_updated_at
  BEFORE UPDATE ON public.amc_reminder_schedules
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_amc_reminder_contract ON public.amc_reminder_schedules(business_id, amc_contract_id);

-- AMC Reminder Schedules RLS
CREATE POLICY "Owners can view own AMC reminder schedules"
  ON public.amc_reminder_schedules
  FOR SELECT
  TO authenticated
  USING (public.is_business_owner(business_id));

CREATE POLICY "Owners can insert own AMC reminder schedules"
  ON public.amc_reminder_schedules
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can update own AMC reminder schedules"
  ON public.amc_reminder_schedules
  FOR UPDATE
  TO authenticated
  USING (public.is_business_owner(business_id))
  WITH CHECK (public.is_business_owner(business_id));

CREATE POLICY "Owners can delete own AMC reminder schedules"
  ON public.amc_reminder_schedules
  FOR DELETE
  TO authenticated
  USING (public.is_business_owner(business_id));

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

-- ==============================================================================
-- Migration: 20261104170005_storage_and_security.sql
-- Description: Supabase Storage Buckets & Storage RLS Policies
-- ==============================================================================

-- 1. CREATE STORAGE BUCKETS (Private by default)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'business-assets',
    'business-assets',
    false,
    5242880, -- 5MB limit
    ARRAY['image/png', 'image/jpeg', 'image/webp']
  ),
  (
    'customer-attachments',
    'customer-attachments',
    false,
    10485760, -- 10MB limit
    ARRAY['image/png', 'image/jpeg', 'image/webp', 'application/pdf']
  ),
  (
    'service-attachments',
    'service-attachments',
    false,
    10485760, -- 10MB limit
    ARRAY['image/png', 'image/jpeg', 'image/webp', 'application/pdf']
  ),
  (
    'amc-documents',
    'amc-documents',
    false,
    15728640, -- 15MB limit
    ARRAY['image/png', 'image/jpeg', 'image/webp', 'application/pdf']
  )
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;


-- 2. STORAGE OBJECTS RLS POLICIES
-- Scoped strictly to business_id prefix: <business_id>/...

CREATE POLICY "Owners can view own business assets"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id IN ('business-assets', 'customer-attachments', 'service-attachments', 'amc-documents') AND
    public.is_business_owner(((storage.foldername(name))[1])::uuid)
  );

CREATE POLICY "Owners can upload own business assets"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id IN ('business-assets', 'customer-attachments', 'service-attachments', 'amc-documents') AND
    public.is_business_owner(((storage.foldername(name))[1])::uuid)
  );

CREATE POLICY "Owners can update own business assets"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id IN ('business-assets', 'customer-attachments', 'service-attachments', 'amc-documents') AND
    public.is_business_owner(((storage.foldername(name))[1])::uuid)
  )
  WITH CHECK (
    bucket_id IN ('business-assets', 'customer-attachments', 'service-attachments', 'amc-documents') AND
    public.is_business_owner(((storage.foldername(name))[1])::uuid)
  );

CREATE POLICY "Owners can delete own business assets"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id IN ('business-assets', 'customer-attachments', 'service-attachments', 'amc-documents') AND
    public.is_business_owner(((storage.foldername(name))[1])::uuid)
  );

