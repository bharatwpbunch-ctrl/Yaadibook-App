# Yaadibook — Customer Consent & Opt-Out Policy

## 1. Compliance Principles
To respect customer privacy and adhere to TRAI and Indian telecom regulations, Yaadibook maintains granular messaging consent records for each customer.

---

## 2. Consent Fields

Table: `customer_messaging_preferences`

| Field | Type | Default | Description |
|---|---|---|---|
| `whatsapp_opt_in` | boolean | `true` | Allows transactional service updates via WhatsApp |
| `sms_opt_in` | boolean | `true` | Allows transactional service alerts via SMS |
| `marketing_consent` | boolean | `false` | Explicit consent required for promotional campaigns |
| `consent_source` | text | `'default'` | `'in_person'`, `'verbal'`, `'electronic'`, `'default'` |
| `is_opted_out` | boolean | `false` | Master kill-switch. When true, blocks all communications |
| `opted_out_at` | timestamptz | `null` | Timestamp when opt-out was recorded |
| `opt_out_reason` | text | `null` | Reason recorded for opt-out |

---

## 3. Enforcement Rules
1. **Promotional / Bulk Messaging**: Strictly requires `is_opted_out == false` AND `marketing_consent == true`.
2. **Transactional Messages (Service/AMC)**: Allowed when `is_opted_out == false` AND respective channel opt-in is `true`.
3. **Opt-Out Action**: Can be recorded directly by the business owner on the Customer Details screen, or automatically when a customer replies "STOP" / "UNSUBSCRIBE".

