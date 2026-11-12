-- ==============================================================================
-- Migration: 20261105160001_add_customer_type.sql
-- Description: Add customer_type column to customers table (individual / business)
-- ==============================================================================

ALTER TABLE public.customers
ADD COLUMN IF NOT EXISTS customer_type TEXT NOT NULL DEFAULT 'individual'
CHECK (customer_type IN ('individual', 'business'));

CREATE INDEX IF NOT EXISTS idx_customers_customer_type
ON public.customers(business_id, customer_type);

