import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../models/dashboard_metrics.dart';
import '../models/today_focus_item.dart';

abstract class IDashboardRepository {
  Future<DashboardMetrics> getDashboardMetrics(String businessId);
  Future<List<TodayFocusItem>> getTodayFocusItems(String businessId);
}

class SupabaseDashboardRepository implements IDashboardRepository {
  final SupabaseClient? _client;

  SupabaseDashboardRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<DashboardMetrics> getDashboardMetrics(String businessId) async {
    try {
      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final thirtyDaysAhead = now.add(const Duration(days: 30));
      final thirtyDaysStr =
          "${thirtyDaysAhead.year.toString().padLeft(4, '0')}-${thirtyDaysAhead.month.toString().padLeft(2, '0')}-${thirtyDaysAhead.day.toString().padLeft(2, '0')}";

      // 1. Total Customers: active, non-archived customers
      final customersRes = await _safeClient
          .from('customers')
          .select('id')
          .eq('business_id', businessId)
          .isFilter('archived_at', null);
      final totalCustomers = (customersRes as List).length;

      // 2. Pending Services: pending or in-progress
      final servicesRes = await _safeClient
          .from('service_entries')
          .select('id')
          .eq('business_id', businessId)
          .inFilter('status', ['pending', 'in_progress']);
      final pendingServices = (servicesRes as List).length;

      // 3. Maintenance Due: scheduled, due, or overdue with due_date <= today
      final maintenanceRes = await _safeClient
          .from('maintenance_occurrences')
          .select('id')
          .eq('business_id', businessId)
          .inFilter('status', ['scheduled', 'due', 'overdue'])
          .lte('due_date', todayStr);
      final maintenanceDue = (maintenanceRes as List).length;

      // 4. AMC Expiring Soon: active/expiring with end_date between today and today+30d
      final amcRes = await _safeClient
          .from('amc_contracts')
          .select('id')
          .eq('business_id', businessId)
          .inFilter('status', ['active', 'expiring'])
          .gte('end_date', todayStr)
          .lte('end_date', thirtyDaysStr);
      final amcExpiringSoon = (amcRes as List).length;

      return DashboardMetrics(
        totalCustomers: totalCustomers,
        pendingServices: pendingServices,
        maintenanceDue: maintenanceDue,
        amcExpiringSoon: amcExpiringSoon,
      );
    } catch (e, stack) {
      AppLogger.error(
        'DashboardRepository.getDashboardMetrics failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load dashboard metrics: $e');
    }
  }

