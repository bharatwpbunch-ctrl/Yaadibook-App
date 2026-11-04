import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/service_entry.dart';

abstract class IServiceRepository {
  Future<List<ServiceEntry>> getServiceEntries({
    String? customerId,
    String? status,
  });
  Future<ServiceEntry?> getServiceEntryById(String id);
  Future<ServiceEntry> createServiceEntry(ServiceEntry entry);
  Future<ServiceEntry> updateServiceEntry(ServiceEntry entry);
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
    String? customerId,
    String? status,
  }) async {
    try {
      var query = _safeClient.from('service_entries').select();

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query.order('service_date', ascending: false);
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
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return ServiceEntry.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.getServiceEntryById failed', e, stack);
      throw AppStorageException('Failed to load service record: $e');
    }
  }

  @override
  Future<ServiceEntry> createServiceEntry(ServiceEntry entry) async {
    try {
      final data = await _safeClient
          .from('service_entries')
          .insert(entry.toJson())
          .select()
          .single();
      return ServiceEntry.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.createServiceEntry failed', e, stack);
      throw AppStorageException('Failed to create service entry: $e');
    }
  }

  @override
  Future<ServiceEntry> updateServiceEntry(ServiceEntry entry) async {
    try {
      final data = await _safeClient
          .from('service_entries')
          .update(entry.toJson())
          .eq('id', entry.id)
          .select()
          .single();
      return ServiceEntry.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ServiceRepository.updateServiceEntry failed', e, stack);
      throw AppStorageException('Failed to update service entry: $e');
    }
  }
}
