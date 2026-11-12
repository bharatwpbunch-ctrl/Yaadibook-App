import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/repositories/customer_repository.dart';
import '../providers/customer_providers.dart';
import 'widgets/customer_list_card.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(customerSearchQueryProvider.notifier).state = query.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(customerSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customersAsync = ref.watch(customersListProvider);
    final activeFilter = ref.watch(customerFilterProvider);
    final activeSort = ref.watch(customerSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customersTitle),
        actions: [
          // Import contacts shortcut
          IconButton(
            icon: const Icon(Icons.contacts_outlined),
            tooltip: l10n.contactImportTitle,
            onPressed: () => context.push('/customers/import'),
          ),
          // Add customer button
          IconButton(
            icon: const Icon(
              Icons.person_add_outlined,
              color: AppColors.primary,
            ),
            tooltip: l10n.customersActionAdd,
            onPressed: () => context.push('/customers/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter controls
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: YbSearchInput(
                    controller: _searchController,
                    hint: l10n.customersSearchHint,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
                ),
                AppSpacing.gapH8,
                // Sort Menu Button
                PopupMenuButton<CustomerSort>(
                  icon: const Icon(
                    Icons.sort_outlined,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: 'Sort customers',
                  initialValue: activeSort,
                  onSelected: (sort) {
                    ref.read(customerSortProvider.notifier).state = sort;
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: CustomerSort.recentlyAdded,
                      child: Text(l10n.customersSortRecentlyAdded),
                    ),
                    PopupMenuItem(
                      value: CustomerSort.nameAsc,
                      child: Text(l10n.customersSortNameAsc),
                    ),
                    PopupMenuItem(
                      value: CustomerSort.nameDesc,
                      child: Text(l10n.customersSortNameDesc),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.customersFilterActive,
                  filter: CustomerFilter.active,
                  isSelected: activeFilter == CustomerFilter.active,
                ),
                AppSpacing.gapH8,
                _buildFilterChip(
                  label: l10n.customersFilterArchived,
                  filter: CustomerFilter.archived,
                  isSelected: activeFilter == CustomerFilter.archived,
                ),
                AppSpacing.gapH8,
                _buildFilterChip(
                  label: l10n.customersFilterAll,
                  filter: CustomerFilter.all,
                  isSelected: activeFilter == CustomerFilter.all,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Customer list / states
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return _buildEmptyState(context, isFiltered: _isFiltered());
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(customersListProvider),
                  child: ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: customers.length + 1,
                    separatorBuilder: (_, i) => AppSpacing.gapV12,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            l10n.customersTotalCount(customers.length),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      }
                      final customer = customers[index - 1];
                      return CustomerListCard(customer: customer);
                    },
                  ),
                );
              },
              loading: () => const Center(child: YbLoadingState()),
              error: (err, _) => RefreshIndicator(
                onRefresh: () async => ref.refresh(customersListProvider),
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    AppSpacing.gapV48,
                    YbErrorState(
                      title: 'Failed to load customers',
                      message: '$err',
                      onRetry: () => ref.refresh(customersListProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/add'),
        icon: const Icon(Icons.add),
        label: Text(l10n.customersActionAdd),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  bool _isFiltered() {
    final query = ref.read(customerSearchQueryProvider);
    final filter = ref.read(customerFilterProvider);
    return query.isNotEmpty || filter != CustomerFilter.active;
  }

  Widget _buildFilterChip({
    required String label,
    required CustomerFilter filter,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
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
          ref.read(customerFilterProvider.notifier).state = filter;
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    final l10n = context.l10n;

    if (isFiltered) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_search_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              AppSpacing.gapV16,
              Text(
                l10n.noDataFound,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapV8,
              Text(
                'No customers matched your search or filter.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapV16,
              TextButton(
                onPressed: () {
                  _clearSearch();
                  ref.read(customerFilterProvider.notifier).state =
                      CustomerFilter.active;
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
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapV20,
            Text(
              l10n.customersEmptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV8,
            Text(
              l10n.customersEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            AppSpacing.gapV24,
            YbPrimaryButton(
              label: l10n.customersActionAdd,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => context.push('/customers/add'),
            ),
            AppSpacing.gapV12,
            YbSecondaryButton(
              label: l10n.customersActionImport,
              icon: const Icon(Icons.contacts_outlined),
              onPressed: () => context.push('/customers/import'),
            ),
          ],
        ),
      ),
    );
  }
}
