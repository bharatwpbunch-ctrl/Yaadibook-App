# Yaadibook — WhatsApp Integration

## 1. Dual-Channel Architecture

Yaadibook supports two complementary WhatsApp integration models:

### Model A: Manual Device-Based WhatsApp (Free)
- Uses `whatsapp://send?phone=...` deep link with universal `https://wa.me/...` fallback.
- Auto-formats Indian phone numbers to E.164 without '+' (`919825012345`).
- Pre-fills message text and opens WhatsApp on owner's phone.
- Owner reviews and taps Send inside WhatsApp.
- Cost: ₹0.00.
- Truthful status in logs: `opened_in_app`.

### Model B: Official Meta WhatsApp Business Cloud API (Paid / Automated)
- Direct integration via Supabase Edge Function (`supabase/functions/whatsapp-cloud-api`).
- Meta Graph API v21.0 template message dispatch.
- Webhook endpoint for live delivery receipts (`submitted`, `delivered`, `read`, `failed`).
- Supports commercial bulk broadcast campaigns.
- Cost: ~₹0.85 / marketing or utility conversation.

---

## 2. Phone Number Normalization

All phone numbers are processed by `CommunicationService.normalizePhoneNumber()`:
1. Strips all spaces, dashes, parentheses, and dots.
2. Removes leading `+`.
3. Strips India country code `91` if followed by 10 digits.
4. Strips leading `0` if followed by 10 digits.
5. `CommunicationService.formatForWhatsApp()` prepends `91` to 10-digit Indian numbers.

---

## 3. Webhook Configuration
- Endpoint: `https://<project-ref>.supabase.co/functions/v1/whatsapp-cloud-api`
- Verify Token: Configurable via `WHATSAPP_WEBHOOK_VERIFY_TOKEN` (default: `yaadibook_wa_verify`)
- Handled events: `messages`, `message_deliveries`, `message_reads`.

