import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/models/business.dart';
import '../../../shared/providers/backend_providers.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  final String? initialSection;

  const BusinessProfileScreen({super.key, this.initialSection});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _addressKey = GlobalKey();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  void _populate(Business b) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = b.businessName;
    _categoryCtrl.text = b.businessCategory;
    _phoneCtrl.text = b.phone;
    _emailCtrl.text = b.email ?? '';
    _addr1Ctrl.text = b.addressLine1;
    _addr2Ctrl.text = b.addressLine2 ?? '';
    _cityCtrl.text = b.city;
    _stateCtrl.text = b.state;
    _postalCtrl.text = b.postalCode;

    if (widget.initialSection == 'address') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _addressKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _save(Business existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = Business(
        id: existing.id,
        ownerUserId: existing.ownerUserId,
        businessName: _nameCtrl.text.trim(),
        businessCategory: _categoryCtrl.text.trim(),
        businessDescription: existing.businessDescription,
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        addressLine1: _addr1Ctrl.text.trim(),
        addressLine2: _addr2Ctrl.text.trim().isEmpty
            ? null
            : _addr2Ctrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        postalCode: _postalCtrl.text.trim(),
        country: existing.country,
        logoPath: existing.logoPath,
        currencyCode: existing.currencyCode,
        timezone: existing.timezone,
        preferredLanguage: existing.preferredLanguage,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      await ref.read(businessRepositoryProvider).updateBusiness(updated);
      ref.invalidate(currentBusinessProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile updated.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update business: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bizAsync = ref.watch(currentBusinessProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialSection == 'address'
              ? 'Address & Contact Details'
              : 'Business Profile & Address',
        ),
      ),
      body: bizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (biz) {
          if (biz == null) {
            return const Center(child: Text('No business workspace found.'));
          }
          _populate(biz);
          return Form(
            key: _formKey,
            child: ListView(
              controller: _scrollController,
              padding: AppSpacing.screenPadding,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapV12,
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapV12,
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapV12,
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                AppSpacing.gapV16,
                Text(
                  'Address Details',
                  key: _addressKey,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AppSpacing.gapV8,
                TextFormField(
                  controller: _addr1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapV12,
                TextFormField(
                  controller: _addr2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2 (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.gapV12,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: TextFormField(
                        controller: _postalCtrl,
                        decoration: const InputDecoration(
                          labelText: 'PIN Code',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV12,
                TextFormField(
                  controller: _stateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapV24,
                FilledButton(
                  onPressed: _saving ? null : () => _save(biz),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
