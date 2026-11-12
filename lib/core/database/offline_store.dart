import 'dart:convert';
import 'package:drift/drift.dart';
import 'drift_offline_database.dart';
import 'local_database_executor_stub.dart'
    if (dart.library.io) 'local_database_executor_io.dart'
    if (dart.library.html) 'local_database_executor_web.dart';

class SyncOperationStatus {
  static const String pendingSync = 'pending_sync';
  static const String syncing = 'syncing';
  static const String synced = 'synced';
  static const String syncFailed = 'sync_failed';
  static const String conflict = 'conflict';
}

class PendingOperationRecord {
  final String id;
  final String businessId;
  final String entityType;
  final String entityId;
  final String operationType;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final DateTime? baseUpdatedAt;
  final String status;
  final Map<String, dynamic>? conflictPayload;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingOperationRecord({
    required this.id,
    required this.businessId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.idempotencyKey,
    this.baseUpdatedAt,
    this.status = SyncOperationStatus.pendingSync,
    this.conflictPayload,
    this.errorMessage,
    this.retryCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  PendingOperationRecord copyWith({
    String? status,
    Map<String, dynamic>? conflictPayload,
    bool clearConflictPayload = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? retryCount,
    DateTime? updatedAt,
  }) {
    return PendingOperationRecord(
      id: id,
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: payload,
      idempotencyKey: idempotencyKey,
      baseUpdatedAt: baseUpdatedAt,
      status: status ?? this.status,
      conflictPayload: clearConflictPayload
          ? null
          : (conflictPayload ?? this.conflictPayload),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CachedEntityEntry {
  final String businessId;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final DateTime cachedAt;
  final bool isDirty;

  const CachedEntityEntry({
    required this.businessId,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.updatedAt,
    required this.cachedAt,
    this.isDirty = false,
  });
}

abstract class IOfflineStore {
  bool get isNativeSqlite;

  Future<void> upsertCachedEntities({
    required String businessId,
    required String entityType,
    required List<Map<String, dynamic>> entities,
    bool replaceClean = false,
  });

  Future<void> upsertSingleEntity({
    required String businessId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
    bool isDirty = false,
  });

  Future<List<Map<String, dynamic>>> getCachedEntities({
    required String businessId,
    required String entityType,
  });

  Future<void> enqueueOperation(PendingOperationRecord op);

  Future<List<PendingOperationRecord>> getPendingOperations(
    String businessId, {
    bool includeSynced = false,
  });

  Future<void> updateOperationStatus({
    required String operationId,
    required String status,
    Map<String, dynamic>? conflictPayload,
    String? errorMessage,
    int? retryCount,
  });

  Future<void> deleteOperation(String operationId);

  Future<void> setLastSyncedAt(
    String businessId,
    String entityType,
    DateTime timestamp,
  );

  Future<DateTime?> getLastSyncedAt(String businessId, String entityType);

  Future<void> clearBusinessData(String businessId);

  Future<void> clearAllData();

  Future<int> countCachedEntities(String businessId);
}

/// Offline persistence facade supporting Drift SQLite on Android/native
/// and seamless in-memory storage fallback on Chrome Web or headless tests.
class HybridOfflineStore implements IOfflineStore {
  DriftOfflineDatabase? _db;
  final InMemoryOfflineStore _memoryFallback = InMemoryOfflineStore();
  bool _initialized = false;
  final bool _forceInMemory;

  HybridOfflineStore({bool forceInMemory = false})
    : _forceInMemory = forceInMemory;

  @override
  bool get isNativeSqlite => _db != null;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (_forceInMemory) return;

    final executor = await openPlatformDriftExecutor();
    if (executor != null) {
      final db = DriftOfflineDatabase(executor);
      try {
        // Trigger schema creation eagerly and verify SQLite runtime availability.
        await db.customSelect('SELECT 1').get();
        _db = db;
      } catch (_) {
        await db.close();
        _db = null;
      }
    }
  }

  @override
  Future<void> upsertCachedEntities({
    required String businessId,
    required String entityType,
    required List<Map<String, dynamic>> entities,
    bool replaceClean = false,
  }) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.upsertCachedEntities(
        businessId: businessId,
        entityType: entityType,
        entities: entities,
        replaceClean: replaceClean,
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.transaction(() async {
      if (replaceClean) {
        await db.customStatement(
          'DELETE FROM cached_entities WHERE business_id = ? AND entity_type = ? AND is_dirty = 0',
          [businessId, entityType],
        );
      }

      for (final raw in entities) {
        final entityId = (raw['id'] ?? '').toString();
        if (entityId.isEmpty) continue;
        final updatedAt = (raw['updated_at'] ?? raw['created_at'] ?? nowIso)
            .toString();
        await db.customStatement(
          '''
          INSERT INTO cached_entities (
            business_id, entity_type, entity_id, payload_json, updated_at, cached_at, is_dirty
          ) VALUES (?, ?, ?, ?, ?, ?, 0)
          ON CONFLICT(business_id, entity_type, entity_id) DO UPDATE SET
            payload_json = excluded.payload_json,
            updated_at = excluded.updated_at,
            cached_at = excluded.cached_at
          WHERE cached_entities.is_dirty = 0
          ''',
          [
            businessId,
            entityType,
            entityId,
            jsonEncode(raw),
            updatedAt,
            nowIso,
          ],
        );
      }
    });
  }

  @override
  Future<void> upsertSingleEntity({
    required String businessId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
    bool isDirty = false,
  }) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.upsertSingleEntity(
        businessId: businessId,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        updatedAt: updatedAt,
        isDirty: isDirty,
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final updatedIso = (updatedAt ?? DateTime.now().toUtc()).toIso8601String();
    await db.customStatement(
      '''
      INSERT INTO cached_entities (
        business_id, entity_type, entity_id, payload_json, updated_at, cached_at, is_dirty
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(business_id, entity_type, entity_id) DO UPDATE SET
        payload_json = excluded.payload_json,
        updated_at = excluded.updated_at,
        cached_at = excluded.cached_at,
        is_dirty = excluded.is_dirty
      ''',
      [
        businessId,
        entityType,
        entityId,
        jsonEncode(payload),
        updatedIso,
        nowIso,
        isDirty ? 1 : 0,
      ],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedEntities({
    required String businessId,
    required String entityType,
  }) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.getCachedEntities(
        businessId: businessId,
        entityType: entityType,
      );
    }

    final rows = await db
        .customSelect(
          'SELECT payload_json FROM cached_entities WHERE business_id = ? AND entity_type = ? ORDER BY updated_at DESC',
          variables: [
            Variable.withString(businessId),
            Variable.withString(entityType),
          ],
        )
        .get();

    return rows
        .map(
          (r) => Map<String, dynamic>.from(
            jsonDecode(r.read<String>('payload_json')) as Map,
          ),
        )
        .toList();
  }

  @override
  Future<void> enqueueOperation(PendingOperationRecord op) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.enqueueOperation(op);
    }

    await db.customStatement(
      '''
      INSERT INTO pending_operations (
        id, business_id, entity_type, entity_id, operation_type, payload_json,
        idempotency_key, base_updated_at, status, conflict_payload_json,
        error_message, retry_count, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(idempotency_key) DO NOTHING
      ''',
      [
        op.id,
        op.businessId,
        op.entityType,
        op.entityId,
        op.operationType,
        jsonEncode(op.payload),
        op.idempotencyKey,
        op.baseUpdatedAt?.toIso8601String(),
        op.status,
        op.conflictPayload == null ? null : jsonEncode(op.conflictPayload),
        op.errorMessage,
        op.retryCount,
        op.createdAt.toUtc().toIso8601String(),
        op.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<List<PendingOperationRecord>> getPendingOperations(
    String businessId, {
    bool includeSynced = false,
  }) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.getPendingOperations(
        businessId,
        includeSynced: includeSynced,
      );
    }

    final sql = includeSynced
        ? 'SELECT * FROM pending_operations WHERE business_id = ? ORDER BY created_at ASC'
        : "SELECT * FROM pending_operations WHERE business_id = ? AND status != 'synced' ORDER BY created_at ASC";

    final rows = await db
        .customSelect(sql, variables: [Variable.withString(businessId)])
        .get();

    return rows.map((r) {
      final conflictStr = r.readNullable<String>('conflict_payload_json');
      final baseStr = r.readNullable<String>('base_updated_at');
      return PendingOperationRecord(
        id: r.read<String>('id'),
        businessId: r.read<String>('business_id'),
        entityType: r.read<String>('entity_type'),
        entityId: r.read<String>('entity_id'),
        operationType: r.read<String>('operation_type'),
        payload: Map<String, dynamic>.from(
          jsonDecode(r.read<String>('payload_json')) as Map,
        ),
        idempotencyKey: r.read<String>('idempotency_key'),
        baseUpdatedAt: baseStr != null ? DateTime.tryParse(baseStr) : null,
        status: r.read<String>('status'),
        conflictPayload: conflictStr != null
            ? Map<String, dynamic>.from(jsonDecode(conflictStr) as Map)
            : null,
        errorMessage: r.readNullable<String>('error_message'),
        retryCount: r.read<int>('retry_count'),
        createdAt: DateTime.parse(r.read<String>('created_at')),
        updatedAt: DateTime.parse(r.read<String>('updated_at')),
      );
    }).toList();
  }

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required String status,
    Map<String, dynamic>? conflictPayload,
    String? errorMessage,
    int? retryCount,
  }) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.updateOperationStatus(
        operationId: operationId,
        status: status,
        conflictPayload: conflictPayload,
        errorMessage: errorMessage,
        retryCount: retryCount,
      );
    }

