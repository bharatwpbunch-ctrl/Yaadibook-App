import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/providers/backend_providers.dart';

class DayOperatingHours {
  final String day;
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  const DayOperatingHours({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  DayOperatingHours copyWith({
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return DayOperatingHours(
      day: day,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'isOpen': isOpen,
    'openHour': openTime.hour,
    'openMinute': openTime.minute,
    'closeHour': closeTime.hour,
    'closeMinute': closeTime.minute,
  };

  factory DayOperatingHours.fromJson(Map<String, dynamic> json) {
    return DayOperatingHours(
      day: json['day'] as String? ?? 'Monday',
      isOpen: json['isOpen'] as bool? ?? true,
      openTime: TimeOfDay(
        hour: (json['openHour'] as int?) ?? 9,
        minute: (json['openMinute'] as int?) ?? 0,
      ),
      closeTime: TimeOfDay(
        hour: (json['closeHour'] as int?) ?? 19,
        minute: (json['closeMinute'] as int?) ?? 0,
      ),
    );
  }

  static List<DayOperatingHours> defaults() => const [
    DayOperatingHours(
      day: 'Monday',
      isOpen: true,
      openTime: TimeOfDay(hour: 9, minute: 0),
      closeTime: TimeOfDay(hour: 19, minute: 0),
    ),
    DayOperatingHours(
      day: 'Tuesday',
      isOpen: true,
      openTime: TimeOfDay(hour: 9, minute: 0),
      closeTime: TimeOfDay(hour: 19, minute: 0),
    ),
    DayOperatingHours(
      day: 'Wednesday',
      isOpen: true,
      openTime: TimeOfDay(hour: 9, minute: 0),
      closeTime: TimeOfDay(hour: 19, minute: 0),
    ),
    DayOperatingHours(
      day: 'Thursday',
      isOpen: true,
      openTime: TimeOfDay(hour: 9, minute: 0),
      closeTime: TimeOfDay(hour: 19, minute: 0),
    ),
    DayOperatingHours(
      day: 'Friday',
      isOpen: true,
      openTime: TimeOfDay(hour: 9, minute: 0),
      closeTime: TimeOfDay(hour: 19, minute: 0),
    ),
    DayOperatingHours(
      day: 'Saturday',
      isOpen: true,
      openTime: TimeOfDay(hour: 9, minute: 0),
      closeTime: TimeOfDay(hour: 18, minute: 0),
    ),
    DayOperatingHours(
      day: 'Sunday',
      isOpen: false,
      openTime: TimeOfDay(hour: 10, minute: 0),
      closeTime: TimeOfDay(hour: 14, minute: 0),
    ),
  ];
}

class OperatingHoursScreen extends ConsumerStatefulWidget {
  const OperatingHoursScreen({super.key});

  @override
  ConsumerState<OperatingHoursScreen> createState() =>
      _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends ConsumerState<OperatingHoursScreen> {
  List<DayOperatingHours> _schedule = DayOperatingHours.defaults();
  bool _loading = true;
  bool _saving = false;
  String? _loadedBusinessId;

  String _storageKey(String? businessId) =>
      'operating_hours_${businessId ?? 'default'}';

  Future<void> _loadForBusiness(String? businessId) async {
    if (_loadedBusinessId == businessId && !_loading) return;
    _loadedBusinessId = businessId;
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.read(_storageKey(businessId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final parsed = decoded
            .map((e) => DayOperatingHours.fromJson(e as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) {
          _schedule = parsed;
        }
      }
    } catch (_) {
      // Keep default schedule cleanly if local storage is unavailable
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save(String? businessId) async {
    setState(() => _saving = true);
    try {
      final storage = ref.read(secureStorageProvider);
      final encoded = jsonEncode(_schedule.map((d) => d.toJson()).toList());
      await storage.write(_storageKey(businessId), encoded);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operating hours saved.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save operating hours: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({required int index, required bool isOpenTime}) async {
    final current = _schedule[index];
    final initial = isOpenTime ? current.openTime : current.closeTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      final updated = List<DayOperatingHours>.from(_schedule);
      updated[index] = isOpenTime
          ? current.copyWith(openTime: picked)
          : current.copyWith(closeTime: picked);
      _schedule = updated;
    });
  }

  void _applyWeekdayHoursToAllOpenDays() {
    final monday = _schedule.first;
    setState(() {
      _schedule = _schedule.map((d) {
        if (!d.isOpen) return d;
        return d.copyWith(
          openTime: monday.openTime,
          closeTime: monday.closeTime,
        );
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applied Monday hours to all open days.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider).valueOrNull;
    if (_loading) {
      _loadForBusiness(business?.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operating Hours'),
        actions: [
          TextButton(
            onPressed: _applyWeekdayHoursToAllOpenDays,
            child: const Text('Copy Mon'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Text(
                  'Set your weekly working hours so your team and customers know when ${business?.businessName ?? 'your business'} is available.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapV16,
                ...List.generate(_schedule.length, (index) {
                  final item = _schedule[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.day,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                AppSpacing.gapV4,
                                if (item.isOpen)
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      ActionChip(
                                        label: Text(
                                          item.openTime.format(context),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _pickTime(
                                          index: index,
                                          isOpenTime: true,
                                        ),
                                      ),
                                      const Text(
                                        'to',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      ActionChip(
                                        label: Text(
                                          item.closeTime.format(context),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _pickTime(
                                          index: index,
                                          isOpenTime: false,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Text(
                                    'Closed',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Switch(
                            value: item.isOpen,
                            onChanged: (val) {
                              setState(() {
                                final updated = List<DayOperatingHours>.from(
                                  _schedule,
                                );
                                updated[index] = item.copyWith(isOpen: val);
                                _schedule = updated;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                AppSpacing.gapV24,
                FilledButton(
                  onPressed: _saving ? null : () => _save(business?.id),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Operating Hours'),
                ),
              ],
            ),
    );
  }
}
