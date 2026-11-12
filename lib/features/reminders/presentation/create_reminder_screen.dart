import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../customers/providers/customer_providers.dart';
import '../providers/reminder_providers.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;
  final String? initialServiceId;
  final String? initialCategory;

  const CreateReminderScreen({
    super.key,
    this.initialCustomerId,
    this.initialServiceId,
    this.initialCategory,
  });

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  Customer? _selectedCustomer;
  String _selectedCategory = 'general_task';
  String _selectedPriority = 'normal';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadInitialCustomer();
  }

  Future<void> _loadInitialCustomer() async {
    if (widget.initialCustomerId != null) {
      final custRepo = ref.read(customerRepositoryProvider);
      final cust = await custRepo.getCustomerById(widget.initialCustomerId!);
      if (mounted && cust != null) {
        setState(() {
          _selectedCustomer = cust;
          if (_selectedCategory == 'general_task') {
            _selectedCategory = 'customer_followup';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersCreateTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveReminder,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.actionSave),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '${l10n.remindersTitleLabel} *',
                hintText: l10n.remindersTitleHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit_note_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a reminder title';
                }
                return null;
              },
            ),
            AppSpacing.gapV16,

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '${l10n.remindersDateLabel} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormatter.formatDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.remindersTimeLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.access_time_outlined),
                      ),
                      child: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapV16,

            // Optional Customer Picker
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.remindersCustomerLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: _selectedCustomer != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _selectedCustomer = null);
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: _openCustomerPicker,
                      ),
              ),
              child: InkWell(
                onTap: _openCustomerPicker,
                child: Text(
                  _selectedCustomer != null
                      ? '${_selectedCustomer!.fullName} (${_selectedCustomer!.primaryPhone})'
                      : 'None (General Business Task)',
                  style: TextStyle(
                    color: _selectedCustomer != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: _selectedCustomer != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            AppSpacing.gapV16,

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: l10n.remindersCategoryLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                DropdownMenuItem(
                  value: 'general_task',
                  child: Text(l10n.remindersCategoryGeneral),
                ),
                DropdownMenuItem(
                  value: 'customer_followup',
                  child: Text(l10n.remindersCategoryFollowup),
                ),
                DropdownMenuItem(
                  value: 'call_customer',
                  child: Text(l10n.remindersCategoryCall),
                ),
                DropdownMenuItem(
                  value: 'payment_followup',
                  child: Text(l10n.remindersCategoryPayment),
                ),
                DropdownMenuItem(
                  value: 'visit_customer',
                  child: Text(l10n.remindersCategoryVisit),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(l10n.remindersCategoryOther),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            AppSpacing.gapV16,

            // Priority Segmented Button
            Text(
              l10n.remindersPriorityLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapV8,
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'low',
                  label: Text(l10n.remindersPriorityLow),
                ),
                ButtonSegment(
                  value: 'normal',
                  label: Text(l10n.remindersPriorityNormal),
                ),
                ButtonSegment(
                  value: 'high',
                  label: Text(l10n.remindersPriorityHigh),
                ),
                ButtonSegment(
                  value: 'urgent',
                  label: Text(l10n.remindersPriorityUrgent),
                ),
              ],
              selected: {_selectedPriority},
              onSelectionChanged: (val) {
                setState(() => _selectedPriority = val.first);
              },
            ),
            AppSpacing.gapV16,

            // Description / Notes
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.remindersDescriptionLabel,
                hintText: l10n.remindersDescriptionHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            AppSpacing.gapV32,
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _openCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) => _CustomerPickerSheet(
        onSelected: (customer) {
          setState(() {
            _selectedCustomer = customer;
            if (_selectedCategory == 'general_task') {
              _selectedCategory = 'customer_followup';
            }
          });
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final business = ref.read(currentBusinessProvider).value;
    if (business == null) return;

    final dueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSaving = true);

    final reminderType = _selectedCustomer != null ? 'follow_up' : 'general';

    final created = await ref
        .read(reminderFormControllerProvider.notifier)
        .createReminder(
          businessId: business.id,
          customerId: _selectedCustomer?.id,
          serviceId: widget.initialServiceId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          reminderType: reminderType,
          category: _selectedCategory,
          priority: _selectedPriority,
          dueAt: dueDateTime,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.remindersCreateSuccess)),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create reminder')),
        );
      }
    }
  }
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<Customer> onSelected;

  const _CustomerPickerSheet({required this.onSelected});

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = customers.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  return c.fullName.toLowerCase().contains(_searchQuery) ||
                      c.primaryPhone.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final cust = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          cust.fullName.isNotEmpty
                              ? cust.fullName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(cust.fullName),
                      subtitle: Text(cust.primaryPhone),
                      onTap: () => widget.onSelected(cust),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
