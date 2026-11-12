import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_empty_state.dart';
import '../../../shared/models/message_template.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';

class MessageTemplatesScreen extends ConsumerWidget {
  const MessageTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final templatesAsync = ref.watch(messageTemplatesProvider);
    final categoryFilter = ref.watch(templateCategoryFilterProvider);
    final languageFilter = ref.watch(templateLanguageFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commTemplatesNavTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language_outlined),
            tooltip: 'Filter by Language',
            initialValue: languageFilter,
            onSelected: (lang) =>
                ref.read(templateLanguageFilterProvider.notifier).state = lang,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Languages')),
              const PopupMenuItem(value: 'en', child: Text('English (EN)')),
              const PopupMenuItem(value: 'gu', child: Text('ગુજરાતી (GU)')),
              const PopupMenuItem(value: 'hi', child: Text('हिन्दी (HI)')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/communications/templates/create'),
        icon: const Icon(Icons.add),
        label: Text(l10n.commCreateTemplateAction),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildCategoryChip(
                  label: l10n.remindersFilterAll,
                  isSelected: categoryFilter == 'all',
                  onSelected: () =>
                      ref.read(templateCategoryFilterProvider.notifier).state =
                          'all',
                ),
                AppSpacing.gapH8,
                _buildCategoryChip(
                  label: l10n.commCategoryServiceUpdate,
                  isSelected: categoryFilter == 'service_update',
                  onSelected: () =>
                      ref.read(templateCategoryFilterProvider.notifier).state =
                          'service_update',
                ),
                AppSpacing.gapH8,
                _buildCategoryChip(
                  label: l10n.commCategoryAmcRenewal,
                  isSelected: categoryFilter == 'amc_renewal',
                  onSelected: () =>
                      ref.read(templateCategoryFilterProvider.notifier).state =
                          'amc_renewal',
                ),
                AppSpacing.gapH8,
                _buildCategoryChip(
                  label: l10n.commCategoryMaintenance,
                  isSelected: categoryFilter == 'maintenance_reminder',
                  onSelected: () =>
                      ref.read(templateCategoryFilterProvider.notifier).state =
                          'maintenance_reminder',
                ),
                AppSpacing.gapH8,
                _buildCategoryChip(
                  label: l10n.commCategoryPayment,
                  isSelected: categoryFilter == 'payment_reminder',
                  onSelected: () =>
                      ref.read(templateCategoryFilterProvider.notifier).state =
                          'payment_reminder',
                ),
              ],
            ),
          ),

          const Divider(height: 12, color: AppColors.borderSubtle),

          // Templates List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(messageTemplatesProvider);
              },
              child: templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return Center(
                      child: YbEmptyState(
                        icon: Icons.assignment_outlined,
                        title: l10n.commTemplatesEmptyTitle,
                        message: l10n.commTemplatesEmptySubtitle,
                        actionLabel: l10n.commCreateTemplateAction,
                        onAction: () =>
                            context.push('/communications/templates/create'),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _buildTemplateCard(context, ref, template);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    MessageTemplate template,
  ) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Name, Category pill & language badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildLanguageBadge(template.language),
                AppSpacing.gapH6,
                _buildProviderStatusBadge(template.providerStatus),
              ],
            ),
            AppSpacing.gapV8,

            // Template Content with variable highlights
            Text(
              template.content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapV8,

            // Variables chips
            if (template.variables.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: template.variables.map((v) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '{{$v}}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.gapV12,
            ],

            const Divider(height: 12, color: AppColors.borderSubtle),

            // Actions row: Use Template, Edit, Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!template.isSystemDefault) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete Template',
                    onPressed: () => _confirmDelete(context, ref, template),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Edit Template',
                    onPressed: () => context.push(
                      '/communications/templates/${template.id}/edit',
                    ),
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(l10n.commUseTemplateAction),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () {
                    CommunicationComposerSheet.show(
                      context,
                      preferredCategory: template.category,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBadge(String lang) {
    final label = switch (lang) {
      'gu' => 'GU',
      'hi' => 'HI',
      _ => 'EN',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProviderStatusBadge(String status) {
    final (label, color) = switch (status) {
      'approved' => ('Approved', AppColors.success),
      'pending' => ('Pending', AppColors.warning),
      'rejected' => ('Rejected', AppColors.error),
      _ => ('Local', AppColors.info),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MessageTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(messageTemplateRepositoryProvider);
      await repo.deleteTemplate(template.id);
      ref.invalidate(messageTemplatesProvider);
    }
  }
}
