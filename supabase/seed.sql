-- ==============================================================================
-- Seed Data: supabase/seed.sql
-- Description: Realistic development seed data for local testing (No real personal info)
-- ==============================================================================

-- 1. Create a test owner user in auth.users if not exists
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
  '11111111-1111-1111-1111-111111111111'::uuid,
  'authenticated',
  'authenticated',
  'testowner@yaadibook.app',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"full_name":"Rakeshbhai Prajapati"}'::jsonb,
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

-- 2. Owner Profile
INSERT INTO public.profiles (
  id,
  full_name,
  phone,
  email,
  preferred_language
) VALUES (
  '11111111-1111-1111-1111-111111111111'::uuid,
  'Rakeshbhai Prajapati',
  '+919825012345',
  'testowner@yaadibook.app',
  'gu'
) ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name;

-- 3. Business Workspace
INSERT INTO public.businesses (
  id,
  owner_user_id,
  business_name,
  business_category,
  business_description,
  phone,
  email,
  address_line_1,
  city,
  state,
  postal_code,
  country,
  currency_code,
  timezone,
  preferred_language
) VALUES (
  '22222222-2222-2222-2222-222222222222'::uuid,
  '11111111-1111-1111-1111-111111111111'::uuid,
  'Maruti AC & CCTV Services',
  'AC & HVAC, CCTV Installation',
  'Specialist in AC servicing, AMC contracts, and CCTV installation across Ahmedabad.',
  '+919825012345',
  'contact@marutiservices.in',
  'Shop 12, Swastik Complex, CG Road',
  'Ahmedabad',
  'Gujarat',
  '380009',
  'India',
  'INR',
  'Asia/Kolkata',
  'gu'
) ON CONFLICT (id) DO NOTHING;

-- 4. Business Settings & Notification Preferences
INSERT INTO public.business_settings (
  business_id,
  date_format,
  time_format,
  preferred_language,
  currency_code,
  timezone
) VALUES (
  '22222222-2222-2222-2222-222222222222'::uuid,
  'dd/MM/yyyy',
  '12h',
  'gu',
  'INR',
  'Asia/Kolkata'
) ON CONFLICT (business_id) DO NOTHING;

INSERT INTO public.notification_preferences (
  business_id,
  reminder_notifications_enabled,
  maintenance_notifications_enabled,
  amc_notifications_enabled,
  followup_notifications_enabled,
  preferred_notification_time
) VALUES (
  '22222222-2222-2222-2222-222222222222'::uuid,
  true,
  true,
  true,
  true,
  '09:30:00'
) ON CONFLICT (business_id) DO NOTHING;

-- 5. Customers
INSERT INTO public.customers (
  id,
  business_id,
  full_name,
  primary_phone,
  alternate_phone,
  email,
  notes,
  source
) VALUES
(
  '33333333-3333-3333-3333-333333333331'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  'Kailash Electronics',
  '+919825011223',
  '+917926401234',
  'kailash@example.com',
  'Corporate client with 16-cam CCTV and 4 split ACs',
  'Referral'
),
(
  '33333333-3333-3333-3333-333333333332'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  'Bhavin Shah',
  '+919724056789',
  NULL,
  NULL,
  'Home AC & Water purifier client',
  'Direct Walk-in'
),
(
  '33333333-3333-3333-3333-333333333333'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  'Shree Krishna Jewellers',
  '+919426099887',
  NULL,
  'jewellers@example.com',
  'High-security showroom with DVR and IP cameras',
  'Existing Client'
)
ON CONFLICT (id) DO NOTHING;

-- 6. Customer Addresses
INSERT INTO public.customer_addresses (
  id,
  business_id,
  customer_id,
  address_label,
  address_line_1,
  area,
  city,
  state,
  postal_code,
  is_default
) VALUES
(
  '44444444-4444-4444-4444-444444444441'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333331'::uuid,
  'Main Showroom',
  'Near S.G. Highway, Bodakdev',
  'Bodakdev',
  'Ahmedabad',
  'Gujarat',
  '380054',
  true
),
(
  '44444444-4444-4444-4444-444444444442'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333332'::uuid,
  'Residence',
  'B-402, Gokul Heights, Satellite Road',
  'Satellite',
  'Ahmedabad',
  'Gujarat',
  '380015',
  true
)
ON CONFLICT (id) DO NOTHING;

