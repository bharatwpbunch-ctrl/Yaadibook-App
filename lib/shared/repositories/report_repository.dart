import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/utils/logger.dart';
import '../../features/reports/models/report_models.dart';
import '../models/amc_contract.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/reminder.dart';
import '../models/service_entry.dart';

abstract class IReportRepository {
  Future<BusinessReportData> getBusinessReport({
    required Business business,
    required DateTime startDate,
    required DateTime endDate,
    required bool isOnline,
  });
}

class SupabaseReportRepository implements IReportRepository {
  final SupabaseClient? _client;
  final SyncEngine _syncEngine;

  SupabaseReportRepository(this._client, this._syncEngine);

  @override
  Future<BusinessReportData> getBusinessReport({
    required Business business,
    required DateTime startDate,
    required DateTime endDate,
    required bool isOnline,
  }) async {
    if (!isOnline || _client == null) {
      return _computeOfflineFallback(business, startDate, endDate);
    }

    try {
      final startStr = _dateStr(startDate);
      final endStr = _dateStr(endDate);

      final summaryFuture = _client.rpc(
        'get_reports_summary',
        params: {
          'p_business_id': business.id,
          'p_start_date': startStr,
          'p_end_date': endStr,
        },
      );

      final customersFuture = _client
          .from('customers')
          .select()
          .eq('business_id', business.id)
          .isFilter('archived_at', null);

      final servicesFuture = _client
          .from('service_entries')
          .select(
            '*, customers(id, business_id, full_name, primary_phone, created_at, updated_at)',
          )
          .eq('business_id', business.id)
          .gte('service_date', startStr)
          .lte('service_date', endStr)
          .order('service_date', ascending: false)
          .limit(300);

      final maintFuture = _client
          .from('maintenance_occurrences')
          .select(
            'id, due_date, status, maintenance_plans(title, customers(full_name))',
          )
          .eq('business_id', business.id)
          .gte('due_date', startStr)
          .lte('due_date', endStr)
          .order('due_date', ascending: false)
          .limit(300);

      final amcFuture = _client
          .from('amc_contracts')
          .select(
            '*, customers(id, business_id, full_name, primary_phone, created_at, updated_at)',
          )
          .eq('business_id', business.id)
          .order('end_date', ascending: true)
          .limit(300);

      final remindersFuture = _client
          .from('reminders')
          .select('*, customers(full_name, primary_phone)')
          .eq('business_id', business.id)
          .order('due_at', ascending: false)
          .limit(300);

      final results = await Future.wait<dynamic>([
        summaryFuture,
        customersFuture,
        servicesFuture,
        maintFuture,
        amcFuture,
        remindersFuture,
      ]);

      final summaryJson = results[0] is Map
          ? Map<String, dynamic>.from(results[0] as Map)
          : const <String, dynamic>{};

      final customers = (results[1] as List)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
      final services = (results[2] as List)
          .map((e) => ServiceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final maintRows = (results[3] as List).map((e) {
        final m = e as Map<String, dynamic>;
        final plan = m['maintenance_plans'] as Map<String, dynamic>?;
        final cust = plan?['customers'] as Map<String, dynamic>?;
        return MaintenanceReportRow(
          id: m['id'] as String,
          title: (plan?['title'] as String?) ?? 'Scheduled Maintenance',
          customerName: (cust?['full_name'] as String?) ?? 'Customer',
          dueDate: DateTime.parse(m['due_date'] as String),
          status: (m['status'] as String?) ?? 'scheduled',
        );
      }).toList();
      final amcs = (results[4] as List)
          .map((e) => AmcContract.fromJson(e as Map<String, dynamic>))
          .toList();
      final reminders = (results[5] as List)
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();

      // Also build baseline metrics from fetched records and overlay authoritative SQL summary
      final computed = BusinessReportData.computeFromEntities(
        businessId: business.id,
        businessName: business.businessName,
        businessPhone: business.phone,
        startDate: startDate,
        endDate: endDate,
        customers: customers,
        services: services,
        amcs: amcs,
        reminders: reminders,
        maintenanceRows: maintRows,
      );

      final custSummary = _asMap(summaryJson['customers']);
      final srvSummary = _asMap(summaryJson['services']);
      final maintSummary = _asMap(summaryJson['maintenance']);
      final amcSummary = _asMap(summaryJson['amc']);
      final fupSummary = _asMap(summaryJson['followups']);
      final commSummary = _asMap(summaryJson['communications']);

      return BusinessReportData(
        businessId: business.id,
        businessName: business.businessName,
        businessPhone: business.phone,
        startDate: startDate,
        endDate: endDate,
        currencyCode: business.currencyCode,
        timezone: business.timezone,
        isOfflineEstimate: false,
        customers: CustomerReportMetrics(
          totalActive: _asInt(
            custSummary['total_active'],
            computed.customers.totalActive,
          ),
          newInPeriod: _asInt(
            custSummary['new_in_period'],
            computed.customers.newInPeriod,
          ),
          repeatCustomers: _asInt(
            custSummary['repeat_customers'],
            computed.customers.repeatCustomers,
          ),
          withActiveAmc: _asInt(
            custSummary['with_active_amc'],
            computed.customers.withActiveAmc,
          ),
          topCustomers: computed.customers.topCustomers,
        ),
        services: ServiceReportMetrics(
          totalActiveCount: _asInt(
            srvSummary['total_active_count'],
            computed.services.totalActiveCount,
          ),
          completedCount: _asInt(
            srvSummary['completed_count'],
            computed.services.completedCount,
          ),
          pendingCount: _asInt(
            srvSummary['pending_count'],
            computed.services.pendingCount,
          ),
          cancelledCount: _asInt(
            srvSummary['cancelled_count'],
            computed.services.cancelledCount,
          ),
          recordedAmountInr: _asDouble(
            srvSummary['recorded_amount_inr'],
            computed.services.recordedAmountInr,
          ),
          paidAmountInr: _asDouble(
            srvSummary['paid_amount_inr'],
            computed.services.paidAmountInr,
          ),
          pendingAmountInr: _asDouble(
            srvSummary['pending_amount_inr'],
            computed.services.pendingAmountInr,
          ),
          byType: computed.services.byType,
          entries: computed.services.entries,
        ),
        maintenance: MaintenanceReportMetrics(
          totalInPeriod: _asInt(
            maintSummary['total_in_period'],
            computed.maintenance.totalInPeriod,
          ),
          completedCount: _asInt(
            maintSummary['completed_count'],
            computed.maintenance.completedCount,
          ),
          upcomingCount: _asInt(
            maintSummary['upcoming_count'],
            computed.maintenance.upcomingCount,
          ),
          overdueCount: _asInt(
            maintSummary['overdue_count'],
            computed.maintenance.overdueCount,
          ),
          rows: computed.maintenance.rows,
        ),
        amc: AmcReportMetrics(
          activeCount: _asInt(
            amcSummary['active_count'],
            computed.amc.activeCount,
          ),
          expiringWithin30Days: _asInt(
            amcSummary['expiring_within_30_days'],
            computed.amc.expiringWithin30Days,
          ),
          expiredCount: _asInt(
            amcSummary['expired_count'],
            computed.amc.expiredCount,
          ),
          renewedInPeriod: _asInt(
            amcSummary['renewed_in_period'],
            computed.amc.renewedInPeriod,
          ),
          portfolioContractValueInr: _asDouble(
            amcSummary['portfolio_contract_value_inr'],
            computed.amc.portfolioContractValueInr,
          ),
          contracts: computed.amc.contracts,
        ),
        followups: FollowupReportMetrics(
          completedCount: _asInt(
            fupSummary['completed_count'],
            computed.followups.completedCount,
          ),
          pendingCount: _asInt(
            fupSummary['pending_count'],
            computed.followups.pendingCount,
          ),
          overdueCount: _asInt(
            fupSummary['overdue_count'],
            computed.followups.overdueCount,
          ),
          byType: computed.followups.byType,
          reminders: computed.followups.reminders,
        ),
        communications: CommunicationReportMetrics(
          whatsappCount: _asInt(commSummary['whatsapp_count'], 0),
          smsCount: _asInt(commSummary['sms_count'], 0),
          recordedCostInr: _asDouble(commSummary['recorded_cost_inr'], 0),
        ),
        generatedAt: DateTime.now(),
      );
    } catch (e, st) {
      AppLogger.warning(
        'ReportRepository: online query failed, using cached offline estimate: $e\n$st',
      );
      return _computeOfflineFallback(business, startDate, endDate);
    }
  }

  Future<BusinessReportData> _computeOfflineFallback(
    Business business,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final customers = await _syncEngine.getCachedCustomers(business.id);
    final services = await _syncEngine.getCachedServices(business.id);
    final reminders = await _syncEngine.getCachedReminders(business.id);
    return BusinessReportData.computeFromEntities(
      businessId: business.id,
      businessName: business.businessName,
      businessPhone: business.phone,
      startDate: startDate,
      endDate: endDate,
      customers: customers,
      services: services,
      amcs: const [],
      reminders: reminders,
      isOfflineEstimate: true,
    );
  }

  String _dateStr(DateTime d) => d.toIso8601String().split('T').first;

  Map<String, dynamic> _asMap(dynamic val) =>
      val is Map ? Map<String, dynamic>.from(val) : const {};

  int _asInt(dynamic val, int fallback) => val is num ? val.toInt() : fallback;

  double _asDouble(dynamic val, double fallback) =>
      val is num ? val.toDouble() : fallback;
}
