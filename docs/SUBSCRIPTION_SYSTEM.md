# Yaadibook — Subscription & Entitlement System

## 1. Plans & Product IDs (`subscription_plans`)
| Plan Code | Billing | Price (INR) | Google Play Product ID | Customer Limit | Monthly API Messages | Storage |
|---|---|---|---|---|---|---|
| `free` | Free | ₹0 | `NULL` | 100 active | 0 | 100 MB |
| `pro_monthly` | Monthly | ₹299 | `yaadibook_pro_monthly` | Unlimited | 1,000 | 2 GB |
| `pro_yearly` | Yearly | ₹2,999 | `yaadibook_pro_yearly` | Unlimited | 1,500 | 5 GB |

## 2. Database & Authorization Security
- On business creation, trigger `handle_new_business_subscription()` provisions an active `free` row in `business_subscriptions`.
- `business_subscriptions` and `subscription_transactions` enforce **SELECT-only RLS** for authenticated business owners. Clients cannot write subscription records directly.
- Authoritative entitlements are evaluated in PostgreSQL via `get_business_entitlements(p_business_id)` and consumed by:
  - Flutter `entitlementsProvider` (`lib/features/subscriptions/providers/subscription_providers.dart`), including `isBulkMessagingEntitledProvider` (no longer hardcoded).
  - Edge Functions (`whatsapp-cloud-api`, `sms-gateway`, `campaign-processor`) via `requireEntitlement(...)` before invoking external gateways.

## 3. Google Play Billing Integration
- Client wrapper: `PlayBillingService` (`lib/core/services/billing_service.dart`) using `in_app_purchase`.
- Server verifier: `supabase/functions/verify-play-purchase/index.ts`.
- Flow:
  1. Android Play Store completes purchase checkout and emits `PurchaseDetails`.
  2. Client sends `businessId`, `productId`, `purchaseToken`, `orderId` to `verify-play-purchase`.
  3. Edge Function validates user JWT ownership, verifies token with Google Play Developer API v3 (`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`), maps Google Play `subscriptionState` (`active`, `grace_period`, `pending`, `cancelled`, `expired`), upserts `business_subscriptions`, and logs idempotently into `subscription_transactions` using `external_transaction_id` uniqueness.
  4. Only after verification completes does `PlayBillingService` call `completePurchase`.

## 4. Cancellation, Grace Period & Data Preservation
- **Cancelled (`auto_renew = false`)**: Existing Pro access continues until `current_period_end`.
- **Grace Period**: Access remains active until `grace_period_end`.
- **Expired / Revoked**: Entitlements downgrade cleanly back to `free`. **Customer, service, maintenance, AMC, and reminder records are NEVER deleted upon expiry.**