  @override
  Future<List<TodayFocusItem>> getTodayFocusItems(String businessId) async {
    try {
      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final endOfTodayIso = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      final List<TodayFocusItem> items = [];

      // A. Real Reminders due today or overdue
      final remindersRes = await _safeClient
          .from('reminders')
          .select('*, customers(full_name, primary_phone)')
          .eq('business_id', businessId)
          .inFilter('status', ['scheduled', 'due', 'overdue'])
          .lte('due_at', endOfTodayIso)
          .order('due_at', ascending: true);

      for (final row in (remindersRes as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final dueAt = DateTime.tryParse(map['due_at'] as String? ?? '') ?? now;
        final customerMap = map['customers'] as Map<String, dynamic>?;

        final rawType = (map['reminder_type'] as String?)?.toLowerCase() ?? '';
        TodayFocusSource source;
        if (rawType.contains('maint')) {
          source = TodayFocusSource.maintenance;
        } else if (rawType.contains('amc')) {
          source = TodayFocusSource.amc;
        } else if (rawType.contains('serv')) {
          source = TodayFocusSource.service;
        } else {
          source = TodayFocusSource.followup;
        }

        items.add(
          TodayFocusItem(
            id: map['id'] as String,
            title: (map['title'] as String?) ?? 'Reminder',
            customerId: map['customer_id'] as String?,
            customerName: customerMap?['full_name'] as String?,
            customerPhone: customerMap?['primary_phone'] as String?,
            dueDate: dueAt,
            source: source,
            isOverdue: dueAt.isBefore(now),
            notes: map['notes'] as String?,
            reminderId: map['id'] as String,
            maintenanceOccurrenceId:
                map['maintenance_occurrence_id'] as String?,
            amcContractId: map['amc_contract_id'] as String?,
            serviceId: map['service_id'] as String?,
          ),
        );
      }

      // B. Maintenance occurrences due today or overdue
      final maintenanceRes = await _safeClient
          .from('maintenance_occurrences')
          .select('*, customers(full_name, primary_phone)')
          .eq('business_id', businessId)
          .inFilter('status', ['scheduled', 'due', 'overdue'])
          .lte('due_date', todayStr)
          .order('due_date', ascending: true);

      for (final row in (maintenanceRes as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final dueDate =
            DateTime.tryParse(map['due_date'] as String? ?? '') ?? now;
        final customerMap = map['customers'] as Map<String, dynamic>?;

        items.add(
          TodayFocusItem(
            id: map['id'] as String,
            title: 'Maintenance Service Due',
            customerId: map['customer_id'] as String?,
            customerName: customerMap?['full_name'] as String?,
            customerPhone: customerMap?['primary_phone'] as String?,
            dueDate: dueDate,
            source: TodayFocusSource.maintenance,
            isOverdue: dueDate.isBefore(DateTime(now.year, now.month, now.day)),
            maintenanceOccurrenceId: map['id'] as String,
          ),
        );
      }

      // C. Pending services due today or overdue
      final servicesRes = await _safeClient
          .from('service_entries')
          .select('*, customers(full_name, primary_phone)')
          .eq('business_id', businessId)
          .inFilter('status', ['pending', 'in_progress'])
          .lte('service_date', todayStr)
          .order('service_date', ascending: true);

      for (final row in (servicesRes as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final serviceDate =
            DateTime.tryParse(map['service_date'] as String? ?? '') ?? now;
        final customerMap = map['customers'] as Map<String, dynamic>?;
        final amt = (map['service_amount'] as num?)?.toDouble();

        items.add(
          TodayFocusItem(
            id: map['id'] as String,
            title: (map['title'] as String?) ?? 'Service Task',
            customerId: map['customer_id'] as String?,
            customerName: customerMap?['full_name'] as String?,
            customerPhone: customerMap?['primary_phone'] as String?,
            dueDate: serviceDate,
            source: TodayFocusSource.service,
            isOverdue: serviceDate.isBefore(
              DateTime(now.year, now.month, now.day),
            ),
            amount: amt,
            notes: map['description'] as String?,
            serviceId: map['id'] as String,
          ),
        );
      }

      // D. AMC Contracts expiring today, overdue, or within the next 15 days
      final fifteenDays = now.add(const Duration(days: 15));
      final fifteenDaysStr =
          "${fifteenDays.year.toString().padLeft(4, '0')}-${fifteenDays.month.toString().padLeft(2, '0')}-${fifteenDays.day.toString().padLeft(2, '0')}";
      final amcFocusRes = await _safeClient
          .from('amc_contracts')
          .select(
            'id, customer_id, contract_title, end_date, contract_amount, customers(full_name, primary_phone)',
          )
          .eq('business_id', businessId)
          .inFilter('status', ['active', 'expiring'])
          .lte('end_date', fifteenDaysStr)
          .order('end_date', ascending: true);

      for (final row in (amcFocusRes as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final endDate =
            DateTime.tryParse(map['end_date'] as String? ?? '') ?? now;
        final customerMap = map['customers'] as Map<String, dynamic>?;
        final amt = (map['contract_amount'] as num?)?.toDouble();

        items.add(
          TodayFocusItem(
            id: map['id'] as String,
            title:
                (map['contract_title'] as String?) ?? 'AMC Contract Expiring',
            customerId: map['customer_id'] as String?,
            customerName: customerMap?['full_name'] as String?,
            customerPhone: customerMap?['primary_phone'] as String?,
            dueDate: endDate,
            source: TodayFocusSource.amc,
            isOverdue: endDate.isBefore(DateTime(now.year, now.month, now.day)),
            amount: amt,
            amcContractId: map['id'] as String,
          ),
        );
      }

      // Sort with overdue items first, then nearest due date
      items.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      return items;
    } catch (e, stack) {
      AppLogger.error(
        'DashboardRepository.getTodayFocusItems failed',
        e,
        stack,
      );
      throw AppStorageException('Failed to load today focus items: $e');
    }
  }
}
