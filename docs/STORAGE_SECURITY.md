# Yaadibook — Storage Architecture & Security Specification

## 1. Overview

Yaadibook utilizes private Supabase Storage buckets to store sensitive business data, including customer service photos, job completion receipts, and equipment documentation.

All storage objects are private by default with zero public read access.

---

## 2. Storage Buckets

| Bucket Name | Public Access | Max File Size | Allowed MIME Types | Purpose |
|---|---|---|---|---|
| `service-attachments` | `false` (Private) | 20 MB | `image/*`, `application/pdf` | Onsite service photos, diagnosis images, vendor invoices |
| `business-assets` | `false` (Private) | 5 MB | `image/*` | Business logos, signature stamps |

---

## 3. Path Isolation Strategy

Files are strictly partitioned by tenant ID (the business's UUID):

```text
service-attachments/
  └── {business_id}/
        └── {service_id}/
              └── {timestamp}_{sanitized_file_name}
```

### Path Extraction Helper
PostgreSQL Supabase Storage functions parse the top-level directory folder:
```sql
(storage.foldername(name))[1]  -- Extracts {business_id}
```

---

## 4. Row-Level Security Policies on `storage.objects`

The Supabase `storage.objects` table enforces multi-tenant boundary checks matching the authenticated user's business ownership:

```sql
-- READ: Allow business owner to view objects in their folder
CREATE POLICY "service_attachments_owner_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'service-attachments'
  AND public.is_business_owner(((storage.foldername(name))[1])::uuid)
);

-- WRITE: Allow business owner to upload files in their folder
CREATE POLICY "service_attachments_owner_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'service-attachments'
  AND public.is_business_owner(((storage.foldername(name))[1])::uuid)
);

-- DELETE: Allow business owner to delete files in their folder
CREATE POLICY "service_attachments_owner_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'service-attachments'
  AND public.is_business_owner(((storage.foldername(name))[1])::uuid)
);
```

---

## 5. Signed URL Access Pattern

Direct public URLs are prohibited. When a business owner views or downloads an attachment:
1. The client requests a signed URL with a short expiration time (e.g., 3600 seconds / 1 hour):
   ```dart
   final signedUrl = await supabase.storage
       .from('service-attachments')
       .createSignedUrl(filePath, 3600);
   ```
2. The signed URL includes an HMAC token that allows temporary read access.
3. Once expired, the URL cannot be reused or guessed.

