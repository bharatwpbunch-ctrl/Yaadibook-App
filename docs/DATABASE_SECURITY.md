# Yaadibook — Database Security & Tenant Isolation Architecture

## 1. Core Security Principles

Yaadibook's security model operates on a **zero-trust client architecture**. The Flutter mobile client is considered an untrusted environment. Consequently, no client-side authorization check is accepted as a substitute for database-level enforcement.

1. **Every table has Row Level Security (RLS) enabled** without exception.
2. **Every business record is tagged with `business_id`**.
3. **No client can access or mutate data without ownership verification**.
4. **All storage objects are scoped by path to `business_id` and verified via RLS**.
5. **Privileged service_role credentials are strictly forbidden on the mobile client**.

---

## 2. Row Level Security (RLS) Implementation

### 2.1 Ownership Verification Functions

To prevent policy duplication and optimize execution, ownership is verified via high-performance, security-definer helper functions:

```sql
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
```

**Security Analysis of `is_business_owner`:**
- **`STABLE`**: Allows PostgreSQL to cache the result for the duration of a single query, preventing redundant subqueries when scanning multi-row result sets.
- **`SECURITY DEFINER`**: Bypasses recursive RLS checks on the `businesses` table when evaluating child table policies.
- **`SET search_path = public`**: Prevents search-path hijacking attacks.

---

### 2.2 Table-by-Table RLS Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
| :--- | :--- | :--- | :--- | :--- |
| `profiles` | `auth.uid() = id` | `auth.uid() = id` | `auth.uid() = id` | ❌ Disabled |
| `businesses` | `owner_user_id = auth.uid()` | `owner_user_id = auth.uid()` | `owner_user_id = auth.uid()` | ❌ Restricted |
| `customers` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `customer_addresses` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `equipment` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `service_entries` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `maintenance_plans` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `maintenance_occurrences` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `amc_contracts` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `amc_reminder_schedules` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `reminders` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` |
| `communication_logs` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | ❌ Immutable | ❌ Immutable |
| `notification_preferences` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | ❌ Managed with business |
| `business_settings` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | `is_business_owner(business_id)` | ❌ Managed with business |
| `audit_logs` | `is_business_owner(business_id)` | `actor_user_id = auth.uid()` | ❌ Immutable | ❌ Immutable |

---

## 3. Storage Security & Bucket Policies

### 3.1 Buckets
- `business-assets` (Private, 5MB limit, PNG/JPEG/WEBP)
- `customer-attachments` (Private, 10MB limit, PNG/JPEG/PDF)
- `service-attachments` (Private, 10MB limit, PNG/JPEG/PDF)
- `amc-documents` (Private, 15MB limit, PNG/JPEG/PDF)

### 3.2 Path-Based Isolation Rule
Files must be uploaded using the path format:
```
<business_id>/<entity_type>/<file_name>
```
The storage RLS policy dynamically validates that the first path segment (`(storage.foldername(name))[1]`) matches a business owned by the authenticated caller:

```sql
CREATE POLICY "Owners can view own business assets"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id IN ('business-assets', 'customer-attachments', 'service-attachments', 'amc-documents') AND
    public.is_business_owner(((storage.foldername(name))[1])::uuid)
  );
```

---

## 4. Privileged Server Operations (RPCs)

### `create_business_workspace`
- Runs with `SECURITY DEFINER` privileges.
- Atomically creates:
  1. The `businesses` workspace record.
  2. Default `business_settings`.
  3. Default `notification_preferences`.
  4. An audit log entry recording the creation.
- Strict anti-abuse checks:
  - Caller must have a non-null `auth.uid()`.
  - An owner who already owns a business cannot create a second business (enforcing the 1-owner = 1-business MVP constraint).

---

## 5. Known Security Limitations & Future Hardening

1. **Unauthenticated Public Access**: None. All public buckets and tables are strictly closed.
2. **Bulk Communications**: Since manual WhatsApp/SMS messages are opened via native intent schemes (`whatsapp://send`), message content and recipient numbers are validated on device before intent dispatch.
3. **Audit Log Protection**: Direct SQL `UPDATE` and `DELETE` on `audit_logs` are forbidden by omitting those policies entirely.