    await db.customStatement(
      '''
      UPDATE pending_operations
      SET status = ?,
          conflict_payload_json = COALESCE(?, conflict_payload_json),
          error_message = ?,
          retry_count = COALESCE(?, retry_count),
          updated_at = ?
      WHERE id = ?
      ''',
      [
        status,
        conflictPayload == null ? null : jsonEncode(conflictPayload),
        errorMessage,
        retryCount,
        DateTime.now().toUtc().toIso8601String(),
        operationId,
      ],
    );
  }

  @override
  Future<void> deleteOperation(String operationId) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.deleteOperation(operationId);
    }
    await db.customStatement('DELETE FROM pending_operations WHERE id = ?', [
      operationId,
    ]);
  }

  @override
  Future<void> setLastSyncedAt(
    String businessId,
    String entityType,
    DateTime timestamp,
  ) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.setLastSyncedAt(businessId, entityType, timestamp);
    }

    await db.customStatement(
      '''
      INSERT INTO sync_metadata (business_id, entity_type, last_synced_at)
      VALUES (?, ?, ?)
      ON CONFLICT(business_id, entity_type) DO UPDATE SET
        last_synced_at = excluded.last_synced_at
      ''',
      [businessId, entityType, timestamp.toUtc().toIso8601String()],
    );
  }

  @override
  Future<DateTime?> getLastSyncedAt(
    String businessId,
    String entityType,
  ) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.getLastSyncedAt(businessId, entityType);
    }
    final rows = await db
        .customSelect(
          'SELECT last_synced_at FROM sync_metadata WHERE business_id = ? AND entity_type = ?',
          variables: [
            Variable.withString(businessId),
            Variable.withString(entityType),
          ],
        )
        .get();
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first.read<String>('last_synced_at'));
  }

  @override
  Future<void> clearBusinessData(String businessId) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.clearBusinessData(businessId);
    }
    await db.transaction(() async {
      await db.customStatement(
        'DELETE FROM cached_entities WHERE business_id = ?',
        [businessId],
      );
      await db.customStatement(
        'DELETE FROM pending_operations WHERE business_id = ?',
        [businessId],
      );
      await db.customStatement(
        'DELETE FROM sync_metadata WHERE business_id = ?',
        [businessId],
      );
    });
  }

  @override
  Future<void> clearAllData() async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.clearAllData();
    }
    await db.transaction(() async {
      await db.customStatement('DELETE FROM cached_entities');
      await db.customStatement('DELETE FROM pending_operations');
      await db.customStatement('DELETE FROM sync_metadata');
    });
  }

  @override
  Future<int> countCachedEntities(String businessId) async {
    await _ensureInitialized();
    final db = _db;
    if (db == null) {
      return _memoryFallback.countCachedEntities(businessId);
    }
    final rows = await db
        .customSelect(
          'SELECT COUNT(*) AS cnt FROM cached_entities WHERE business_id = ?',
          variables: [Variable.withString(businessId)],
        )
        .get();
    return rows.isEmpty ? 0 : rows.first.read<int>('cnt');
  }
}

