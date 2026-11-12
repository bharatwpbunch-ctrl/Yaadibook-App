-- ==============================================================================
-- Yaadibook: Schema Privileges & User Auto-Confirm Fix
-- Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/indaxefhyszjllrnssvm/sql/new
-- ==============================================================================

-- 1. Grant usage and CRUD permissions to authenticated and anon roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- 2. Auto-confirm any pending/unconfirmed users in auth.users
UPDATE auth.users
SET email_confirmed_at = timezone('utc'::text, now())
WHERE email_confirmed_at IS NULL;

-- 3. Notify PostgREST to reload its schema cache
NOTIFY pgrst, 'reload schema';

