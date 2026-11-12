import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/offline_store.dart';
import '../errors/app_exception.dart';
import '../utils/logger.dart';
import '../../shared/models/customer.dart';
import '../../shared/models/reminder.dart';
import '../../shared/models/service_entry.dart';
import '../../shared/repositories/customer_repository.dart';
import '../../shared/repositories/reminder_repository.dart';
import '../../shared/repositories/service_repository.dart';

class OfflineEntityTypes {
  static const String customer = 'customer';
  static const String service = 'service';
  static const String maintenancePlan = 'maintenance_plan';
  static const String maintenanceOccurrence = 'maintenance_occurrence';
  static const String amc = 'amc_contract';
  static const String reminder = 'reminder';
  static const String messageTemplate = 'message_template';
}

class SyncOpTypes {
  static const String createCustomer = 'create_customer';
  static const String updateCustomer = 'update_customer';
  static const String createService = 'create_service';
  static const String updateService = 'update_service';
  static const String createReminder = 'create_reminder';
  static const String completeReminder = 'complete_reminder';
}

class OfflineUnsupportedException implements Exception {
  final String message;

  const OfflineUnsupportedException(this.message);

  @override
  String toString() => message;
}

class SyncRunResult {
  final int syncedCount;
  final int failedCount;
  final int conflictCount;
  final int remainingPending;

  const SyncRunResult({
    this.syncedCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.remainingPending = 0,
  });
}

/// Manages local offline caching, safe mutation queueing, idempotency keys,
/// server conflict detection, and FIFO replay synchronization.
class SyncEngine {
  static const Set<String> onlineOnlyOperations = {
    'amc_renewal',
    'subscription_purchase',
    'bulk_messaging',
    'api_dispatch',
    'recurrence_generation',
  };

  final IOfflineStore _store;
  final ICustomerRepository? _customerRepo;
  final IServiceRepository? _serviceRepo;
  final IReminderRepository? _reminderRepo;
  final Uuid _uuid = const Uuid();
  bool _isSyncing = false;

  SyncEngine({
    required IOfflineStore store,
    ICustomerRepository? customerRepo,
    IServiceRepository? serviceRepo,
    IReminderRepository? reminderRepo,
  }) : _store = store,
       _customerRepo = customerRepo,
       _serviceRepo = serviceRepo,
       _reminderRepo = reminderRepo;

  /// Enforces that complex financial, billing, and external provider operations run online-only.
  static void ensureOnlineOperationSupported({
    required String operationKey,
    required bool isOnline,
  }) {
    if (!isOnline && onlineOnlyOperations.contains(operationKey)) {
      throw const OfflineUnsupportedException(
        'This action requires an active internet connection to verify safely with the server.',
      );
    }
  }

  // --------------------------------------------------------------------------
  // Entity Caching Helpers
  // --------------------------------------------------------------------------

  Future<void> cacheCustomers(
    String businessId,
    List<Customer> customers,
  ) async {
    await _store.upsertCachedEntities(
      businessId: businessId,
      entityType: OfflineEntityTypes.customer,
      entities: customers.map((c) => c.toJson()).toList(),
      replaceClean: true,
    );
    await _store.setLastSyncedAt(
      businessId,
      OfflineEntityTypes.customer,
      DateTime.now().toUtc(),
    );
  }

  Future<List<Customer>> getCachedCustomers(String businessId) async {
    final rows = await _store.getCachedEntities(
      businessId: businessId,
      entityType: OfflineEntityTypes.customer,
    );
    return rows.map(Customer.fromJson).toList();
  }

  Future<void> cacheServices(
    String businessId,
    List<ServiceEntry> services,
  ) async {
    await _store.upsertCachedEntities(
      businessId: businessId,
      entityType: OfflineEntityTypes.service,
      entities: services.map((s) => s.toJson()).toList(),
      replaceClean: true,
    );
    await _store.setLastSyncedAt(
      businessId,
      OfflineEntityTypes.service,
      DateTime.now().toUtc(),
    );
  }