/// Deterministic in-memory offline store for Web/unit tests/unsupported native runtimes.
class InMemoryOfflineStore implements IOfflineStore {
  final Map<String, CachedEntityEntry> _entities = {};
  final Map<String, PendingOperationRecord> _ops = {};
  final Map<String, DateTime> _syncMeta = {};

  @override
  bool get isNativeSqlite => false;

  String _entityKey(String bizId, String type, String id) =>
      '$bizId::$type::$id';

  @override
  Future<void> upsertCachedEntities({
    required String businessId,
    required String entityType,
    required List<Map<String, dynamic>> entities,
    bool replaceClean = false,
  }) async {
    final now = DateTime.now().toUtc();
    if (replaceClean) {
      _entities.removeWhere(
        (_, v) =>
            v.businessId == businessId &&
            v.entityType == entityType &&
            !v.isDirty,
      );
    }
    for (final raw in entities) {
      final entityId = (raw['id'] ?? '').toString();
      if (entityId.isEmpty) continue;
      final key = _entityKey(businessId, entityType, entityId);
      final existing = _entities[key];
      if (existing != null && existing.isDirty) continue;
      final updatedAt =
          DateTime.tryParse(
            (raw['updated_at'] ?? raw['created_at'] ?? '').toString(),
          ) ??
          now;
      _entities[key] = CachedEntityEntry(
        businessId: businessId,
        entityType: entityType,
        entityId: entityId,
        payload: Map<String, dynamic>.from(raw),
        updatedAt: updatedAt,
        cachedAt: now,
        isDirty: false,
      );
    }
  }

