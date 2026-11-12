import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool hasNetworkFromResults(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

/// Real-time connectivity stream derived from `connectivity_plus`.
final connectivityStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    final initial = await connectivity.checkConnectivity();
    yield hasNetworkFromResults(initial);
    await for (final next in connectivity.onConnectivityChanged) {
      yield hasNetworkFromResults(next);
    }
  } catch (_) {
    // Fallback to online if platform channel is unavailable (e.g., headless tests)
    yield true;
  }
});

/// Overridable connectivity check for UI and SyncEngine.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStreamProvider).valueOrNull ?? true;
});
