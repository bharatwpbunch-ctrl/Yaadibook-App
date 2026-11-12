# Yaadibook — Phase 10 Performance Audit

## 1. Database & Query Optimization
- Added composite reporting & pagination indexes in `supabase/migrations/20261112100001_subscriptions_entitlements_and_deletion.sql`:
  - `idx_service_entries_business_date_status` on `service_entries(business_id, service_date DESC, status)`
  - `idx_maint_occ_business_due_status` on `maintenance_occurrences(business_id, due_date DESC, status)`
  - `idx_amc_contracts_business_end_status` on `amc_contracts(business_id, end_date ASC, status)`
  - `idx_reminders_business_due_status` on `reminders(business_id, due_at ASC, status)`
  - `idx_comm_logs_business_created` on `communication_logs(business_id, created_at DESC)`
- Server-side `get_reports_summary(p_business_id, p_start_date, p_end_date)` aggregates KPIs directly in PostgreSQL, avoiding excessive client-side aggregation over unbounded historical rows.
- Report detail list queries apply bounded date filters and `.limit(300)` caps, while PDF table output caps at 60 rows per export to keep mobile memory footprint low.

## 2. Offline Cache & Sync Performance
- Local Drift SQLite database creates targeted indexes (`idx_cached_entities_lookup`, `idx_pending_ops_business_status`) and wraps bulk entity cache writes in a single SQLite `transaction(...)`.
- Dirty cached records (`is_dirty = 1`) are preserved during server refresh (`WHERE cached_entities.is_dirty = 0`) so pending offline user edits are never overwritten before sync completes.

## 3. Android Release Optimization
- Enabled R8 code shrinking (`isMinifyEnabled = true`) and resource shrinking (`isShrinkResources = true`) in `android/app/build.gradle.kts` alongside keep rules in `android/app/proguard-rules.pro`.
- Pure Flutter progress bars are used in Reports breakdown charts instead of heavy third-party charting libraries to keep AAB size minimal.

