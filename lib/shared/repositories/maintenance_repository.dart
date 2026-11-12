import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../models/maintenance_occurrence.dart';
import '../models/maintenance_plan.dart';

/// Aggregated count summary for maintenance operations.
class MaintenanceOverviewCounts {
  final int dueToday;
  final int overdue;
  final int upcoming;
  final int activePlans;

  const MaintenanceOverviewCounts({
    this.dueToday = 0,
    this.overdue = 0,
    this.upcoming = 0,
    this.activePlans = 0,
  });
}

abstract class IMaintenanceRepository {
  Future<MaintenanceOverviewCounts> getMaintenanceOverviewCounts(
    String businessId,
  );

  Future<List<MaintenanceOccurrence>> getMaintenanceOccurrences({
    String? businessId,
    String? customerId,
    String? planId,
    String? filter, // 'all', 'today', 'overdue', 'upcoming', 'completed'
    int? limit,
  });

  Future<MaintenanceOccurrence?> getMaintenanceOccurrenceById(String id);

  Future<List<MaintenancePlan>> getMaintenancePlans({
    String? businessId,
    String? customerId,
    String? status, // 'all', 'active', 'paused', 'completed', 'cancelled'
    String? searchQuery,
    int? limit,
  });

  Future<MaintenancePlan?> getMaintenancePlanById(String id);

  Future<List<MaintenanceOccurrence>> getCustomerMaintenanceHistory(
    String customerId,
  );

  Future<MaintenancePlan> createMaintenancePlan(MaintenancePlan plan);

  Future<MaintenancePlan> updateMaintenancePlan(MaintenancePlan plan);

  Future<void> updatePlanStatus(String planId, String newStatus);

  Future<Map<String, dynamic>> completeOccurrence({
    required String occurrenceId,
    required DateTime completionDate,
    String? workPerformed,
    String? notes,
    double? amount,
    String? serviceEntryId,
  });

  Future<Map<String, dynamic>> skipOccurrence({
    required String occurrenceId,
    String? reason,
  });

  Future<void> rescheduleOccurrence({
    required String occurrenceId,
    required DateTime newDueDate,
  });
}

class SupabaseMaintenanceRepository implements IMaintenanceRepository {
  final SupabaseClient? _client;

  SupabaseMaintenanceRepository([this._client]);

  SupabaseClient get _safeClient {
    if (_client != null) return _client;
    return Supabase.instance.client;
  }

  String _formatSqlDate(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<String> _generatePlanNumber(String businessId) async {
    try {
      final generated = await _safeClient.rpc(
        'next_maintenance_plan_number',
        params: {'p_business_id': businessId},
      );
      if (generated != null && generated.toString().trim().isNotEmpty) {
        return generated.toString();
      }
    } catch (e) {
      AppLogger.warning(
        'next_maintenance_plan_number RPC unavailable, using fallback: $e',
      );
    }
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
      6,
    );
    return 'YB-MP-$suffix';
  }

  DateTime _addMonthsAnchored(DateTime base, int months, int anchorDay) {
    final targetTotalMonths = base.year * 12 + (base.month - 1) + months;
    final targetYear = targetTotalMonths ~/ 12;
    final targetMonth = (targetTotalMonths % 12) + 1;
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = anchorDay.clamp(1, lastDayOfMonth);
    return DateTime(targetYear, targetMonth, day);
  }

