import '../../core/database/offline_store.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/utils/logger.dart';
import '../../features/customers/models/customer_activity_item.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/equipment.dart';
import '../models/reminder.dart';
import '../models/service_activity.dart';
import '../models/service_attachment.dart';
import '../models/service_entry.dart';
import 'customer_repository.dart';
import 'reminder_repository.dart';
import 'service_repository.dart';

/// Decorates [ICustomerRepository] with Drift/SQLite caching and offline mutation queuing.
class OfflineAwareCustomerRepository implements ICustomerRepository {
  final ICustomerRepository _remote;
  final SyncEngine _syncEngine;
  final IOfflineStore _store;
  final String? Function() _getBusinessId;
  final bool Function() _isOnline;
  final void Function()? _onQueueChanged;

  OfflineAwareCustomerRepository({
    required ICustomerRepository remote,
    required SyncEngine syncEngine,
    required IOfflineStore store,
    required String? Function() getBusinessId,
    required bool Function() isOnline,
    void Function()? onQueueChanged,
  }) : _remote = remote,
       _syncEngine = syncEngine,
       _store = store,
       _getBusinessId = getBusinessId,
       _isOnline = isOnline,
       _onQueueChanged = onQueueChanged;

  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    CustomerFilter filter = CustomerFilter.active,
    CustomerSort sort = CustomerSort.recentlyAdded,
  }) async {
    final businessId = _getBusinessId();
    if (_isOnline()) {
      try {
        final remoteList = await _remote.getCustomers(
          searchQuery: searchQuery,
          filter: filter,
          sort: sort,
        );
        if ((searchQuery == null || searchQuery.isEmpty) &&
            filter == CustomerFilter.active &&
            businessId != null) {
          await _syncEngine.cacheCustomers(businessId, remoteList);
        }
        return remoteList;
      } catch (e) {
        AppLogger.warning(
          'OfflineAwareCustomerRepository: falling back to cache ($e)',
        );
      }
    }

    if (businessId == null) return const [];
    final cached = await _syncEngine.getCachedCustomers(businessId);
    Iterable<Customer> filtered = cached;
    if (filter == CustomerFilter.active) {
      filtered = filtered.where((c) => !c.isArchived);
    } else if (filter == CustomerFilter.archived) {
      filtered = filtered.where((c) => c.isArchived);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered.where(
        (c) =>
            c.fullName.toLowerCase().contains(q) ||
            c.primaryPhone.toLowerCase().contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false),
      );
    }
    final list = filtered.toList();
    if (sort == CustomerSort.nameAsc) {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (sort == CustomerSort.nameDesc) {
      list.sort((a, b) => b.fullName.compareTo(a.fullName));
    }
    return list;
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    if (_isOnline()) {
      try {
        return await _remote.getCustomerById(id);
      } catch (e) {
        AppLogger.warning(
          'OfflineAwareCustomerRepository.getCustomerById cache fallback: $e',
        );
      }
    }
    final businessId = _getBusinessId();
    if (businessId == null) return null;
    final cached = await _syncEngine.getCachedCustomers(businessId);
    return cached.where((c) => c.id == id).firstOrNull;
  }

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
    if (_isOnline()) {
      try {
        final created = await _remote.createCustomer(
          businessId: businessId,
          fullName: fullName,
          primaryPhone: primaryPhone,
          alternatePhone: alternatePhone,
          email: email,
          customerType: customerType,
          notes: notes,
          source: source,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          area: area,
          city: city,
          state: state,
          postalCode: postalCode,
          landmark: landmark,
        );
        await _store.upsertSingleEntity(
          businessId: businessId,
          entityType: OfflineEntityTypes.customer,
          entityId: created.id,
          payload: created.toJson(),
          updatedAt: created.updatedAt,
          isDirty: false,
        );
        return created;
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }

    final queued = await _syncEngine.queueCreateCustomer(
      businessId: businessId,
      fullName: fullName,
      primaryPhone: primaryPhone,
      alternatePhone: alternatePhone,
      email: email,
      customerType: customerType,
      notes: notes,
    );
    _onQueueChanged?.call();
    return queued;
  }

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
    if (_isOnline()) {
      try {
        final updated = await _remote.updateCustomer(
          customer,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          area: area,
          city: city,
          state: state,
          postalCode: postalCode,
          landmark: landmark,
        );
        await _store.upsertSingleEntity(
          businessId: updated.businessId,
          entityType: OfflineEntityTypes.customer,
          entityId: updated.id,
          payload: updated.toJson(),
          updatedAt: updated.updatedAt,
          isDirty: false,
        );
        return updated;
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }

    await _syncEngine.queueUpdateCustomer(
      updatedCustomer: customer,
      baseUpdatedAt: customer.updatedAt,
    );
    _onQueueChanged?.call();
    return customer.copyWith(updatedAt: DateTime.now().toUtc());
  }

  @override
  Future<void> archiveCustomer(String id) async {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Archiving a customer requires an active internet connection.',
      );
    }
    await _remote.archiveCustomer(id);
  }

  @override
  Future<void> restoreCustomer(String id) async {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Restoring a customer requires an active internet connection.',
      );
    }
    await _remote.restoreCustomer(id);
  }

  @override
  Future<Customer?> checkDuplicatePhone(
    String businessId,
    String phone, {
    String? excludeCustomerId,
  }) async {
    if (_isOnline()) {
      try {
        return await _remote.checkDuplicatePhone(
          businessId,
          phone,
          excludeCustomerId: excludeCustomerId,
        );
      } catch (_) {}
    }
    final cached = await _syncEngine.getCachedCustomers(businessId);
    final normalized = phone.replaceAll(RegExp(r'\D'), '');
    return cached.where((c) {
      if (excludeCustomerId != null && c.id == excludeCustomerId) return false;
      return c.primaryPhone.replaceAll(RegExp(r'\D'), '') == normalized;
    }).firstOrNull;
  }

  @override
  Future<List<CustomerAddress>> getCustomerAddresses(String customerId) async {
    if (_isOnline()) {
      try {
        return await _remote.getCustomerAddresses(customerId);
      } catch (_) {}
    }
    final bizId = _getBusinessId();
    if (bizId == null) return const [];
    final cached = await _syncEngine.getCachedCustomers(bizId);
    return cached.where((c) => c.id == customerId).firstOrNull?.addresses ??
        const [];
  }

  @override
  Future<void> logCommunication({
    required String businessId,
    required String customerId,
    required String channel,
    String direction = 'outgoing',
    String? messageContent,
    String status = 'initiated',
  }) {
    return _remote.logCommunication(
      businessId: businessId,
      customerId: customerId,
      channel: channel,
      direction: direction,
      messageContent: messageContent,
      status: status,
    );
  }

  @override
  Future<List<CustomerActivityItem>> getCustomerActivity(
    Customer customer,
  ) async {
    if (!_isOnline()) return const [];
    try {
      return await _remote.getCustomerActivity(customer);
    } catch (_) {
      return const [];
    }
  }
}

