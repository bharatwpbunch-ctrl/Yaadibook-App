-- ==============================================================================
-- Self-Contained Demo Seed Script: supabase/seed_bharat_cctv_company.sql
-- Account: bharat.wpbunch@gmail.com
-- Business: Bharat CCTV Company
-- Description: 
--   1. Idempotently applies all schema upgrades (Phases 5-8) if not already present.
--   2. Resolves or provisions user bharat.wpbunch@gmail.com with confirmed email.
--   3. Seeds rich, realistic demo data covering all features:
--      - Customers (Business & Individual) + Multi-location Addresses
--      - Equipment Tracking (Hikvision, CP Plus, Dahua, Ezviz)
--      - Service Entries (Installation, Repair, Maintenance, Inspection) + Charges
--      - Service Activities History Timeline
--      - Maintenance Plans & Occurrences (Completed, Due Today, Overdue, Scheduled)
--      - AMC Contracts & Renewal Chain (Active, Expiring in 12d, Expired, Renewed)
--      - Unified Reminders (Due Today, Overdue, Upcoming, Snoozed, Completed)
--      - In-App Notification Centre (Unread Badges, Categories, Read History)
--      - Notification Preferences & Quiet Hours Configuration
--      - Communication & Audit Logs
-- ==============================================================================

-- ==============================================================================
-- PART 1: IDEMPOTENT SCHEMA UPGRADES (Guarantees all tables & columns exist)
-- ==============================================================================

-- 1. Customers customer_type
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS customer_type TEXT NOT NULL DEFAULT 'individual';

-- 2. Business sequences table
CREATE TABLE IF NOT EXISTS public.business_sequences (
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  sequence_type TEXT NOT NULL,
  current_val BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (business_id, sequence_type)
);
ALTER TABLE public.business_sequences ENABLE ROW LEVEL SECURITY;

-- 3. Service entries columns
ALTER TABLE public.service_entries
  ADD COLUMN IF NOT EXISTS service_number TEXT,
  ADD COLUMN IF NOT EXISTS work_performed TEXT,
  ADD COLUMN IF NOT EXISTS additional_charges NUMERIC(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_amount NUMERIC(12, 2);

-- 4. Service attachments & activities tables
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

CREATE TABLE IF NOT EXISTS public.service_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.service_entries(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
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

-- 5. Maintenance plans & occurrences columns
ALTER TABLE public.maintenance_plans
  ADD COLUMN IF NOT EXISTS plan_number TEXT,
  ADD COLUMN IF NOT EXISTS maintenance_type TEXT NOT NULL DEFAULT 'general',
  ADD COLUMN IF NOT EXISTS interval_unit TEXT NOT NULL DEFAULT 'months',
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS anchor_day INTEGER;

ALTER TABLE public.maintenance_occurrences
  ADD COLUMN IF NOT EXISTS occurrence_number INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS original_due_date DATE,
  ADD COLUMN IF NOT EXISTS work_performed TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS skip_reason TEXT,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2);

ALTER TABLE public.maintenance_occurrences
  DROP CONSTRAINT IF EXISTS maintenance_occurrences_status_check;
ALTER TABLE public.maintenance_occurrences
  ADD CONSTRAINT maintenance_occurrences_status_check
  CHECK (status IN ('scheduled', 'upcoming', 'due', 'overdue', 'completed', 'skipped', 'cancelled'));

-- 6. AMC contracts columns
ALTER TABLE public.amc_contracts
  ADD COLUMN IF NOT EXISTS number_of_visits INTEGER DEFAULT 4,
  ADD COLUMN IF NOT EXISTS included_services TEXT,
  ADD COLUMN IF NOT EXISTS excluded_services TEXT,
  ADD COLUMN IF NOT EXISTS special_terms TEXT,
  ADD COLUMN IF NOT EXISTS renewal_terms TEXT,
  ADD COLUMN IF NOT EXISTS renewal_date DATE,
  ADD COLUMN IF NOT EXISTS renewed_to_contract_id UUID REFERENCES public.amc_contracts(id) ON DELETE SET NULL;

-- 7. Notification preferences columns
ALTER TABLE public.notification_preferences
  ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS general_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS maintenance_advance_days INTEGER[] NOT NULL DEFAULT '{7, 3, 1, 0}',
  ADD COLUMN IF NOT EXISTS amc_advance_days INTEGER[] NOT NULL DEFAULT '{30, 15, 7, 1, 0}',
  ADD COLUMN IF NOT EXISTS quiet_hours_enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS quiet_hours_start TIME NOT NULL DEFAULT '22:00:00',
  ADD COLUMN IF NOT EXISTS quiet_hours_end TIME NOT NULL DEFAULT '08:00:00';

-- 8. Reminders columns & status check
ALTER TABLE public.reminders DROP CONSTRAINT IF EXISTS reminders_status_check;
ALTER TABLE public.reminders ADD CONSTRAINT reminders_status_check
  CHECK (status IN ('scheduled', 'due', 'overdue', 'completed', 'snoozed', 'cancelled'));

ALTER TABLE public.reminders
  ADD COLUMN IF NOT EXISTS snoozed_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS original_due_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS priority TEXT NOT NULL DEFAULT 'normal',
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'general_task',
  ADD COLUMN IF NOT EXISTS service_id UUID REFERENCES public.service_entries(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS completed_notes TEXT,
  ADD COLUMN IF NOT EXISTS completed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- 9. Device tokens table
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  device_name TEXT,
  device_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_device_token UNIQUE (business_id, fcm_token)
);
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- 10. In-App notifications table
CREATE TABLE IF NOT EXISTS public.in_app_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_id UUID REFERENCES public.reminders(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  provider_status TEXT NOT NULL DEFAULT 'delivered',
  provider_message_id TEXT,
  failure_reason TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.in_app_notifications ENABLE ROW LEVEL SECURITY;

-- 11. Notification queue table
CREATE TABLE IF NOT EXISTS public.notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_id UUID REFERENCES public.reminders(id) ON DELETE CASCADE,
  idempotency_key TEXT NOT NULL UNIQUE,
  notification_type TEXT NOT NULL DEFAULT 'general',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  scheduled_for TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued',
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  last_attempt_at TIMESTAMPTZ,
  next_retry_at TIMESTAMPTZ,
  last_error TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;

-- RLS policies helper
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'in_app_notifications' AND policyname = 'Owners can view own notifications') THEN
    CREATE POLICY "Owners can view own notifications" ON public.in_app_notifications FOR SELECT TO authenticated USING (public.is_business_owner(business_id));
    CREATE POLICY "Owners can update own notifications" ON public.in_app_notifications FOR UPDATE TO authenticated USING (public.is_business_owner(business_id)) WITH CHECK (public.is_business_owner(business_id));
    CREATE POLICY "Owners can insert own notifications" ON public.in_app_notifications FOR INSERT TO authenticated WITH CHECK (public.is_business_owner(business_id));
    CREATE POLICY "Owners can delete own notifications" ON public.in_app_notifications FOR DELETE TO authenticated USING (public.is_business_owner(business_id));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'service_activities' AND policyname = 'Owners can view own service activities') THEN
    CREATE POLICY "Owners can view own service activities" ON public.service_activities FOR SELECT TO authenticated USING (public.is_business_owner(business_id));
    CREATE POLICY "Owners can insert own service activities" ON public.service_activities FOR INSERT TO authenticated WITH CHECK (public.is_business_owner(business_id));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'service_attachments' AND policyname = 'Owners can view own service attachments') THEN
    CREATE POLICY "Owners can view own service attachments" ON public.service_attachments FOR SELECT TO authenticated USING (public.is_business_owner(business_id));
    CREATE POLICY "Owners can insert own service attachments" ON public.service_attachments FOR INSERT TO authenticated WITH CHECK (public.is_business_owner(business_id));
    CREATE POLICY "Owners can update own service attachments" ON public.service_attachments FOR UPDATE TO authenticated USING (public.is_business_owner(business_id)) WITH CHECK (public.is_business_owner(business_id));
    CREATE POLICY "Owners can delete own service attachments" ON public.service_attachments FOR DELETE TO authenticated USING (public.is_business_owner(business_id));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'device_tokens' AND policyname = 'Users can view own device tokens') THEN
    CREATE POLICY "Users can view own device tokens" ON public.device_tokens FOR SELECT TO authenticated USING (user_id = auth.uid() AND public.is_business_owner(business_id));
    CREATE POLICY "Users can insert own device tokens" ON public.device_tokens FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND public.is_business_owner(business_id));
    CREATE POLICY "Users can update own device tokens" ON public.device_tokens FOR UPDATE TO authenticated USING (user_id = auth.uid() AND public.is_business_owner(business_id)) WITH CHECK (user_id = auth.uid() AND public.is_business_owner(business_id));
    CREATE POLICY "Users can delete own device tokens" ON public.device_tokens FOR DELETE TO authenticated USING (user_id = auth.uid() AND public.is_business_owner(business_id));
  END IF;
