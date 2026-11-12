import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/communication_log.dart';

abstract class ICommunicationRepository {
  Future<List<CommunicationLog>> getCommunicationLogs({
    String? customerId,
    String? channel,
    String? status,
    int limit = 50,
  });

  /// Logs a manual WhatsApp or SMS action opened in the native app.
  /// Status is strictly recorded as 'opened_in_app' (never 'sent' or 'delivered').
  Future<CommunicationLog> logManualCommunication({
    required String businessId,
    String? customerId,
    String? serviceId,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? templateId,
    required String channel,
    required String recipientPhone,
    String? recipientName,
    required String messageBody,
  });

  Future<CommunicationLog> createLog(CommunicationLog log);
  Future<Map<String, int>> getCommunicationStats();
}

class SupabaseCommunicationRepository implements ICommunicationRepository {
  final SupabaseClient? _client;

  SupabaseCommunicationRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<CommunicationLog>> getCommunicationLogs({
    String? customerId,
    String? channel,
    String? status,
    int limit = 50,
  }) async {
    try {
      dynamic query = _safeClient
          .from('communication_logs')
          .select('*, customers(full_name, primary_phone)');

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (channel != null && channel != 'all') {
        query = query.eq('channel', channel);
      }
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List<dynamic>)
          .map(
            (item) => CommunicationLog.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'CommunicationRepository.getCommunicationLogs failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load communication logs: $e');
    }
  }

  @override
  Future<CommunicationLog> logManualCommunication({
    required String businessId,
    String? customerId,
    String? serviceId,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? templateId,
    required String channel,
    required String recipientPhone,
    String? recipientName,
    required String messageBody,
  }) async {
    try {
      final insertData = {
        'business_id': businessId,
        'customer_id': customerId,
        'service_id': serviceId,
        'maintenance_occurrence_id': maintenanceOccurrenceId,
        'amc_contract_id': amcContractId,
        'template_id': templateId,
        'channel': channel,
        'message_type': 'manual',
        'recipient_phone': recipientPhone,
        'recipient_name': recipientName,
        'direction': 'outbound',
        'status':
            'opened_in_app', // Mandatory truthful status for manual actions
        'message_body': messageBody,
        'cost': 0.0,
      };

      final data = await _safeClient
          .from('communication_logs')
          .insert(insertData)
          .select('*, customers(full_name, primary_phone)')
          .single();

      return CommunicationLog.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'CommunicationRepository.logManualCommunication failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to log communication: $e');
    }
  }

  @override
  Future<CommunicationLog> createLog(CommunicationLog log) async {
    try {
      final map = log.toJson();
      map.remove('id');
      map.remove('created_at');
      map.remove('updated_at');

      final data = await _safeClient
          .from('communication_logs')
          .insert(map)
          .select('*, customers(full_name, primary_phone)')
          .single();

      return CommunicationLog.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('CommunicationRepository.createLog failed', e, stack);
      throw AppStorageException('Failed to create communication log: $e');
    }
  }

  @override
  Future<Map<String, int>> getCommunicationStats() async {
    try {
      final logs = await getCommunicationLogs(limit: 100);
      int whatsappCount = 0;
      int smsCount = 0;
      int manualOpenedCount = 0;
      int deliveredCount = 0;

      for (final l in logs) {
        if (l.isWhatsApp) whatsappCount++;
        if (l.isSms) smsCount++;
        if (l.wasOpenedInApp) manualOpenedCount++;
        if (l.isDelivered) deliveredCount++;
      }

      return {
        'total': logs.length,
        'whatsapp': whatsappCount,
        'sms': smsCount,
        'manual_opened': manualOpenedCount,
        'delivered': deliveredCount,
      };
    } catch (e, stack) {
      AppLogger.error(
        'CommunicationRepository.getCommunicationStats failed',
        e,
        stack,
      );
      return {
        'total': 0,
        'whatsapp': 0,
        'sms': 0,
        'manual_opened': 0,
        'delivered': 0,
      };
    }
  }
}
