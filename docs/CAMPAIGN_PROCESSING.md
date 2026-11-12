# Yaadibook — Campaign Batch Processing & Rate Limiting

## 1. Overview
Bulk messaging campaigns are processed in rate-limited batches via the Supabase Edge Function `campaign-processor`.

---

## 2. Batch Execution Flow
1. Edge Function queries active campaigns with status `scheduled` or `processing`.
2. Fetches up to 50 pending recipients per batch.
3. Performs consent check against `customer_messaging_preferences`.
4. If opted out, marks recipient `skipped_opted_out` and logs reason.
5. If eligible, submits to WhatsApp Cloud API or SMS gateway.
6. Records `submitted` log in `communication_logs` with per-message cost.
7. Increments campaign progress counters (`successful_count`, `failed_count`, `actual_cost_inr`).
8. Updates aggregated usage table `communication_usage`.
9. When all recipients are processed, marks campaign status as `completed`.

