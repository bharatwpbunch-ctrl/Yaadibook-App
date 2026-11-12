import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/errors/app_exception.dart';
import 'package:yaadibook/features/dashboard/data/dashboard_repository.dart';
import 'package:yaadibook/features/dashboard/models/dashboard_metrics.dart';
import 'package:yaadibook/features/dashboard/models/today_focus_item.dart';
import 'package:yaadibook/features/dashboard/providers/dashboard_providers.dart';

void main() {
  group('Greeting Period Calculation Tests', () {
    test('Calculates morning between 05:00 and 11:59', () {
      final t1 = DateTime(2026, 11, 5, 5, 0);
      final t2 = DateTime(2026, 11, 5, 8, 30);
      final t3 = DateTime(2026, 11, 5, 11, 59);

      expect(getGreetingPeriod(t1), GreetingPeriod.morning);
      expect(getGreetingPeriod(t2), GreetingPeriod.morning);
      expect(getGreetingPeriod(t3), GreetingPeriod.morning);
    });

    test('Calculates afternoon between 12:00 and 16:59', () {
      final t1 = DateTime(2026, 11, 5, 12, 0);
      final t2 = DateTime(2026, 11, 5, 14, 45);
      final t3 = DateTime(2026, 11, 5, 16, 59);

      expect(getGreetingPeriod(t1), GreetingPeriod.afternoon);
      expect(getGreetingPeriod(t2), GreetingPeriod.afternoon);
      expect(getGreetingPeriod(t3), GreetingPeriod.afternoon);
    });

    test('Calculates evening between 17:00 and 04:59', () {
      final t1 = DateTime(2026, 11, 5, 17, 0);
      final t2 = DateTime(2026, 11, 5, 20, 15);
      final t3 = DateTime(2026, 11, 5, 23, 30);
      final t4 = DateTime(2026, 11, 5, 3, 0);

      expect(getGreetingPeriod(t1), GreetingPeriod.evening);
      expect(getGreetingPeriod(t2), GreetingPeriod.evening);
      expect(getGreetingPeriod(t3), GreetingPeriod.evening);
      expect(getGreetingPeriod(t4), GreetingPeriod.evening);
    });
  });

  group('DashboardMetrics Model Tests', () {
    test('Default zero instance has zero counts', () {
      const metrics = DashboardMetrics.zero;
      expect(metrics.totalCustomers, 0);
      expect(metrics.pendingServices, 0);
      expect(metrics.maintenanceDue, 0);
      expect(metrics.amcExpiringSoon, 0);
    });

    test('Equality and copyWith operate immutably', () {
      const m1 = DashboardMetrics(
        totalCustomers: 12,
        pendingServices: 3,
        maintenanceDue: 1,
        amcExpiringSoon: 2,
      );
      final m2 = m1.copyWith(pendingServices: 4);

      expect(m1.pendingServices, 3);
      expect(m2.pendingServices, 4);
      expect(m2.totalCustomers, 12);
      expect(m1 == m2, isFalse);
    });
  });

  group('TodayFocusItem Entity Tests', () {
    test('Focus items support all 4 source types with correct labels', () {
      expect(TodayFocusSource.maintenance.label, 'Maintenance');
      expect(TodayFocusSource.amc.label, 'AMC');
      expect(TodayFocusSource.followup.label, 'Follow-up');
      expect(TodayFocusSource.service.label, 'Service');

      final item = TodayFocusItem(
        id: 'f1',
        title: 'Quarterly RO Filter Replacement',
        customerName: 'Shreeji Restaurant',
        dueDate: DateTime(2026, 11, 5, 10, 0),
        source: TodayFocusSource.maintenance,
        isOverdue: false,
      );

      expect(item.id, 'f1');
      expect(item.customerName, 'Shreeji Restaurant');
      expect(item.source, TodayFocusSource.maintenance);
    });
  });

  group('SupabaseDashboardRepository Tests', () {
    test('Gracefully guards against uninitialized/null SupabaseClient', () {
      final repo = SupabaseDashboardRepository(null);

      expect(
        () => repo.getDashboardMetrics('biz-123'),
        throwsA(isA<AppStorageException>()),
      );
      expect(
        () => repo.getTodayFocusItems('biz-123'),
        throwsA(isA<AppStorageException>()),
      );
    });
  });
}
