import 'package:drift/drift.dart';

/// Drift-backed local SQLite database for offline entity caching,
/// pending sync queue, conflict preservation, and sync metadata.
class DriftOfflineDatabase extends GeneratedDatabase {
  DriftOfflineDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement('''
            CREATE TABLE IF NOT EXISTS cached_entities (
              business_id TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              payload_json TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              cached_at TEXT NOT NULL,
              is_dirty INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (business_id, entity_type, entity_id)
            );
          ''');
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_cached_entities_lookup
            ON cached_entities(business_id, entity_type, updated_at DESC);
          ''');
      await customStatement('''
            CREATE TABLE IF NOT EXISTS pending_operations (
              id TEXT PRIMARY KEY,
              business_id TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              operation_type TEXT NOT NULL,
              payload_json TEXT NOT NULL,
              idempotency_key TEXT NOT NULL UNIQUE,
              base_updated_at TEXT,
              status TEXT NOT NULL DEFAULT 'pending_sync',
              conflict_payload_json TEXT,
              error_message TEXT,
              retry_count INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_pending_ops_business_status
            ON pending_operations(business_id, status, created_at ASC);
          ''');
      await customStatement('''
            CREATE TABLE IF NOT EXISTS sync_metadata (
              business_id TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              last_synced_at TEXT NOT NULL,
              PRIMARY KEY (business_id, entity_type)
            );
          ''');
    },
  );
}
