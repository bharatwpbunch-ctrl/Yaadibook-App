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

      try {
        final data = await _safeClient
            .from('businesses')
            .select()
            .eq('owner_user_id', user.id)
            .maybeSingle();

        if (data != null) {
          return Business.fromJson(data);
        }
      } catch (tableError) {
        AppLogger.warning(
          'BusinessRepository.getMyBusiness: direct table query failed ($tableError), checking RPC fallback',
        );
      }

      // Check via SECURITY DEFINER RPC get_my_business_id
      final fallbackBusiness = await _fallbackGetBusinessViaRpc(user);
      return fallbackBusiness;
    } catch (e, stack) {
      AppLogger.error('BusinessRepository.getMyBusiness failed', e, stack);
      throw AppStorageException('Failed to load business workspace: $e');
    }
  }

  Future<Business?> _fallbackGetBusinessViaRpc(User user) async {
    try {
      final dynamic rpcResult = await _safeClient.rpc('get_my_business_id');
      if (rpcResult != null && rpcResult.toString().isNotEmpty) {
        final bId = rpcResult.toString();
        AppLogger.info(
          'BusinessRepository: recovered existing business workspace ID via RPC: $bId',
        );
        final meta = user.userMetadata ?? {};
        final fullName = (meta['full_name'] as String?) ?? 'My Business';

        return Business(
          id: bId,
          ownerUserId: user.id,
          businessName: '$fullName Services',
          businessCategory: 'General Services',
          phone: user.phone ?? '',
          addressLine1: 'Gujarat',
          city: 'Ahmedabad',
          postalCode: '380001',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
      }
    } catch (rpcErr) {
      AppLogger.warning(
        'BusinessRepository: RPC fallback check failed: $rpcErr',
      );
    }
    return null;
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
      final dynamic businessId = await _safeClient.rpc(
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
      return businessId?.toString() ?? '';
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
