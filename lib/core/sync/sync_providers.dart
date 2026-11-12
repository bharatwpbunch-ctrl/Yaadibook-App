import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/offline_store.dart';
import '../../shared/providers/backend_providers.dart';
import '../../shared/repositories/customer_repository.dart';
import '../../shared/repositories/offline_aware_repositories.dart';
import '../../shared/repositories/reminder_repository.dart';
import '../../shared/repositories/service_repository.dart';
import 'connectivity_service.dart';
import 'sync_engine.dart';

/// Singleton offline store backed by Drift SQLite on Android/native
/// and an in-memory store fallback on Web/headless tests.
final offlineStoreProvider = Provider<IOfflineStore>((ref) {
  final store = HybridOfflineStore();

  // Security hygiene: automatically clear offline cache on auth session termination.
  ref.listen(authStateProvider, (_, next) {
    next.whenData((authState) {
      if (authState.session == null) {
        store.clearAllData();
      }
    });
  });

  return store;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SyncEngine(
    store: ref.watch(offlineStoreProvider),
    customerRepo: SupabaseCustomerRepository(client),
    serviceRepo: SupabaseServiceRepository(client),
    reminderRepo: SupabaseReminderRepository(client),
  );
});

/// Runtime Riverpod overrides wiring offline caching & queuing into Customer,
/// Service, and Reminder repositories without circular dependencies.
List<Override> buildOfflineRepositoryOverrides() {
  return [
    customerRepositoryProvider.overrideWith((ref) {
      final client = ref.watch(supabaseClientProvider);
      return OfflineAwareCustomerRepository(
        remote: SupabaseCustomerRepository(client),
        syncEngine: ref.watch(syncEngineProvider),
        store: ref.watch(offlineStoreProvider),
        getBusinessId: () => ref.read(currentBusinessProvider).valueOrNull?.id,
        isOnline: () => ref.read(isOnlineProvider),
        onQueueChanged: () =>
            ref.read(syncControllerProvider.notifier).refreshStatus(),
      );
    }),
    serviceRepositoryProvider.overrideWith((ref) {
      final client = ref.watch(supabaseClientProvider);
      return OfflineAwareServiceRepository(
        remote: SupabaseServiceRepository(client),
        syncEngine: ref.watch(syncEngineProvider),
        store: ref.watch(offlineStoreProvider),
        getBusinessId: () => ref.read(currentBusinessProvider).valueOrNull?.id,
        isOnline: () => ref.read(isOnlineProvider),
        onQueueChanged: () =>
            ref.read(syncControllerProvider.notifier).refreshStatus(),
      );
    }),
    reminderRepositoryProvider.overrideWith((ref) {
      final client = ref.watch(supabaseClientProvider);
      return OfflineAwareReminderRepository(
        remote: SupabaseReminderRepository(client),
        syncEngine: ref.watch(syncEngineProvider),
        store: ref.watch(offlineStoreProvider),
        getBusinessId: () => ref.read(currentBusinessProvider).valueOrNull?.id,
        isOnline: () => ref.read(isOnlineProvider),
        onQueueChanged: () =>
            ref.read(syncControllerProvider.notifier).refreshStatus(),
      );
    }),
  ];
}

