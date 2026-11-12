import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../models/amc_contract.dart';

/// Aggregated count summary for AMC contract management.
class AmcOverviewCounts {
  final int active;
  final int expiringSoon;
  final int expired;
  final int recentlyRenewed;

  const AmcOverviewCounts({
    this.active = 0,
    this.expiringSoon = 0,
    this.expired = 0,
    this.recentlyRenewed = 0,
  });
}

abstract class IAmcRepository {
  Future<AmcOverviewCounts> getAmcOverviewCounts(String businessId);

  Future<List<AmcContract>> getAmcContracts({
    String? businessId,
    String? customerId,
    String?
    status, // 'all', 'active', 'expiring', 'expired', 'renewed', 'cancelled'
    String? searchQuery,
    int? limit,
  });

  Future<AmcContract?> getAmcContractById(String id);

  Future<List<AmcContract>> getCustomerAmcContracts(String customerId);

  Future<AmcContract> createAmcContract(
    AmcContract contract, {
    int reminderDaysBefore = 15,
  });

  Future<AmcContract> updateAmcContract(AmcContract contract);

  Future<void> cancelAmcContract(String contractId, {String? notes});

  Future<String> renewAmcContract({
    required String previousContractId,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required double contractAmount,
    String? contractTitle,
    String? coverageDetails,
    int? numberOfVisits,
    String? includedServices,
    String? excludedServices,
    String? specialTerms,
    String? notes,
  });
}

class SupabaseAmcRepository implements IAmcRepository {
  final SupabaseClient? _client;

  SupabaseAmcRepository([this._client]);

  SupabaseClient get _safeClient {
    if (_client != null) return _client;
    return Supabase.instance.client;
  }

  static const String _selectWithJoins = '''
    *,
    customers:customer_id(*, customer_addresses(*)),
    equipment:equipment_id(*)
  ''';

  String _formatSqlDate(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<String> _generateContractNumber(String businessId) async {
    try {
      final generated = await _safeClient.rpc(
        'next_amc_contract_number',
        params: {'p_business_id': businessId},
      );
      if (generated != null && generated.toString().trim().isNotEmpty) {
        return generated.toString();
      }
    } catch (e) {
      Logger.warning(
        'next_amc_contract_number RPC unavailable, using client fallback: $e',
      );
    }
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
      6,
    );
    return 'YB-AMC-$suffix';
  }

