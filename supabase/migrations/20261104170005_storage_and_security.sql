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

