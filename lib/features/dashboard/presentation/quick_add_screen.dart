import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/widgets.dart';

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  DateTime? _selectedDate = DateTime.now();
  String? _selectedCategory = 'AC Servicing';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickAddTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            l10n.quickAddSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV24,

          // Quick category choice
          YbDropdown<String>(
            label: 'Service Category',
            value: _selectedCategory,
            items: const [
              DropdownMenuItem(
                value: 'AC Servicing',
                child: Text('AC & HVAC Service'),
              ),
              DropdownMenuItem(
                value: 'CCTV Installation',
                child: Text('CCTV & Security'),
              ),
              DropdownMenuItem(
                value: 'RO Purifier',
                child: Text('RO & Water Purifier'),
              ),
              DropdownMenuItem(
                value: 'Appliance Repair',
                child: Text('Appliance Repair'),
              ),
            ],
            onChanged: (val) {
              setState(() => _selectedCategory = val);
            },
          ),
          AppSpacing.gapV16,

          // Customer Name
          YbTextInput(
            label: 'Customer Name',
            hint: l10n.sampleCustomerName,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
          AppSpacing.gapV16,

          // Phone Number
          YbTextInput(
            label: 'Mobile Number',
            hint: '+91 98250 00000',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
          ),
          AppSpacing.gapV16,

          // Service Date Picker
          YbDatePickerField(
            label: 'Service / Due Date',
            selectedDate: _selectedDate,
            onDateSelected: (newDate) {
              setState(() => _selectedDate = newDate);
            },
          ),
          AppSpacing.gapV24,

          // Primary save button
          YbPrimaryButton(
            label: l10n.actionSave,
            onPressed: () {
              YbConfirmDialog.show(
                context,
                title: l10n.confirmDialogTitle,
                message: l10n.confirmDialogDefaultMessage,
                confirmLabel: l10n.actionSave,
                cancelLabel: l10n.actionCancel,
              );
            },
          ),
          AppSpacing.gapV12,

          // Secondary cancel button
          YbSecondaryButton(
            label: l10n.actionCancel,
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          AppSpacing.gapV32,
        ],
      ),
    );
  }
}