  Future<void> _ensurePreExpiryReminder(
    AmcContract contract, {
    required int reminderDaysBefore,
  }) async {
    try {
      final days = reminderDaysBefore < 0 ? 0 : reminderDaysBefore;

      // Best-effort schedule record for server/cron awareness
      try {
        await _safeClient.from('amc_reminder_schedules').upsert({
          'business_id': contract.businessId,
          'amc_contract_id': contract.id,
          'days_before_expiry': days,
          'is_enabled': true,
        }, onConflict: 'amc_contract_id,days_before_expiry');
      } catch (schedErr) {
        Logger.warning('Could not upsert amc_reminder_schedules: $schedErr');
      }

      final now = DateTime.now();
      final today9am = DateTime(now.year, now.month, now.day, 9, 0);
      final endDay = DateTime(
        contract.endDate.year,
        contract.endDate.month,
        contract.endDate.day,
      );
      final rawTrigger = endDay.subtract(Duration(days: days));
      final trigger9am = DateTime(
        rawTrigger.year,
        rawTrigger.month,
        rawTrigger.day,
        9,
        0,
      );
      final effectiveDue = trigger9am.isBefore(today9am)
          ? today9am
          : trigger9am;

      final customerName = contract.customer?.fullName ?? 'customer';
      final title = 'AMC Expiry: ${contract.contractTitle}';
      final description =
          'AMC for $customerName ends on ${_formatSqlDate(contract.endDate)}. Follow up $days day(s) prior for renewal.';

      final existing = await _safeClient
          .from('reminders')
          .select('id')
          .eq('amc_contract_id', contract.id)
          .not('status', 'in', '(completed,cancelled)')
          .limit(1);

      if ((existing as List).isNotEmpty) {
        final existingId = existing.first['id'] as String;
        await _safeClient
            .from('reminders')
            .update({
              'title': title,
              'description': description,
              'due_at': effectiveDue.toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', existingId);
      } else {
        await _safeClient.from('reminders').insert({
          'business_id': contract.businessId,
          'customer_id': contract.customerId,
          'amc_contract_id': contract.id,
          'title': title,
          'description': description,
          'reminder_type': 'amc',
          'due_at': effectiveDue.toUtc().toIso8601String(),
          'status': 'scheduled',
        });
      }
    } catch (e) {
      Logger.warning(
        'Could not create pre-expiry reminder for AMC ${contract.id}: $e',
      );
    }
  }

  @override
  Future<AmcOverviewCounts> getAmcOverviewCounts(String businessId) async {
    try {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final todayStr =
          "${todayDate.year.toString().padLeft(4, '0')}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}";
      final in30DaysDate = todayDate.add(const Duration(days: 30));
      final in30DaysStr =
          "${in30DaysDate.year.toString().padLeft(4, '0')}-${in30DaysDate.month.toString().padLeft(2, '0')}-${in30DaysDate.day.toString().padLeft(2, '0')}";

      // 1. Expiring Soon (active contracts ending between today and 30 days ahead)
      final expiringRes = await _safeClient
          .from('amc_contracts')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'active')
          .gte('end_date', todayStr)
          .lte('end_date', in30DaysStr);
      final expiringSoon = (expiringRes as List).length;

      // 2. Active contracts total
      final activeRes = await _safeClient
          .from('amc_contracts')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'active')
          .gte('end_date', todayStr);
      final active = (activeRes as List).length;

      // 3. Expired contracts
      final expiredRes = await _safeClient
          .from('amc_contracts')
          .select('id')
          .eq('business_id', businessId)
          .or('status.eq.expired,and(status.eq.active,end_date.lt.$todayStr)');
      final expired = (expiredRes as List).length;

      // 4. Recently renewed contracts
      final renewedRes = await _safeClient
          .from('amc_contracts')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'renewed');
      final recentlyRenewed = (renewedRes as List).length;

      return AmcOverviewCounts(
        active: active,
        expiringSoon: expiringSoon,
        expired: expired,
        recentlyRenewed: recentlyRenewed,
      );
    } catch (e, stack) {
      Logger.error('Failed to get AMC overview counts: $e', stack);
      return const AmcOverviewCounts();
    }
  }

  @override
  Future<List<AmcContract>> getAmcContracts({
    String? businessId,
    String? customerId,
    String? status,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final todayStr =
          "${todayDate.year.toString().padLeft(4, '0')}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}";
      final in30DaysDate = todayDate.add(const Duration(days: 30));
      final in30DaysStr =
          "${in30DaysDate.year.toString().padLeft(4, '0')}-${in30DaysDate.month.toString().padLeft(2, '0')}-${in30DaysDate.day.toString().padLeft(2, '0')}";

      var query = _safeClient.from('amc_contracts').select(_selectWithJoins);

      if (businessId != null && businessId.isNotEmpty) {
        query = query.eq('business_id', businessId);
      }
      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      final normalizedStatus = status?.toLowerCase().trim();
      if (normalizedStatus == 'expiring') {
        // Expiring in <= 30 days and end_date >= today and status == 'active'
        query = query
            .eq('status', 'active')
            .gte('end_date', todayStr)
            .lte('end_date', in30DaysStr);
      } else if (normalizedStatus == 'expired') {
        query = query.or(
          'status.eq.expired,and(status.eq.active,end_date.lt.$todayStr)',
        );
      } else if (normalizedStatus == 'active') {
        query = query.eq('status', 'active').gte('end_date', todayStr);
      } else if (normalizedStatus != null &&
          normalizedStatus.isNotEmpty &&
          normalizedStatus != 'all') {
        query = query.eq('status', normalizedStatus);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or(
          'contract_number.ilike.%$term%,contract_title.ilike.%$term%',
        );
      }

      dynamic transformQuery = query.order('end_date', ascending: true);

      if (limit != null && limit > 0) {
        transformQuery = transformQuery.limit(limit);
      }

      final response = await transformQuery;
      return (response as List)
          .map((data) => AmcContract.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      Logger.error('Failed to get AMC contracts: $e', stack);
      return [];
    }
  }

  @override
  Future<AmcContract?> getAmcContractById(String id) async {
    try {
      final response = await _safeClient
          .from('amc_contracts')
          .select(_selectWithJoins)
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return AmcContract.fromJson(response);
    } catch (e, stack) {
      Logger.error('Failed to get AMC contract by id ($id): $e', stack);
      return null;
    }
  }

  @override
  Future<List<AmcContract>> getCustomerAmcContracts(String customerId) async {
    return getAmcContracts(customerId: customerId);
  }

  @override
  Future<AmcContract> createAmcContract(
    AmcContract contract, {
    int reminderDaysBefore = 15,
  }) async {
    try {
      String? contractNumber = contract.contractNumber;
      if (contractNumber == null || contractNumber.isEmpty) {
        contractNumber = await _generateContractNumber(contract.businessId);
      }

      final payload = {
        'business_id': contract.businessId,
        'customer_id': contract.customerId,
        'equipment_id': contract.equipmentId,
        'contract_number': contractNumber,
        'contract_title': contract.contractTitle,
        'start_date': _formatSqlDate(contract.startDate),
        'end_date': _formatSqlDate(contract.endDate),
        'contract_amount': contract.contractAmount,
        'number_of_visits': contract.numberOfVisits,
        'included_services': contract.includedServices,
        'excluded_services': contract.excludedServices,
        'special_terms': contract.specialTerms,
        'renewal_terms': contract.renewalTerms,
        'notes': contract.notes,
        'status': contract.status.isEmpty ? 'active' : contract.status,
      };

      final response = await _safeClient
          .from('amc_contracts')
          .insert(payload)
          .select(_selectWithJoins)
          .single();

      final created = AmcContract.fromJson(response);
      await _ensurePreExpiryReminder(
        created,
        reminderDaysBefore: reminderDaysBefore,
      );
      return created;
    } catch (e, stack) {
      Logger.error('Failed to create AMC contract: $e', stack);
      rethrow;
    }
  }

  @override
  Future<AmcContract> updateAmcContract(AmcContract contract) async {
    try {
      final payload = {
        'customer_id': contract.customerId,
        'equipment_id': contract.equipmentId,
        'contract_title': contract.contractTitle,
        'start_date': _formatSqlDate(contract.startDate),
        'end_date': _formatSqlDate(contract.endDate),
        'contract_amount': contract.contractAmount,
        'number_of_visits': contract.numberOfVisits,
        'included_services': contract.includedServices,
        'excluded_services': contract.excludedServices,
        'special_terms': contract.specialTerms,
        'renewal_terms': contract.renewalTerms,
        'notes': contract.notes,
        'status': contract.status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _safeClient
          .from('amc_contracts')
          .update(payload)
          .eq('id', contract.id)
          .select(_selectWithJoins)
          .single();

      return AmcContract.fromJson(response);
    } catch (e, stack) {
      Logger.error('Failed to update AMC contract (${contract.id}): $e', stack);
      rethrow;
    }
  }

  @override
  Future<void> cancelAmcContract(String contractId, {String? notes}) async {
    try {
      final payload = <String, dynamic>{
        'status': 'cancelled',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (notes != null && notes.isNotEmpty) {
        payload['notes'] = notes;
      }

      await _safeClient
          .from('amc_contracts')
          .update(payload)
          .eq('id', contractId);
    } catch (e, stack) {
      Logger.error('Failed to cancel AMC contract ($contractId): $e', stack);
      rethrow;
    }
  }

  @override
  Future<String> renewAmcContract({
    required String previousContractId,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required double contractAmount,
    String? contractTitle,
    String? coverageDetails,
    int? numberOfVisits,
    String? includedServices,
    String? excludedServices,
    String? specialTerms,
    String? notes,
  }) async {
    try {
      try {
        final res = await _safeClient.rpc(
          'renew_amc_contract',
          params: {
            'p_previous_contract_id': previousContractId,
            'p_new_start_date': _formatSqlDate(newStartDate),
            'p_new_end_date': _formatSqlDate(newEndDate),
            'p_contract_amount': contractAmount,
            'p_contract_title': contractTitle,
            'p_coverage_details': coverageDetails,
            'p_number_of_visits': numberOfVisits,
            'p_included_services': includedServices,
            'p_excluded_services': excludedServices,
            'p_special_terms': specialTerms,
            'p_notes': notes,
          },
        );
        final newId = res.toString();
        final renewedContract = await getAmcContractById(newId);
        if (renewedContract != null) {
          await _ensurePreExpiryReminder(
            renewedContract,
            reminderDaysBefore: 15,
          );
        }
        return newId;
      } catch (rpcErr) {
        Logger.warning(
          'renew_amc_contract RPC unavailable, using client fallback: $rpcErr',
        );
      }

      // Fallback when RPC is not yet deployed on Postgres
      final prev = await getAmcContractById(previousContractId);
      if (prev == null) {
        throw Exception('Previous AMC contract not found.');
      }

      await _safeClient
          .from('amc_contracts')
          .update({
            'status': 'renewed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', previousContractId);

      try {
        await _safeClient
            .from('reminders')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('amc_contract_id', previousContractId)
            .not('status', 'in', '(completed,cancelled)');
      } catch (_) {}

      final newNumber = await _generateContractNumber(prev.businessId);
      final inserted = await _safeClient
          .from('amc_contracts')
          .insert({
            'business_id': prev.businessId,
            'customer_id': prev.customerId,
            'equipment_id': prev.equipmentId,
            'contract_number': newNumber,
            'contract_title':
                (contractTitle != null && contractTitle.trim().isNotEmpty)
                ? contractTitle.trim()
                : prev.contractTitle,
            'start_date': _formatSqlDate(newStartDate),
            'end_date': _formatSqlDate(newEndDate),
            'contract_amount': contractAmount,
            'coverage_details': coverageDetails ?? prev.coverageDetails,
            'number_of_visits': numberOfVisits ?? prev.numberOfVisits,
            'included_services': includedServices ?? prev.includedServices,
            'excluded_services': excludedServices ?? prev.excludedServices,
            'special_terms': specialTerms ?? prev.specialTerms,
            'renewal_terms': prev.renewalTerms,
            'notes': notes ?? prev.notes,
            'status': 'active',
            'renewed_from_contract_id': previousContractId,
          })
          .select(_selectWithJoins)
          .single();

      final created = AmcContract.fromJson(inserted);
      await _ensurePreExpiryReminder(created, reminderDaysBefore: 15);
      return created.id;
    } catch (e, stack) {
      Logger.error(
        'Failed to renew AMC contract ($previousContractId): $e',
        stack,
      );
      rethrow;
    }
  }
}
