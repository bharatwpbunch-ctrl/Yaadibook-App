# Yaadibook — Offline Support & Synchronization Guide

## 1. Local Persistence Architecture
- **Mobile (Android / IO)**: Powered by `drift` + `sqlite3_flutter_libs` (`DriftOfflineDatabase` in `lib/core/database/drift_offline_database.dart`) stored inside the app's private application documents directory (`yaadibook_offline_v1.sqlite`).
- **Web & Headless Test Fallback**: `HybridOfflineStore` (`lib/core/database/offline_store.dart`) detects native SQLite availability cleanly and falls back to `InMemoryOfflineStore` when `dart:io` or `sqlite3` dynamic libraries are unavailable (such as Chrome Web).
- **Local Tables**:
  - `cached_entities(business_id, entity_type, entity_id, payload_json, updated_at, cached_at, is_dirty)`
  - `pending_operations(id, business_id, entity_type, entity_id, operation_type, payload_json, idempotency_key, base_updated_at, status, conflict_payload_json, error_message, retry_count, created_at, updated_at)`
  - `sync_metadata(business_id, entity_type, last_synced_at)`

## 2. Offline Capabilities Matrix
| Operation | Offline Behavior | Reason |
|---|---|---|
| View cached Customers, Services, Reminders | **Allowed** | Read-only cached JSON payloads per `business_id` |
| Create / Edit Customer | **Queued (`pending_sync`)** | Optimistically updated in cache with idempotency key |
| Create / Update Service Entry | **Queued (`pending_sync`)** | Safe append/update replay |
| Create / Complete General Reminder | **Queued (`pending_sync`)** | Safe reminder log completion |
| Business Reports View | **Offline Estimate** | Computed locally from cached entities with visible offline notice |
| AMC Renewal | **Blocked Offline** | Requires transactional multi-table contract transition |
| Google Play Subscription Upgrade | **Blocked Offline** | Requires Play Store checkout & server token verification |
| Bulk Campaigns & WhatsApp/SMS Cloud APIs | **Blocked Offline** | Requires server quota/consent enforcement & provider APIs |

## 3. Sync Flow & Conflict Handling
1. `connectivity_plus` monitors device network connectivity (`isOnlineProvider`).
2. When connectivity returns—or when the user taps **Sync Now** in `/settings/offline-sync`—`SyncController` runs `SyncEngine.syncPendingOperations()`.
3. Operations replay FIFO with UUID `idempotency_key` deduplication (plus phone-number duplicate check on offline-created customers).
4. Before applying `update_customer` or `update_service`, `SyncEngine` compares the server `updated_at` timestamp against `op.baseUpdatedAt`.
   - If the server record changed more recently (>2s tolerance), the operation enters status `conflict` and preserves `conflict_payload_json`.
   - The owner resolves conflicts in `OfflineSyncScreen` via **Keep My Edit** or **Use Server Copy**.

## 4. Logout & Multi-Tenant Cache Isolation
- Every query filters explicitly by `business_id`.
- `offlineStoreProvider` observes `authStateProvider` and automatically calls `store.clearAllData()` on sign-out, session termination, or account deletion.

