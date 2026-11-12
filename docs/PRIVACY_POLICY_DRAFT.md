# Privacy Policy (Draft for Publication) — Yaadibook

> **Status**: Draft template prepared for legal review and hosting by the app publisher before Google Play submission. Replace bracketed placeholders (`[PUBLIC_ENTITY_NAME]`, `[SUPPORT_EMAIL]`, `[PRIVACY_URL]`).

**Effective Date**: [EFFECTIVE_DATE]  
**App Name**: Yaadibook  
**Publisher / Data Controller**: [PUBLIC_ENTITY_NAME]  
**Contact Email**: [SUPPORT_EMAIL]

## 1. Information We Collect
When you register and operate a business workspace on Yaadibook, we collect:
- **Owner & Business Account Data**: Name, email address, business name, business phone number, business address, preferred language (English, Gujarati, or Hindi).
- **Customer & Operational Records Entered by You**: Customer names, phone numbers, addresses, equipment notes, service logs, recorded amounts, maintenance schedules, AMC agreements, reminders, and communication logs.
- **Optional User-Uploaded Attachments**: Service photos or AMC PDF/image documents you choose to attach.
- **Optional Device Contacts Access**: Only when you explicitly tap "Import from Contacts" to create a customer record.
- **Push Notification Tokens**: Firebase Cloud Messaging (FCM) device registration tokens solely to deliver scheduled reminder alerts.
- **Subscription Verification Metadata**: Google Play product IDs, order IDs, and hashed purchase tokens to verify Pro entitlements. We do not collect or store raw credit card or UPI credentials.

## 2. How We Use Information
- Operating your business workspace, reminders, offline synchronization, and PDF/CSV exports.
- Enforcing business tenant isolation and verifying paid subscriptions.
- Sending user-requested or scheduled operational notifications.

## 3. Data Storage, Isolation & Security
- Data is stored in Supabase PostgreSQL protected by Row-Level Security (RLS) scoped strictly to the authenticated business owner.
- Traffic is encrypted in transit via TLS/HTTPS.
- Offline caches stored locally on your device are wiped automatically when you sign out or delete your account.

## 4. Third-Party Service Providers
- **Supabase**: Authentication, PostgreSQL database, file storage, and Edge Functions.
- **Google Firebase (FCM)**: Push notification delivery on Android.
- **Google Play Billing**: Subscription processing on Android.
- **Meta WhatsApp Cloud API / India DLT SMS Gateway** (only if enabled by a Pro business with consent).

## 5. Data Retention & Account Deletion
We retain your business data as long as your account remains active. You may permanently delete your account and all business records at any time from **More -> Delete Account & Data** inside the app or via [ACCOUNT_DELETION_URL].