class SyncUiState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final int cachedCount;
  final DateTime? lastSyncedAt;
  final SyncRunResult? lastResult;
  final List<PendingOperationRecord> operations;
  final String? message;

  const SyncUiState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.cachedCount = 0,
    this.lastSyncedAt,
    this.lastResult,
    this.operations = const [],
    this.message,
  });

  SyncUiState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    int? conflictCount,
    int? cachedCount,
    DateTime? lastSyncedAt,
    SyncRunResult? lastResult,
    List<PendingOperationRecord>? operations,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncUiState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      cachedCount: cachedCount ?? this.cachedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastResult: lastResult ?? this.lastResult,
      operations: operations ?? this.operations,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class SyncController extends StateNotifier<SyncUiState> {
  final Ref _ref;

  SyncController(this._ref) : super(const SyncUiState()) {
    _init();
  }

  void _init() {
    _ref.listen<bool>(isOnlineProvider, (prev, next) {
      state = state.copyWith(isOnline: next);
      if (next && prev == false) {
        // Auto-sync when device reconnects
        syncNow();
      }
    }, fireImmediately: true);

    _ref.listen(currentBusinessProvider, (_, next) {
      next.whenData((biz) {
        if (biz != null) {
          refreshStatus();
        }
      });
    }, fireImmediately: true);
  }

  Future<void> refreshStatus() async {
    final biz = _ref.read(currentBusinessProvider).valueOrNull;
    if (biz == null) return;
    final store = _ref.read(offlineStoreProvider);
    final ops = await store.getPendingOperations(biz.id);
    final cachedCount = await store.countCachedEntities(biz.id);
    final lastCustSync = await store.getLastSyncedAt(
      biz.id,
      OfflineEntityTypes.customer,
    );

    if (!mounted) return;
    state = state.copyWith(
      pendingCount: ops
          .where((o) => o.status == SyncOperationStatus.pendingSync)
          .length,
      failedCount: ops
          .where((o) => o.status == SyncOperationStatus.syncFailed)
          .length,
      conflictCount: ops
          .where((o) => o.status == SyncOperationStatus.conflict)
          .length,
      cachedCount: cachedCount,
      lastSyncedAt: lastCustSync ?? state.lastSyncedAt,
      operations: ops,
    );
  }

  Future<SyncRunResult> syncNow() async {
    final biz = _ref.read(currentBusinessProvider).valueOrNull;
    final isOnline = _ref.read(isOnlineProvider);
    if (biz == null) return const SyncRunResult();

    if (!isOnline) {
      state = state.copyWith(
        isOnline: false,
        message:
            'Device is offline. Changes will sync automatically once online.',
      );
      return SyncRunResult(remainingPending: state.pendingCount);
    }

    state = state.copyWith(isSyncing: true, clearMessage: true);
    final engine = _ref.read(syncEngineProvider);
    final result = await engine.syncPendingOperations(
      businessId: biz.id,
      isOnline: true,
    );

    // Refresh local cache from server for core offline views
    try {
      final customers = await _ref
          .read(customerRepositoryProvider)
          .getCustomers();
      await engine.cacheCustomers(biz.id, customers);
      final services = await _ref
          .read(serviceRepositoryProvider)
          .getServiceEntries(businessId: biz.id);
      await engine.cacheServices(biz.id, services);
      final reminders = await _ref
          .read(reminderRepositoryProvider)
          .getReminders(includeCompleted: true);
      await engine.cacheReminders(biz.id, reminders);
    } catch (_) {
      // Partial cache refresh failure is non-fatal
    }

    await refreshStatus();
    if (!mounted) return result;
    state = state.copyWith(
      isSyncing: false,
      lastSyncedAt: DateTime.now().toUtc(),
      lastResult: result,
      message: result.conflictCount > 0
          ? '${result.conflictCount} sync conflict(s) require review.'
          : result.syncedCount > 0
          ? 'Synced ${result.syncedCount} queued change(s).'
          : 'All data is up to date.',
    );
    return result;
  }

  Future<void> resolveConflictKeepMine(PendingOperationRecord op) async {
    state = state.copyWith(isSyncing: true, clearMessage: true);
    try {
      await _ref.read(syncEngineProvider).resolveConflictKeepMine(op: op);
      await refreshStatus();
      state = state.copyWith(
        isSyncing: false,
        message: 'Your offline version was saved to server.',
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, message: 'Resolve failed: $e');
    }
  }

  Future<void> resolveConflictUseServer(PendingOperationRecord op) async {
    state = state.copyWith(isSyncing: true, clearMessage: true);
    try {
      await _ref.read(syncEngineProvider).resolveConflictUseServer(op: op);
      await refreshStatus();
      state = state.copyWith(
        isSyncing: false,
        message: 'Server version kept cleanly.',
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, message: 'Resolve failed: $e');
    }
  }

  Future<void> clearLocalCache() async {
    await _ref.read(offlineStoreProvider).clearAllData();
    await refreshStatus();
    if (mounted) {
      state = state.copyWith(
        cachedCount: 0,
        message: 'Local offline cache cleared.',
      );
    }
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncUiState>(
      (ref) => SyncController(ref),
    );
