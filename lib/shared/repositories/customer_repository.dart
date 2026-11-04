import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/customer.dart';

abstract class ICustomerRepository {
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    bool includeArchived = false,
  });
  Future<Customer?> getCustomerById(String id);
  Future<Customer> createCustomer({
    required String businessId,
    required String fullName,
    required String primaryPhone,
    String? alternatePhone,
    String? email,
    String? notes,
    String? source,
  });
  Future<Customer> updateCustomer(Customer customer);
  Future<void> archiveCustomer(String id);
}

class SupabaseCustomerRepository implements ICustomerRepository {
  final SupabaseClient? _client;

  SupabaseCustomerRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    bool includeArchived = false,
  }) async {
    try {
      var query = _safeClient.from('customers').select();

      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or('full_name.ilike.%$term%,primary_phone.ilike.%$term%');
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.getCustomers failed', e, stack);
      throw AppStorageException('Failed to load customers: $e');
    }
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    try {
      final data = await _safeClient
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.getCustomerById failed', e, stack);
      throw AppStorageException('Failed to load customer: $e');
    }
  }

  @override
  Future<Customer> createCustomer({
    required String businessId,
    required String fullName,
    required String primaryPhone,
    String? alternatePhone,
    String? email,
    String? notes,
    String? source,
  }) async {
    try {
      final payload = <String, dynamic>{
        'business_id': businessId,
        'full_name': fullName,
        'primary_phone': primaryPhone,
      };
      if (alternatePhone != null) payload['alternate_phone'] = alternatePhone;
      if (email != null) payload['email'] = email;
      if (notes != null) payload['notes'] = notes;
      if (source != null) payload['source'] = source;

      final data = await _safeClient
          .from('customers')
          .insert(payload)
          .select()
          .single();
      return Customer.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.createCustomer failed', e, stack);
      throw AppStorageException('Failed to create customer: $e');
    }
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final data = await _safeClient
          .from('customers')
          .update(customer.toJson())
          .eq('id', customer.id)
          .select()
          .single();
      return Customer.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.updateCustomer failed', e, stack);
      throw AppStorageException('Failed to update customer: $e');
    }
  }

  @override
  Future<void> archiveCustomer(String id) async {
    try {
      await _safeClient
          .from('customers')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.archiveCustomer failed', e, stack);
      throw AppStorageException('Failed to archive customer: $e');
    }
  }
}
