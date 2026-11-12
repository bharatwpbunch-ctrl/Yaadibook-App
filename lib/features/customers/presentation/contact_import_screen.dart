import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/contacts_service.dart';
import '../../../core/widgets/yb_loading_state.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../shared/providers/backend_providers.dart';
import '../providers/customer_providers.dart';

/// Screen for selectively importing customer contacts from the mobile device.
class ContactImportScreen extends ConsumerStatefulWidget {
  const ContactImportScreen({super.key});

  @override
  ConsumerState<ContactImportScreen> createState() =>
      _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(contactImportControllerProvider.notifier)
          .checkPermissionAndLoad();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _resolvePhoneNumber(
    BuildContext context,
    DeviceContact contact,
  ) async {
    if (contact.phones.isEmpty) return null;
    if (contact.phones.length == 1) return contact.phones.first;

    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        title: Text(
          l10n.contactSelectPhoneTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.contactSelectPhoneMessage,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapV12,
            ...contact.phones.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importSelectedContacts(
    List<DeviceContact> selectedContacts,
  ) async {
    if (selectedContacts.isEmpty) return;

    final business = await ref.read(currentBusinessProvider.future);
    if (business == null) return;

    setState(() => _isImporting = true);

    final repo = ref.read(customerRepositoryProvider);
    int importedCount = 0;
    int skippedCount = 0;

    for (final contact in selectedContacts) {
      if (contact.phones.isEmpty) {
        skippedCount++;
        continue;
      }
      final phone = contact.phones.first;
      try {
        final duplicate = await repo.checkDuplicatePhone(business.id, phone);
        if (duplicate != null) {
          skippedCount++;
          continue;
        }

        await repo.createCustomer(
          businessId: business.id,
          fullName: contact.displayName.isNotEmpty
              ? contact.displayName
              : 'Unknown Contact',
          primaryPhone: phone,
          email: contact.emails.isNotEmpty ? contact.emails.first : null,
          customerType: 'individual',
        );
        importedCount++;
      } catch (_) {
        skippedCount++;
      }
    }

    if (mounted) {
      setState(() => _isImporting = false);
      ref.invalidate(customersListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$importedCount customer${importedCount == 1 ? '' : 's'} imported'
            '${skippedCount > 0 ? ' ($skippedCount skipped/duplicates)' : ''}.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final importState = ref.watch(contactImportControllerProvider);
    final notifier = ref.read(contactImportControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.contactImportTitle,
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
          if (importState.permissionStatus.isGranted &&
              importState.contacts.isNotEmpty)
            TextButton(
              onPressed: () {
                if (importState.selectedContactIds.length ==
                    importState.contacts.length) {
                  notifier.clearSelection();
                } else {
                  notifier.selectAll();
                }
              },
              child: Text(
                importState.selectedContactIds.length ==
                        importState.contacts.length
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: importState.isLoading && importState.contacts.isEmpty
            ? const Center(child: YbLoadingState())
            : !importState.permissionStatus.isGranted
            ? _buildPermissionRationale(context, notifier, importState)
            : _buildContactsView(context, notifier, importState),
      ),
      bottomNavigationBar:
          importState.permissionStatus.isGranted &&
              importState.selectedContactIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: YbPrimaryButton(
                label:
                    '${l10n.contactActionImportSelected} (${importState.selectedContactIds.length})',
                isLoading: _isImporting,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () {
                  final selectedList = importState.contacts
                      .where(
                        (c) => importState.selectedContactIds.contains(c.id),
                      )
                      .toList();
                  _importSelectedContacts(selectedList);
                },
              ),
            )
          : null,
    );
  }

  Widget _buildPermissionRationale(
    BuildContext context,
    ContactImportController notifier,
    ContactImportState state,
  ) {
    final l10n = context.l10n;
    final isPermanentlyDenied = state.permissionStatus.isPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contacts_rounded,
                  size: 32,
                  color: AppColors.primaryDark,
                ),
              ),
              AppSpacing.gapV16,
              Text(
                l10n.contactPermissionRationaleTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapV8,
              Text(
                isPermanentlyDenied
                    ? l10n.contactPermissionDeniedMessage
                    : l10n.contactPermissionRationaleMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              AppSpacing.gapV24,
              YbPrimaryButton(
                label: isPermanentlyDenied
                    ? l10n.contactOpenSettings
                    : l10n.contactPermissionGrant,
                icon: Icon(
                  isPermanentlyDenied
                      ? Icons.settings_outlined
                      : Icons.check_circle_outline,
                ),
                onPressed: () async {
                  if (isPermanentlyDenied) {
                    await openAppSettings();
                  } else {
                    await notifier.requestPermission();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsView(
    BuildContext context,
    ContactImportController notifier,
    ContactImportState state,
  ) {
    final contacts = state.contacts;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => notifier.updateSearch(val),
            decoration: InputDecoration(
              hintText: 'Search contacts by name...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        notifier.updateSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Contact List
        Expanded(
          child: contacts.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isNotEmpty
                        ? 'No contacts matching "${_searchController.text}"'
                        : 'No contacts found on device.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (ctx, i) =>
                      const Divider(height: 1, color: AppColors.borderSubtle),
                  itemBuilder: (ctx, index) {
                    final contact = contacts[index];
                    final isSelected = state.selectedContactIds.contains(
                      contact.id,
                    );
                    final primaryPhone = contact.phones.isNotEmpty
                        ? contact.phones.first
                        : 'No phone number';

                    return ListTile(
                      tileColor: isSelected
                          ? AppColors.primaryContainer.withValues(alpha: 0.3)
                          : AppColors.surface,
                      leading: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (_) =>
                            notifier.toggleSelectContact(contact.id),
                      ),
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            primaryPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (contact.phones.length > 1) ...[
                            AppSpacing.gapH6,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+${contact.phones.length - 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        tooltip: 'Open in Add Customer',
                        onPressed: () async {
                          final selectedPhone = await _resolvePhoneNumber(
                            context,
                            contact,
                          );
                          if (context.mounted) {
                            final params = <String, String>{
                              'name': contact.displayName,
                            };
                            if (selectedPhone != null) {
                              params['phone'] = selectedPhone;
                            }
                            context.push(
                              Uri(
                                path: '/customers/add',
                                queryParameters: params,
                              ).toString(),
                            );
                          }
                        },
                      ),
                      onTap: () => notifier.toggleSelectContact(contact.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
