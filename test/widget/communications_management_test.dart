import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/features/bulk_messaging/presentation/campaigns_screen.dart';
import 'package:yaadibook/features/communications/presentation/communication_overview_screen.dart';
import 'package:yaadibook/features/communications/providers/communication_providers.dart';
import 'package:yaadibook/features/message_templates/presentation/message_templates_screen.dart';
import 'package:yaadibook/shared/models/communication_campaign.dart';
import 'package:yaadibook/shared/models/communication_log.dart';
import 'package:yaadibook/shared/models/message_template.dart';
import 'package:yaadibook/features/subscriptions/providers/subscription_providers.dart';

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('gu', ''),
        Locale('hi', ''),
      ],
      home: child,
    ),
  );
}

void main() {
  group('Communications Overview Widget Tests', () {
    testWidgets('renders metric summary cards and navigation hub', (
      tester,
    ) async {
      final mockLogs = [
        CommunicationLog(
          id: 'log-1',
          businessId: 'biz-1',
          recipientPhone: '9825012345',
          recipientName: 'Kishore Kumar',
          channel: 'whatsapp',
          status: 'opened_in_app',
          messageBody: 'Hello, your CCTV service is completed.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final mockStats = {
        'total': 12,
        'whatsapp': 8,
        'sms': 4,
        'manual_opened': 7,
        'delivered': 5,
      };

      await tester.pumpWidget(
        _buildTestApp(
          child: const CommunicationOverviewScreen(),
          overrides: [
            communicationStatsProvider.overrideWith((ref) => mockStats),
            communicationLogsProvider.overrideWith((ref) => mockLogs),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Communications'), findsOneWidget);

      // Verify Metrics Header values
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Verify Navigation Hub Cards
      expect(find.text('Message Templates'), findsOneWidget);
      expect(find.text('Bulk Campaigns'), findsOneWidget);

      // Verify Filter Chips & Header Labels
      expect(find.text('All'), findsOneWidget);
      expect(find.text('WhatsApp'), findsWidgets);
      expect(find.text('SMS'), findsWidgets);

      // Verify Log Entry
      expect(find.text('Kishore Kumar'), findsOneWidget);
      expect(find.text('Opened in App'), findsOneWidget);
    });
  });

  group('Message Templates Widget Tests', () {
    testWidgets(
      'renders templates screen with category chips and template cards',
      (tester) async {
        final mockTemplates = [
          MessageTemplate(
            id: 'tpl-1',
            businessId: 'biz-1',
            name: 'Service Update Notice',
            category: 'service_update',
            channel: 'both',
            language: 'en',
            content:
                'Hello {{customer_name}}, service {{service_reference}} is completed.',
            variables: const ['customer_name', 'service_reference'],
            providerStatus: 'approved',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            child: const MessageTemplatesScreen(),
            overrides: [
              messageTemplatesProvider.overrideWith((ref) => mockTemplates),
            ],
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Message Templates'), findsOneWidget);
        expect(find.text('Service Update Notice'), findsOneWidget);
        expect(find.text('{{customer_name}}'), findsOneWidget);
        expect(find.text('Approved'), findsOneWidget);
        expect(find.text('Use Template'), findsOneWidget);
      },
    );
  });

  group('Campaigns Screen Widget Tests', () {
    testWidgets('renders entitlement banner and campaign cards', (
      tester,
    ) async {
      final mockCampaigns = [
        CommunicationCampaign(
          id: 'cmp-1',
          businessId: 'biz-1',
          title: 'Diwali Annual Service Offer',
          channel: 'whatsapp',
          status: 'completed',
          totalRecipients: 45,
          successfulCount: 45,
          failedCount: 0,
          estimatedCostInr: 38.25,
          actualCostInr: 38.25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: const CampaignsScreen(),
          overrides: [
            campaignsListProvider.overrideWith((ref) => mockCampaigns),
            isBulkMessagingEntitledProvider.overrideWith((ref) => true),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bulk Campaigns'), findsOneWidget);
      expect(find.text('Bulk Messaging Entitlement Active'), findsOneWidget);
      expect(find.text('Diwali Annual Service Offer'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('45/45 Sent'), findsOneWidget);
    });
  });
}
