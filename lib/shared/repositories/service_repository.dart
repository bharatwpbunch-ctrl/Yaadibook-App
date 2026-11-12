import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/equipment.dart';
import '../models/service_activity.dart';
import '../models/service_attachment.dart';
import '../models/service_entry.dart';

/// Filter options for service entries.
enum ServiceFilter { all, pending, inProgress, completed, cancelled }

/// Sort options for service entries.
enum ServiceSort { recentlyCreated, newestDate, oldestDate }

/// Aggregated count summary for services.
class ServiceSummaryCounts {
  final int totalServices;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const ServiceSummaryCounts({
    this.totalServices = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.cancelled = 0,
  });
}

abstract class IServiceRepository {
  Future<List<ServiceEntry>> getServiceEntries({
    String? businessId,
    String? customerId,
    ServiceFilter filter = ServiceFilter.all,
    ServiceSort sort = ServiceSort.recentlyCreated,
    String? searchQuery,
    int? limit,
  });

  Future<ServiceEntry?> getServiceEntryById(String id);

  Future<ServiceSummaryCounts> getServiceSummaryCounts(String businessId);

  Future<ServiceSummaryCounts> getCustomerServiceCounts(String customerId);

  Future<List<ServiceEntry>> getCustomerServiceHistory(String customerId);

  Future<List<Equipment>> getCustomerEquipment(String customerId);

  Future<ServiceEntry> createServiceEntry(ServiceEntry entry);

  Future<ServiceEntry> updateServiceEntry(ServiceEntry entry);

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
  });

  Future<List<ServiceActivity>> getServiceActivities(String serviceId);

  Future<ServiceAttachment> addServiceAttachment({
    required String businessId,
    required String serviceId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
  });

  Future<void> deleteServiceAttachment({
    required String attachmentId,
    required String filePath,
  });

  Future<String?> getAttachmentDownloadUrl(String filePath);
}

class SupabaseServiceRepository implements IServiceRepository {
  final SupabaseClient? _client;

  SupabaseServiceRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<ServiceEntry>> getServiceEntries({
    String? businessId,
    String? customerId,
    ServiceFilter filter = ServiceFilter.all,
    ServiceSort sort = ServiceSort.recentlyCreated,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      var query = _safeClient
          .from('service_entries')
          .select('*, customers(*), customer_addresses(*), equipment(*)');

      if (businessId != null) {
        query = query.eq('business_id', businessId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      // Status filters
      switch (filter) {
        case ServiceFilter.pending:
          query = query.eq('status', 'pending');
          break;
        case ServiceFilter.inProgress:
          query = query.eq('status', 'in_progress');
          break;
        case ServiceFilter.completed:
          query = query.eq('status', 'completed');
          break;
        case ServiceFilter.cancelled:
          query = query.eq('status', 'cancelled');
          break;
        case ServiceFilter.all:
          break;
      }

      // Search term
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or(
          'title.ilike.%$term%,service_number.ilike.%$term%,description.ilike.%$term%',
        );
      }

      // Sort
      final PostgrestTransformBuilder<PostgrestList> transformQuery;
      switch (sort) {
        case ServiceSort.recentlyCreated:
          transformQuery = query.order('created_at', ascending: false);
          break;
        case ServiceSort.newestDate:
          transformQuery = query.order('service_date', ascending: false);
          break;
        case ServiceSort.oldestDate:
          transformQuery = query.order('service_date', ascending: true);
          break;
      }

      if (limit != null) {
        final limited = transformQuery.limit(limit);
        final data = await limited;
        return (data as List<dynamic>)
            .map((item) => ServiceEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      final data = await transformQuery;
      return (data as List<dynamic>)
          .map((item) => ServiceEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.getServiceEntries failed', e, stack);
      throw AppStorageException('Failed to load service records: $e');
    }
  }

  @override
  Future<ServiceEntry?> getServiceEntryById(String id) async {
    try {
      final data = await _safeClient
          .from('service_entries')
          .select(
            '*, customers(*), customer_addresses(*), equipment(*), service_attachments(*), service_activities(*)',
          )
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return ServiceEntry.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.getServiceEntryById failed', e, stack);
      // Fallback query if service_attachments / activities table not available on older instances
      try {
        final fallback = await _safeClient
            .from('service_entries')
            .select('*, customers(*), customer_addresses(*), equipment(*)')
            .eq('id', id)
            .maybeSingle();
        if (fallback == null) return null;
        return ServiceEntry.fromJson(fallback);
      } catch (_) {
        throw AppStorageException('Failed to load service record: $e');
      }
    }
  }

  @override
  Future<ServiceSummaryCounts> getServiceSummaryCounts(
    String businessId,
  ) async {
    try {
      final data = await _safeClient
          .from('service_entries')
          .select('status')
          .eq('business_id', businessId);

      int total = 0;
      int pending = 0;
      int inProgress = 0;
      int completed = 0;
      int cancelled = 0;

      for (final row in (data as List<dynamic>)) {
        total++;
        final status = (row['status'] as String?)?.toLowerCase();
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return ServiceSummaryCounts(
        totalServices: total,
        pending: pending,
        inProgress: inProgress,
        completed: completed,
        cancelled: cancelled,
      );
    } catch (e, stack) {
      AppLogger.warning(
        'ServiceRepository.getServiceSummaryCounts error: $e\n$stack',
      );
      return const ServiceSummaryCounts();
    }
  }

  @override
  Future<ServiceSummaryCounts> getCustomerServiceCounts(
    String customerId,
  ) async {
    try {
      final data = await _safeClient
          .from('service_entries')
          .select('status')
          .eq('customer_id', customerId);

      int total = 0;
      int pending = 0;
      int inProgress = 0;
      int completed = 0;
      int cancelled = 0;

      for (final row in (data as List<dynamic>)) {
        total++;
        final status = (row['status'] as String?)?.toLowerCase();
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return ServiceSummaryCounts(
        totalServices: total,
        pending: pending,
        inProgress: inProgress,
        completed: completed,
        cancelled: cancelled,
      );
    } catch (e, stack) {
      AppLogger.warning(
        'ServiceRepository.getCustomerServiceCounts error: $e\n$stack',
      );
      return const ServiceSummaryCounts();
    }
  }

  @override
  Future<List<ServiceEntry>> getCustomerServiceHistory(
    String customerId,
  ) async {
    return getServiceEntries(
      customerId: customerId,
      filter: ServiceFilter.all,
      sort: ServiceSort.recentlyCreated,
    );
  }

  @override
  Future<List<Equipment>> getCustomerEquipment(String customerId) async {
    try {
      final data = await _safeClient
          .from('equipment')
          .select()
          .eq('customer_id', customerId)
          .eq('status', 'active')
          .order('equipment_name', ascending: true);

      return (data as List<dynamic>)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.warning(
        'ServiceRepository.getCustomerEquipment warning: $e\n$stack',
      );
      return const [];
    }
  }

  @override
  Future<ServiceEntry> createServiceEntry(ServiceEntry entry) async {
    try {
      final payload = entry.toJson();
      // Remove empty id if generated by database
      if (entry.id.isEmpty) {
        payload.remove('id');
      }

      final data = await _safeClient
          .from('service_entries')
          .insert(payload)
          .select('*, customers(*), customer_addresses(*), equipment(*)')
          .single();

      final created = ServiceEntry.fromJson(data);

      // Log initial creation activity
      try {
        await _safeClient.from('service_activities').insert({
          'business_id': created.businessId,
          'service_id': created.id,
          'activity_type': 'created',
          'title': 'Service Created',
          'description':
              'Service entry was created with status "${created.status}".',
          'new_status': created.status,
        });
      } catch (actErr) {
        AppLogger.warning(
          'Could not write service_activities on create: $actErr',
        );
      }

      return created;
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.createServiceEntry failed', e, stack);
      throw AppStorageException('Failed to create service entry: $e');
    }
  }

  @override
  Future<ServiceEntry> updateServiceEntry(ServiceEntry entry) async {
    try {
      final payload = entry.toJson();
      final data = await _safeClient
          .from('service_entries')
          .update(payload)
          .eq('id', entry.id)
          .select('*, customers(*), customer_addresses(*), equipment(*)')
          .single();

      final updated = ServiceEntry.fromJson(data);

      // Record update activity
      try {
        await _safeClient.from('service_activities').insert({
          'business_id': updated.businessId,
          'service_id': updated.id,
          'activity_type': 'details_updated',
          'title': 'Service Details Updated',
          'description': 'Service information and charges were updated.',
        });
      } catch (actErr) {
        AppLogger.warning(
          'Could not write service_activities on update: $actErr',
        );
      }

      return updated;
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.updateServiceEntry failed', e, stack);
      throw AppStorageException('Failed to update service entry: $e');
    }
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
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (newStatus == 'completed') {
        updates['completed_at'] = (completionDate ?? DateTime.now())
            .toUtc()
            .toIso8601String();
      }

      if (workPerformed != null && workPerformed.trim().isNotEmpty) {
        updates['work_performed'] = workPerformed.trim();
      }
      if (finalNotes != null && finalNotes.trim().isNotEmpty) {
        updates['notes'] = finalNotes.trim();
      }
      if (finalAmount != null) {
        updates['total_amount'] = finalAmount;
      }

      final data = await _safeClient
          .from('service_entries')
          .update(updates)
          .eq('id', serviceId)
          .select('*, customers(*), customer_addresses(*), equipment(*)')
          .single();

      final updated = ServiceEntry.fromJson(data);

      // Map activity type based on transition
      String actType = 'status_changed';
      String title = 'Status Changed to $newStatus';
      if (newStatus == 'completed') {
        actType = 'completed';
        title = 'Service Completed';
      } else if (newStatus == 'cancelled') {
        actType = 'cancelled';
        title = 'Service Cancelled';
      } else if (oldStatus == 'cancelled' && newStatus != 'cancelled') {
        actType = 'resumed';
        title = 'Service Resumed';
      }

      try {
        await _safeClient.from('service_activities').insert({
          'business_id': businessId,
          'service_id': serviceId,
          'activity_type': actType,
          'title': title,
          'description': workPerformed?.isNotEmpty == true
              ? 'Work performed: $workPerformed'
              : 'Status updated from "$oldStatus" to "$newStatus".',
          'old_status': oldStatus,
          'new_status': newStatus,
          'actor_user_id': actorUserId,
        });
      } catch (actErr) {
        AppLogger.warning('Could not record status activity: $actErr');
      }

      return updated;
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.updateServiceStatus failed', e, stack);
      throw AppStorageException('Failed to update service status: $e');
    }
  }

  @override
  Future<List<ServiceActivity>> getServiceActivities(String serviceId) async {
    try {
      final data = await _safeClient
          .from('service_activities')
          .select()
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((a) => ServiceActivity.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.warning(
        'ServiceRepository.getServiceActivities warning: $e\n$stack',
      );
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
  }) async {
    try {
      final sanitizedName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-\.]'),
        '_',
      );
      final storagePath =
          '$businessId/$serviceId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      // 1. Upload to Supabase Storage
      await _safeClient.storage
          .from('service-attachments')
          .uploadBinary(
            storagePath,
            Uint8List.fromList(fileBytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      // 2. Insert metadata record in service_attachments
      final data = await _safeClient
          .from('service_attachments')
          .insert({
            'business_id': businessId,
            'service_id': serviceId,
            'file_path': storagePath,
            'file_name': fileName,
            'file_size': fileBytes.length,
            'mime_type': mimeType,
          })
          .select()
          .single();

      final attachment = ServiceAttachment.fromJson(data);

      // 3. Record in activity log
      try {
        await _safeClient.from('service_activities').insert({
          'business_id': businessId,
          'service_id': serviceId,
          'activity_type': 'attachment_added',
          'title': 'Attachment Added',
          'description':
              'Added "$fileName" (${(fileBytes.length / 1024).toStringAsFixed(1)} KB)',
        });
      } catch (actErr) {
        AppLogger.warning('Could not log attachment activity: $actErr');
      }

      return attachment;
    } catch (e, stack) {
      AppLogger.error(
        'ServiceRepository.addServiceAttachment failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to upload service attachment: $e');
    }
  }

  @override
  Future<void> deleteServiceAttachment({
    required String attachmentId,
    required String filePath,
  }) async {
    try {
      await _safeClient.storage.from('service-attachments').remove([filePath]);
      await _safeClient
          .from('service_attachments')
          .delete()
          .eq('id', attachmentId);
    } catch (e, stack) {
      AppLogger.error(
        'ServiceRepository.deleteServiceAttachment failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to delete attachment: $e');
    }
  }

  @override
  Future<String?> getAttachmentDownloadUrl(String filePath) async {
    try {
      // Create a 1-hour signed URL for secure, authenticated access
      final signedUrl = await _safeClient.storage
          .from('service-attachments')
          .createSignedUrl(filePath, 3600);
      return signedUrl;
    } catch (e, stack) {
      AppLogger.warning(
        'Could not create signed URL for $filePath: $e\n$stack',
      );
      return null;
    }
  }
}