  @override
  Future<void> upsertSingleEntity({
    required String businessId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
    bool isDirty = false,
  }) async {
    final now = DateTime.now().toUtc();
    final key = _entityKey(businessId, entityType, entityId);
    _entities[key] = CachedEntityEntry(
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      payload: Map<String, dynamic>.from(payload),
      updatedAt: updatedAt ?? now,
      cachedAt: now,
      isDirty: isDirty,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedEntities({
    required String businessId,
    required String entityType,
  }) async {
    final matched =
        _entities.values
            .where(
              (e) => e.businessId == businessId && e.entityType == entityType,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matched.map((e) => Map<String, dynamic>.from(e.payload)).toList();
  }

  @override
  Future<void> enqueueOperation(PendingOperationRecord op) async {
    final alreadyExists = _ops.values.any(
      (existing) => existing.idempotencyKey == op.idempotencyKey,
    );
    if (!alreadyExists) {
      _ops[op.id] = op;
    }
  }

  @override
  Future<List<PendingOperationRecord>> getPendingOperations(
    String businessId, {
    bool includeSynced = false,
  }) async {
    final list =
        _ops.values
            .where(
              (o) =>
                  o.businessId == businessId &&
                  (includeSynced || o.status != SyncOperationStatus.synced),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required String status,
    Map<String, dynamic>? conflictPayload,
    String? errorMessage,
    int? retryCount,
  }) async {
    final existing = _ops[operationId];
    if (existing == null) return;
    _ops[operationId] = existing.copyWith(
      status: status,
      conflictPayload: conflictPayload,
      errorMessage: errorMessage,
      clearErrorMessage: errorMessage == null,
      retryCount: retryCount,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> deleteOperation(String operationId) async {
    _ops.remove(operationId);
  }

  @override
  Future<void> setLastSyncedAt(
    String businessId,
    String entityType,
    DateTime timestamp,
  ) async {
    _syncMeta['$businessId::$entityType'] = timestamp.toUtc();
  }

  @override
  Future<DateTime?> getLastSyncedAt(
    String businessId,
    String entityType,
  ) async {
    return _syncMeta['$businessId::$entityType'];
  }

  @override
  Future<void> clearBusinessData(String businessId) async {
    _entities.removeWhere((_, v) => v.businessId == businessId);
    _ops.removeWhere((_, v) => v.businessId == businessId);
    _syncMeta.removeWhere((k, _) => k.startsWith('$businessId::'));
  }

  @override
  Future<void> clearAllData() async {
    _entities.clear();
    _ops.clear();
    _syncMeta.clear();
  }

  @override
  Future<int> countCachedEntities(String businessId) async {
    return _entities.values.where((e) => e.businessId == businessId).length;
  }
}
