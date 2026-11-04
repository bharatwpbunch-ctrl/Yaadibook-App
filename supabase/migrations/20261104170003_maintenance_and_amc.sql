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

