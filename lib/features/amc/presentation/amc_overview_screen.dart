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
import '../providers/amc_providers.dart';
import 'widgets/amc_contract_card.dart';

/// Screen displaying AMC overview metrics, status tabs, search, and contracts list.
class AmcOverviewScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const AmcOverviewScreen({super.key, this.initialStatus});

  @override
  ConsumerState<AmcOverviewScreen> createState() => _AmcOverviewScreenState();
}

class _AmcOverviewScreenState extends ConsumerState<AmcOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initializedStatus = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedStatus && widget.initialStatus != null) {
      _initializedStatus = true;
      Future.microtask(() {
        final status = widget.initialStatus!.toLowerCase();
        if (status == 'expiring') {
          ref.read(amcFilterProvider.notifier).state = AmcFilter.expiring;
        } else if (status == 'expired') {
          ref.read(amcFilterProvider.notifier).state = AmcFilter.expired;
        } else if (status == 'active') {
          ref.read(amcFilterProvider.notifier).state = AmcFilter.active;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countsAsync = ref.watch(amcOverviewCountsProvider);
    final contractsAsync = ref.watch(amcContractsListProvider);
    final activeFilter = ref.watch(amcFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.amcTitle,
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
        label: Text(l10n.amcCreateContract),
        onPressed: () => context.push('/amc/create'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(amcOverviewCountsProvider);
          ref.invalidate(amcContractsListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // 1. Metric Counts Row
            SliverToBoxAdapter(
              child: countsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
                error: (err, stack) => const SizedBox.shrink(),
                data: (counts) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      // Active
                      Expanded(
                        child: _AmcMetricCard(
                          title: l10n.amcTabActive,
                          count: counts.active,
                          color: AppColors.success,
                          bgColor: AppColors.successBg,
                          icon: Icons.check_circle_outline_rounded,
                          isSelected: activeFilter == AmcFilter.active,
                          onTap: () =>
                              ref.read(amcFilterProvider.notifier).state =
                                  AmcFilter.active,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Expiring Soon
                      Expanded(
                        child: _AmcMetricCard(
                          title: l10n.amcTabExpiring,
                          count: counts.expiringSoon,
                          color: AppColors.warning,
                          bgColor: AppColors.warningBg,
                          icon: Icons.timer_outlined,
                          isSelected: activeFilter == AmcFilter.expiring,
                          onTap: () =>
                              ref.read(amcFilterProvider.notifier).state =
                                  AmcFilter.expiring,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Expired
                      Expanded(
                        child: _AmcMetricCard(
                          title: l10n.amcTabExpired,
                          count: counts.expired,
                          color: AppColors.error,
                          bgColor: AppColors.errorBg,
                          icon: Icons.event_busy_rounded,
                          isSelected: activeFilter == AmcFilter.expired,
                          onTap: () =>
                              ref.read(amcFilterProvider.notifier).state =
                                  AmcFilter.expired,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Renewed
                      Expanded(
                        child: _AmcMetricCard(
                          title: l10n.amcRenewedCount,
                          count: counts.recentlyRenewed,
                          color: AppColors.info,
                          bgColor: AppColors.infoBg,
                          icon: Icons.autorenew_rounded,
                          isSelected: activeFilter == AmcFilter.renewed,
                          onTap: () =>
                              ref.read(amcFilterProvider.notifier).state =
                                  AmcFilter.renewed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Search Field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contract # or title...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(amcSearchQueryProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
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
                    ref.read(amcSearchQueryProvider.notifier).state = val
                        .trim();
                  },
                ),
              ),
            ),

            // 3. Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.amcTabAll,
                      selected: activeFilter == AmcFilter.all,
                      onSelected: () =>
                          ref.read(amcFilterProvider.notifier).state =
                              AmcFilter.all,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.amcTabActive,
                      selected: activeFilter == AmcFilter.active,
                      onSelected: () =>
                          ref.read(amcFilterProvider.notifier).state =
                              AmcFilter.active,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.amcTabExpiring,
                      selected: activeFilter == AmcFilter.expiring,
                      onSelected: () =>
                          ref.read(amcFilterProvider.notifier).state =
                              AmcFilter.expiring,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.amcTabExpired,
                      selected: activeFilter == AmcFilter.expired,
                      onSelected: () =>
                          ref.read(amcFilterProvider.notifier).state =
                              AmcFilter.expired,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: l10n.amcRenewedCount,
                      selected: activeFilter == AmcFilter.renewed,
                      onSelected: () =>
                          ref.read(amcFilterProvider.notifier).state =
                              AmcFilter.renewed,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Contracts List
            contractsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: YbLoadingState()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: YbErrorState(
                  title: 'Failed to load AMC contracts',
                  message: err.toString(),
                  onRetry: () => ref.invalidate(amcContractsListProvider),
                ),
              ),
              data: (contracts) {
                if (contracts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: YbEmptyState(
                      title: l10n.amcEmptyContracts,
                      message:
                          'Track service warranties, annual agreements and recurring contract revenues.',
                      icon: Icons.assignment_outlined,
                      actionLabel: l10n.amcCreateContract,
                      onAction: () => context.push('/amc/create'),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return AmcContractCard(contract: contracts[index]);
                  }, childCount: contracts.length),
                );
              },
            ),

            // Bottom Spacer for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _AmcMetricCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmcMetricCard({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
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
