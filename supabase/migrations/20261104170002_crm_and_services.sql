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

