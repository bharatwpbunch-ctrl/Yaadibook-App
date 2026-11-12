import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/services/communication_service.dart';
import 'package:yaadibook/shared/models/communication_campaign.dart';
import 'package:yaadibook/shared/models/communication_log.dart';
import 'package:yaadibook/shared/models/communication_usage.dart';
import 'package:yaadibook/shared/models/customer_messaging_preference.dart';
import 'package:yaadibook/shared/models/message_template.dart';
import 'package:yaadibook/shared/models/provider_configuration.dart';

void main() {
  group('CommunicationService Utility Tests', () {
    test('normalizes Indian phone numbers with various formats', () {
      expect(
        CommunicationService.normalizePhoneNumber('+91 98250 12345'),
        '9825012345',
      );
      expect(
        CommunicationService.normalizePhoneNumber('098250-12345'),
        '9825012345',
      );
      expect(
        CommunicationService.normalizePhoneNumber('919825012345'),
        '9825012345',
      );
      expect(
        CommunicationService.normalizePhoneNumber('9825012345'),
        '9825012345',
      );
    });

    test('formats phone number for WhatsApp with 91 prefix', () {
      expect(
        CommunicationService.formatForWhatsApp('9825012345'),
        '919825012345',
      );
      expect(
        CommunicationService.formatForWhatsApp('+91 98250 12345'),
        '919825012345',
      );
    });

    test('extracts placeholder variables correctly from template', () {
      const template =
          'Hello {{customer_name}}, your service {{service_title}} with {{business_name}} is ready. Call {{business_phone}}.';
      final vars = CommunicationService.extractVariables(template);
      expect(
        vars,
        containsAll([
          'customer_name',
          'service_title',
          'business_name',
          'business_phone',
        ]),
      );
      expect(vars.length, 4);
    });

    test('replaces variables accurately', () {
      const template = 'Hello {{customer_name}}, amount due is ₹{{amount}}.';
      final rendered = CommunicationService.replaceVariables(template, {
        'customer_name': 'Aarav Patel',
        'amount': '1,500',
      });
      expect(rendered, 'Hello Aarav Patel, amount due is ₹1,500.');
    });
  });

  group('CommunicationLog Model Tests', () {
    test('enforces truthful opened_in_app status for manual actions', () {
      final log = CommunicationLog(
        id: 'log-1',
        businessId: 'biz-1',
        channel: 'whatsapp',
        messageType: 'manual',
        recipientPhone: '9825012345',
        status: 'opened_in_app',
        messageBody: 'Hello world',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(log.isManual, isTrue);
      expect(log.wasOpenedInApp, isTrue);
      expect(log.isDelivered, isFalse);
    });

    test('serializes and deserializes accurately', () {
      final now = DateTime.now();
      final log = CommunicationLog(
        id: 'log-2',
        businessId: 'biz-1',
        customerId: 'cust-1',
        recipientPhone: '9825012345',
        recipientName: 'Rahul Shah',
        channel: 'sms',
        messageType: 'cloud_api',
        status: 'delivered',
        messageBody: 'Payment received',
        cost: 0.20,
        createdAt: now,
        updatedAt: now,
      );

      final json = log.toJson();
      final fromJson = CommunicationLog.fromJson(json);

      expect(fromJson.id, log.id);
      expect(fromJson.recipientName, 'Rahul Shah');
      expect(fromJson.channel, 'sms');
      expect(fromJson.isDelivered, isTrue);
      expect(fromJson.cost, 0.20);
    });
  });

  group('MessageTemplate Model Tests', () {
    test('renders variables with instance render method', () {
      final template = MessageTemplate(
        id: 'tpl-1',
        businessId: 'biz-1',
        name: 'Service Update',
        category: 'service_update',
        content:
            'Hi {{customer_name}}, your service {{service_reference}} is {{service_status}}.',
        variables: const [
          'customer_name',
          'service_reference',
          'service_status',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rendered = template.render({
        'customer_name': 'Pooja',
        'service_reference': 'SRV-102',
        'service_status': 'Completed',
      });

      expect(rendered, 'Hi Pooja, your service SRV-102 is Completed.');
    });
  });

  group('CustomerMessagingPreference Model Tests', () {
    test('calculates consent permissions correctly', () {
      final now = DateTime.now();
      final activePref = CustomerMessagingPreference(
        id: 'pref-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        whatsappOptIn: true,
        smsOptIn: true,
        marketingConsent: false,
        isOptedOut: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(activePref.canReceiveTransactionalWhatsApp, isTrue);
      expect(activePref.canReceiveTransactionalSms, isTrue);
      expect(activePref.canReceiveMarketing, isFalse);

      final optedOut = activePref.copyWith(isOptedOut: true);
      expect(optedOut.canReceiveTransactionalWhatsApp, isFalse);
      expect(optedOut.canReceiveMarketing, isFalse);
    });
  });

  group('CommunicationCampaign & Usage Model Tests', () {
    test('calculates campaign progress percentage accurately', () {
      final campaign = CommunicationCampaign(
        id: 'cmp-1',
        businessId: 'biz-1',
        title: 'Festival Offer',
        channel: 'whatsapp',
        totalRecipients: 100,
        successfulCount: 80,
        failedCount: 20,
        estimatedCostInr: 85.0,
        actualCostInr: 85.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(campaign.progress, 1.0);
      expect(campaign.isCompleted, isFalse); // status is still draft by default
    });

    test('serializes communication usage record', () {
      final usage = CommunicationUsage(
        id: 'usg-1',
        businessId: 'biz-1',
        channel: 'whatsapp',
        category: 'marketing',
        messageCount: 50,
        totalCostInr: 42.50,
        usageDate: DateTime(2026, 11, 6),
      );

      final json = usage.toJson();
      expect(json['message_count'], 50);
      expect(json['total_cost_inr'], 42.50);
      expect(json['usage_date'], '2026-11-06');
    });

    test('validates provider configuration model', () {
      final config = ProviderConfiguration(
        id: 'cfg-1',
        businessId: 'biz-1',
        providerType: 'whatsapp_cloud_api',
        phoneNumberId: '1029384756',
        connectionStatus: 'connected',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(config.isConnected, isTrue);
      expect(config.isWhatsApp, isTrue);
      expect(config.isSms, isFalse);
    });
  });
}