END $$;


-- ==============================================================================
-- PART 2: DATA SEEDING (Bharat CCTV Company)
-- ==============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_business_id UUID;
  
  -- Customers
  c_shreeji UUID := gen_random_uuid();
  c_dr_patel UUID := gen_random_uuid();
  c_radhe_krishna UUID := gen_random_uuid();
  c_vikram UUID := gen_random_uuid();
  c_mehul UUID := gen_random_uuid();
  c_pooja UUID := gen_random_uuid();

  -- Addresses
  a_shreeji UUID := gen_random_uuid();
  a_dr_patel UUID := gen_random_uuid();
  a_radhe_krishna UUID := gen_random_uuid();
  a_vikram UUID := gen_random_uuid();
  a_mehul UUID := gen_random_uuid();
  a_pooja UUID := gen_random_uuid();

  -- Equipment
  eq_nvr_32 UUID := gen_random_uuid();
  eq_dvr_8 UUID := gen_random_uuid();
  eq_poe_16 UUID := gen_random_uuid();
  eq_wifi_4 UUID := gen_random_uuid();
  eq_ptz_dome UUID := gen_random_uuid();

  -- Services
  s_install UUID := gen_random_uuid();
  s_repair UUID := gen_random_uuid();
  s_maint UUID := gen_random_uuid();
  s_inspect UUID := gen_random_uuid();
  s_hdd_repair UUID := gen_random_uuid();

  -- Maintenance Plans
  mp_quarterly UUID := gen_random_uuid();
  mp_monthly UUID := gen_random_uuid();
  mp_half_yearly UUID := gen_random_uuid();

  -- Maintenance Occurrences
  mo_completed UUID := gen_random_uuid();
  mo_due_today UUID := gen_random_uuid();
  mo_future UUID := gen_random_uuid();
  mo_overdue UUID := gen_random_uuid();

  -- AMC Contracts
  amc_active UUID := gen_random_uuid();
  amc_expiring UUID := gen_random_uuid();
  amc_old_renewed UUID := gen_random_uuid();
  amc_new_renewed UUID := gen_random_uuid();
  amc_expired UUID := gen_random_uuid();

  -- Reminders
  r_due_maint UUID := gen_random_uuid();
  r_due_call UUID := gen_random_uuid();
  r_overdue_power UUID := gen_random_uuid();
  r_overdue_payment UUID := gen_random_uuid();
  r_upcoming_amc UUID := gen_random_uuid();
  r_upcoming_fw UUID := gen_random_uuid();
  r_snoozed UUID := gen_random_uuid();
  r_completed UUID := gen_random_uuid();