/// Decorates [IServiceRepository] with local SQLite cache & offline create/update queue.
class OfflineAwareServiceRepository implements IServiceRepository {
  final IServiceRepository _remote;
  final SyncEngine _syncEngine;
  final IOfflineStore _store;
  final String? Function() _getBusinessId;
  final bool Function() _isOnline;
  final void Function()? _onQueueChanged;

  OfflineAwareServiceRepository({
    required IServiceRepository remote,
    required SyncEngine syncEngine,
    required IOfflineStore store,
    required String? Function() getBusinessId,
    required bool Function() isOnline,
    void Function()? onQueueChanged,
  }) : _remote = remote,
       _syncEngine = syncEngine,
       _store = store,
       _getBusinessId = getBusinessId,
       _isOnline = isOnline,
       _onQueueChanged = onQueueChanged;

  @override
  Future<List<ServiceEntry>> getServiceEntries({
    String? businessId,
    String? customerId,
    ServiceFilter filter = ServiceFilter.all,
    ServiceSort sort = ServiceSort.recentlyCreated,
    String? searchQuery,
    int? limit,
  }) async {
    final targetBizId = businessId ?? _getBusinessId();
    if (_isOnline()) {
      try {
        final list = await _remote.getServiceEntries(
          businessId: businessId,
          customerId: customerId,
          filter: filter,
          sort: sort,
          searchQuery: searchQuery,
          limit: limit,
        );
        if (targetBizId != null &&
            customerId == null &&
            filter == ServiceFilter.all &&
            (searchQuery == null || searchQuery.isEmpty)) {
          await _syncEngine.cacheServices(targetBizId, list);
        }
        return list;
      } catch (e) {
        AppLogger.warning(
          'OfflineAwareServiceRepository fallback to cache ($e)',
        );
      }
    }

    if (targetBizId == null) return const [];
    final cached = await _syncEngine.getCachedServices(targetBizId);
    Iterable<ServiceEntry> filtered = cached;
    if (customerId != null) {
      filtered = filtered.where((s) => s.customerId == customerId);
    }
    if (filter == ServiceFilter.pending) {
      filtered = filtered.where((s) => s.status == 'pending');
    } else if (filter == ServiceFilter.inProgress) {
      filtered = filtered.where((s) => s.status == 'in_progress');
    } else if (filter == ServiceFilter.completed) {
      filtered = filtered.where((s) => s.status == 'completed');
    } else if (filter == ServiceFilter.cancelled) {
      filtered = filtered.where((s) => s.status == 'cancelled');
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered.where(
        (s) =>
            s.title.toLowerCase().contains(q) ||
            (s.description?.toLowerCase().contains(q) ?? false),
      );
    }
    final result = filtered.toList();
    if (limit != null && result.length > limit) {
      return result.take(limit).toList();
    }
    return result;
  }

