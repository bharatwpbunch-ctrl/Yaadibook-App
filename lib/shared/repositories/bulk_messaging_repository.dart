import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/communication_campaign.dart';
import '../models/communication_usage.dart';
import '../models/provider_configuration.dart';

abstract class IBulkMessagingRepository {
  Future<List<CommunicationCampaign>> getCampaigns({
    String? status,
    String? channel,
  });
  Future<CommunicationCampaign?> getCampaignById(String id);
  Future<List<CampaignRecipient>> getCampaignRecipients(String campaignId);
  Future<CommunicationCampaign> createCampaign(
    CommunicationCampaign campaign,
    List<CampaignRecipient> recipients,
  );
  Future<List<Map<String, dynamic>>> previewAudience({
    required String businessId,
    required String
    filterCategory, // 'all', 'residential', 'commercial', 'industrial', 'with_amc'
    bool marketingOnly = true,
  });
  Future<List<CommunicationUsage>> getCommunicationUsageSummary(
    String businessId,
  );
  Future<List<ProviderConfiguration>> getProviderConfigurations(
    String businessId,
  );
  Future<ProviderConfiguration> saveProviderConfiguration(
    ProviderConfiguration config,
  );
}

class SupabaseBulkMessagingRepository implements IBulkMessagingRepository {
  final SupabaseClient? _client;

  SupabaseBulkMessagingRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<CommunicationCampaign>> getCampaigns({
    String? status,
    String? channel,
  }) async {
    try {
      dynamic query = _safeClient.from('communication_campaigns').select();

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (channel != null && channel != 'all') {
        query = query.eq('channel', channel);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map(
            (item) =>
                CommunicationCampaign.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error('BulkMessagingRepository.getCampaigns failed', e, stack);
      throw AppStorageException('Failed to load campaigns: $e');
    }
  }

  @override
  Future<CommunicationCampaign?> getCampaignById(String id) async {
    try {
      final data = await _safeClient
          .from('communication_campaigns')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return CommunicationCampaign.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.getCampaignById failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load campaign: $e');
    }
  }

  @override
  Future<List<CampaignRecipient>> getCampaignRecipients(
    String campaignId,
  ) async {
    try {
      final data = await _safeClient
          .from('campaign_recipients')
          .select('*, customers(full_name)')
          .eq('campaign_id', campaignId)
          .order('dispatched_at', ascending: true);

      return (data as List<dynamic>)
          .map(
            (item) => CampaignRecipient.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.getCampaignRecipients failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load campaign recipients: $e');
    }
  }

  @override
  Future<CommunicationCampaign> createCampaign(
    CommunicationCampaign campaign,
    List<CampaignRecipient> recipients,
  ) async {
    try {
      final campaignMap = campaign.toJson();
      campaignMap.remove('id');
      campaignMap.remove('created_at');
      campaignMap.remove('updated_at');

      final createdCampaignData = await _safeClient
          .from('communication_campaigns')
          .insert(campaignMap)
          .select()
          .single();

      final createdCampaign = CommunicationCampaign.fromJson(
        createdCampaignData,
      );

      if (recipients.isNotEmpty) {
        final recipientMaps = recipients.map((r) {
          final m = r.toJson();
          m.remove('id');
          m['campaign_id'] = createdCampaign.id;
          return m;
        }).toList();

        await _safeClient.from('campaign_recipients').insert(recipientMaps);
      }

      return createdCampaign;
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.createCampaign failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to create campaign: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> previewAudience({
    required String businessId,
    required String filterCategory,
    bool marketingOnly = true,
  }) async {
    try {
      // 1. Fetch active customers
      dynamic custQuery = _safeClient
          .from('customers')
          .select('id, full_name, primary_phone, customer_type')
          .eq('business_id', businessId)
          .eq('is_archived', false);

      if (filterCategory != 'all' && filterCategory != 'with_amc') {
        custQuery = custQuery.eq('customer_type', filterCategory);
      }

      final customersData = await custQuery as List<dynamic>;

      // 2. Fetch messaging preferences for business customers
      final prefsData =
          await _safeClient
                  .from('customer_messaging_preferences')
                  .select(
                    'customer_id, whatsapp_opt_in, sms_opt_in, marketing_consent, is_opted_out',
                  )
                  .eq('business_id', businessId)
              as List<dynamic>;

      final prefsMap = <String, Map<String, dynamic>>{};
      for (final p in prefsData) {
        prefsMap[p['customer_id'].toString()] = p as Map<String, dynamic>;
      }

      final eligible = <Map<String, dynamic>>[];

      for (final c in customersData) {
        final cust = c as Map<String, dynamic>;
        final custId = cust['id'].toString();
        final pref = prefsMap[custId];

        final isOptedOut = pref?['is_opted_out'] == true;
        if (isOptedOut) continue; // Always exclude opted out

        if (marketingOnly) {
          // Marketing requires explicit marketing_consent
          final hasMarketingConsent = pref?['marketing_consent'] == true;
          if (!hasMarketingConsent) continue;
        }

        eligible.add({
          'customer_id': custId,
          'customer_name': cust['full_name'],
          'customer_phone': cust['primary_phone'],
          'customer_type': cust['customer_type'] ?? 'residential',
          'whatsapp_opt_in': pref?['whatsapp_opt_in'] ?? true,
          'sms_opt_in': pref?['sms_opt_in'] ?? true,
        });
      }

      return eligible;
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.previewAudience failed',
        e,
        stack,
      );
      return [];
    }
  }

  @override
  Future<List<CommunicationUsage>> getCommunicationUsageSummary(
    String businessId,
  ) async {
    try {
      final data = await _safeClient
          .from('communication_usage')
          .select()
          .eq('business_id', businessId)
          .order('usage_date', ascending: false)
          .limit(30);

      return (data as List<dynamic>)
          .map(
            (item) => CommunicationUsage.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.getCommunicationUsageSummary failed',
        e,
        stack,
      );
      return [];
    }
  }

  @override
  Future<List<ProviderConfiguration>> getProviderConfigurations(
    String businessId,
  ) async {
    try {
      final data = await _safeClient
          .from('provider_configurations')
          .select()
          .eq('business_id', businessId);

      return (data as List<dynamic>)
          .map(
            (item) =>
                ProviderConfiguration.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.getProviderConfigurations failed',
        e,
        stack,
      );
      return [];
    }
  }

  @override
  Future<ProviderConfiguration> saveProviderConfiguration(
    ProviderConfiguration config,
  ) async {
    try {
      final map = config.toJson();
      map.remove('id');
      map['updated_at'] = DateTime.now().toIso8601String();

      final data = await _safeClient
          .from('provider_configurations')
          .upsert(map, onConflict: 'business_id,provider_type')
          .select()
          .single();

      return ProviderConfiguration.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'BulkMessagingRepository.saveProviderConfiguration failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to save provider configuration: $e');
    }
  }
}
