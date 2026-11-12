import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/database/offline_store.dart';
import 'package:yaadibook/core/sync/sync_engine.dart';
import 'package:yaadibook/features/customers/models/customer_activity_item.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/models/customer_address.dart';
import 'package:yaadibook/shared/models/equipment.dart';
import 'package:yaadibook/shared/models/reminder.dart';
import 'package:yaadibook/shared/models/service_activity.dart';
import 'package:yaadibook/shared/models/service_attachment.dart';
import 'package:yaadibook/shared/models/service_entry.dart';
import 'package:yaadibook/shared/repositories/customer_repository.dart';
import 'package:yaadibook/shared/repositories/reminder_repository.dart';
import 'package:yaadibook/shared/repositories/service_repository.dart';

class _FakeCustomerRepo implements ICustomerRepository {
  final Map<String, Customer> db = {};
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<Customer> createCustomer({
    required String businessId,
    required String fullName,
    required String primaryPhone,
    String? alternatePhone,
    String? email,
    String customerType = 'individual',
    String? notes,
    String? source,
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? state,
    String? postalCode,
    String? landmark,
  }) async {
    createCalls++;
    final now = DateTime.now().toUtc();
    final c = Customer(
      id: 'srv_cust_$createCalls',
      businessId: businessId,
      fullName: fullName,
      primaryPhone: primaryPhone,
      createdAt: now,
      updatedAt: now,
    );
    db[c.id] = c;
    return c;
  }

  @override
  Future<Customer?> getCustomerById(String id) async => db[id];

  @override
  Future<Customer> updateCustomer(
    Customer customer, {
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? state,
    String? postalCode,
    String? landmark,
  }) async {
    updateCalls++;
    final updated = customer.copyWith(updatedAt: DateTime.now().toUtc());
    db[updated.id] = updated;
    return updated;
  }

  @override
  Future<Customer?> checkDuplicatePhone(
    String businessId,
    String phone, {
    String? excludeCustomerId,
  }) async {
    return db.values
        .where((c) => c.businessId == businessId && c.primaryPhone == phone)
        .firstOrNull;
  }

  @override
  Future<void> archiveCustomer(String id) async {}
  @override
  Future<List<CustomerActivityItem>> getCustomerActivity(Customer c) async =>
      const [];
  @override
  Future<List<CustomerAddress>> getCustomerAddresses(String customerId) async =>
      const [];
  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    CustomerFilter filter = CustomerFilter.active,
    CustomerSort sort = CustomerSort.recentlyAdded,
  }) async => db.values.toList();
  @override
  Future<void> logCommunication({
    required String businessId,
    required String customerId,
    required String channel,
    String direction = 'outgoing',
    String? messageContent,
    String status = 'initiated',
  }) async {}
  @override
  Future<void> restoreCustomer(String id) async {}
}

class _FakeServiceRepo implements IServiceRepository {
  int createCalls = 0;

  @override
  Future<ServiceEntry> createServiceEntry(ServiceEntry entry) async {
    createCalls++;
    return entry;
  }

