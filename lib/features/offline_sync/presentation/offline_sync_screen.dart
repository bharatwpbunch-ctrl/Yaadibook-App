import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/offline_store.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/utils/date_formatter.dart';

class OfflineSyncScreen extends ConsumerWidget {
  const OfflineSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineSyncTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshStatus,
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Connectivity & Engine Status Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isOnline
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      color: state.isOnline
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      state.isOnline
                          ? 'Online — Connected to Cloud'
                          : 'Offline Mode Active',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV12,
                _InfoLine(
                  label: 'Cached Local Records',
                  value: '${state.cachedCount}',
                ),
                AppSpacing.gapV8,
                _InfoLine(
                  label: 'Pending Sync Operations',
                  value: '${state.pendingCount}',
                ),
                AppSpacing.gapV8,
                _InfoLine(
                  label: 'Failed Operations',
                  value: '${state.failedCount}',
                ),
                AppSpacing.gapV8,
                _InfoLine(
                  label: 'Sync Conflicts',
                  value: '${state.conflictCount}',
                ),
                AppSpacing.gapV8,
                _InfoLine(
                  label: 'Last Successful Sync',
                  value: state.lastSyncedAt == null
                      ? 'Not yet synced this session'
                      : DateFormatter.formatDateTime(
                          state.lastSyncedAt!.toLocal(),
                        ),
                ),
                if (state.message != null) ...[
                  AppSpacing.gapV12,
                  Text(
                    state.message!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                AppSpacing.gapV16,
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: state.isSyncing ? null : controller.syncNow,
                        icon: state.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(l10n.offlineSyncNowAction),
                      ),
                    ),
                    AppSpacing.gapH12,
                    OutlinedButton.icon(
                      onPressed: state.isSyncing
                          ? null
                          : () => _confirmClearCache(context, controller),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l10n.offlineClearCacheAction),
                    ),
                  ],
                ),
              ],
            ),
          ),

          AppSpacing.gapV20,

          // Offline Capabilities Policy Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Capabilities & Safety Boundaries',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '• Available offline: View cached customers, services, maintenance schedules, AMCs, and reminders; create/edit customers & services; complete reminders.\n'
                  '• Online-only for data integrity: AMC renewals, Google Play subscription purchases, bulk messaging campaigns, and server push dispatch.',
                  style: TextStyle(fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),

          AppSpacing.gapV20,
          Text(
            'Sync Queue & Conflicts (${state.operations.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.gapV8,
          if (state.operations.isEmpty)
            Container(
              padding: AppSpacing.paddingXl,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No pending offline changes or sync conflicts.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...state.operations.map((op) {
              final isConflict = op.status == SyncOperationStatus.conflict;
              final isFailed = op.status == SyncOperationStatus.syncFailed;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: isConflict || isFailed
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${op.operationType} (${op.entityType})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Chip(
                          label: Text(op.status),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (op.errorMessage != null) ...[
                      AppSpacing.gapV8,
                      Text(
                        op.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    if (isConflict) ...[
                      AppSpacing.gapV12,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  controller.resolveConflictUseServer(op),
                              child: const Text('Use Server Copy'),
                            ),
                          ),
                          AppSpacing.gapH12,
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  controller.resolveConflictKeepMine(op),
                              child: const Text('Keep My Edit'),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isFailed) ...[
                      AppSpacing.gapV8,
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: state.isSyncing
                              ? null
                              : controller.syncNow,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _confirmClearCache(
    BuildContext context,
    SyncController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Cache?'),
        content: const Text(
          'This removes cached local data and any unsynced pending edits on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearLocalCache();
    }
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