  DateTime _computeNextDueDate(
    DateTime currentDue,
    String frequencyType,
    int intervalValue,
    String intervalUnit, {
    int? anchorDay,
  }) {
    final anchor = anchorDay ?? currentDue.day;
    switch (frequencyType.toLowerCase()) {
      case 'monthly':
        return _addMonthsAnchored(currentDue, 1, anchor);
      case 'quarterly':
        return _addMonthsAnchored(currentDue, 3, anchor);
      case 'half_yearly':
        return _addMonthsAnchored(currentDue, 6, anchor);
      case 'yearly':
        return _addMonthsAnchored(currentDue, 12, anchor);
      case 'custom':
        switch (intervalUnit.toLowerCase()) {
          case 'days':
            return currentDue.add(Duration(days: intervalValue));
          case 'weeks':
            return currentDue.add(Duration(days: intervalValue * 7));
          case 'years':
            return _addMonthsAnchored(currentDue, intervalValue * 12, anchor);
          case 'months':
          default:
            return _addMonthsAnchored(currentDue, intervalValue, anchor);
        }
      default:
        return _addMonthsAnchored(currentDue, 1, anchor);
    }
  }

  Future<void> _ensureOccurrenceReminder({
    required String businessId,
    required String customerId,
    required String occurrenceId,
    required String planTitle,
    required DateTime dueDate,
    required int reminderDaysBefore,
    String? customerName,
  }) async {
    try {
      final days = reminderDaysBefore < 0 ? 0 : reminderDaysBefore;
      final now = DateTime.now();
      final today9am = DateTime(now.year, now.month, now.day, 9, 0);
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final rawTrigger = dueDay.subtract(Duration(days: days));
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

      final title = 'Maintenance Due: $planTitle';
      final description =
          'Scheduled visit on ${_formatSqlDate(dueDate)}${customerName != null && customerName.isNotEmpty ? " for $customerName" : ""}.';

      final existing = await _safeClient
          .from('reminders')
          .select('id')
          .eq('maintenance_occurrence_id', occurrenceId)
          .not('status', 'in', '(completed,cancelled)')
          .limit(1);

      if ((existing as List).isNotEmpty) {
        await _safeClient
            .from('reminders')
            .update({
              'title': title,
              'description': description,
              'due_at': effectiveDue.toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', existing.first['id'] as String);
      } else {
        await _safeClient.from('reminders').insert({
          'business_id': businessId,
          'customer_id': customerId,
          'maintenance_occurrence_id': occurrenceId,
          'title': title,
          'description': description,
          'reminder_type': 'maintenance',
          'due_at': effectiveDue.toUtc().toIso8601String(),
          'status': 'scheduled',
        });
      }
    } catch (e) {
      AppLogger.warning(
        'Could not schedule pre-due reminder for occurrence $occurrenceId: $e',
      );
    }
  }

  Future<void> _advanceRecurringPlanFallback({
    required MaintenanceOccurrence occ,
    required DateTime baseDate,
  }) async {
    final plan =
        occ.plan ?? await getMaintenancePlanById(occ.maintenancePlanId);
    if (plan == null) return;

    if (plan.frequencyType == 'one_time') {
      await _safeClient
          .from('maintenance_plans')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', plan.id);
      return;
    }

    final nextDue = _computeNextDueDate(
      baseDate,
      plan.frequencyType,
      plan.intervalValue ?? 1,
      plan.intervalUnit,
      anchorDay: plan.anchorDay,
    );

    if (plan.endDate != null) {
      final endOnly = DateTime(
        plan.endDate!.year,
        plan.endDate!.month,
        plan.endDate!.day,
      );
      if (nextDue.isAfter(endOnly)) {
        await _safeClient
            .from('maintenance_plans')
            .update({
              'status': 'completed',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', plan.id);
        return;
      }
    }

    final triggerDate = nextDue.subtract(
      Duration(days: plan.reminderDaysBefore),
    );
    final nextDueStr = _formatSqlDate(nextDue);
    final insertedNext = await _safeClient
        .from('maintenance_occurrences')
        .insert({
          'business_id': plan.businessId,
          'maintenance_plan_id': plan.id,
          'customer_id': plan.customerId,
          'equipment_id': plan.equipmentId,
          'due_date': nextDueStr,
          'original_due_date': nextDueStr,
          'reminder_trigger_date': _formatSqlDate(triggerDate),
          'occurrence_number': occ.occurrenceNumber + 1,
          'status': 'scheduled',
        })
        .select('id')
        .single();

    await _safeClient
        .from('maintenance_plans')
        .update({
          'next_due_date': nextDueStr,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', plan.id);

    await _ensureOccurrenceReminder(
      businessId: plan.businessId,
      customerId: plan.customerId,
      occurrenceId: insertedNext['id'] as String,
      planTitle: plan.title,
      dueDate: nextDue,
      reminderDaysBefore: plan.reminderDaysBefore,
      customerName: plan.customer?.fullName,
    );
  }

  @override
  Future<MaintenanceOverviewCounts> getMaintenanceOverviewCounts(
    String businessId,
  ) async {
    try {
      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. Due Today: scheduled/due with due_date = today
      final dueTodayRes = await _safeClient
          .from('maintenance_occurrences')
          .select('id')
          .eq('business_id', businessId)
          .inFilter('status', ['scheduled', 'upcoming', 'due'])
          .eq('due_date', todayStr);
      final dueToday = (dueTodayRes as List).length;

      // 2. Overdue: scheduled/due/overdue with due_date < today
      final overdueRes = await _safeClient
          .from('maintenance_occurrences')
          .select('id')
          .eq('business_id', businessId)
          .inFilter('status', ['scheduled', 'upcoming', 'due', 'overdue'])
          .lt('due_date', todayStr);
      final overdue = (overdueRes as List).length;

      // 3. Upcoming: scheduled/upcoming with due_date > today
      final upcomingRes = await _safeClient
          .from('maintenance_occurrences')
          .select('id')
          .eq('business_id', businessId)
          .inFilter('status', ['scheduled', 'upcoming'])
          .gt('due_date', todayStr);
      final upcoming = (upcomingRes as List).length;

      // 4. Active Plans
      final activePlansRes = await _safeClient
          .from('maintenance_plans')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'active');
      final activePlans = (activePlansRes as List).length;

      return MaintenanceOverviewCounts(
        dueToday: dueToday,
        overdue: overdue,
        upcoming: upcoming,
        activePlans: activePlans,
      );
    } catch (e, stack) {
      AppLogger.error('getMaintenanceOverviewCounts failed', e, stack);
      return const MaintenanceOverviewCounts();
    }
  }

  @override
  Future<List<MaintenanceOccurrence>> getMaintenanceOccurrences({
    String? businessId,
    String? customerId,
    String? planId,
    String? filter,
    int? limit,
  }) async {
    try {
      var query = _safeClient.from('maintenance_occurrences').select('''
        *,
        customers:customers(*),
        equipment:equipment(*),
        maintenance_plans:maintenance_plans(*)
      ''');

      if (businessId != null) query = query.eq('business_id', businessId);
      if (customerId != null) query = query.eq('customer_id', customerId);
      if (planId != null) query = query.eq('maintenance_plan_id', planId);

      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (filter == 'today') {
        query = query
            .inFilter('status', ['scheduled', 'upcoming', 'due'])
            .eq('due_date', todayStr);
      } else if (filter == 'overdue') {
        query = query
            .inFilter('status', ['scheduled', 'upcoming', 'due', 'overdue'])
            .lt('due_date', todayStr);
      } else if (filter == 'upcoming') {
        query = query
            .inFilter('status', ['scheduled', 'upcoming'])
            .gt('due_date', todayStr);
      } else if (filter == 'completed') {
        query = query.eq('status', 'completed');
      }

      dynamic transformQuery = query.order(
        'due_date',
        ascending: filter != 'completed',
      );

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      final response = await transformQuery;
      return (response as List<dynamic>)
          .map(
            (json) =>
                MaintenanceOccurrence.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      AppLogger.error('getMaintenanceOccurrences failed', e, stack);
      return [];
    }
  }

  @override
  Future<MaintenanceOccurrence?> getMaintenanceOccurrenceById(String id) async {
    Map<String, dynamic>? response;
    try {
      response = await _safeClient
          .from('maintenance_occurrences')
          .select('''
        *,
        customers:customers(*),
        equipment:equipment(*),
        maintenance_plans:maintenance_plans(*)
      ''')
          .eq('id', id)
          .maybeSingle();
    } catch (e, stack) {
      AppLogger.error(
        'getMaintenanceOccurrenceById joined query failed',
        e,
        stack,
      );
      try {
        response = await _safeClient
            .from('maintenance_occurrences')
            .select('*')
            .eq('id', id)
            .maybeSingle();
      } catch (fallbackError, fallbackStack) {
        AppLogger.error(
          'getMaintenanceOccurrenceById fallback failed',
          fallbackError,
          fallbackStack,
        );
        return null;
      }
    }

    if (response == null) return null;

    final data = Map<String, dynamic>.from(response);
    final serviceEntryId = data['completed_service_entry_id'] as String?;
    if (serviceEntryId != null && serviceEntryId.isNotEmpty) {
      try {
        final serviceJson = await _safeClient
            .from('service_entries')
            .select('*')
            .eq('id', serviceEntryId)
            .maybeSingle();
        if (serviceJson != null) {
          data['service_entries'] = serviceJson;
        }
      } catch (e, stack) {
        AppLogger.error(
          'Failed to load linked completed service entry',
          e,
          stack,
        );
      }
    }

    return MaintenanceOccurrence.fromJson(data);
  }

  @override
  Future<List<MaintenancePlan>> getMaintenancePlans({
    String? businessId,
    String? customerId,
    String? status,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      var query = _safeClient.from('maintenance_plans').select('''
        *,
        customers:customers(*),
        equipment:equipment(*),
        service_entries:service_entry_id(*)
      ''');

      if (businessId != null) query = query.eq('business_id', businessId);
      if (customerId != null) query = query.eq('customer_id', customerId);

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final clean = searchQuery.trim();
        query = query.or('title.ilike.%$clean%,plan_number.ilike.%$clean%');
      }

      dynamic transformQuery = query.order('next_due_date', ascending: true);

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      final response = await transformQuery;
      return (response as List<dynamic>)
          .map((json) => MaintenancePlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('getMaintenancePlans failed', e, stack);
      return [];
    }
  }

  @override
  Future<MaintenancePlan?> getMaintenancePlanById(String id) async {
    Map<String, dynamic>? response;
    try {
      response = await _safeClient
          .from('maintenance_plans')
          .select('''
        *,
        customers:customers(*),
        equipment:equipment(*),
        maintenance_occurrences:maintenance_occurrences(*)
      ''')
          .eq('id', id)
          .maybeSingle();
    } catch (e, stack) {
      AppLogger.error('getMaintenancePlanById joined query failed', e, stack);
      try {
        response = await _safeClient
            .from('maintenance_plans')
            .select('*')
            .eq('id', id)
            .maybeSingle();
      } catch (fallbackError, fallbackStack) {
        AppLogger.error(
          'getMaintenancePlanById fallback failed',
          fallbackError,
          fallbackStack,
        );
        return null;
      }
    }

    if (response == null) return null;

    final data = Map<String, dynamic>.from(response);
    final serviceEntryId = data['service_entry_id'] as String?;
    if (serviceEntryId != null && serviceEntryId.isNotEmpty) {
      try {
        final serviceJson = await _safeClient
            .from('service_entries')
            .select('*')
            .eq('id', serviceEntryId)
            .maybeSingle();
        if (serviceJson != null) {
          data['service_entries'] = serviceJson;
        }
      } catch (e, stack) {
        AppLogger.error(
          'Failed to load linked service entry for plan',
          e,
          stack,
        );
      }
    }

    return MaintenancePlan.fromJson(data);
  }

  @override
  Future<List<MaintenanceOccurrence>> getCustomerMaintenanceHistory(
    String customerId,
  ) async {
    return getMaintenanceOccurrences(customerId: customerId);
  }

  @override
  Future<MaintenancePlan> createMaintenancePlan(MaintenancePlan plan) async {
    try {
      // 1. Insert plan with safe DB-compatible date formatting and frequency_type
      final insertData = plan.toJson();
      insertData.remove('id'); // let Postgres allocate UUID
      if ((insertData['plan_number'] as String?)?.isEmpty ?? true) {
        insertData['plan_number'] = await _generatePlanNumber(plan.businessId);
      }
      if (insertData['frequency_type'] == 'recurring') {
        insertData['frequency_type'] = 'monthly';
      }
      insertData['start_date'] = _formatSqlDate(plan.startDate);
      insertData['next_due_date'] = _formatSqlDate(plan.nextDueDate);
      if (plan.endDate != null) {
        insertData['end_date'] = _formatSqlDate(plan.endDate!);
      }

      final planRes = await _safeClient
          .from('maintenance_plans')
          .insert(insertData)
          .select('''
            *,
            customers:customers(*),
            equipment:equipment(*)
          ''')
          .single();

      final createdPlan = MaintenancePlan.fromJson(planRes);

      // 2. Generate first occurrence transactionally
      final firstDueDate = createdPlan.startDate;
      final triggerDate = firstDueDate.subtract(
        Duration(days: createdPlan.reminderDaysBefore),
      );
      final firstDueStr = _formatSqlDate(firstDueDate);

      final occRes = await _safeClient
          .from('maintenance_occurrences')
          .insert({
            'business_id': createdPlan.businessId,
            'maintenance_plan_id': createdPlan.id,
            'customer_id': createdPlan.customerId,
            'equipment_id': createdPlan.equipmentId,
            'due_date': firstDueStr,
            'original_due_date': firstDueStr,
            'reminder_trigger_date': _formatSqlDate(triggerDate),
            'occurrence_number': 1,
            'status': 'scheduled',
          })
          .select('id')
          .single();

      // 3. Ensure an actionable pre-due reminder exists for the Reminders workspace
      await _ensureOccurrenceReminder(
        businessId: createdPlan.businessId,
        customerId: createdPlan.customerId,
        occurrenceId: occRes['id'] as String,
        planTitle: createdPlan.title,
        dueDate: firstDueDate,
        reminderDaysBefore: createdPlan.reminderDaysBefore,
        customerName: createdPlan.customer?.fullName,
      );

      return createdPlan;
    } catch (e, stack) {
      AppLogger.error('createMaintenancePlan failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<MaintenancePlan> updateMaintenancePlan(MaintenancePlan plan) async {
    try {
      final updateData = plan.toJson();
      if (updateData['frequency_type'] == 'recurring') {
        updateData['frequency_type'] = 'monthly';
      }
      updateData['start_date'] = _formatSqlDate(plan.startDate);
      updateData['next_due_date'] = _formatSqlDate(plan.nextDueDate);
      if (plan.endDate != null) {
        updateData['end_date'] = _formatSqlDate(plan.endDate!);
      }
      updateData['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final res = await _safeClient
          .from('maintenance_plans')
          .update(updateData)
          .eq('id', plan.id)
          .select('''
            *,
            customers:customers(*),
            equipment:equipment(*)
          ''')
          .single();

      return MaintenancePlan.fromJson(res);
    } catch (e, stack) {
      AppLogger.error('updateMaintenancePlan failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updatePlanStatus(String planId, String newStatus) async {
    try {
      await _safeClient
          .from('maintenance_plans')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', planId);
    } catch (e, stack) {
      AppLogger.error('updatePlanStatus failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> completeOccurrence({
    required String occurrenceId,
    required DateTime completionDate,
    String? workPerformed,
    String? notes,
    double? amount,
    String? serviceEntryId,
  }) async {
    try {
      final completionStr = _formatSqlDate(completionDate);
      try {
        final res = await _safeClient.rpc(
          'complete_maintenance_occurrence',
          params: {
            'p_occurrence_id': occurrenceId,
            'p_completion_date': completionStr,
            'p_work_performed': workPerformed,
            'p_notes': notes,
            'p_amount': amount,
            'p_service_entry_id': serviceEntryId,
          },
        );
        return (res as Map<String, dynamic>?) ?? {};
      } catch (rpcErr) {
        AppLogger.warning(
          'complete_maintenance_occurrence RPC unavailable, using fallback: $rpcErr',
        );
      }

      final occ = await getMaintenanceOccurrenceById(occurrenceId);
      await _safeClient
          .from('maintenance_occurrences')
          .update({
            'status': 'completed',
            'completed_date': completionStr,
            'work_performed': ?workPerformed,
            'notes': ?notes,
            'amount': ?amount,
            'completed_service_entry_id': ?serviceEntryId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', occurrenceId);

      try {
        await _safeClient
            .from('reminders')
            .update({
              'status': 'completed',
              'completed_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('maintenance_occurrence_id', occurrenceId)
            .not('status', 'in', '(completed,cancelled)');
      } catch (_) {}

      if (occ != null) {
        await _advanceRecurringPlanFallback(occ: occ, baseDate: completionDate);
      }

      return {'status': 'completed'};
    } catch (e, stack) {
      AppLogger.error('completeOccurrence failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> skipOccurrence({
    required String occurrenceId,
    String? reason,
  }) async {
    try {
      try {
        final res = await _safeClient.rpc(
          'skip_maintenance_occurrence',
          params: {'p_occurrence_id': occurrenceId, 'p_skip_reason': reason},
        );
        return (res as Map<String, dynamic>?) ?? {};
      } catch (rpcErr) {
        AppLogger.warning(
          'skip_maintenance_occurrence RPC unavailable, using fallback: $rpcErr',
        );
      }

      final occ = await getMaintenanceOccurrenceById(occurrenceId);
      await _safeClient
          .from('maintenance_occurrences')
          .update({
            'status': 'skipped',
            if (reason != null && reason.isNotEmpty) 'skip_reason': reason,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', occurrenceId);

      try {
        await _safeClient
            .from('reminders')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('maintenance_occurrence_id', occurrenceId)
            .not('status', 'in', '(completed,cancelled)');
      } catch (_) {}

      if (occ != null) {
        await _advanceRecurringPlanFallback(occ: occ, baseDate: occ.dueDate);
      }

      return {'status': 'skipped'};
    } catch (e, stack) {
      AppLogger.error('skipOccurrence failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> rescheduleOccurrence({
    required String occurrenceId,
    required DateTime newDueDate,
  }) async {
    try {
      final occ = await getMaintenanceOccurrenceById(occurrenceId);
      final reminderDays = occ?.plan?.reminderDaysBefore ?? 7;
      final dueDateStr = _formatSqlDate(newDueDate);
      final triggerDateStr = _formatSqlDate(
        newDueDate.subtract(Duration(days: reminderDays)),
      );

      await _safeClient
          .from('maintenance_occurrences')
          .update({
            'due_date': dueDateStr,
            'reminder_trigger_date': triggerDateStr,
            'status': 'scheduled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', occurrenceId);

      if (occ != null) {
        await _ensureOccurrenceReminder(
          businessId: occ.businessId,
          customerId: occ.customerId,
          occurrenceId: occurrenceId,
          planTitle: occ.plan?.title ?? 'Maintenance Visit',
          dueDate: newDueDate,
          reminderDaysBefore: reminderDays,
          customerName: occ.customer?.fullName,
        );
      }
    } catch (e, stack) {
      AppLogger.error('rescheduleOccurrence failed', e, stack);
      rethrow;
    }
  }
}
