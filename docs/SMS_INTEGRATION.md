# Yaadibook — Indian SMS Integration & TRAI DLT Compliance

## 1. Indian Telecom Regulations (TRAI DLT)

In India, commercial and transactional SMS messages are regulated by TRAI (Telecom Regulatory Authority of India) under the TCCCPR regulations. Sending commercial SMS without DLT registration leads to message blocking and operator penalties.

### Required DLT Parameters:
1. **Principal Entity ID (PE ID)**: The 14–19 digit unique registration ID assigned to the business on operator portals (Vilpower, PingConnect, TrueConnect, etc.).
2. **Header / Sender ID**: 6-character alphabetic sender name (e.g. `YADIBK` or `BHRCCT`).
3. **Content Template ID**: Unique template identifier approved on DLT with fixed and variable placeholder parts.

---

## 2. Dual SMS Dispatch Modes

### Mode 1: Native Device SMS (Default / Free)
- Uses `sms:<phone>?body=<encodedText>` URI via `url_launcher`.
- Works on Android and iOS using the owner's cellular SIM plan.
- No DLT approvals needed for personal one-on-one device SMS.
- Logged truthfully as `status: 'opened_in_app'`.

### Mode 2: DLT Gateway Dispatch (Automated / Bulk)
- Handled by Edge Function `supabase/functions/sms-gateway`.
- Configured in Provider Settings (`/communications/settings/sms`).
- Connects to Indian SMS aggregators (Fast2SMS, Textlocal, MSG91).
- Average rate: ₹0.20 / 160-character message.

