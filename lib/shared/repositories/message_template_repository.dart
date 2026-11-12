import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/message_template.dart';

abstract class IMessageTemplateRepository {
  Future<List<MessageTemplate>> getTemplates({
    String? category,
    String? channel,
    String? language,
  });
  Future<MessageTemplate?> getTemplateById(String id);
  Future<MessageTemplate> createTemplate(MessageTemplate template);
  Future<MessageTemplate> updateTemplate(MessageTemplate template);
  Future<void> deleteTemplate(String id);
  Future<void> seedDefaultTemplatesIfEmpty(String businessId);
}

class SupabaseMessageTemplateRepository implements IMessageTemplateRepository {
  final SupabaseClient? _client;

  SupabaseMessageTemplateRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<MessageTemplate>> getTemplates({
    String? category,
    String? channel,
    String? language,
  }) async {
    try {
      dynamic query = _safeClient.from('message_templates').select();

      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }
      if (channel != null && channel != 'all') {
        query = query.or('channel.eq.$channel,channel.eq.both');
      }
      if (language != null && language != 'all') {
        query = query.eq('language', language);
      }

      final data = await query.order('created_at', ascending: true);
      return (data as List<dynamic>)
          .map((item) => MessageTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'MessageTemplateRepository.getTemplates failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load message templates: $e');
    }
  }

  @override
  Future<MessageTemplate?> getTemplateById(String id) async {
    try {
      final data = await _safeClient
          .from('message_templates')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return MessageTemplate.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'MessageTemplateRepository.getTemplateById failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load message template: $e');
    }
  }

  @override
  Future<MessageTemplate> createTemplate(MessageTemplate template) async {
    try {
      final map = template.toJson();
      map.remove('id');
      map.remove('created_at');
      map.remove('updated_at');

      final data = await _safeClient
          .from('message_templates')
          .insert(map)
          .select()
          .single();

      return MessageTemplate.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'MessageTemplateRepository.createTemplate failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to create message template: $e');
    }
  }

  @override
  Future<MessageTemplate> updateTemplate(MessageTemplate template) async {
    try {
      final map = template.toJson();
      map.remove('created_at');
      map['updated_at'] = DateTime.now().toIso8601String();

      final data = await _safeClient
          .from('message_templates')
          .update(map)
          .eq('id', template.id)
          .select()
          .single();

      return MessageTemplate.fromJson(data);
    } catch (e, stack) {
      AppLogger.error(
        'MessageTemplateRepository.updateTemplate failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to update message template: $e');
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    try {
      await _safeClient.from('message_templates').delete().eq('id', id);
    } catch (e, stack) {
      AppLogger.error(
        'MessageTemplateRepository.deleteTemplate failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to delete message template: $e');
    }
  }

  @override
  Future<void> seedDefaultTemplatesIfEmpty(String businessId) async {
    try {
      final existing = await _safeClient
          .from('message_templates')
          .select('id')
          .eq('business_id', businessId)
          .limit(1);

      if ((existing as List<dynamic>).isNotEmpty) return;

      final defaultTemplates = [
        // 1. Service Update - English
        {
          'business_id': businessId,
          'name': 'Service Status Update (English)',
          'category': 'service_update',
          'channel': 'both',
          'language': 'en',
          'content':
              'Hello {{customer_name}}, this is {{business_name}}. Update on your service {{service_title}} (Ref: {{service_reference}}): Status is now {{service_status}}. For questions, contact {{business_phone}}.',
          'variables': [
            'customer_name',
            'business_name',
            'service_title',
            'service_reference',
            'service_status',
            'business_phone',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
        // 2. Service Update - Gujarati
        {
          'business_id': businessId,
          'name': 'સર્વિસ અપડેટ (Gujarati)',
          'category': 'service_update',
          'channel': 'both',
          'language': 'gu',
          'content':
              'નમસ્તે {{customer_name}}, {{business_name}} તરફથી. આપની સર્વિસ {{service_title}} (નંબર: {{service_reference}}) નું સ્ટેટસ {{service_status}} છે. વધુ માહિતી માટે સંપર્ક કરો: {{business_phone}}.',
          'variables': [
            'customer_name',
            'business_name',
            'service_title',
            'service_reference',
            'service_status',
            'business_phone',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
        // 3. Service Update - Hindi
        {
          'business_id': businessId,
          'name': 'सेवा स्थिति अपडेट (Hindi)',
          'category': 'service_update',
          'channel': 'both',
          'language': 'hi',
          'content':
              'नमस्ते {{customer_name}}, {{business_name}} से सूचना. आपकी सेवा {{service_title}} (संदर्भ: {{service_reference}}) की स्थिति अब {{service_status}} है. संपर्क करें: {{business_phone}}.',
          'variables': [
            'customer_name',
            'business_name',
            'service_title',
            'service_reference',
            'service_status',
            'business_phone',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
        // 4. AMC Renewal - English
        {
          'business_id': businessId,
          'name': 'AMC Renewal Notice (English)',
          'category': 'amc_renewal',
          'channel': 'both',
          'language': 'en',
          'content':
              'Dear {{customer_name}}, your AMC contract with {{business_name}} expires on {{amc_end_date}}. Renew today to ensure uninterrupted service and support. Call {{business_phone}}.',
          'variables': [
            'customer_name',
            'business_name',
            'amc_end_date',
            'business_phone',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
        // 5. AMC Renewal - Gujarati
        {
          'business_id': businessId,
          'name': 'AMC રીન્યુઅલ નોટિસ (Gujarati)',
          'category': 'amc_renewal',
          'channel': 'both',
          'language': 'gu',
          'content':
              'આદરણીય {{customer_name}}, {{business_name}} સાથે આપનો AMC કરાર {{amc_end_date}} ના રોજ પૂર્ણ થાય છે. અવિરત સેવા માટે રિન્યુ કરાવો. સંપર્ક: {{business_phone}}.',
          'variables': [
            'customer_name',
            'business_name',
            'amc_end_date',
            'business_phone',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
        // 6. Maintenance Visit - English
        {
          'business_id': businessId,
          'name': 'Maintenance Reminder (English)',
          'category': 'maintenance_reminder',
          'channel': 'both',
          'language': 'en',
          'content':
              'Hello {{customer_name}}, your scheduled maintenance visit is due on {{maintenance_date}}. Our technician will visit as planned. Regards, {{business_name}} ({{business_phone}}).',
          'variables': [
            'customer_name',
            'maintenance_date',
            'business_name',
            'business_phone',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
        // 7. Payment Follow-up - English
        {
          'business_id': businessId,
          'name': 'Payment Reminder (English)',
          'category': 'payment_reminder',
          'channel': 'both',
          'language': 'en',
          'content':
              'Dear {{customer_name}}, a pending payment of ₹{{amount}} is due for service {{service_reference}}. Kindly settle at your earliest convenience. Thank you, {{business_name}}.',
          'variables': [
            'customer_name',
            'amount',
            'service_reference',
            'business_name',
          ],
          'is_system_default': true,
          'provider_status': 'approved',
        },
      ];

      await _safeClient.from('message_templates').insert(defaultTemplates);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to seed default message templates: $e',
        e,
        stack,
      );
    }
  }
}
