import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/communication_service.dart';
import '../../../shared/models/communication_campaign.dart';
import '../../../shared/models/communication_log.dart';
import '../../../shared/models/communication_usage.dart';
import '../../../shared/models/customer_messaging_preference.dart';
import '../../../shared/models/message_template.dart';
import '../../../shared/models/provider_configuration.dart';
import '../../../shared/providers/backend_providers.dart';

// --- Filter Providers ---
final commChannelFilterProvider = StateProvider<String>(
  (ref) => 'all',
); // 'all', 'whatsapp', 'sms'
final commStatusFilterProvider = StateProvider<String>(
  (ref) => 'all',
); // 'all', 'opened_in_app', 'submitted', 'delivered', 'failed'
final templateCategoryFilterProvider = StateProvider<String>((ref) => 'all');
final templateLanguageFilterProvider = StateProvider<String>((ref) => 'all');

// --- Communications Data Providers ---
final communicationLogsProvider = FutureProvider<List<CommunicationLog>>((
  ref,
) async {
  final repo = ref.watch(communicationRepositoryProvider);
  final channel = ref.watch(commChannelFilterProvider);
  final status = ref.watch(commStatusFilterProvider);

  return repo.getCommunicationLogs(
    channel: channel == 'all' ? null : channel,
    status: status == 'all' ? null : status,
    limit: 50,
  );
});

final customerCommunicationLogsProvider =
    FutureProvider.family<List<CommunicationLog>, String>((
      ref,
      customerId,
    ) async {
      final repo = ref.watch(communicationRepositoryProvider);
      return repo.getCommunicationLogs(customerId: customerId, limit: 30);
    });

final communicationStatsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getCommunicationStats();
});

// --- Templates Data Providers ---
final messageTemplatesProvider = FutureProvider<List<MessageTemplate>>((
  ref,
) async {
  final repo = ref.watch(messageTemplateRepositoryProvider);
  final category = ref.watch(templateCategoryFilterProvider);
  final language = ref.watch(templateLanguageFilterProvider);

  // Auto-seed defaults for active business if empty
  final business = ref.watch(currentBusinessProvider).valueOrNull;
  if (business != null) {
    await repo.seedDefaultTemplatesIfEmpty(business.id);
  }

  return repo.getTemplates(
    category: category == 'all' ? null : category,
    language: language == 'all' ? null : language,
  );
});

final templateDetailProvider = FutureProvider.family<MessageTemplate?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(messageTemplateRepositoryProvider);
  return repo.getTemplateById(id);
});

// --- Customer Consent Provider ---
final customerConsentProvider =
    FutureProvider.family<CustomerMessagingPreference, String>((
      ref,
      customerId,
    ) async {
      final repo = ref.watch(consentRepositoryProvider);
      final business = ref.watch(currentBusinessProvider).valueOrNull;
      final businessId = business?.id ?? '';
      return repo.getPreference(customerId, businessId);
    });

// --- Campaigns Data Providers ---
final campaignsListProvider = FutureProvider<List<CommunicationCampaign>>((
  ref,
) async {
  final repo = ref.watch(bulkMessagingRepositoryProvider);
  return repo.getCampaigns();
});

final campaignDetailProvider =
    FutureProvider.family<CommunicationCampaign?, String>((ref, id) async {
      final repo = ref.watch(bulkMessagingRepositoryProvider);
      return repo.getCampaignById(id);
    });

final campaignRecipientsProvider =
    FutureProvider.family<List<CampaignRecipient>, String>((
      ref,
      campaignId,
    ) async {
      final repo = ref.watch(bulkMessagingRepositoryProvider);
      return repo.getCampaignRecipients(campaignId);
    });

final communicationUsageSummaryProvider =
    FutureProvider<List<CommunicationUsage>>((ref) async {
      final repo = ref.watch(bulkMessagingRepositoryProvider);
      final business = ref.watch(currentBusinessProvider).valueOrNull;
      if (business == null) return [];
      return repo.getCommunicationUsageSummary(business.id);
    });

