import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/reminder.dart';
import '../providers/reminder_providers.dart';

class EditReminderScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const EditReminderScreen({super.key, required this.reminderId});

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'general_task';
  String _selectedPriority = 'normal';
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _initFields(Reminder reminder) {
    if (_isInitialized) return;
    _titleController.text = reminder.title;
    _descriptionController.text = reminder.description ?? '';
    _selectedDate = reminder.dueAt;
    _selectedTime = TimeOfDay.fromDateTime(reminder.dueAt);
    _selectedCategory = reminder.category;
    _selectedPriority = reminder.priority;
    _isInitialized = true;
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
    final reminderAsync = ref.watch(reminderDetailProvider(widget.reminderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersEditTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: FilledButton(
            onPressed: _isSaving
                ? null
                : () => _saveChanges(reminderAsync.value),
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
      body: reminderAsync.when(
        data: (reminder) {
          if (reminder == null) {
            return const Center(child: Text('Reminder not found'));
          }

          _initFields(reminder);

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '${l10n.remindersTitleLabel} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a title';
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
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          child: Text(
                            DateFormatter.formatDate(
                              _selectedDate ?? DateTime.now(),
                            ),
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
                            _selectedTime?.format(context) ?? '09:00 AM',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV16,

                // Category
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

                // Priority
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

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.remindersDescriptionLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveChanges(Reminder? original) async {
    if (original == null || !_formKey.currentState!.validate()) return;

    final date = _selectedDate ?? original.dueAt;
    final time = _selectedTime ?? TimeOfDay.fromDateTime(original.dueAt);
    final dueDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() => _isSaving = true);

    final updated = original.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      dueAt: dueDateTime,
    );

    final res = await ref
        .read(reminderFormControllerProvider.notifier)
        .updateReminder(updated);

    setState(() => _isSaving = false);

    if (mounted) {
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.remindersUpdateSuccess)),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update reminder')),
        );
      }
    }
  }
}