  @override
  Future<ServiceAttachment> addServiceAttachment({
    required String businessId,
    required String serviceId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteServiceAttachment({
    required String attachmentId,
    required String filePath,
  }) async {}
  @override
  Future<String?> getAttachmentDownloadUrl(String filePath) async => null;
  @override
  Future<List<Equipment>> getCustomerEquipment(String customerId) async =>
      const [];
  @override
  Future<ServiceSummaryCounts> getCustomerServiceCounts(String id) async =>
      const ServiceSummaryCounts();
  @override
  Future<List<ServiceEntry>> getCustomerServiceHistory(String id) async =>
      const [];
  @override
  Future<List<ServiceActivity>> getServiceActivities(String id) async =>
      const [];
  @override
  Future<List<ServiceEntry>> getServiceEntries({
    String? businessId,
    String? customerId,
    ServiceFilter filter = ServiceFilter.all,
    ServiceSort sort = ServiceSort.recentlyCreated,
    String? searchQuery,
    int? limit,
  }) async => const [];
  @override
  Future<ServiceEntry?> getServiceEntryById(String id) async => null;
  @override
  Future<ServiceSummaryCounts> getServiceSummaryCounts(String bizId) async =>
      const ServiceSummaryCounts();
  @override
  Future<ServiceEntry> updateServiceEntry(ServiceEntry entry) async => entry;
  @override
  Future<ServiceEntry> updateServiceStatus({
    required String serviceId,
    required String businessId,
    required String newStatus,
    String? oldStatus,
    DateTime? completionDate,
    String? workPerformed,
    String? finalNotes,
    double? finalAmount,
    String? actorUserId,
  }) => throw UnimplementedError();
}

class _FakeReminderRepo implements IReminderRepository {
  int completedCalls = 0;

  @override
  Future<void> completeReminder(String id, {String? notes}) async {
    completedCalls++;
  }

  @override
  Future<void> cancelReminder(String id) async {}
  @override
  Future<Reminder> createReminder(Reminder r) async => r;
  @override
  Future<ReminderOverviewStats> getOverviewStats() async =>
      const ReminderOverviewStats();
  @override
  Future<Reminder?> getReminderById(String id) async => null;
  @override
  Future<List<Reminder>> getReminders({
    String? status,
    String? type,
    String? category,
    String? customerId,
    bool includeCompleted = false,
  }) async => const [];
  @override
  Future<void> markCompleted(String id) async => completeReminder(id);
  @override
  Future<void> snoozeReminder(String id, DateTime snoozeUntil) async {}
  @override
  Future<Reminder> updateReminder(Reminder r) async => r;
}

void main() {
  group('Offline store & SyncEngine', () {
    test('enforces strict tenant isolation and clears data cleanly', () async {
      final store = InMemoryOfflineStore();
      await store.upsertSingleEntity(
        businessId: 'biz_a',
        entityType: OfflineEntityTypes.customer,
        entityId: 'c1',
        payload: {'id': 'c1', 'full_name': 'Alice'},
      );
      await store.upsertSingleEntity(
        businessId: 'biz_b',
        entityType: OfflineEntityTypes.customer,
        entityId: 'c2',
        payload: {'id': 'c2', 'full_name': 'Bob'},
      );

      expect(
        (await store.getCachedEntities(
          businessId: 'biz_a',
          entityType: 'customer',
        )).length,
        1,
      );
      expect(
        (await store.getCachedEntities(
          businessId: 'biz_b',
          entityType: 'customer',
        )).length,
        1,
      );

      await store.clearBusinessData('biz_a');
      expect(
        (await store.getCachedEntities(
          businessId: 'biz_a',
          entityType: 'customer',
        )).isEmpty,
        isTrue,
      );
      expect(
        (await store.getCachedEntities(
          businessId: 'biz_b',
          entityType: 'customer',
        )).length,
        1,
      );

      await store.clearAllData();
      expect(
        (await store.getCachedEntities(
          businessId: 'biz_b',
          entityType: 'customer',
        )).isEmpty,
        isTrue,
      );
    });

    test('blocks unsafe online-only operations while offline', () {
      expect(
        () => SyncEngine.ensureOnlineOperationSupported(
          operationKey: 'amc_renewal',
          isOnline: false,
        ),
        throwsA(isA<OfflineUnsupportedException>()),
      );
      expect(
        () => SyncEngine.ensureOnlineOperationSupported(
          operationKey: 'subscription_purchase',
          isOnline: false,
        ),
        throwsA(isA<OfflineUnsupportedException>()),
      );
      expect(
        () => SyncEngine.ensureOnlineOperationSupported(
          operationKey: 'bulk_messaging',
          isOnline: false,
        ),
        throwsA(isA<OfflineUnsupportedException>()),
      );
    });

    test(
      'queues offline create customer & reminder completion and syncs FIFO when online',
      () async {
        final store = InMemoryOfflineStore();
        final custRepo = _FakeCustomerRepo();
        final srvRepo = _FakeServiceRepo();
        final remRepo = _FakeReminderRepo();

        final engine = SyncEngine(
          store: store,
          customerRepo: custRepo,
          serviceRepo: srvRepo,
          reminderRepo: remRepo,
        );

        final queuedCust = await engine.queueCreateCustomer(
          businessId: 'b1',
          fullName: 'Offline Customer',
          primaryPhone: '+919898989898',
        );
        final cachedCust = await engine.getCachedCustomers('b1');
        expect(cachedCust.any((c) => c.id == queuedCust.id), isTrue);

        await engine.queueCompleteReminder(
          reminder: Reminder(
            id: 'rem_1',
            businessId: 'b1',
            title: 'Follow up',
            reminderType: 'follow_up',
            dueAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          notes: 'Done offline',
        );

        final pendingWhileOffline = await engine.syncPendingOperations(
          businessId: 'b1',
          isOnline: false,
        );
        expect(pendingWhileOffline.remainingPending, 2);
        expect(custRepo.createCalls, 0);

        final syncedOnline = await engine.syncPendingOperations(
          businessId: 'b1',
          isOnline: true,
        );
        expect(syncedOnline.syncedCount, 2);
        expect(syncedOnline.remainingPending, 0);
        expect(custRepo.createCalls, 1);
        expect(remRepo.completedCalls, 1);
      },
    );

    test(
      'detects server edit conflicts and preserves conflict resolution choice',
      () async {
        final store = InMemoryOfflineStore();
        final custRepo = _FakeCustomerRepo();
        final engine = SyncEngine(store: store, customerRepo: custRepo);

        final baseTime = DateTime.utc(2026, 11, 10, 10, 0);
        final serverNewerTime = DateTime.utc(2026, 11, 10, 12, 0);

        custRepo.db['c1'] = Customer(
          id: 'c1',
          businessId: 'b1',
          fullName: 'Server Updated Name',
          primaryPhone: '+919900112233',
          createdAt: baseTime,
          updatedAt: serverNewerTime,
        );

        await engine.queueUpdateCustomer(
          updatedCustomer: Customer(
            id: 'c1',
            businessId: 'b1',
            fullName: 'Offline Edited Name',
            primaryPhone: '+919900112233',
            createdAt: baseTime,
            updatedAt: baseTime,
          ),
          baseUpdatedAt: baseTime,
        );

        final res = await engine.syncPendingOperations(
          businessId: 'b1',
          isOnline: true,
        );
        expect(res.conflictCount, 1);
        final ops = await store.getPendingOperations('b1');
        expect(ops.single.status, SyncOperationStatus.conflict);
        expect(ops.single.conflictPayload?['full_name'], 'Server Updated Name');

        // Resolve by keeping local edit
        await engine.resolveConflictKeepMine(op: ops.single);
        expect(custRepo.db['c1']?.fullName, 'Offline Edited Name');
        final afterResolve = await store.getPendingOperations('b1');
        expect(afterResolve.isEmpty, isTrue);
      },
    );
  });
}