final providerConfigurationsListProvider =
    FutureProvider<List<ProviderConfiguration>>((ref) async {
      final repo = ref.watch(bulkMessagingRepositoryProvider);
      final business = ref.watch(currentBusinessProvider).valueOrNull;
      if (business == null) return [];
      return repo.getProviderConfigurations(business.id);
    });

// --- Audience Preview Provider for Campaign Wizard ---
final audiencePreviewProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      filterCategory,
    ) async {
      final repo = ref.watch(bulkMessagingRepositoryProvider);
      final business = ref.watch(currentBusinessProvider).valueOrNull;
      if (business == null) return [];
      return repo.previewAudience(
        businessId: business.id,
        filterCategory: filterCategory,
        marketingOnly: true,
      );
    });

// --- Action Controllers ---

class CommunicationComposerController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CommunicationComposerController(this._ref)
    : super(const AsyncValue.data(null));

  /// Builds a clean pre-filled reminder message when no custom template is matched yet.
  static String buildDefaultReminderMessage({
    required String category,
    required String customerName,
    String? businessName,
    String? businessPhone,
    String? title,
    String? maintenanceDate,
    String? amcEndDate,
    String? amount,
  }) {
    final cust = customerName.trim().isNotEmpty
        ? customerName.trim()
        : 'Valued Customer';
    final biz = (businessName != null && businessName.trim().isNotEmpty)
        ? businessName.trim()
        : 'our service team';
    final contact = (businessPhone != null && businessPhone.trim().isNotEmpty)
        ? ' Contact: $businessPhone'
        : '';

    if (category == 'amc_renewal') {
      final contractPart = (title != null && title.trim().isNotEmpty)
          ? ' ($title)'
          : '';
      final datePart = amcEndDate ?? 'soon';
      final amountPart =
          (amount != null && amount.trim().isNotEmpty && amount != '0')
          ? ' (Renewal Amount: Rs. $amount)'
          : '';
      return 'Hello $cust, your Annual Maintenance Contract$contractPart with $biz is due to end on $datePart$amountPart. Please reply to renew for uninterrupted service support.$contact';
    }

    if (category == 'maintenance_reminder') {
      final planPart = (title != null && title.trim().isNotEmpty)
          ? ' for $title'
          : '';
      final datePart = maintenanceDate ?? 'soon';
      return 'Hello $cust, friendly reminder from $biz that your scheduled maintenance visit$planPart is due on $datePart. Let us know a convenient time slot.$contact';
    }

    return 'Hello $cust, thank you for choosing $biz.$contact';
  }

  /// Sends a 1-click reminder via WhatsApp (or SMS) using the matching category template or fallback text.
  Future<bool> sendOneClickReminder({
    required String category,
    required String recipientPhone,
    required String recipientName,
    String? customerId,
    String? maintenanceOccurrenceId,
    String? maintenanceDate,
    String? amcContractId,
    String? amcEndDate,
    String? title,
    String? amount,
    String channel = 'whatsapp',
  }) async {
    final business = _ref.read(currentBusinessProvider).valueOrNull;
    final businessId = business?.id ?? '';

    MessageTemplate? matchedTemplate;
    try {
      final templates = await _ref.read(messageTemplatesProvider.future);
      for (final t in templates) {
        if (t.category == category) {
          matchedTemplate = t;
          break;
        }
      }
    } catch (_) {
      // Fallback below handles empty/unavailable templates gracefully
    }

    final variableData = <String, dynamic>{
      'customer_name': recipientName.trim().isNotEmpty
          ? recipientName.trim()
          : 'Valued Customer',
      'business_name': business?.businessName ?? 'Yaadibook Service',
      'business_phone': business?.phone ?? '',
      'service_title': title ?? 'Service Work',
      'service_status': 'Scheduled',
      'maintenance_date': maintenanceDate ?? 'Upcoming',
      'amc_end_date': amcEndDate ?? 'Soon',
      'amount': amount ?? '0',
    };

    final messageBody = matchedTemplate != null
        ? matchedTemplate.render(variableData)
        : buildDefaultReminderMessage(
            category: category,
            customerName: recipientName,
            businessName: business?.businessName,
            businessPhone: business?.phone,
            title: title,
            maintenanceDate: maintenanceDate,
            amcEndDate: amcEndDate,
            amount: amount,
          );

    if (channel == 'sms') {
      return sendOrOpenSms(
        businessId: businessId,
        customerId: customerId,
        maintenanceOccurrenceId: maintenanceOccurrenceId,
        amcContractId: amcContractId,
        templateId: matchedTemplate?.id,
        recipientPhone: recipientPhone,
        recipientName: recipientName,
        messageBody: messageBody,
      );
    }

    return sendOrOpenWhatsApp(
      businessId: businessId,
      customerId: customerId,
      maintenanceOccurrenceId: maintenanceOccurrenceId,
      amcContractId: amcContractId,
      templateId: matchedTemplate?.id,
      recipientPhone: recipientPhone,
      recipientName: recipientName,
      messageBody: messageBody,
    );
  }

  /// Dispatches or opens WhatsApp prefilled with message and logs action truthfully as 'opened_in_app'.
  Future<bool> sendOrOpenWhatsApp({
    required String businessId,
    String? customerId,
    String? serviceId,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? templateId,
    required String recipientPhone,
    String? recipientName,
    required String messageBody,
  }) async {
    state = const AsyncValue.loading();
    try {
      final success = await CommunicationService.openWhatsApp(
        phoneNumber: recipientPhone,
        message: messageBody,
      );

      if (success) {
        final commRepo = _ref.read(communicationRepositoryProvider);
        await commRepo.logManualCommunication(
          businessId: businessId,
          customerId: customerId,
          serviceId: serviceId,
          maintenanceOccurrenceId: maintenanceOccurrenceId,
          amcContractId: amcContractId,
          templateId: templateId,
          channel: 'whatsapp',
          recipientPhone: recipientPhone,
          recipientName: recipientName,
          messageBody: messageBody,
        );

        _ref.invalidate(communicationLogsProvider);
        _ref.invalidate(communicationStatsProvider);
        if (customerId != null) {
          _ref.invalidate(customerCommunicationLogsProvider(customerId));
        }
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Dispatches or opens native SMS prefilled and logs action truthfully as 'opened_in_app'.
  Future<bool> sendOrOpenSms({
    required String businessId,
    String? customerId,
    String? serviceId,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? templateId,
    required String recipientPhone,
    String? recipientName,
    required String messageBody,
  }) async {
    state = const AsyncValue.loading();
    try {
      final success = await CommunicationService.openSms(
        phoneNumber: recipientPhone,
        message: messageBody,
      );

      if (success) {
        final commRepo = _ref.read(communicationRepositoryProvider);
        await commRepo.logManualCommunication(
          businessId: businessId,
          customerId: customerId,
          serviceId: serviceId,
          maintenanceOccurrenceId: maintenanceOccurrenceId,
          amcContractId: amcContractId,
          templateId: templateId,
          channel: 'sms',
          recipientPhone: recipientPhone,
          recipientName: recipientName,
          messageBody: messageBody,
        );

        _ref.invalidate(communicationLogsProvider);
        _ref.invalidate(communicationStatsProvider);
        if (customerId != null) {
          _ref.invalidate(customerCommunicationLogsProvider(customerId));
        }
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final communicationComposerControllerProvider =
    StateNotifierProvider<CommunicationComposerController, AsyncValue<void>>((
      ref,
    ) {
      return CommunicationComposerController(ref);
    });

// --- Customer Consent Controller ---
class CustomerConsentController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CustomerConsentController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateConsent({
    required CustomerMessagingPreference preference,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(consentRepositoryProvider);
      await repo.updatePreference(preference);
      _ref.invalidate(customerConsentProvider(preference.customerId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> recordOptOut({
    required String customerId,
    required String businessId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(consentRepositoryProvider);
      await repo.recordOptOut(
        customerId: customerId,
        businessId: businessId,
        reason: reason,
      );
      _ref.invalidate(customerConsentProvider(customerId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final customerConsentControllerProvider =
    StateNotifierProvider<CustomerConsentController, AsyncValue<void>>((ref) {
      return CustomerConsentController(ref);
    });
