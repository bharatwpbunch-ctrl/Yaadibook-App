import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../utils/date_formatter.dart';

/// Form date picker input field.
class YbDatePickerField extends StatelessWidget {
  final String? label;
  final String? hint;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const YbDatePickerField({
    super.key,
    this.label,
    this.hint,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled || onDateSelected == null) return;

    final now = DateTime.now();
    final initial = selectedDate ?? now;
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2035);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = selectedDate != null
        ? DateFormatter.formatShort(selectedDate!)
        : (hint ?? 'Select Date');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV8,
        ],
        InkWell(
          onTap: enabled ? () => _pickDate(context) : null,
          borderRadius: AppRadii.borderMd,
          child: Container(
            height: AppSpacing.minTouchTarget,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceVariant,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: selectedDate != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
