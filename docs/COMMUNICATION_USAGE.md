# Yaadibook — Communication Usage & Cost Tracking

## 1. Cost Transparency for Indian SMBs
Local businesses need absolute clarity on communication costs. Yaadibook breaks down messaging expenses transparently:

- **Free Device Dispatch**: When using "Open in WhatsApp" or "Open in SMS", no gateway costs are incurred (₹0.00).
- **Official WhatsApp Cloud API**: ~₹0.85 per utility / marketing conversation.
- **Indian DLT SMS Gateway**: ~₹0.20 per 160-character message.

---

## 2. Daily & Aggregated Metrics
The `communication_usage` table records:
- Channel (`whatsapp`, `sms`)
- Category (`transactional`, `service_update`, `amc_renewal`, `marketing`)
- Message count
- Total cost in INR (₹)
- Usage date