  @override
  Future<ServiceEntry?> getServiceEntryById(String id) async {
    if (_isOnline()) {
      try {
        return await _remote.getServiceEntryById(id);
      } catch (_) {}
    }
    final bizId = _getBusinessId();
    if (bizId == null) return null;
    final cached = await _syncEngine.getCachedServices(bizId);
    return cached.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<ServiceSummaryCounts> getServiceSummaryCounts(
    String businessId,
  ) async {
    if (_isOnline()) {
      try {
        return await _remote.getServiceSummaryCounts(businessId);
      } catch (_) {}
    }
    final cached = await _syncEngine.getCachedServices(businessId);
    return ServiceSummaryCounts(
      totalServices: cached.length,
      pending: cached.where((s) => s.isPending).length,
      inProgress: cached.where((s) => s.isInProgress).length,
      completed: cached.where((s) => s.isCompleted).length,
      cancelled: cached.where((s) => s.isCancelled).length,
    );
  }

  @override
  Future<ServiceSummaryCounts> getCustomerServiceCounts(
    String customerId,
  ) async {
    if (_isOnline()) {
      try {
        return await _remote.getCustomerServiceCounts(customerId);
      } catch (_) {}
    }
    final bizId = _getBusinessId();
    if (bizId == null) return const ServiceSummaryCounts();
    final cached = (await _syncEngine.getCachedServices(
      bizId,
    )).where((s) => s.customerId == customerId).toList();
    return ServiceSummaryCounts(
      totalServices: cached.length,
      pending: cached.where((s) => s.isPending).length,
      inProgress: cached.where((s) => s.isInProgress).length,
      completed: cached.where((s) => s.isCompleted).length,
      cancelled: cached.where((s) => s.isCancelled).length,
    );
  }

  @override
  Future<List<ServiceEntry>> getCustomerServiceHistory(String customerId) {
    return getServiceEntries(customerId: customerId);
  }

  @override
  Future<List<Equipment>> getCustomerEquipment(String customerId) async {
    if (!_isOnline()) return const [];
    try {
      return await _remote.getCustomerEquipment(customerId);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ServiceEntry> createServiceEntry(ServiceEntry entry) async {
    if (_isOnline()) {
      try {
        final created = await _remote.createServiceEntry(entry);
        await _store.upsertSingleEntity(
          businessId: created.businessId,
          entityType: OfflineEntityTypes.service,
          entityId: created.id,
          payload: created.toJson(),
          updatedAt: created.updatedAt,
          isDirty: false,
        );
        return created;
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }
    final queued = await _syncEngine.queueCreateService(entry: entry);
    _onQueueChanged?.call();
    return queued;
  }

  @override
  Future<ServiceEntry> updateServiceEntry(ServiceEntry entry) async {
    if (_isOnline()) {
      try {
        final updated = await _remote.updateServiceEntry(entry);
        await _store.upsertSingleEntity(
          businessId: updated.businessId,
          entityType: OfflineEntityTypes.service,
          entityId: updated.id,
          payload: updated.toJson(),
          updatedAt: updated.updatedAt,
          isDirty: false,
        );
        return updated;
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }
    await _syncEngine.queueUpdateService(
      entry: entry,
      baseUpdatedAt: entry.updatedAt,
    );
    _onQueueChanged?.call();
    return entry;
  }

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
  }) async {
    if (_isOnline()) {
      try {
        return await _remote.updateServiceStatus(
          serviceId: serviceId,
          businessId: businessId,
          newStatus: newStatus,
          oldStatus: oldStatus,
          completionDate: completionDate,
          workPerformed: workPerformed,
          finalNotes: finalNotes,
          finalAmount: finalAmount,
          actorUserId: actorUserId,
        );
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }
    final existing = await getServiceEntryById(serviceId);
    if (existing == null) {
      throw const OfflineUnsupportedException(
        'Service status update requires connectivity or a cached service record.',
      );
    }
    final updated = ServiceEntry(
      id: existing.id,
      businessId: existing.businessId,
      customerId: existing.customerId,
      customerAddressId: existing.customerAddressId,
      equipmentId: existing.equipmentId,
      serviceNumber: existing.serviceNumber,
      serviceType: existing.serviceType,
      title: existing.title,
      description: existing.description,
      workPerformed: workPerformed ?? existing.workPerformed,
      serviceDate: existing.serviceDate,
      status: newStatus,
      serviceAmount: finalAmount ?? existing.serviceAmount,
      additionalCharges: existing.additionalCharges,
      discountAmount: existing.discountAmount,
      totalAmount: finalAmount ?? existing.totalAmount,
      paymentStatus: existing.paymentStatus,
      notes: finalNotes ?? existing.notes,
      completedAt: newStatus == 'completed'
          ? (completionDate ?? DateTime.now().toUtc())
          : existing.completedAt,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
    );
    await _syncEngine.queueUpdateService(
      entry: updated,
      baseUpdatedAt: existing.updatedAt,
    );
    _onQueueChanged?.call();
    return updated;
  }

  @override
  Future<List<ServiceActivity>> getServiceActivities(String serviceId) async {
    if (!_isOnline()) return const [];
    try {
      return await _remote.getServiceActivities(serviceId);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ServiceAttachment> addServiceAttachment({
    required String businessId,
    required String serviceId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
  }) {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Uploading attachments requires an active internet connection.',
      );
    }
    return _remote.addServiceAttachment(
      businessId: businessId,
      serviceId: serviceId,
      fileName: fileName,
      fileBytes: fileBytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> deleteServiceAttachment({
    required String attachmentId,
    required String filePath,
  }) {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Deleting attachments requires an active internet connection.',
      );
    }
    return _remote.deleteServiceAttachment(
      attachmentId: attachmentId,
      filePath: filePath,
    );
  }

  @override
  Future<String?> getAttachmentDownloadUrl(String filePath) {
    return _remote.getAttachmentDownloadUrl(filePath);
  }
}

/// Decorates [IReminderRepository] with local caching and offline reminder creation/completion.
class OfflineAwareReminderRepository implements IReminderRepository {
  final IReminderRepository _remote;
  final SyncEngine _syncEngine;
  final IOfflineStore _store;
  final String? Function() _getBusinessId;
  final bool Function() _isOnline;
  final void Function()? _onQueueChanged;

  OfflineAwareReminderRepository({
    required IReminderRepository remote,
    required SyncEngine syncEngine,
    required IOfflineStore store,
    required String? Function() getBusinessId,
    required bool Function() isOnline,
    void Function()? onQueueChanged,
  }) : _remote = remote,
       _syncEngine = syncEngine,
       _store = store,
       _getBusinessId = getBusinessId,
       _isOnline = isOnline,
       _onQueueChanged = onQueueChanged;

  @override
  Future<List<Reminder>> getReminders({
    String? status,
    String? type,
    String? category,
    String? customerId,
    bool includeCompleted = false,
  }) async {
    final businessId = _getBusinessId();
    if (_isOnline()) {
      try {
        final list = await _remote.getReminders(
          status: status,
          type: type,
          category: category,
          customerId: customerId,
          includeCompleted: includeCompleted,
        );
        if (businessId != null &&
            status == null &&
            type == null &&
            category == null &&
            customerId == null) {
          await _syncEngine.cacheReminders(businessId, list);
        }
        return list;
      } catch (e) {
        AppLogger.warning(
          'OfflineAwareReminderRepository fallback to cache ($e)',
        );
      }
    }

    if (businessId == null) return const [];
    final cached = await _syncEngine.getCachedReminders(businessId);
    return cached.where((r) {
      if (!includeCompleted &&
          status != 'completed' &&
          (r.isCompleted || r.isCancelled)) {
        return false;
      }
      if (status != null && status != 'all') {
        switch (status) {
          case 'today':
            if (r.isOverdue || !r.isDueToday) return false;
            break;
          case 'overdue':
            if (!r.isOverdue) return false;
            break;
          case 'upcoming':
            if (r.isOverdue || !r.isUpcoming) return false;
            break;
          case 'completed':
            if (!r.isCompleted) return false;
            break;
          default:
            if (r.status != status) return false;
        }
      }
      if (type != null && type != 'all' && r.reminderType != type) return false;
      if (category != null && r.category != category) return false;
      if (customerId != null && r.customerId != customerId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    if (_isOnline()) {
      try {
        return await _remote.getReminderById(id);
      } catch (_) {}
    }
    final businessId = _getBusinessId();
    if (businessId == null) return null;
    final cached = await _syncEngine.getCachedReminders(businessId);
    return cached.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    if (_isOnline()) {
      try {
        final created = await _remote.createReminder(reminder);
        await _store.upsertSingleEntity(
          businessId: created.businessId,
          entityType: OfflineEntityTypes.reminder,
          entityId: created.id,
          payload: created.toJson(),
          updatedAt: created.updatedAt,
          isDirty: false,
        );
        return created;
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }
    final queued = await _syncEngine.queueCreateReminder(reminder: reminder);
    _onQueueChanged?.call();
    return queued;
  }

  @override
  Future<Reminder> updateReminder(Reminder reminder) {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Editing existing reminders requires an active connection.',
      );
    }
    return _remote.updateReminder(reminder);
  }

  @override
  Future<void> snoozeReminder(String id, DateTime snoozeUntil) {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Snoozing reminders requires server scheduling connectivity.',
      );
    }
    return _remote.snoozeReminder(id, snoozeUntil);
  }

  @override
  Future<void> completeReminder(String id, {String? notes}) async {
    if (_isOnline()) {
      try {
        await _remote.completeReminder(id, notes: notes);
        return;
      } catch (e) {
        if (!_looksLikeNetworkError(e)) rethrow;
      }
    }
    final existing = await getReminderById(id);
    if (existing == null) {
      throw const OfflineUnsupportedException(
        'Reminder not found in local cache.',
      );
    }
    await _syncEngine.queueCompleteReminder(reminder: existing, notes: notes);
    _onQueueChanged?.call();
  }

  @override
  Future<void> markCompleted(String id) => completeReminder(id);

  @override
  Future<void> cancelReminder(String id) {
    if (!_isOnline()) {
      throw const OfflineUnsupportedException(
        'Cancelling reminders requires an active internet connection.',
      );
    }
    return _remote.cancelReminder(id);
  }

  @override
  Future<ReminderOverviewStats> getOverviewStats() async {
    if (_isOnline()) {
      try {
        return await _remote.getOverviewStats();
      } catch (_) {}
    }
    final businessId = _getBusinessId();
    if (businessId == null) return const ReminderOverviewStats();
    final cached = await _syncEngine.getCachedReminders(businessId);
    return ReminderOverviewStats(
      dueToday: cached
          .where((r) => !r.isCompleted && !r.isOverdue && r.isDueToday)
          .length,
      overdue: cached.where((r) => !r.isCompleted && r.isOverdue).length,
      upcoming: cached
          .where((r) => !r.isCompleted && !r.isOverdue && r.isUpcoming)
          .length,
      completed: cached.where((r) => r.isCompleted).length,
    );
  }
}

bool _looksLikeNetworkError(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('socket') ||
      msg.contains('network') ||
      msg.contains('timeout') ||
      msg.contains('failed host lookup') ||
      msg.contains('clientexception');
}