  Future<List<ServiceEntry>> getCachedServices(String businessId) async {
    final rows = await _store.getCachedEntities(
      businessId: businessId,
      entityType: OfflineEntityTypes.service,
    );
    return rows.map(ServiceEntry.fromJson).toList();
  }

  Future<void> cacheReminders(
    String businessId,
    List<Reminder> reminders,
  ) async {
    await _store.upsertCachedEntities(
      businessId: businessId,
      entityType: OfflineEntityTypes.reminder,
      entities: reminders.map((r) => r.toJson()).toList(),
      replaceClean: true,
    );
    await _store.setLastSyncedAt(
      businessId,
      OfflineEntityTypes.reminder,
      DateTime.now().toUtc(),
    );
  }

  Future<List<Reminder>> getCachedReminders(String businessId) async {
    final rows = await _store.getCachedEntities(
      businessId: businessId,
      entityType: OfflineEntityTypes.reminder,
    );
    return rows.map(Reminder.fromJson).toList();
  }

  Future<void> cacheRawEntities({
    required String businessId,
    required String entityType,
    required List<Map<String, dynamic>> entities,
  }) async {
    await _store.upsertCachedEntities(
      businessId: businessId,
      entityType: entityType,
      entities: entities,
      replaceClean: true,
    );
    await _store.setLastSyncedAt(
      businessId,
      entityType,
      DateTime.now().toUtc(),
    );
  }

  Future<List<Map<String, dynamic>>> getCachedRawEntities({
    required String businessId,
    required String entityType,
  }) {
    return _store.getCachedEntities(
      businessId: businessId,
      entityType: entityType,
    );
  }

  // --------------------------------------------------------------------------
  // Offline Mutation Queueing
  // --------------------------------------------------------------------------

