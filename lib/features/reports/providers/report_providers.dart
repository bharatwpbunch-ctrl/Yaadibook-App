import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/connectivity_service.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/report_repository.dart';
import '../models/report_models.dart';

final reportRepositoryProvider = Provider<IReportRepository>((ref) {
  return SupabaseReportRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(syncEngineProvider),
  );
});

final reportDateRangeProvider = StateProvider<ReportDateRange>((ref) {
  return ReportDateRange.fromPreset(ReportDatePreset.thisMonth);
});

final businessReportProvider = FutureProvider<BusinessReportData?>((ref) async {
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return null;
  final range = ref.watch(reportDateRangeProvider);
  final isOnline = ref.watch(isOnlineProvider);

  return ref
      .watch(reportRepositoryProvider)
      .getBusinessReport(
        business: business,
        startDate: range.startDate,
        endDate: range.endDate,
        isOnline: isOnline,
      );
});
