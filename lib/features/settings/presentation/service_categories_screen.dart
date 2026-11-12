import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/providers/backend_providers.dart';

class ServiceCategoryItem {
  final String name;
  final String description;
  final bool isEnabled;

  const ServiceCategoryItem({
    required this.name,
    this.description = '',
    this.isEnabled = true,
  });

  ServiceCategoryItem copyWith({
    String? name,
    String? description,
    bool? isEnabled,
  }) {
    return ServiceCategoryItem(
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'isEnabled': isEnabled,
  };

  factory ServiceCategoryItem.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryItem(
      name: json['name'] as String? ?? 'Service',
      description: json['description'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  static List<ServiceCategoryItem> defaults() => const [
    ServiceCategoryItem(
      name: 'Installation',
      description: 'New system or hardware setup and commissioning',
    ),
    ServiceCategoryItem(
      name: 'Repair',
      description: 'Fault troubleshooting and component replacement',
    ),
    ServiceCategoryItem(
      name: 'Maintenance',
      description: 'Routine preventive checkup and servicing',
    ),
    ServiceCategoryItem(
      name: 'Inspection',
      description: 'Site survey, audit, and system diagnostics',
    ),
    ServiceCategoryItem(
      name: 'AMC Support',
      description: 'Annual maintenance contract visits & renewals',
    ),
    ServiceCategoryItem(
      name: 'General Service',
      description: 'Custom on-demand customer visits & support',
    ),
  ];
}

class ServiceCategoriesScreen extends ConsumerStatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  ConsumerState<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState
    extends ConsumerState<ServiceCategoriesScreen> {
  List<ServiceCategoryItem> _categories = ServiceCategoryItem.defaults();
  bool _loading = true;
  bool _saving = false;
  String? _loadedBusinessId;

  String _storageKey(String? businessId) =>
      'service_categories_${businessId ?? 'default'}';

  Future<void> _loadForBusiness(String? businessId) async {
    if (_loadedBusinessId == businessId && !_loading) return;
    _loadedBusinessId = businessId;
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.read(_storageKey(businessId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final parsed = decoded
            .map((e) => ServiceCategoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) {
          _categories = parsed;
        }
      }
    } catch (_) {
      // Keep default categories gracefully
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _persist(String? businessId, {bool showSnackbar = true}) async {
    setState(() => _saving = true);
    try {
      final storage = ref.read(secureStorageProvider);
      final encoded = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await storage.write(_storageKey(businessId), encoded);
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service categories updated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save categories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddCategoryDialog(String? businessId) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await showDialog<ServiceCategoryItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Service Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. DVR Upgrade, Cabling',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              AppSpacing.gapV12,
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(
                  ServiceCategoryItem(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();

    if (added == null || !mounted) return;
    setState(() {
      _categories = [..._categories, added];
    });
    await _persist(businessId, showSnackbar: true);
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider).valueOrNull;
    if (_loading) {
      _loadForBusiness(business?.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories'),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() => _categories = ServiceCategoryItem.defaults());
              await _persist(business?.id, showSnackbar: true);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _showAddCategoryDialog(business?.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                88,
              ),
              children: [
                const Text(
                  'Enable or add work categories used when creating services, maintenance visits, and AMC contracts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapV16,
                ...List.generate(_categories.length, (index) {
                  final cat = _categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cat.isEnabled
                            ? AppColors.primaryContainer
                            : AppColors.surfaceVariant,
                        child: Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: cat.isEnabled
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      title: Text(
                        cat.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: cat.description.isNotEmpty
                          ? Text(
                              cat.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : null,
                      trailing: Switch(
                        value: cat.isEnabled,
                        onChanged: (val) async {
                          setState(() {
                            final updated = List<ServiceCategoryItem>.from(
                              _categories,
                            );
                            updated[index] = cat.copyWith(isEnabled: val);
                            _categories = updated;
                          });
                          await _persist(business?.id, showSnackbar: false);
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