-- 7. Equipment
INSERT INTO public.equipment (
  id,
  business_id,
  customer_id,
  customer_address_id,
  equipment_name,
  category,
  brand,
  model_number,
  serial_number,
  installation_date,
  warranty_start_date,
  warranty_end_date,
  status
) VALUES
(
  '55555555-5555-5555-5555-555555555551'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333331'::uuid,
  '44444444-4444-4444-4444-444444444441'::uuid,
  '16-Channel 4K NVR System',
  'CCTV',
  'Hikvision',
  'DS-7616NI-K2',
  'HKV-2026-9811',
  '2026-01-10',
  '2026-01-10',
  '2027-01-09',
  'active'
),
(
  '55555555-5555-5555-5555-555555555552'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333332'::uuid,
  '44444444-4444-4444-4444-444444444442'::uuid,
  '1.5 Ton 5-Star Inverter AC',
  'AC',
  'Voltas',
  '185V-DAZ',
  'VLT-2025-4422',
  '2025-05-15',
  '2025-05-15',
  '2026-05-14',
  'active'
)
ON CONFLICT (id) DO NOTHING;

-- 8. Service Entries
INSERT INTO public.service_entries (
  id,
  business_id,
  customer_id,
  customer_address_id,
  equipment_id,
  service_type,
  title,
  description,
  service_date,
  status,
  service_amount,
  payment_status,
  completed_at
) VALUES
(
  '66666666-6666-6666-6666-666666666661'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333331'::uuid,
  '44444444-4444-4444-4444-444444444441'::uuid,
  '55555555-5555-5555-5555-555555555551'::uuid,
  'installation',
  '16-Camera Setup and Cabling',
  'Installed 16 dome cameras and configured remote mobile view on owner phone.',
  '2026-01-10',
  'completed',
  24500.00,
  'paid',
  '2026-01-10 18:30:00+05:30'
),
(
  '66666666-6666-6666-6666-666666666662'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333332'::uuid,
  '44444444-4444-4444-4444-444444444442'::uuid,
  '55555555-5555-5555-5555-555555555552'::uuid,
  'maintenance',
  'Summer Jet Wash & Gas Pressure Check',
  'Complete coil cleaning, filter wash, pressure test R-32 gas.',
  '2026-04-12',
  'completed',
  1450.00,
  'paid',
  '2026-04-12 11:45:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

-- 9. AMC Contract & Reminder Schedule
INSERT INTO public.amc_contracts (
  id,
  business_id,
  customer_id,
  equipment_id,
  contract_title,
  contract_number,
  description,
  start_date,
  end_date,
  contract_amount,
  payment_status,
  status
) VALUES (
  '77777777-7777-7777-7777-777777777771'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333331'::uuid,
  '55555555-5555-5555-5555-555555555551'::uuid,
  'Comprehensive Annual CCTV Maintenance',
  'AMC-2026-001',
  'Quarterly inspection of cameras, connector tightening, backup battery check.',
  '2026-01-10',
  '2027-01-09',
  12000.00,
  'paid',
  'active'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.amc_reminder_schedules (
  business_id,
  amc_contract_id,
  days_before_expiry,
  is_enabled
) VALUES
  ('22222222-2222-2222-2222-222222222222'::uuid, '77777777-7777-7777-7777-777777777771'::uuid, 30, true),
  ('22222222-2222-2222-2222-222222222222'::uuid, '77777777-7777-7777-7777-777777777771'::uuid, 15, true),
  ('22222222-2222-2222-2222-222222222222'::uuid, '77777777-7777-7777-7777-777777777771'::uuid, 7, true)
ON CONFLICT (amc_contract_id, days_before_expiry) DO NOTHING;

-- 10. Reminders
INSERT INTO public.reminders (
  id,
  business_id,
  customer_id,
  amc_contract_id,
  title,
  description,
  reminder_type,
  due_at,
  status
) VALUES
(
  '88888888-8888-8888-8888-888888888881'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333331'::uuid,
  '77777777-7777-7777-7777-777777777771'::uuid,
  'AMC 4th Quarter Preventative Checkup',
  'Check camera focus and DVR power supply',
  'amc',
  '2026-11-15 10:00:00+05:30',
  'scheduled'
),
(
  '88888888-8888-8888-8888-888888888882'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333332'::uuid,
  NULL,
  'Follow-up on AC Winter Servicing Quote',
  'Call customer regarding servicing quotation',
  'follow_up',
  '2026-11-02 11:30:00+05:30',
  'overdue'
)
ON CONFLICT (id) DO NOTHING;

-- 11. Communication Logs
INSERT INTO public.communication_logs (
  business_id,
  customer_id,
  reminder_id,
  channel,
  direction,
  message_type,
  message_content,
  status,
  created_at
) VALUES (
  '22222222-2222-2222-2222-222222222222'::uuid,
  '33333333-3333-3333-3333-333333333332'::uuid,
  '88888888-8888-8888-8888-888888888882'::uuid,
  'call',
  'outgoing',
  'manual',
  'Initiated phone call for follow-up quote',
  'initiated',
  '2026-11-02 11:35:00+05:30'
);
