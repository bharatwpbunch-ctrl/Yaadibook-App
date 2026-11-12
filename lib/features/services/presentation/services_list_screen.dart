import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_error_state.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../core/widgets/yb_search_input.dart';
import '../../../shared/repositories/service_repository.dart';
import '../providers/service_providers.dart';
import 'widgets/service_card.dart';

/// Full searchable and filterable list of all business services.
class ServicesListScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const ServicesListScreen({super.key, this.initialStatus});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (widget.initialStatus!.toLowerCase()) {
          case 'pending':
            ref.read(serviceFilterProvider.notifier).state =
                ServiceFilter.pending;
            break;
          case 'in_progress':
            ref.read(serviceFilterProvider.notifier).state =
                ServiceFilter.inProgress;
            break;
          case 'completed':
            ref.read(serviceFilterProvider.notifier).state =
                ServiceFilter.completed;
            break;
          case 'cancelled':
            ref.read(serviceFilterProvider.notifier).state =
                ServiceFilter.cancelled;
            break;
          default:
            ref.read(serviceFilterProvider.notifier).state = ServiceFilter.all;
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(serviceSearchQueryProvider.notifier).state = query;
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(serviceSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeFilter = ref.watch(serviceFilterProvider);
    final activeSort = ref.watch(serviceSortProvider);
    final servicesAsync = ref.watch(servicesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.servicesListTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: l10n.addServiceTitle,
            onPressed: () => context.push('/services/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: YbSearchInput(
                    controller: _searchController,
                    hint: l10n.serviceSearchHint,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
                ),
                AppSpacing.gapH8,
                PopupMenuButton<ServiceSort>(
                  icon: const Icon(
                    Icons.sort_rounded,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: 'Sort services',
                  initialValue: activeSort,
                  onSelected: (sort) {
                    ref.read(serviceSortProvider.notifier).state = sort;
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: ServiceSort.recentlyCreated,
                      child: Text(l10n.serviceSortRecentlyCreated),
                    ),
                    PopupMenuItem(
                      value: ServiceSort.newestDate,
                      child: Text(l10n.serviceSortNewestDate),
                    ),
                    PopupMenuItem(
                      value: ServiceSort.oldestDate,
                      child: Text(l10n.serviceSortOldestDate),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.serviceFilterAll,
                  filter: ServiceFilter.all,
                  isSelected: activeFilter == ServiceFilter.all,
                ),
                AppSpacing.gapH8,
                _buildFilterChip(
                  label: l10n.serviceFilterPending,
                  filter: ServiceFilter.pending,
                  isSelected: activeFilter == ServiceFilter.pending,
                ),
                AppSpacing.gapH8,
                _buildFilterChip(
                  label: l10n.serviceFilterInProgress,
                  filter: ServiceFilter.inProgress,
                  isSelected: activeFilter == ServiceFilter.inProgress,
                ),
                AppSpacing.gapH8,
                _buildFilterChip(
                  label: l10n.serviceFilterCompleted,
                  filter: ServiceFilter.completed,
                  isSelected: activeFilter == ServiceFilter.completed,
                ),
                AppSpacing.gapH8,
                _buildFilterChip(
                  label: l10n.serviceFilterCancelled,
                  filter: ServiceFilter.cancelled,
                  isSelected: activeFilter == ServiceFilter.cancelled,
                ),
              ],
            ),
          ),
          AppSpacing.gapV8,

          // List results
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: YbLoadingState()),
              error: (err, _) => YbErrorState(
                title: 'Could not load services',
                message: err.toString(),
                onRetry: () => ref.refresh(servicesListProvider),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(servicesListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    itemCount: services.length + 1,
                    separatorBuilder: (ctx, i) => AppSpacing.gapV8,
                    itemBuilder: (ctx, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            l10n.serviceTotalCount(services.length),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      }
                      final service = services[index - 1];
                      return ServiceCard(service: service);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/services/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: l10n.addServiceTitle,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required ServiceFilter filter,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(serviceFilterProvider.notifier).state = filter;
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final isFiltered =
        _searchController.text.isNotEmpty ||
        ref.read(serviceFilterProvider) != ServiceFilter.all;

    if (isFiltered) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              AppSpacing.gapV16,
              Text(
                l10n.noDataFound,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapV8,
              const Text(
                'No services match your active search or filters.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapV16,
              TextButton(
                onPressed: () {
                  _clearSearch();
                  ref.read(serviceFilterProvider.notifier).state =
                      ServiceFilter.all;
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_circle_outlined,
                size: 36,
                color: AppColors.primaryDark,
              ),
            ),
            AppSpacing.gapV16,
            Text(
              l10n.serviceEmptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV8,
            Text(
              l10n.serviceEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
