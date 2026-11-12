# Yaadibook — Provider Webhook Receipts & Inbound Status Handling

## 1. Webhook Endpoints
- **WhatsApp Cloud API**: `supabase/functions/whatsapp-cloud-api`
- **SMS Gateway Callback**: `supabase/functions/sms-gateway`

---

## 2. Status Ingestion Lifecycle

When Meta WhatsApp Cloud API pushes a delivery status webhook:
1. Webhook parses `entry[0].changes[0].value.statuses`.
2. Extracts Meta message ID (`wamid`).
3. Maps provider status:
   - `sent` -> `submitted`
   - `delivered` -> `delivered`
   - `read` -> `read`
   - `failed` -> `failed`
4. Updates matching record in `communication_logs` and `campaign_recipients`.
5. Mobile client receives realtime or polling updates via Riverpod.

