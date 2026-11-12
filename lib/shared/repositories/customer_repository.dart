import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/communication_service.dart';
import '../../core/utils/logger.dart';
import '../../features/customers/models/customer_activity_item.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';

enum CustomerFilter { active, archived, all }

enum CustomerSort { recentlyAdded, nameAsc, nameDesc }

abstract class ICustomerRepository {
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    CustomerFilter filter = CustomerFilter.active,
    CustomerSort sort = CustomerSort.recentlyAdded,
  });

  Future<Customer?> getCustomerById(String id);

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
  });

  Future<Customer> updateCustomer(
    Customer customer, {
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? state,
    String? postalCode,
    String? landmark,
  });

  Future<void> archiveCustomer(String id);

  Future<void> restoreCustomer(String id);

  Future<Customer?> checkDuplicatePhone(
    String businessId,
    String phone, {
    String? excludeCustomerId,
  });

  Future<List<CustomerAddress>> getCustomerAddresses(String customerId);

  Future<void> logCommunication({
    required String businessId,
    required String customerId,
    required String channel, // 'whatsapp', 'call'
    String direction = 'outgoing',
    String? messageContent,
    String status = 'initiated',
  });

  Future<List<CustomerActivityItem>> getCustomerActivity(Customer customer);
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
    CustomerFilter filter = CustomerFilter.active,
    CustomerSort sort = CustomerSort.recentlyAdded,
  }) async {
    try {
      var query = _safeClient
          .from('customers')
          .select('*, customer_addresses(*)');

      // 1. Filter logic
      switch (filter) {
        case CustomerFilter.active:
          query = query.isFilter('archived_at', null);
          break;
        case CustomerFilter.archived:
          query = query.not('archived_at', 'is', null);
          break;
        case CustomerFilter.all:
          // No filter on archived_at
          break;
      }

      // 2. Search logic (name, primary phone, email)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or(
          'full_name.ilike.%$term%,primary_phone.ilike.%$term%,email.ilike.%$term%',
        );
      }

      // 3. Sorting logic
      final PostgrestTransformBuilder<PostgrestList> transformQuery;
      switch (sort) {
        case CustomerSort.recentlyAdded:
          transformQuery = query.order('created_at', ascending: false);
          break;
        case CustomerSort.nameAsc:
          transformQuery = query.order('full_name', ascending: true);
          break;
        case CustomerSort.nameDesc:
          transformQuery = query.order('full_name', ascending: false);
          break;
      }

      final data = await transformQuery;
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
          .select('*, customer_addresses(*)')
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
    try {
      final payload = <String, dynamic>{
        'business_id': businessId,
        'full_name': fullName.trim(),
        'primary_phone': primaryPhone.trim(),
        'customer_type': customerType,
      };
      if (alternatePhone != null && alternatePhone.trim().isNotEmpty) {
        payload['alternate_phone'] = alternatePhone.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }
      if (source != null && source.trim().isNotEmpty) {
        payload['source'] = source.trim();
      }

      final customerData = await _safeClient
          .from('customers')
          .insert(payload)
          .select()
          .single();

      final customerId = customerData['id'] as String;

      // Create address if address fields are provided
      CustomerAddress? createdAddress;
      final hasAddress =
          (addressLine1 != null && addressLine1.trim().isNotEmpty) ||
          (area != null && area.trim().isNotEmpty) ||
          (city != null && city.trim().isNotEmpty);

      if (hasAddress) {
        final addressPayload = <String, dynamic>{
          'business_id': businessId,
          'customer_id': customerId,
          'address_label': 'Main',
          'address_line_1': addressLine1?.trim() ?? '',
          'area': area?.trim() ?? '',
          'city': city?.trim() ?? '',
          'state': state?.trim() ?? 'Gujarat',
          'postal_code': postalCode?.trim() ?? '',
          'is_default': true,
        };
        if (addressLine2 != null && addressLine2.trim().isNotEmpty) {
          addressPayload['address_line_2'] = addressLine2.trim();
        }
        if (landmark != null && landmark.trim().isNotEmpty) {
          addressPayload['landmark'] = landmark.trim();
        }

        final addrData = await _safeClient
            .from('customer_addresses')
            .insert(addressPayload)
            .select()
            .single();
        createdAddress = CustomerAddress.fromJson(addrData);
      }

      final customer = Customer.fromJson(customerData);
      return customer.copyWith(
        addresses: createdAddress != null ? [createdAddress] : const [],
      );
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.createCustomer failed', e, stack);
      throw AppStorageException('Failed to create customer: $e');
    }
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
    try {
      final payload = <String, dynamic>{
        'full_name': customer.fullName.trim(),
        'primary_phone': customer.primaryPhone.trim(),
        'alternate_phone': customer.alternatePhone?.trim(),
        'email': customer.email?.trim(),
        'customer_type': customer.customerType,
        'notes': customer.notes?.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final data = await _safeClient
          .from('customers')
          .update(payload)
          .eq('id', customer.id)
          .select()
          .single();

      // Upsert address if address details are passed
      final hasAddressInfo =
          (addressLine1 != null && addressLine1.trim().isNotEmpty) ||
          (area != null && area.trim().isNotEmpty) ||
          (city != null && city.trim().isNotEmpty);

      List<CustomerAddress> updatedAddresses = List.from(customer.addresses);

      if (hasAddressInfo) {
        final existingAddress = customer.primaryAddress;
        if (existingAddress != null) {
          final addrPayload = <String, dynamic>{
            'address_line_1':
                addressLine1?.trim() ?? existingAddress.addressLine1,
            'address_line_2':
                addressLine2?.trim() ?? existingAddress.addressLine2,
            'area': area?.trim() ?? existingAddress.area,
            'city': city?.trim() ?? existingAddress.city,
            'state': state?.trim() ?? existingAddress.state,
            'postal_code': postalCode?.trim() ?? existingAddress.postalCode,
            'landmark': landmark?.trim() ?? existingAddress.landmark,
            'updated_at': DateTime.now().toIso8601String(),
          };

          final updatedAddrData = await _safeClient
              .from('customer_addresses')
              .update(addrPayload)
              .eq('id', existingAddress.id)
              .select()
              .single();

          final updatedAddr = CustomerAddress.fromJson(updatedAddrData);
          updatedAddresses = [updatedAddr];
        } else {
          final addrPayload = <String, dynamic>{
            'business_id': customer.businessId,
            'customer_id': customer.id,
            'address_label': 'Main',
            'address_line_1': addressLine1?.trim() ?? '',
            'address_line_2': addressLine2?.trim(),
            'area': area?.trim() ?? '',
            'city': city?.trim() ?? '',
            'state': state?.trim() ?? 'Gujarat',
            'postal_code': postalCode?.trim() ?? '',
            'landmark': landmark?.trim(),
            'is_default': true,
          };

          final newAddrData = await _safeClient
              .from('customer_addresses')
              .insert(addrPayload)
              .select()
              .single();

          final newAddr = CustomerAddress.fromJson(newAddrData);
          updatedAddresses = [newAddr];
        }
      }

      final updatedCustomer = Customer.fromJson(data);
      return updatedCustomer.copyWith(addresses: updatedAddresses);
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
          .update({
            'archived_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.archiveCustomer failed', e, stack);
      throw AppStorageException('Failed to archive customer: $e');
    }
  }

  @override
  Future<void> restoreCustomer(String id) async {
    try {
      await _safeClient
          .from('customers')
          .update({
            'archived_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e, stack) {
      AppLogger.error('CustomerRepository.restoreCustomer failed', e, stack);
      throw AppStorageException('Failed to restore customer: $e');
    }
  }

  @override
  Future<Customer?> checkDuplicatePhone(
    String businessId,
    String phone, {
    String? excludeCustomerId,
  }) async {
    try {
      final normalized = CommunicationService.normalizePhoneNumber(phone);
      if (normalized.isEmpty) return null;

      var query = _safeClient
          .from('customers')
          .select('*, customer_addresses(*)')
          .eq('business_id', businessId)
          .or(
            'primary_phone.ilike.%$normalized%,alternate_phone.ilike.%$normalized%',
          );

      if (excludeCustomerId != null) {
        query = query.neq('id', excludeCustomerId);
      }

      final data = await query.maybeSingle();
      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'CustomerRepository.checkDuplicatePhone failed',
        e,
        stack,
      );
      return null;
    }
  }

  @override
  Future<List<CustomerAddress>> getCustomerAddresses(String customerId) async {
    try {
      final data = await _safeClient
          .from('customer_addresses')
          .select()
          .eq('customer_id', customerId)
          .order('is_default', ascending: false);

      return (data as List<dynamic>)
          .map((a) => CustomerAddress.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'CustomerRepository.getCustomerAddresses failed',
        e,
        stack,
      );
      return [];
    }
  }

  @override
  Future<void> logCommunication({
    required String businessId,
    required String customerId,
    required String channel,
    String direction = 'outgoing',
    String? messageContent,
    String status = 'initiated',
  }) async {
    try {
      await _safeClient.from('communication_logs').insert({
        'business_id': businessId,
        'customer_id': customerId,
        'channel': channel,
        'direction': direction,
        'message_type': 'manual',
        'message_content': messageContent,
        'status': status,
      });
    } catch (e, stack) {
      AppLogger.warning('Failed to log communication: $e\n$stack');
      // Communication logging is non-blocking for user actions
    }
  }

  @override
  Future<List<CustomerActivityItem>> getCustomerActivity(
    Customer customer,
  ) async {
    try {
      final List<CustomerActivityItem> items = [];

      // 1. Customer created event
      items.add(
        CustomerActivityItem(
          id: 'created_${customer.id}',
          type: CustomerActivityType.created,
          title: 'Customer Created',
          description: 'Added to customer directory',
          timestamp: customer.createdAt,
        ),
      );

      // 2. Customer updated event (if significantly newer than creation)
      if (customer.updatedAt.difference(customer.createdAt).inMinutes >= 1) {
        items.add(
          CustomerActivityItem(
            id: 'updated_${customer.id}_${customer.updatedAt.millisecondsSinceEpoch}',
            type: CustomerActivityType.updated,
            title: 'Details Updated',
            description: 'Customer contact or address modified',
            timestamp: customer.updatedAt,
          ),
        );
      }

      // 3. Customer archived event
      if (customer.isArchived && customer.archivedAt != null) {
        items.add(
          CustomerActivityItem(
            id: 'archived_${customer.id}',
            type: CustomerActivityType.archived,
            title: 'Customer Archived',
            description: 'Moved to archived records',
            timestamp: customer.archivedAt!,
          ),
        );
      }

      // 4. Communication logs
      try {
        final logsData = await _safeClient
            .from('communication_logs')
            .select()
            .eq('customer_id', customer.id)
            .order('created_at', ascending: false)
            .limit(20);

        for (final row in (logsData as List<dynamic>)) {
          final map = row as Map<String, dynamic>;
          final channel = (map['channel'] as String?)?.toLowerCase() ?? '';
          final createdAt = DateTime.parse(map['created_at'] as String);

          if (channel == 'call') {
            items.add(
              CustomerActivityItem(
                id: map['id'] as String,
                type: CustomerActivityType.call,
                title: 'Phone Call Dialed',
                description: 'Dialer opened from app',
                timestamp: createdAt,
              ),
            );
          } else if (channel == 'whatsapp') {
            final content = map['message_content'] as String?;
            items.add(
              CustomerActivityItem(
                id: map['id'] as String,
                type: CustomerActivityType.whatsapp,
                title: 'WhatsApp Opened',
                description: content ?? 'Pre-filled message initiated',
                timestamp: createdAt,
              ),
            );
          }
        }
      } catch (_) {
        // Safe fallback if communication logs query fails
      }

      // Sort chronological descending (latest first)
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e, stack) {
      AppLogger.error(
        'CustomerRepository.getCustomerActivity failed',
        e,
        stack,
      );
      return [
        CustomerActivityItem(
          id: 'created_${customer.id}',
          type: CustomerActivityType.created,
          title: 'Customer Created',
          description: 'Added to customer directory',
          timestamp: customer.createdAt,
        ),
      ];
    }
  }
}