BEGIN
  -- ----------------------------------------------------------------------------
  -- 1. RESOLVE OR CREATE USER in auth.users
  -- ----------------------------------------------------------------------------
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = 'bharat.wpbunch@gmail.com';

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    INSERT INTO auth.users (
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      'authenticated',
      'authenticated',
      'bharat.wpbunch@gmail.com',
      crypt('Bharat@123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Bharat Patel"}'::jsonb,
      timezone('utc', now()),
      timezone('utc', now())
    );
  ELSE
    -- Auto-confirm email so login works seamlessly without verification blockers
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc', now())),
        raw_user_meta_data = jsonb_set(COALESCE(raw_user_meta_data, '{}'::jsonb), '{full_name}', '"Bharat Patel"')
    WHERE id = v_user_id;
  END IF;

  -- ----------------------------------------------------------------------------
  -- 2. OWNER PROFILE
  -- ----------------------------------------------------------------------------
  INSERT INTO public.profiles (
    id,
    full_name,
    phone,
    email,
    preferred_language
  ) VALUES (
    v_user_id,
    'Bharat Patel',
    '+919825011223',
    'bharat.wpbunch@gmail.com',
    'en'
  ) ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone;

  -- ----------------------------------------------------------------------------
  -- 3. BUSINESS WORKSPACE ("Bharat CCTV Company")
  -- ----------------------------------------------------------------------------
  SELECT id INTO v_business_id FROM public.businesses WHERE owner_user_id = v_user_id;

  IF v_business_id IS NULL THEN
    v_business_id := gen_random_uuid();
    INSERT INTO public.businesses (
      id,
      owner_user_id,
      business_name,
      business_category,
      business_description,
      phone,
      email,
      address_line_1,
      address_line_2,
      city,
      state,
      postal_code,
      country,
      currency_code,
      timezone,
      preferred_language,
      is_active
    ) VALUES (
      v_business_id,
      v_user_id,
      'Bharat CCTV Company',
      'CCTV & Security Systems',
      'Specialist in commercial IP camera installations, DVR/NVR surveillance setups, and Annual Maintenance Contracts (AMC) across Surat and South Gujarat.',
      '+919825011223',
      'bharat.wpbunch@gmail.com',
      'Shop 14, Ground Floor, Silicon Shoppers',
      'Opp. Satyanarayan Temple, Ring Road',
      'Surat',
      'Gujarat',
      '395002',
      'India',
      'INR',
      'Asia/Kolkata',
      'en',
      true
    );
  ELSE
    UPDATE public.businesses
    SET business_name = 'Bharat CCTV Company',
        business_category = 'CCTV & Security Systems',
        business_description = 'Specialist in commercial IP camera installations, DVR/NVR surveillance setups, and Annual Maintenance Contracts (AMC) across Surat and South Gujarat.',
        phone = '+919825011223',
        address_line_1 = 'Shop 14, Ground Floor, Silicon Shoppers',
        city = 'Surat',
        state = 'Gujarat',
        postal_code = '395002',
        updated_at = timezone('utc', now())
    WHERE id = v_business_id;
  END IF;

  -- ----------------------------------------------------------------------------
  -- 4. BUSINESS SETTINGS & NOTIFICATION PREFERENCES
  -- ----------------------------------------------------------------------------
  INSERT INTO public.business_settings (
    business_id,
    date_format,
    time_format,
    preferred_language,
    currency_code,
    timezone
  ) VALUES (
    v_business_id,
    'dd/MM/yyyy',
    '12h',
    'en',
    'INR',
    'Asia/Kolkata'
  ) ON CONFLICT (business_id) DO UPDATE SET
    preferred_language = 'en',
    timezone = 'Asia/Kolkata';

  INSERT INTO public.notification_preferences (
    business_id,
    push_notifications_enabled,
    maintenance_notifications_enabled,
    amc_notifications_enabled,
    followup_notifications_enabled,
    general_notifications_enabled,
    maintenance_advance_days,
    amc_advance_days,
    quiet_hours_enabled,
    quiet_hours_start,
    quiet_hours_end,
    preferred_notification_time
  ) VALUES (
    v_business_id,
    true,
    true,
    true,
    true,
    true,
    ARRAY[7, 3, 1, 0],
    ARRAY[30, 15, 7, 1, 0],
    true,
    '22:00:00'::time,
    '08:00:00'::time,
    '09:00:00'::time
  ) ON CONFLICT (business_id) DO UPDATE SET
    push_notifications_enabled = true,
    quiet_hours_enabled = true;

  -- Initialize atomic sequences
  INSERT INTO public.business_sequences (business_id, sequence_type, current_val)
  VALUES 
    (v_business_id, 'service', 10),
    (v_business_id, 'maintenance_plan', 5),
    (v_business_id, 'amc_contract', 5)
  ON CONFLICT (business_id, sequence_type) DO UPDATE SET
    current_val = GREATEST(business_sequences.current_val, EXCLUDED.current_val);

  -- ----------------------------------------------------------------------------
  -- 5. CLEAN PREVIOUS DEMO DATA FOR THIS BUSINESS (Idempotent cleanup)
  -- ----------------------------------------------------------------------------
  DELETE FROM public.in_app_notifications WHERE business_id = v_business_id;
  DELETE FROM public.notification_queue WHERE business_id = v_business_id;
  DELETE FROM public.communication_logs WHERE business_id = v_business_id;
  DELETE FROM public.reminders WHERE business_id = v_business_id;
  DELETE FROM public.service_activities WHERE business_id = v_business_id;
  DELETE FROM public.service_attachments WHERE business_id = v_business_id;
  DELETE FROM public.amc_reminder_schedules WHERE business_id = v_business_id;
  DELETE FROM public.amc_contracts WHERE business_id = v_business_id;
  DELETE FROM public.maintenance_occurrences WHERE business_id = v_business_id;
  DELETE FROM public.maintenance_plans WHERE business_id = v_business_id;
  DELETE FROM public.service_entries WHERE business_id = v_business_id;
  DELETE FROM public.equipment WHERE business_id = v_business_id;
  DELETE FROM public.customer_addresses WHERE business_id = v_business_id;
  DELETE FROM public.customers WHERE business_id = v_business_id;

  -- ----------------------------------------------------------------------------
  -- 6. INSERT CUSTOMERS (Mix of Business & Residential)
  -- ----------------------------------------------------------------------------
  INSERT INTO public.customers (
    id, business_id, full_name, primary_phone, alternate_phone, email, customer_type, notes, source
  ) VALUES
  (
    c_shreeji,
    v_business_id,
    'Shreeji Diamond Jewellers',
    '+919825123456',
    '+912612541122',
    'shreejidiamonds.surat@gmail.com',
    'business',
    'High-value diamond jewellery showroom. 32 4K IP cameras with server rack, dual 8TB HDDs and 4-hour emergency SLA.',
    'Client Referral'
  ),
  (
    c_dr_patel,
    v_business_id,
    'Dr. Rajesh Patel (Patel Clinic)',
    '+919879012345',
    '+912612781122',
    'drrajesh.clinic@yahoo.com',
    'business',
    'Multi-speciality eye & dental clinic with 8 cameras across reception, operation rooms, and pharmacy.',
    'Direct Walk-in'
  ),
  (
    c_radhe_krishna,
    v_business_id,
    'Radhe Krishna Textiles Pvt Ltd',
    '+919824098765',
    '+912612345678',
    'accounts@radhekrishnatex.com',
    'business',
    'Textile warehouse and trading office in Ring Road market. 16 high-range night vision bullet cameras.',
    'Textile Association'
  ),
  (
    c_vikram,
    v_business_id,
    'Vikrambhai Desai',
    '+919909011223',
    NULL,
    'vikram.desai@gmail.com',
    'individual',
    'Bungalow perimeter security with 8 cameras, smart video door bell, and mobile remote access.',
    'Word of Mouth'
  ),
  (
    c_mehul,
    v_business_id,
    'Mehulbhai Shah',
    '+919725044556',
    NULL,
    'mehul.shah88@gmail.com',
    'individual',
    '4-camera apartment system covering main entrance, parking area and lobby.',
    'Local Flyer'
  ),
  (
    c_pooja,
    v_business_id,
    'Poojaben Sharma',
    '+919825566778',
    NULL,
    NULL,
    'individual',
    'Requested quotation for complete home automation and 6 CCTV dome cameras for new villa construction.',
    'Walk-in Enquiry'
  );

  -- ----------------------------------------------------------------------------
  -- 7. CUSTOMER ADDRESSES
  -- ----------------------------------------------------------------------------
  INSERT INTO public.customer_addresses (
    id, business_id, customer_id, address_label, address_line_1, address_line_2, area, city, state, postal_code, landmark, is_default
  ) VALUES
  (
    a_shreeji,
    v_business_id,
    c_shreeji,
    'Main Showroom',
    'Shop 101-104, Zaveri Chambers',
    'Mini Bazaar, Main Road',
    'Varachha',
    'Surat',
    'Gujarat',
    '395006',
    'Opp. Surat Diamond Bourse Road',
    true
  ),
  (
    a_dr_patel,
    v_business_id,
    c_dr_patel,
    'Clinic',
    'B-201, 2nd Floor, Green Plaza',
    'LP Savani Road',
    'Adajan',
    'Surat',
    'Gujarat',
    '395009',
    'Near LP Savani Circle',
    true
  ),
  (
    a_radhe_krishna,
    v_business_id,
    c_radhe_krishna,
    'Main Warehouse',
    'Plot 45-48, Block C, GIDC Industrial Estate',
    'Near Surat-Navsari Road',
    'Pandesara',
    'Surat',
    'Gujarat',
    '394221',
    'Behind Overhead Water Tank',
    true
  ),
  (
    a_vikram,
    v_business_id,
    c_vikram,
    'Bungalow',
    'Bungalow 7, Shanti Niketan Society',
    'VIP Road',
    'Vesu',
    'Surat',
    'Gujarat',
    '395007',
    'Near Someshwara Enclave',
    true
  ),
  (
    a_mehul,
    v_business_id,
    c_mehul,
    'Residence',
    'Flat A-504, Skydeck Heights',
    'Canal Road',
    'Althan',
    'Surat',
    'Gujarat',
    '395017',
    'Near Althan BRTS Stand',
    true
  ),
  (
    a_pooja,
    v_business_id,
    c_pooja,
    'New Villa Site',
    'Villa 12, Royal Palm Residency',
    'Dumas Road',
    'Piplod',
    'Surat',
    'Gujarat',
    '395007',
    'Opp. VR Surat Mall',
    true
  );

  -- ----------------------------------------------------------------------------
  -- 8. EQUIPMENT
  -- ----------------------------------------------------------------------------
  INSERT INTO public.equipment (
    id, business_id, customer_id, customer_address_id, equipment_name, category, brand, model_number, serial_number, installation_date, warranty_start_date, warranty_end_date, status
  ) VALUES
  (
    eq_nvr_32,
    v_business_id,
    c_shreeji,
    a_shreeji,
    'Hikvision 32-Channel 4K NVR System',
    'CCTV',
    'Hikvision',
    'DS-7732NI-I4',
    'HKV-32-984411',
    '2026-01-10',
    '2026-01-10',
    '2028-01-09',
    'active'
  ),
  (
    eq_dvr_8,
    v_business_id,
    c_dr_patel,
    a_dr_patel,
    'CP Plus 8-Channel 5MP HD DVR Kit',
    'CCTV',
    'CP Plus',
    'CP-UVR-0801E1-CS',
    'CPP-08-112233',
    '2025-11-20',
    '2025-11-20',
    '2026-11-19',
    'active'
  ),
  (
    eq_poe_16,
    v_business_id,
    c_radhe_krishna,
    a_radhe_krishna,
    'Dahua 16-Channel PoE NVR',
    'CCTV',
    'Dahua',
    'DHI-NVR4216-16P-4KS2',
    'DH-16-553188',
    '2025-08-15',
    '2025-08-15',
    '2027-08-14',
    'active'
  ),
  (
    eq_wifi_4,
    v_business_id,
    c_mehul,
    a_mehul,
    'Ezviz 4-Camera Wireless NVR Kit',
    'CCTV',
    'Ezviz',
    'CS-W2D-B4-EUP',
    'EZV-04-778899',
    '2026-03-12',
    '2026-03-12',
    '2027-03-11',
    'active'
  ),
  (
    eq_ptz_dome,
    v_business_id,
    c_shreeji,
    a_shreeji,
    'Hikvision 2MP 25x Speed Dome PTZ Camera',
    'CCTV',
    'Hikvision',
    'DS-2DE4225IW-DE',
    'HKV-PTZ-332199',
    '2026-01-10',
    '2026-01-10',
    '2028-01-09',
    'active'
  );

  -- ----------------------------------------------------------------------------
  -- 9. SERVICE ENTRIES & BREAKDOWN CHARGES
  -- ----------------------------------------------------------------------------
  INSERT INTO public.service_entries (
    id, business_id, customer_id, customer_address_id, equipment_id, service_number, service_type, title, description, work_performed, service_date, status, service_amount, additional_charges, discount_amount, total_amount, payment_status, completed_at
  ) VALUES
  (
    s_install,
    v_business_id,
    c_shreeji,
    a_shreeji,
    eq_nvr_32,
    'YB-SRV-000001',
    'installation',
    'Full 32 IP Camera Setup & Server Rack Installation',
    'Complete turnkey installation of 32 IP cameras with 9U server rack, dual 8TB Western Digital Purple surveillance hard disks, and gigabit PoE switches.',
    'Mounted 28 dome cameras indoors, 4 bullet cameras outdoors, 1 PTZ camera in central hall. Pulled 1,200m D-Link CAT6 cable. Configured Hik-Connect mobile monitoring app on owner and manager phones.',
    CURRENT_DATE - INTERVAL '30 days',
    'completed',
    14000.00,
    42000.00,
    2000.00,
    54000.00,
    'paid',
    timezone('utc', now() - INTERVAL '30 days')
  ),
  (
    s_repair,
    v_business_id,
    c_dr_patel,
    a_dr_patel,
    eq_dvr_8,
    'YB-SRV-000002',
    'repair',
    'Power Supply Repair & BNC Cable Replacement',
    'Chamber 2 and reception cameras flickering due to 12V 10A central power supply failure.',
    'Diagnosed fluctuating DC voltage. Replaced SMPS unit with genuine CP Plus 12V 10A power supply. Re-crimped 4 BNC connectors and tested night vision LEDs.',
    CURRENT_DATE - INTERVAL '1 day',
    'in_progress',
    1500.00,
    3000.00,
    0.00,
    4500.00,
    'partially_paid',
    NULL
  ),
  (
    s_maint,
    v_business_id,
    c_shreeji,
    a_shreeji,
    eq_nvr_32,
    'YB-SRV-000003',
    'maintenance',
    'Quarterly Lens Cleaning & Camera Angle Recalibration',
    'Routine quarterly preventative maintenance checkup under AMC agreement.',
    NULL,
    CURRENT_DATE,
    'pending',
    2200.00,
    0.00,
    0.00,
    2200.00,
    'unpaid',
    NULL
  ),
  (
    s_inspect,
    v_business_id,
    c_radhe_krishna,
    a_radhe_krishna,
    eq_poe_16,
    'YB-SRV-000004',
    'inspection',
    'Comprehensive Security Audit & Blind Spot Survey',
    'On-site inspection of warehouse loading bays and fabric inventory racks.',
    'Inspected existing 16 camera field of view. Identified 3 blind spots near emergency exit and loading ramp. Submitted proposal for 4 additional long-range 80m IR bullet cameras.',
    CURRENT_DATE - INTERVAL '15 days',
    'completed',
    0.00,
    0.00,
    0.00,
    0.00,
    'paid',
    timezone('utc', now() - INTERVAL '15 days')
  ),
  (
    s_hdd_repair,
    v_business_id,
    c_mehul,
    a_mehul,
    eq_wifi_4,
    'YB-SRV-000005',
    'repair',
    'Hard Disk Replacement with 4TB SkyHawk Surveillance Drive',
    'DVR continuous beeping error due to bad sectors on aging hard drive.',
    NULL,
    CURRENT_DATE + INTERVAL '1 day',
    'pending',
    1800.00,
    8000.00,
    0.00,
    9800.00,
    'unpaid',
    NULL
  );

  -- ----------------------------------------------------------------------------
  -- 10. SERVICE ACTIVITIES (Audit Timeline)
  -- ----------------------------------------------------------------------------
  INSERT INTO public.service_activities (
    business_id, service_id, activity_type, title, description, old_status, new_status, actor_user_id
  ) VALUES
  (
    v_business_id,
    s_install,
    'created',
    'Service entry created',
    'Initial installation scheduled for Shreeji Diamond Jewellers.',
    NULL,
    'pending',
    v_user_id
  ),
  (
    v_business_id,
    s_install,
    'status_changed',
    'Work started',
    'Technician team arrived on-site and commenced cabling.',
    'pending',
    'in_progress',
    v_user_id
  ),
  (
    v_business_id,
    s_install,
    'completed',
    'Installation successfully completed',
    'All 32 cameras tested and verified. Client signed completion handover note.',
    'in_progress',
    'completed',
    v_user_id
  ),
  (
    v_business_id,
    s_repair,
    'created',
    'Service entry created',
    'Repair ticket logged for power supply issue at Patel Clinic.',
    NULL,
    'pending',
    v_user_id
  ),
  (
    v_business_id,
    s_repair,
    'status_changed',
    'Repair in progress',
    'SMPS unit replaced, awaiting final 24-hour recording observation.',
    'pending',
    'in_progress',
    v_user_id
  );

  -- ----------------------------------------------------------------------------
  -- 11. MAINTENANCE PLANS & OCCURRENCES
  -- ----------------------------------------------------------------------------
  INSERT INTO public.maintenance_plans (
    id, business_id, customer_id, equipment_id, plan_number, title, description, maintenance_type, frequency_type, interval_value, interval_unit, start_date, next_due_date, reminder_days_before, status, anchor_day
  ) VALUES
  (
    mp_quarterly,
    v_business_id,
    c_shreeji,
    eq_nvr_32,
    'YB-MP-000001',
    'Quarterly CCTV Maintenance & Recording Verification',
    'Quarterly checkup of 32 cameras, NVR firmware, hard drive SMART health status, and UPS battery backup.',
    'preventative',
    'quarterly',
    3,
    'months',
    CURRENT_DATE - INTERVAL '90 days',
    CURRENT_DATE,
    7,
    'active',
    EXTRACT(DAY FROM CURRENT_DATE)::integer
  ),
  (
    mp_monthly,
    v_business_id,
    c_radhe_krishna,
    eq_poe_16,
    'YB-MP-000002',
    'Monthly Fabric Dust Cleaning & Camera Alignment',
    'Monthly cleaning of camera glass from textile airborne fluff and checking PTZ wiper blades.',
    'cleaning',
    'monthly',
    1,
    'months',
    CURRENT_DATE - INTERVAL '60 days',
    CURRENT_DATE - INTERVAL '4 days',
    3,
    'active',
    EXTRACT(DAY FROM (CURRENT_DATE - INTERVAL '4 days'))::integer
  ),
  (
    mp_half_yearly,
    v_business_id,
    c_vikram,
    NULL,
    'YB-MP-000003',
    'Six-Monthly Residential Perimeter Audit',
    'Bungalow boundary camera inspection, night vision infrared check, and video doorbell battery replacement.',
    'inspection',
    'half_yearly',
    6,
    'months',
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE + INTERVAL '150 days',
    7,
    'active',
    15
  );

  -- Maintenance Occurrences
  INSERT INTO public.maintenance_occurrences (
    id, business_id, maintenance_plan_id, customer_id, equipment_id, occurrence_number, due_date, original_due_date, reminder_trigger_date, status, work_performed, notes, amount, completed_at
  ) VALUES
  (
    mo_completed,
    v_business_id,
    mp_quarterly,
    c_shreeji,
    eq_nvr_32,
    1,
    CURRENT_DATE - INTERVAL '90 days',
    CURRENT_DATE - INTERVAL '90 days',
    CURRENT_DATE - INTERVAL '97 days',
    'completed',
    'Cleaned all 32 domes, tightened BNC connections, verified 30-day recording retention on 16TB storage.',
    'Client satisfied with recording clarity.',
    2200.00,
    timezone('utc', now() - INTERVAL '90 days')
  ),
  (
    mo_due_today,
    v_business_id,
    mp_quarterly,
    c_shreeji,
    eq_nvr_32,
    2,
    CURRENT_DATE,
    CURRENT_DATE,
    CURRENT_DATE - INTERVAL '7 days',
    'due',
    NULL,
    'Today visit scheduled at 10:30 AM. Contact manager Rameshbhai.',
    2200.00,
    NULL
  ),
  (
    mo_future,
    v_business_id,
    mp_quarterly,
    c_shreeji,
    eq_nvr_32,
    3,
    CURRENT_DATE + INTERVAL '90 days',
    CURRENT_DATE + INTERVAL '90 days',
    CURRENT_DATE + INTERVAL '83 days',
    'scheduled',
    NULL,
    'Q3 scheduled preventative maintenance.',
    2200.00,
    NULL
  ),
  (
    mo_overdue,
    v_business_id,
    mp_monthly,
    c_radhe_krishna,
    eq_poe_16,
    2,
    CURRENT_DATE - INTERVAL '4 days',
    CURRENT_DATE - INTERVAL '4 days',
    CURRENT_DATE - INTERVAL '7 days',
    'overdue',
    NULL,
    'Overdue! Fabric dust accumulation reported on warehouse camera 4 and camera 9.',
    1500.00,
    NULL
  );

  -- ----------------------------------------------------------------------------
  -- 12. AMC CONTRACTS & RENEWAL CHAINS
  -- ----------------------------------------------------------------------------
  INSERT INTO public.amc_contracts (
    id, business_id, customer_id, equipment_id, contract_number, contract_title, description, start_date, end_date, contract_amount, number_of_visits, payment_status, status, included_services, excluded_services, special_terms
  ) VALUES
  (
    amc_active,
    v_business_id,
    c_shreeji,
    eq_nvr_32,
    'YB-AMC-000001',
    'Comprehensive Diamond Showroom 24x7 Security AMC',
    'Annual premium contract for 32 cameras and Hikvision NVR with guaranteed 4-hour breakdown response time.',
    CURRENT_DATE - INTERVAL '60 days',
    CURRENT_DATE + INTERVAL '305 days',
    36000.00,
    4,
    'paid',
    'active',
    'Includes 4 scheduled quarterly visits, unlimited breakdown call-outs, connector replacements, and DVR software updates.',
    'Excludes lightning strike damage and physical camera breakage.',
    'Emergency response within 4 hours of phone logging.'
  ),
  (
    amc_expiring,
    v_business_id,
    c_dr_patel,
    eq_dvr_8,
    'YB-AMC-000002',
    'Annual CCTV Preventative Maintenance Contract',
    'Expiring Soon! Annual maintenance contract for clinic surveillance cameras.',
    CURRENT_DATE - INTERVAL '353 days',
    CURRENT_DATE + INTERVAL '12 days',
    14000.00,
    3,
    'paid',
    'expiring',
    'Includes 3 preventative maintenance visits, lens cleaning, SMPS load check, and backup recovery support.',
    'Hardware replacements billed at actuals with 10% discount.',
    'Ready for 1-tap contract renewal for upcoming year.'
  ),
  (
    amc_old_renewed,
    v_business_id,
    c_mehul,
    eq_wifi_4,
    'YB-AMC-000003',
    'Apartment CCTV Standard AMC (Year 2025)',
    'Previous year apartment AMC contract. Successfully renewed for 2026.',
    CURRENT_DATE - INTERVAL '400 days',
    CURRENT_DATE - INTERVAL '35 days',
    6000.00,
    2,
    'paid',
    'renewed',
    'Two seasonal visits and mobile app troubleshooting.',
    'New camera additions not included.',
    'Non-destructive renewal predecessor contract.'
  ),
  (
    amc_new_renewed,
    v_business_id,
    c_mehul,
    eq_wifi_4,
    'YB-AMC-000004',
    'Apartment CCTV Standard AMC (Year 2026)',
    'Current renewed contract with successor link pointing to Year 2025 predecessor.',
    CURRENT_DATE - INTERVAL '34 days',
    CURRENT_DATE + INTERVAL '330 days',
    6500.00,
    2,
    'paid',
    'active',
    'Two seasonal visits and mobile app troubleshooting.',
    'New camera additions not included.',
    'Renewed with 500 INR revision.'
  ),
  (
    amc_expired,
    v_business_id,
    c_vikram,
    NULL,
    'YB-AMC-000005',
    'Bungalow Perimeter Surveillance AMC',
    'Expired contract! Ready to contact owner for annual renewal proposal.',
    CURRENT_DATE - INTERVAL '410 days',
    CURRENT_DATE - INTERVAL '45 days',
    12000.00,
    2,
    'paid',
    'expired',
    'Bi-annual thorough inspection of perimeter cameras and boundary motion sensors.',
    'Wire chewing by rodents excluded.',
    'Client requested renewal quote with addition of 2 new driveway cameras.'
  );

  -- Link renewal chain pointers
  UPDATE public.amc_contracts
  SET renewed_to_contract_id = amc_new_renewed
  WHERE id = amc_old_renewed;

  UPDATE public.amc_contracts
  SET renewed_from_contract_id = amc_old_renewed
  WHERE id = amc_new_renewed;

  -- AMC Reminder schedules
  INSERT INTO public.amc_reminder_schedules (business_id, amc_contract_id, days_before_expiry, is_enabled)
  VALUES
    (v_business_id, amc_expiring, 30, true),
    (v_business_id, amc_expiring, 15, true),
    (v_business_id, amc_expiring, 7, true),
    (v_business_id, amc_expiring, 1, true),
    (v_business_id, amc_active, 30, true),
    (v_business_id, amc_active, 15, true)
  ON CONFLICT (amc_contract_id, days_before_expiry) DO NOTHING;

  -- ----------------------------------------------------------------------------
  -- 13. UNIFIED REMINDERS (All Categories, Priorities & Statuses)
  -- ----------------------------------------------------------------------------
  INSERT INTO public.reminders (
    id, business_id, customer_id, service_id, maintenance_occurrence_id, amc_contract_id, title, description, reminder_type, category, priority, due_at, original_due_at, snoozed_until, status, completed_at, completed_by_user_id, completed_notes
  ) VALUES
  (
    r_due_maint,
    v_business_id,
    c_shreeji,
    s_maint,
    mo_due_today,
    amc_active,
    'Quarterly Camera Lens Cleaning & Recording Check',
    'On-site maintenance visit scheduled today at 10:30 AM. Shreeji Diamond Jewellers showroom, Varachha.',
    'maintenance',
    'visit_customer',
    'high',
    CURRENT_DATE + TIME '10:30:00',
    CURRENT_DATE + TIME '10:30:00',
    NULL,
    'due',
    NULL,
    NULL,
    NULL
  ),
  (
    r_due_call,
    v_business_id,
    c_dr_patel,
    NULL,
    NULL,
    amc_expiring,
    'Call Dr. Rajesh Patel regarding AMC Contract Renewal',
    'AMC contract expires in 12 days. Discuss renewal quotation and confirm visit for signing.',
    'amc',
    'call_customer',
    'normal',
    CURRENT_DATE + TIME '15:00:00',
    CURRENT_DATE + TIME '15:00:00',
    NULL,
    'due',
    NULL,
    NULL,
    NULL
  ),
  (
    r_overdue_power,
    v_business_id,
    c_radhe_krishna,
    NULL,
    mo_overdue,
    NULL,
    'Urgent: Replace faulty power supply for Radhe Krishna Textiles',
    'Overdue visit: Warehouse cameras 4 & 9 down due to fabric dust clogging cooling fan.',
    'maintenance',
    'customer_followup',
    'urgent',
    CURRENT_DATE - INTERVAL '3 days' + TIME '11:00:00',
    CURRENT_DATE - INTERVAL '3 days' + TIME '11:00:00',
    NULL,
    'overdue',
    NULL,
    NULL,
    NULL
  ),
  (
    r_overdue_payment,
    v_business_id,
    c_dr_patel,
    s_repair,
    NULL,
    NULL,
    'Collect balance payment ₹3,000 for SMPS power supply repair',
    'Pending balance for CP Plus SMPS replacement. Contact Dr. Patel accounts desk.',
    'follow_up',
    'payment_followup',
    'normal',
    CURRENT_DATE - INTERVAL '2 days' + TIME '17:00:00',
    CURRENT_DATE - INTERVAL '2 days' + TIME '17:00:00',
    NULL,
    'overdue',
    NULL,
    NULL,
    NULL
  ),
  (
    r_upcoming_amc,
    v_business_id,
    c_dr_patel,
    NULL,
    NULL,
    amc_expiring,
    'AMC Contract Expiry in 12 Days - Send Renewal Quotation',
    'Send WhatsApp proposal with 10% early renewal discount.',
    'amc',
    'customer_followup',
    'high',
    CURRENT_DATE + INTERVAL '5 days' + TIME '10:00:00',
    CURRENT_DATE + INTERVAL '5 days' + TIME '10:00:00',
    NULL,
    'scheduled',
    NULL,
    NULL,
    NULL
  ),
  (
    r_upcoming_fw,
    v_business_id,
    NULL,
    NULL,
    NULL,
    NULL,
    'Annual firmware update and password rotation for Hikvision NVRs',
    'Routine cybersecurity check: Update Hikvision firmware to latest security patch across corporate clients.',
    'general',
    'general_task',
    'low',
    CURRENT_DATE + INTERVAL '10 days' + TIME '11:00:00',
    CURRENT_DATE + INTERVAL '10 days' + TIME '11:00:00',
    NULL,
    'scheduled',
    NULL,
    NULL,
    NULL
  ),
  (
    r_snoozed,
    v_business_id,
    c_pooja,
    NULL,
    NULL,
    NULL,
    'Follow up with Poojaben Sharma for 8-camera villa quotation',
    'Client requested quotation review after family discussion. Snoozed until tomorrow morning.',
    'follow_up',
    'call_customer',
    'normal',
    CURRENT_DATE + INTERVAL '1 day' + TIME '09:00:00',
    CURRENT_DATE + TIME '11:00:00',
    CURRENT_DATE + INTERVAL '1 day' + TIME '09:00:00',
    'snoozed',
    NULL,
    NULL,
    NULL
  ),
  (
    r_completed,
    v_business_id,
    c_shreeji,
    s_install,
    NULL,
    NULL,
    'Handover mobile monitoring credentials & user training to Rajesh Zaveri',
    'Installed Hik-Connect on owner and manager phones. Provided live demonstration.',
    'general',
    'general_task',
    'normal',
    CURRENT_DATE - INTERVAL '2 days' + TIME '16:00:00',
    CURRENT_DATE - INTERVAL '2 days' + TIME '16:00:00',
    NULL,
    'completed',
    timezone('utc', now() - INTERVAL '2 days'),
    v_user_id,
    'Credentials securely handed over. Demonstrated PTZ joystick controls and playback bookmarking.'
  );

  -- ----------------------------------------------------------------------------
  -- 14. IN-APP NOTIFICATIONS (Notification Centre)
  -- ----------------------------------------------------------------------------
  INSERT INTO public.in_app_notifications (
    business_id, user_id, reminder_id, title, body, category, is_read, read_at, provider_status, created_at
  ) VALUES
  (
    v_business_id,
    v_user_id,
    r_due_maint,
    'Maintenance Visit Due Today',
    'Quarterly Camera Lens Cleaning & Recording Check scheduled today for Shreeji Diamond Jewellers.',
    'maintenance',
    false,
    NULL,
    'delivered',
    timezone('utc', now() - INTERVAL '2 hours')
  ),
  (
    v_business_id,
    v_user_id,
    r_due_call,
    'AMC Contract Expiring Soon (12 Days)',
    'Annual AMC Contract for Dr. Rajesh Patel Clinic expires in 12 days. Tap to review and renew.',
    'amc',
    false,
    NULL,
    'delivered',
    timezone('utc', now() - INTERVAL '4 hours')
  ),
  (
    v_business_id,
    v_user_id,
    r_overdue_power,
    'Urgent Task Overdue (3 Days)',
    'Replace faulty power supply for Radhe Krishna Textiles is overdue. Contact customer immediately.',
    'followup',
    false,
    NULL,
    'delivered',
    timezone('utc', now() - INTERVAL '6 hours')
  ),
  (
    v_business_id,
    v_user_id,
    NULL,
    'Service Completed Successfully',
    'Full 32 IP Camera Setup & Server Rack Installation for Shreeji Diamond Jewellers marked completed. Payment of ₹54,000 received.',
    'general',
    true,
    timezone('utc', now() - INTERVAL '1 day'),
    'delivered',
    timezone('utc', now() - INTERVAL '2 days')
  ),
  (
    v_business_id,
    v_user_id,
    NULL,
    'Welcome to Yaadibook!',
    'Your workspace "Bharat CCTV Company" has been successfully set up with demo data across all modules.',
    'system',
    true,
    timezone('utc', now() - INTERVAL '2 days'),
    'delivered',
    timezone('utc', now() - INTERVAL '3 days')
  );

  -- ----------------------------------------------------------------------------
  -- 15. COMMUNICATION LOGS
  -- ----------------------------------------------------------------------------
  INSERT INTO public.communication_logs (
    business_id, customer_id, reminder_id, channel, direction, message_type, message_content, status, created_at
  ) VALUES
  (
    v_business_id,
    c_shreeji,
    r_due_maint,
    'call',
    'outgoing',
    'manual',
    'Initiated call to confirm 10:30 AM arrival for quarterly maintenance.',
    'initiated',
    timezone('utc', now() - INTERVAL '1 hour')
  ),
  (
    v_business_id,
    c_dr_patel,
    r_due_call,
    'whatsapp',
    'outgoing',
    'manual',
    'Opened WhatsApp chat with renewal proposal for AMC-202511-0002.',
    'opened',
    timezone('utc', now() - INTERVAL '3 hours')
  );

  -- ----------------------------------------------------------------------------
  -- 16. AUDIT LOGS
  -- ----------------------------------------------------------------------------
  INSERT INTO public.audit_logs (
    business_id, actor_user_id, action, entity_type, entity_id, metadata, created_at
  ) VALUES
  (
    v_business_id,
    v_user_id,
    'workspace_seeded',
    'business',
    v_business_id,
    '{"event":"demo_data_populated","business_name":"Bharat CCTV Company"}'::jsonb,
    timezone('utc', now())
  ),
  (
    v_business_id,
    v_user_id,
    'service_completed',
    'service_entry',
    s_install,
    '{"service_number":"YB-SRV-000001","amount":54000}'::jsonb,
    timezone('utc', now() - INTERVAL '30 days')
  );

  RAISE NOTICE 'SUCCESS: Comprehensive demo data successfully created for Bharat CCTV Company!';
  RAISE NOTICE 'User ID: %', v_user_id;
  RAISE NOTICE 'Business ID: %', v_business_id;

END $$;
