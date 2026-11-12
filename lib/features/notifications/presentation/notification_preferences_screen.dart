import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../shared/models/notification_preferences.dart';
import '../providers/notification_providers.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _isInitialized = false;
  bool _isSaving = false;

  late bool _pushEnabled;
  late bool _maintEnabled;
  late bool _amcEnabled;
  late bool _followupEnabled;
  late bool _generalEnabled;
  late List<int> _maintAdvanceDays;
  late List<int> _amcAdvanceDays;
  late bool _quietHoursEnabled;
  late TimeOfDay _quietHoursStart;
  late TimeOfDay _quietHoursEnd;
  late TimeOfDay _preferredDailyTime;

  void _initFromPrefs(NotificationPreferences prefs) {
    if (_isInitialized) return;
    _pushEnabled = prefs.pushNotificationsEnabled;
    _maintEnabled = prefs.maintenanceNotificationsEnabled;
    _amcEnabled = prefs.amcNotificationsEnabled;
    _followupEnabled = prefs.followupNotificationsEnabled;
    _generalEnabled = prefs.generalNotificationsEnabled;
    _maintAdvanceDays = List.from(prefs.maintenanceAdvanceDays);
    _amcAdvanceDays = List.from(prefs.amcAdvanceDays);
    _quietHoursEnabled = prefs.quietHoursEnabled;
    _quietHoursStart = _parseTime(prefs.quietHoursStart);
    _quietHoursEnd = _parseTime(prefs.quietHoursEnd);
    _preferredDailyTime = _parseTime(prefs.preferredNotificationTime);
    _isInitialized = true;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationPreferencesTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: FilledButton(
            onPressed: _isSaving
                ? null
                : () => _savePreferences(prefsAsync.value),
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
      body: prefsAsync.when(
        data: (prefs) {
          if (prefs == null) {
            return const Center(child: Text('Failed to load preferences'));
          }

          _initFromPrefs(prefs);

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // 1. Push Notifications Master Switch
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: SwitchListTile(
                  title: Text(
                    l10n.notificationPreferencesPushEnabled,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    l10n.notificationPreferencesPushSubtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _pushEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final messenger = ScaffoldMessenger.of(context);
                      final granted = await PushNotificationService.instance
                          .requestPermission();
                      if (!granted && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enable notification permissions in device settings.',
                            ),
                          ),
                        );
                      }
                    }
                    setState(() => _pushEnabled = val);
                  },
                ),
              ),
              AppSpacing.gapV16,

              // 2. Reminder Category Toggles
              Card(
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
                      Text(
                        l10n.notificationPreferencesCategoriesHeader,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationPreferencesMaintenance),
                        value: _maintEnabled,
                        onChanged: (v) => setState(() => _maintEnabled = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationPreferencesAmc),
                        value: _amcEnabled,
                        onChanged: (v) => setState(() => _amcEnabled = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationPreferencesFollowups),
                        value: _followupEnabled,
                        onChanged: (v) => setState(() => _followupEnabled = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationPreferencesGeneral),
                        value: _generalEnabled,
                        onChanged: (v) => setState(() => _generalEnabled = v),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapV16,

              // 3. Advance Reminder Offsets
              Card(
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
                      const Text(
                        'Advance Notification Days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapV8,
                      const Text(
                        'Maintenance Visits:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapV4,
                      Wrap(
                        spacing: 8,
                        children: [7, 3, 1, 0].map((d) {
                          final selected = _maintAdvanceDays.contains(d);
                          return FilterChip(
                            label: Text(
                              d == 0 ? 'Day of Visit' : '$d days before',
                            ),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _maintAdvanceDays.add(d);
                                } else {
                                  _maintAdvanceDays.remove(d);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      AppSpacing.gapV12,
                      const Text(
                        'AMC Expirations:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapV4,
                      Wrap(
                        spacing: 8,
                        children: [30, 15, 7, 1, 0].map((d) {
                          final selected = _amcAdvanceDays.contains(d);
                          return FilterChip(
                            label: Text(
                              d == 0 ? 'Expiry Day' : '$d days before',
                            ),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _amcAdvanceDays.add(d);
                                } else {
                                  _amcAdvanceDays.remove(d);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapV16,

              // 4. Quiet Hours & Daily Timing Card
              Card(
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.notificationPreferencesQuietHours,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          l10n.notificationPreferencesQuietHoursSubtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _quietHoursEnabled,
                        onChanged: (v) =>
                            setState(() => _quietHoursEnabled = v),
                      ),
                      if (_quietHoursEnabled) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.notificationPreferencesQuietHoursStart,
                                ),
                                subtitle: Text(
                                  _quietHoursStart.format(context),
                                ),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _quietHoursStart,
                                  );
                                  if (t != null) {
                                    setState(() => _quietHoursStart = t);
                                  }
                                },
                              ),
                            ),
                            AppSpacing.gapH12,
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.notificationPreferencesQuietHoursEnd,
                                ),
                                subtitle: Text(_quietHoursEnd.format(context)),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _quietHoursEnd,
                                  );
                                  if (t != null) {
                                    setState(() => _quietHoursEnd = t);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24, color: AppColors.borderSubtle),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationPreferencesPreferredTime),
                        subtitle: Text(_preferredDailyTime.format(context)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _preferredDailyTime,
                          );
                          if (t != null) {
                            setState(() => _preferredDailyTime = t);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapV32,
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }

  Future<void> _savePreferences(NotificationPreferences? original) async {
    if (original == null) return;

    setState(() => _isSaving = true);

    final updated = original.copyWith(
      pushNotificationsEnabled: _pushEnabled,
      maintenanceNotificationsEnabled: _maintEnabled,
      amcNotificationsEnabled: _amcEnabled,
      followupNotificationsEnabled: _followupEnabled,
      generalNotificationsEnabled: _generalEnabled,
      maintenanceAdvanceDays: _maintAdvanceDays,
      amcAdvanceDays: _amcAdvanceDays,
      quietHoursEnabled: _quietHoursEnabled,
      quietHoursStart: _formatTime(_quietHoursStart),
      quietHoursEnd: _formatTime(_quietHoursEnd),
      preferredNotificationTime: _formatTime(_preferredDailyTime),
    );

    final success = await ref
        .read(notificationControllerProvider.notifier)
        .updatePreferences(updated);

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings updated!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update settings')),
        );
      }
    }
  }
}