  Future<Customer> queueCreateCustomer({
    required String businessId,
    required String fullName,
    required String primaryPhone,
    String? alternatePhone,
    String? email,
    String customerType = 'individual',
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final localId = _uuid.v4();
    final customer = Customer(
      id: localId,
      businessId: businessId,
      fullName: fullName.trim(),
      primaryPhone: primaryPhone.trim(),
      alternatePhone: alternatePhone?.trim(),
      email: email?.trim(),
      customerType: customerType,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final payload = customer.toJson();
    await _store.upsertSingleEntity(
      businessId: businessId,
      entityType: OfflineEntityTypes.customer,
      entityId: localId,
      payload: payload,
      updatedAt: now,
      isDirty: true,
    );

    await _store.enqueueOperation(
      PendingOperationRecord(
        id: _uuid.v4(),
        businessId: businessId,
        entityType: OfflineEntityTypes.customer,
        entityId: localId,
        operationType: SyncOpTypes.createCustomer,
        payload: payload,
        idempotencyKey: 'cust_create_$localId',
        baseUpdatedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return customer;
  }

  Future<void> queueUpdateCustomer({
    required Customer updatedCustomer,
    required DateTime baseUpdatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = updatedCustomer.copyWith(updatedAt: now).toJson();
    await _store.upsertSingleEntity(
      businessId: updatedCustomer.businessId,
      entityType: OfflineEntityTypes.customer,
      entityId: updatedCustomer.id,
      payload: payload,
      updatedAt: now,
      isDirty: true,
    );

    await _store.enqueueOperation(
      PendingOperationRecord(
        id: _uuid.v4(),
        businessId: updatedCustomer.businessId,
        entityType: OfflineEntityTypes.customer,
        entityId: updatedCustomer.id,
        operationType: SyncOpTypes.updateCustomer,
        payload: payload,
        idempotencyKey:
            'cust_upd_${updatedCustomer.id}_${now.millisecondsSinceEpoch}',
        baseUpdatedAt: baseUpdatedAt.toUtc(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<ServiceEntry> queueCreateService({required ServiceEntry entry}) async {
    final now = DateTime.now().toUtc();
    final localId = entry.id.isNotEmpty ? entry.id : _uuid.v4();
    final normalized = ServiceEntry(
      id: localId,
      businessId: entry.businessId,
      customerId: entry.customerId,
      customerAddressId: entry.customerAddressId,
      equipmentId: entry.equipmentId,
      serviceNumber: entry.serviceNumber,
      serviceType: entry.serviceType,
      title: entry.title,
      description: entry.description,
      workPerformed: entry.workPerformed,
      serviceDate: entry.serviceDate,
      status: entry.status,
      serviceAmount: entry.serviceAmount,
      additionalCharges: entry.additionalCharges,
      discountAmount: entry.discountAmount,
      totalAmount: entry.totalAmount,
      paymentStatus: entry.paymentStatus,
      notes: entry.notes,
      completedAt: entry.completedAt,
      createdAt: now,
      updatedAt: now,
    );

    final payload = normalized.toJson();
    await _store.upsertSingleEntity(
      businessId: entry.businessId,
      entityType: OfflineEntityTypes.service,
      entityId: localId,
      payload: payload,
      updatedAt: now,
      isDirty: true,
    );

    await _store.enqueueOperation(
      PendingOperationRecord(
        id: _uuid.v4(),
        businessId: entry.businessId,
        entityType: OfflineEntityTypes.service,
        entityId: localId,
        operationType: SyncOpTypes.createService,
        payload: payload,
        idempotencyKey: 'srv_create_$localId',
        baseUpdatedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return normalized;
  }

  Future<void> queueUpdateService({
    required ServiceEntry entry,
    required DateTime baseUpdatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = entry.toJson()..['updated_at'] = now.toIso8601String();
    await _store.upsertSingleEntity(
      businessId: entry.businessId,
      entityType: OfflineEntityTypes.service,
      entityId: entry.id,
      payload: payload,
      updatedAt: now,
      isDirty: true,
    );

    await _store.enqueueOperation(
      PendingOperationRecord(
        id: _uuid.v4(),
        businessId: entry.businessId,
        entityType: OfflineEntityTypes.service,
        entityId: entry.id,
        operationType: SyncOpTypes.updateService,
        payload: payload,
        idempotencyKey: 'srv_upd_${entry.id}_${now.millisecondsSinceEpoch}',
        baseUpdatedAt: baseUpdatedAt.toUtc(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Reminder> queueCreateReminder({required Reminder reminder}) async {
    final now = DateTime.now().toUtc();
    final localId = reminder.id.isNotEmpty ? reminder.id : _uuid.v4();
    final normalized = Reminder(
      id: localId,
      businessId: reminder.businessId,
      customerId: reminder.customerId,
      customerName: reminder.customerName,
      customerPhone: reminder.customerPhone,
      serviceId: reminder.serviceId,
      title: reminder.title,
      description: reminder.description,
      reminderType: reminder.reminderType,
      category: reminder.category,
      priority: reminder.priority,
      dueAt: reminder.dueAt,
      timezone: reminder.timezone,
      notificationEnabled: reminder.notificationEnabled,
      status: reminder.status,
      createdAt: now,
      updatedAt: now,
    );

    final payload = normalized.toJson();
    await _store.upsertSingleEntity(
      businessId: reminder.businessId,
      entityType: OfflineEntityTypes.reminder,
      entityId: localId,
      payload: payload,
      updatedAt: now,
      isDirty: true,
    );

    await _store.enqueueOperation(
      PendingOperationRecord(
        id: _uuid.v4(),
        businessId: reminder.businessId,
        entityType: OfflineEntityTypes.reminder,
        entityId: localId,
        operationType: SyncOpTypes.createReminder,
        payload: payload,
        idempotencyKey: 'rem_create_$localId',
        baseUpdatedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return normalized;
  }

  Future<void> queueCompleteReminder({
    required Reminder reminder,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = Map<String, dynamic>.from(reminder.toJson())
      ..['status'] = 'completed'
      ..['completed_at'] = now.toIso8601String()
      ..['completed_notes'] = notes
      ..['updated_at'] = now.toIso8601String();

    await _store.upsertSingleEntity(
      businessId: reminder.businessId,
      entityType: OfflineEntityTypes.reminder,
      entityId: reminder.id,
      payload: payload,
      updatedAt: now,
      isDirty: true,
    );

    await _store.enqueueOperation(
      PendingOperationRecord(
        id: _uuid.v4(),
        businessId: reminder.businessId,
        entityType: OfflineEntityTypes.reminder,
        entityId: reminder.id,
        operationType: SyncOpTypes.completeReminder,
        payload: {
          'reminder_id': reminder.id,
          'business_id': reminder.businessId,
          'notes': notes,
        },
        idempotencyKey: 'rem_complete_${reminder.id}',
        baseUpdatedAt: reminder.updatedAt.toUtc(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Synchronization Execution & Conflict Handling
  // --------------------------------------------------------------------------

  Future<SyncRunResult> syncPendingOperations({
    required String businessId,
    bool isOnline = true,
  }) async {
    if (!isOnline || _isSyncing || businessId.isEmpty) {
      final ops = await _store.getPendingOperations(businessId);
      return SyncRunResult(remainingPending: ops.length);
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;
    int conflictCount = 0;

    try {
      final ops = await _store.getPendingOperations(businessId);
      for (final op in ops) {
        if (op.status == SyncOperationStatus.conflict) {
          conflictCount++;
          continue;
        }

        await _store.updateOperationStatus(
          operationId: op.id,
          status: SyncOperationStatus.syncing,
        );

        try {
          await _executeOperation(op, forceOverwrite: false);
          await _store.updateOperationStatus(
            operationId: op.id,
            status: SyncOperationStatus.synced,
          );
          syncedCount++;
        } on _SyncConflictException catch (conflict) {
          await _store.updateOperationStatus(
            operationId: op.id,
            status: SyncOperationStatus.conflict,
            conflictPayload: conflict.serverPayload,
            errorMessage: conflict.message,
          );
          conflictCount++;
        } catch (e) {
          AppLogger.warning('SyncEngine: operation ${op.id} failed: $e');
          await _store.updateOperationStatus(
            operationId: op.id,
            status: SyncOperationStatus.syncFailed,
            errorMessage: e.toString(),
            retryCount: op.retryCount + 1,
          );
          failedCount++;
        }
      }

      final remaining = await _store.getPendingOperations(businessId);
      return SyncRunResult(
        syncedCount: syncedCount,
        failedCount: failedCount,
        conflictCount: conflictCount,
        remainingPending: remaining.length,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> resolveConflictKeepMine({
    required PendingOperationRecord op,
  }) async {
    await _executeOperation(op, forceOverwrite: true);
    await _store.updateOperationStatus(
      operationId: op.id,
      status: SyncOperationStatus.synced,
    );
  }

  Future<void> resolveConflictUseServer({
    required PendingOperationRecord op,
  }) async {
    final serverData = op.conflictPayload;
    if (serverData != null) {
      await _store.upsertSingleEntity(
        businessId: op.businessId,
        entityType: op.entityType,
        entityId: op.entityId,
        payload: serverData,
        updatedAt: DateTime.tryParse(
          serverData['updated_at']?.toString() ?? '',
        ),
        isDirty: false,
      );
    }
    await _store.deleteOperation(op.id);
  }

  Future<void> retryOperation(PendingOperationRecord op) async {
    await _store.updateOperationStatus(
      operationId: op.id,
      status: SyncOperationStatus.pendingSync,
    );
    await syncPendingOperations(businessId: op.businessId, isOnline: true);
  }

  T _requireRepo<T>(T? repo, String label) {
    if (repo == null) {
      throw AppStorageException('$label repository unavailable');
    }
    return repo;
  }

  Future<void> _executeOperation(
    PendingOperationRecord op, {
    required bool forceOverwrite,
  }) async {
    switch (op.operationType) {
      case SyncOpTypes.createCustomer:
        final repo = _requireRepo(_customerRepo, 'Customer');
        final c = Customer.fromJson(op.payload);
        final dup = await repo.checkDuplicatePhone(
          c.businessId,
          c.primaryPhone,
        );
        if (dup != null) {
          // Idempotent match on same phone
          await _store.upsertSingleEntity(
            businessId: op.businessId,
            entityType: OfflineEntityTypes.customer,
            entityId: dup.id,
            payload: dup.toJson(),
            updatedAt: dup.updatedAt,
            isDirty: false,
          );
          return;
        }
        final created = await repo.createCustomer(
          businessId: c.businessId,
          fullName: c.fullName,
          primaryPhone: c.primaryPhone,
          alternatePhone: c.alternatePhone,
          email: c.email,
          customerType: c.customerType,
          notes: c.notes,
        );
        await _store.upsertSingleEntity(
          businessId: op.businessId,
          entityType: OfflineEntityTypes.customer,
          entityId: op.entityId,
          payload: created.toJson(),
          updatedAt: created.updatedAt,
          isDirty: false,
        );
        break;

      case SyncOpTypes.updateCustomer:
        final repo = _requireRepo(_customerRepo, 'Customer');
        final local = Customer.fromJson(op.payload);
        if (!forceOverwrite && op.baseUpdatedAt != null) {
          final latest = await repo.getCustomerById(local.id);
          if (latest != null &&
              latest.updatedAt.toUtc().isAfter(
                op.baseUpdatedAt!.toUtc().add(const Duration(seconds: 2)),
              )) {
            throw _SyncConflictException(
              message:
                  'Customer "${latest.fullName}" was modified on the server since your offline edit.',
              serverPayload: latest.toJson(),
            );
          }
        }
        final updated = await repo.updateCustomer(local);
        await _store.upsertSingleEntity(
          businessId: op.businessId,
          entityType: OfflineEntityTypes.customer,
          entityId: updated.id,
          payload: updated.toJson(),
          updatedAt: updated.updatedAt,
          isDirty: false,
        );
        break;

      case SyncOpTypes.createService:
        final repo = _requireRepo(_serviceRepo, 'Service');
        final entry = ServiceEntry.fromJson(op.payload);
        final created = await repo.createServiceEntry(entry);
        await _store.upsertSingleEntity(
          businessId: op.businessId,
          entityType: OfflineEntityTypes.service,
          entityId: op.entityId,
          payload: created.toJson(),
          updatedAt: created.updatedAt,
          isDirty: false,
        );
        break;

      case SyncOpTypes.updateService:
        final repo = _requireRepo(_serviceRepo, 'Service');
        final entry = ServiceEntry.fromJson(op.payload);
        if (!forceOverwrite && op.baseUpdatedAt != null) {
          final latest = await repo.getServiceEntryById(entry.id);
          if (latest != null &&
              latest.updatedAt.toUtc().isAfter(
                op.baseUpdatedAt!.toUtc().add(const Duration(seconds: 2)),
              )) {
            throw _SyncConflictException(
              message:
                  'Service "${latest.title}" was modified on another session since your offline edit.',
              serverPayload: latest.toJson(),
            );
          }
        }
        final updated = await repo.updateServiceEntry(entry);
        await _store.upsertSingleEntity(
          businessId: op.businessId,
          entityType: OfflineEntityTypes.service,
          entityId: updated.id,
          payload: updated.toJson(),
          updatedAt: updated.updatedAt,
          isDirty: false,
        );
        break;

      case SyncOpTypes.createReminder:
        final repo = _requireRepo(_reminderRepo, 'Reminder');
        final rem = Reminder.fromJson(op.payload);
        final created = await repo.createReminder(rem);
        await _store.upsertSingleEntity(
          businessId: op.businessId,
          entityType: OfflineEntityTypes.reminder,
          entityId: op.entityId,
          payload: created.toJson(),
          updatedAt: created.updatedAt,
          isDirty: false,
        );
        break;

      case SyncOpTypes.completeReminder:
        final repo = _requireRepo(_reminderRepo, 'Reminder');
        final reminderId = op.payload['reminder_id'] as String;
        final notes = op.payload['notes'] as String?;
        await repo.completeReminder(reminderId, notes: notes);
        break;

      default:
        throw AppStorageException(
          'Unknown sync operation: ${jsonEncode(op.operationType)}',
        );
    }
  }
}

class _SyncConflictException implements Exception {
  final String message;
  final Map<String, dynamic> serverPayload;

  _SyncConflictException({required this.message, required this.serverPayload});
}
