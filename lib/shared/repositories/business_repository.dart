import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/business.dart';

abstract class IBusinessRepository {
  Future<Business?> getMyBusiness();
  Future<String> createBusinessWorkspace({
    required String businessName,
    required String businessCategory,
    required String phone,
    required String addressLine1,
    required String city,
    required String postalCode,
    String state = 'Gujarat',
    String country = 'India',
    String currencyCode = 'INR',
    String timezone = 'Asia/Kolkata',
    String preferredLanguage = 'en',
  });
  Future<void> updateBusiness(Business business);
}

class SupabaseBusinessRepository implements IBusinessRepository {
  final SupabaseClient? _client;

  SupabaseBusinessRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<Business?> getMyBusiness() async {
    try {
      final user = _safeClient.auth.currentUser;
      if (user == null) return null;

      final data = await _safeClient
          .from('businesses')
          .select()
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return Business.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('BusinessRepository.getMyBusiness failed', e, stack);
      throw AppStorageException('Failed to load business workspace: $e');
    }
  }

  @override
  Future<String> createBusinessWorkspace({
    required String businessName,
    required String businessCategory,
    required String phone,
    required String addressLine1,
    required String city,
    required String postalCode,
    String state = 'Gujarat',
    String country = 'India',
    String currencyCode = 'INR',
    String timezone = 'Asia/Kolkata',
    String preferredLanguage = 'en',
  }) async {
    try {
      final businessId = await _safeClient.rpc<String>(
        'create_business_workspace',
        params: {
          'p_business_name': businessName,
          'p_business_category': businessCategory,
          'p_phone': phone,
          'p_address_line_1': addressLine1,
          'p_city': city,
          'p_postal_code': postalCode,
          'p_state': state,
          'p_country': country,
          'p_currency_code': currencyCode,
          'p_timezone': timezone,
          'p_preferred_language': preferredLanguage,
        },
      );
      return businessId;
    } catch (e, stack) {
      AppLogger.error(
        'BusinessRepository.createBusinessWorkspace failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to create business workspace: $e');
    }
  }

  @override
  Future<void> updateBusiness(Business business) async {
    try {
      await _safeClient
          .from('businesses')
          .update(business.toJson())
          .eq('id', business.id);
    } catch (e, stack) {
      AppLogger.error('BusinessRepository.updateBusiness failed', e, stack);
      throw AppStorageException('Failed to update business: $e');
    }
  }
}
