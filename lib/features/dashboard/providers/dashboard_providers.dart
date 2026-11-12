import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/backend_providers.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_metrics.dart';
import '../models/today_focus_item.dart';

/// Provider for Dashboard Repository.
final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseDashboardRepository(client);
});

/// Future provider for live dashboard counts for the active business.
final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardMetrics>((
  ref,
) async {
  final businessAsync = await ref.watch(currentBusinessProvider.future);
  if (businessAsync == null) {
    return DashboardMetrics.zero;
  }
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboardMetrics(businessAsync.id);
});

/// Future provider for real records due today or overdue for the active business.
final todayFocusProvider = FutureProvider.autoDispose<List<TodayFocusItem>>((
  ref,
) async {
  final businessAsync = await ref.watch(currentBusinessProvider.future);
  if (businessAsync == null) {
    return const [];
  }
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getTodayFocusItems(businessAsync.id);
});

/// Time-of-day classification for greetings.
enum GreetingPeriod { morning, afternoon, evening }

/// Pure function to calculate greeting period from local time.
GreetingPeriod getGreetingPeriod(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) {
    return GreetingPeriod.morning;
  } else if (hour >= 12 && hour < 17) {
    return GreetingPeriod.afternoon;
  } else {
    return GreetingPeriod.evening;
  }
}
