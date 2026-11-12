import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/customer_messaging_preference.dart';

abstract class IConsentRepository {
  Future<CustomerMessagingPreference> getPreference(
    String customerId,
    String businessId,
  );
  Future<CustomerMessagingPreference> updatePreference(
    CustomerMessagingPreference preference,
  );
  Future<void> recordOptOut({
    required String customerId,
    required String businessId,
    required String reason,
  });
}

class SupabaseConsentRepository implements IConsentRepository {
  final SupabaseClient? _client;

  SupabaseConsentRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<CustomerMessagingPreference> getPreference(
    String customerId,
    String businessId,
  ) async {
    try {
      final data = await _safeClient
          .from('customer_messaging_preferences')
          .select()
          .eq('customer_id', customerId)
          .maybeSingle();

      if (data == null) {
        // Return sensible default: transactional opt-in true, marketing consent false
        return CustomerMessagingPreference(
          id: '',
          businessId: businessId,
          customerId: customerId,
          whatsappOptIn: true,
          smsOptIn: true,
          marketingConsent: false,
          consentSource: 'default',
          isOptedOut: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return CustomerMessagingPreference.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ConsentRepository.getPreference failed', e, stack);
      throw AppStorageException('Failed to load messaging preferences: $e');
    }
  }

  @override
  Future<CustomerMessagingPreference> updatePreference(
    CustomerMessagingPreference preference,
  ) async {
    try {
      final map = preference.toJson();
      map['updated_at'] = DateTime.now().toIso8601String();

      // Upsert preference for customer
      final data = await _safeClient
          .from('customer_messaging_preferences')
          .upsert(map, onConflict: 'customer_id')
          .select()
          .single();

      return CustomerMessagingPreference.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ConsentRepository.updatePreference failed', e, stack);
      throw AppStorageException('Failed to update messaging preference: $e');
    }
  }

  @override
  Future<void> recordOptOut({
    required String customerId,
    required String businessId,
    required String reason,
  }) async {
    try {
      await _safeClient.from('customer_messaging_preferences').upsert({
        'business_id': businessId,
        'customer_id': customerId,
        'is_opted_out': true,
        'opted_out_at': DateTime.now().toIso8601String(),
        'opt_out_reason': reason,
        'whatsapp_opt_in': false,
        'sms_opt_in': false,
        'marketing_consent': false,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'customer_id');
    } catch (e, stack) {
      AppLogger.error('ConsentRepository.recordOptOut failed', e, stack);
      throw AppStorageException('Failed to record opt-out: $e');
    }
  }
}
