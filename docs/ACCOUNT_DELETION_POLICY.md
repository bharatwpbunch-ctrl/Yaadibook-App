# Account & Data Deletion Policy — Yaadibook

## 1. Google Play Data Deletion Compliance
To meet Google Play User Data Policy requirements, Yaadibook provides an **in-app account deletion workflow** and documents an external web-request path.

## 2. In-App Deletion Workflow (Verified Implemented)
1. Navigate to **More -> Delete Account & Data** (`/settings/delete-account`).
2. Review the permanent deletion warning detailing all affected business records.
3. Optionally enter a reason and type the explicit safeguard confirmation phrase **`DELETE MY ACCOUNT`**.
4. Tap **Permanently Delete Account**.
5. Client invokes Supabase Edge Function `request-account-deletion` (`supabase/functions/request-account-deletion/index.ts`).

## 3. What Gets Deleted vs Retained
- **Deleted Immediately Upon Execution**:
  - Owner `auth.users` account & `public.profiles` row
  - Owned `public.businesses` workspace(s)
  - All cascaded operational records: customers, addresses, equipment, service entries, activities, maintenance plans & occurrences, AMC contracts, reminders, notifications, device tokens, message templates, communication logs, campaigns, and `business_subscriptions`
  - All uploaded storage files across buckets (`business-assets`, `customer-attachments`, `service-attachments`, `amc-documents`) under `{business_id}/`
  - Local device SQLite/offline cache (`offlineStoreProvider.clearAllData()`)
- **Minimal Compliance / Financial Audit Notes**:
  - `public.account_deletion_requests` logs an internal timestamped completion record (`email`, `status = 'completed'`, `completed_at`).
  - Google Play Store billing receipts remain retained independently by Google LLC under Play Store statutory records.

## 4. External Web Deletion Link (Before Publishing)
Before submitting to Google Play Console, publish a lightweight support page at `[ACCOUNT_DELETION_URL]` instructing users who uninstalled the app to email `[SUPPORT_EMAIL]` from their registered address to trigger the same server purge.

