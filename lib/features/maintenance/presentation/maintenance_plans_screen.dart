import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_empty_state.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../providers/maintenance_providers.dart';
import 'widgets/maintenance_plan_card.dart';

/// Screen listing customer maintenance plans with search and status filtering.
class MaintenancePlansScreen extends ConsumerStatefulWidget {
  const MaintenancePlansScreen({super.key});

  @override
  ConsumerState<MaintenancePlansScreen> createState() =>
      _MaintenancePlansScreenState();
}

class _MaintenancePlansScreenState
    extends ConsumerState<MaintenancePlansScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plansAsync = ref.watch(maintenancePlansListProvider);
    final activeFilter = ref.watch(planFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.maintenancePlans,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.maintenanceAddPlan),
        onPressed: () => context.push('/maintenance/add'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search plans by number or customer...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                      .read(
                                        maintenanceSearchQueryProvider.notifier,
                                      )
                                      .state =
                                  '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(maintenanceSearchQueryProvider.notifier).state =
                        val.trim();
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PlanFilterChip(
                        label: l10n.serviceFilterAll,
                        selected: activeFilter == MaintenancePlanFilter.all,
                        onSelected: () =>
                            ref.read(planFilterProvider.notifier).state =
                                MaintenancePlanFilter.all,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PlanFilterChip(
                        label: l10n.maintenanceActivePlans,
                        selected: activeFilter == MaintenancePlanFilter.active,
                        onSelected: () =>
                            ref.read(planFilterProvider.notifier).state =
                                MaintenancePlanFilter.active,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PlanFilterChip(
                        label: l10n.maintenancePausedPlans,
                        selected: activeFilter == MaintenancePlanFilter.paused,
                        onSelected: () =>
                            ref.read(planFilterProvider.notifier).state =
                                MaintenancePlanFilter.paused,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PlanFilterChip(
                        label: l10n.maintenanceCompleted,
                        selected:
                            activeFilter == MaintenancePlanFilter.completed,
                        onSelected: () =>
                            ref.read(planFilterProvider.notifier).state =
                                MaintenancePlanFilter.completed,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PlanFilterChip(
                        label: l10n.maintenanceCancelled,
                        selected:
                            activeFilter == MaintenancePlanFilter.cancelled,
                        onSelected: () =>
                            ref.read(planFilterProvider.notifier).state =
                                MaintenancePlanFilter.cancelled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Plans List
          Expanded(
            child: plansAsync.when(
              loading: () => const Center(child: YbLoadingState()),
              error: (err, _) => YbErrorState(
                title: 'Failed to load maintenance plans',
                message: err.toString(),
                onRetry: () => ref.invalidate(maintenancePlansListProvider),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return YbEmptyState(
                    title: l10n.maintenanceEmptyPlans,
                    message:
                        'Create maintenance plans to automatically track periodic service visits for your customers.',
                    icon: Icons.repeat_rounded,
                    actionLabel: l10n.maintenanceAddPlan,
                    onAction: () => context.push('/maintenance/add'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(maintenancePlansListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: 80,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      return MaintenancePlanCard(plan: plans[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _PlanFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
