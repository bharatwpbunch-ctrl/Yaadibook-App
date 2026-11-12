import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../sync/sync_providers.dart';

/// Compact contextual banner shown when the device is offline,
/// syncing pending operations, or has sync conflicts/failures requiring attention.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);

    final showBanner =
        !syncState.isOnline ||
        syncState.isSyncing ||
        syncState.pendingCount > 0 ||
        syncState.failedCount > 0 ||
        syncState.conflictCount > 0;

    if (!showBanner) return const SizedBox.shrink();

    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    if (syncState.conflictCount > 0) {
      bgColor = AppColors.error.withValues(alpha: 0.12);
      fgColor = AppColors.error;
      icon = Icons.warning_amber_rounded;
      label = '${syncState.conflictCount} sync conflict(s) need attention';
    } else if (!syncState.isOnline) {
      bgColor = AppColors.warning.withValues(alpha: 0.14);
      fgColor = Colors.orange.shade900;
      icon = Icons.cloud_off_rounded;
      final pendingPart = syncState.pendingCount > 0
          ? ' • ${syncState.pendingCount} pending sync'
          : ' • Cached mode';
      label = 'Offline$pendingPart';
    } else if (syncState.isSyncing) {
      bgColor = AppColors.info.withValues(alpha: 0.12);
      fgColor = AppColors.info;
      icon = Icons.sync_rounded;
      label = 'Syncing offline changes...';
    } else if (syncState.failedCount > 0) {
      bgColor = AppColors.error.withValues(alpha: 0.10);
      fgColor = AppColors.error;
      icon = Icons.sync_problem_rounded;
      label = '${syncState.failedCount} change(s) failed to sync';
    } else {
      bgColor = AppColors.info.withValues(alpha: 0.10);
      fgColor = AppColors.info;
      icon = Icons.cloud_upload_outlined;
      label = '${syncState.pendingCount} pending change(s) ready to sync';
    }

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () => context.push('/settings/offline-sync'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
              if (syncState.isOnline && !syncState.isSyncing)
                TextButton(
                  onPressed: () =>
                      ref.read(syncControllerProvider.notifier).syncNow(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Sync Now'),
                )
              else
                Icon(Icons.chevron_right, size: 18, color: fgColor),
            ],
          ),
        ),
      ),
    );
  }
}
