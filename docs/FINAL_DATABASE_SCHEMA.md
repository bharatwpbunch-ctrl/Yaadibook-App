# Yaadibook — Final Database Schema (PostgreSQL / Supabase)

All migrations reside in version-controlled chronological SQL files under `supabase/migrations/` (`20261104170001` through `20261112100001`).

## 1. Core & Multi-Tenant Root
- `public.profiles`: Linked 1:1 with `auth.users(id)` (`full_name`, `email`, `preferred_language`).
- `public.businesses`: Root tenant entity (`owner_user_id`, `business_name`, `business_category`, `phone`, `address_line_1/2`, `city`, `state`, `postal_code`, `currency_code`, `timezone`). Every business-owned table carries `business_id` protected by RLS helper `public.is_business_owner(business_id)`.

## 2. CRM, Services, Maintenance & AMC
- `public.customers` (`uq_customers_business_id_id` composite FK anchor)
- `public.customer_addresses`
- `public.equipment`
- `public.service_entries` (`service_type`, `service_date`, `status`, `service_amount`, `additional_charges`, `discount_amount`, `total_amount`, `payment_status`)
- `public.service_activities`, `public.service_attachments`
- `public.maintenance_plans` (`frequency_type`, `interval_value`, `start_date`, `next_due_date`, `reminder_days_before`, `status`)
- `public.maintenance_occurrences`
- `public.amc_contracts` (`contract_title`, `start_date`, `end_date`, `contract_amount`, `payment_status`, `status`, `renewed_from_contract_id`)
- `public.amc_reminder_schedules`

## 3. Unified Reminders, Notifications & Messaging
- `public.reminders` (`reminder_type`, `category`, `priority`, `due_at`, `status`, `snoozed_until`, `completed_notes`)
- `public.notification_preferences` (channel toggles, advance days arrays, quiet hours)
- `public.device_tokens` (`user_id`, `business_id`, `fcm_token`, `platform`)
- `public.in_app_notifications`, `public.notification_queue`
- `public.message_templates`, `public.customer_messaging_preferences`
- `public.communication_logs`, `public.provider_configurations`
- `public.communication_campaigns`, `public.campaign_recipients`, `public.communication_usage`

## 4. Subscriptions, Entitlements & Compliance (Phase 10)
- `public.subscription_plans`: Seeded plans (`free`, `pro_monthly`, `pro_yearly`), INR pricing, Play Store `play_product_id`, limits (`max_customers`, `max_monthly_campaign_messages`, `max_storage_bytes`), feature booleans. Authenticated SELECT only.
- `public.business_subscriptions`: One row per `business_id` (`plan_code`, `status`, `store_provider`, `product_id`, `purchase_token_hash`, `order_id`, `current_period_start`, `current_period_end`, `grace_period_end`, `auto_renew`, `cancelled_at`). **RLS strictly SELECT-only for owners; mutations allowed exclusively via service-role Edge Functions / triggers.**
- `public.subscription_transactions`: Immutable ledger (`external_transaction_id` UNIQUE replay guard). **RLS strictly SELECT-only for owners.**
- `public.account_deletion_requests`: Audit log tracking deletion status (`requested`, `processing`, `completed`, `failed`).

## 5. Server-Side RPCs
- `get_my_business_id()`
- `get_business_entitlements(p_business_id UUID)`
- `check_business_entitlement(p_business_id UUID, p_feature_key TEXT)`
- `get_reports_summary(p_business_id UUID, p_start_date DATE, p_end_date DATE)`

## 6. Storage Buckets
Private buckets `business-assets`, `customer-attachments`, `service-attachments`, `amc-documents` gated by `public.is_business_owner(((storage.foldername(name))[1])::uuid)`.

