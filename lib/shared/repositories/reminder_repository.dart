import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/reminder.dart';

class ReminderOverviewStats {
  final int dueToday;
  final int overdue;
  final int upcoming;
  final int completed;

  const ReminderOverviewStats({
    this.dueToday = 0,
    this.overdue = 0,
    this.upcoming = 0,
    this.completed = 0,
  });
}

abstract class IReminderRepository {
  Future<List<Reminder>> getReminders({
    String? status,
    String? type,
    String? category,
    String? customerId,
    bool includeCompleted = false,
  });
  Future<Reminder?> getReminderById(String id);
  Future<Reminder> createReminder(Reminder reminder);
  Future<Reminder> updateReminder(Reminder reminder);
  Future<void> snoozeReminder(String id, DateTime snoozeUntil);
  Future<void> completeReminder(String id, {String? notes});
  Future<void> markCompleted(String id);
  Future<void> cancelReminder(String id);
  Future<ReminderOverviewStats> getOverviewStats();
}

class SupabaseReminderRepository implements IReminderRepository {
  final SupabaseClient? _client;

  SupabaseReminderRepository([this._client]);

  SupabaseClient get _safeClient {
    final client = _client;
    if (client == null) {
      throw const AppStorageException('Supabase client is not initialized');
    }
    return client;
  }

  @override
  Future<List<Reminder>> getReminders({
    String? status,
    String? type,
    String? category,
    String? customerId,
    bool includeCompleted = false,
  }) async {
    try {
      dynamic query = _safeClient
          .from('reminders')
          .select('*, customers(full_name, primary_phone)');

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }

      final data = await query.order('due_at', ascending: true);
      var reminders = (data as List<dynamic>)
          .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
          .toList();

      // Exclude completed reminders unless explicitly included or requested
      if (!includeCompleted && (status == null || status != 'completed')) {
        reminders = reminders.where((r) => !r.isCompleted).toList();
      }

      // Filter by dynamic status category matching UI overview counters
      if (status != null && status != 'all') {
        reminders = reminders.where((r) {
          switch (status) {
            case 'today':
              return !r.isOverdue && r.isDueToday;
            case 'overdue':
              return r.isOverdue;
            case 'upcoming':
              return !r.isOverdue && r.isUpcoming;
            case 'completed':
              return r.isCompleted;
            default:
              return r.status == status;
          }
        }).toList();
      }

      // Filter by source type (maintenance, amc, follow_up, general)
      if (type != null && type != 'all') {
        reminders = reminders.where((r) => r.reminderType == type).toList();
      }

      return reminders;
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.getReminders failed', e, stack);
      throw AppStorageException('Failed to load reminders: $e');
    }
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    try {
      final data = await _safeClient
          .from('reminders')
          .select('*, customers(full_name, primary_phone)')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Reminder.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.getReminderById failed', e, stack);
      throw AppStorageException('Failed to load reminder: $e');
    }
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    try {
      final map = reminder.toJson();
      map.remove('id'); // let postgres generate UUID
      map.remove('created_at');
      map.remove('updated_at');

      final data = await _safeClient
          .from('reminders')
          .insert(map)
          .select('*, customers(full_name, primary_phone)')
          .single();

      final created = Reminder.fromJson(data);

      // Schedule notification queue entry for general reminder
      try {
        await _safeClient.from('notification_queue').insert({
          'business_id': created.businessId,
          'user_id': _safeClient.auth.currentUser?.id,
          'reminder_id': created.id,
          'idempotency_key':
              'rem_${created.id}_due_${created.dueAt.millisecondsSinceEpoch}',
          'notification_type': created.reminderType,
          'title': created.title,
          'body': created.description ?? 'Reminder due now',
          'scheduled_for': created.dueAt.toIso8601String(),
          'payload': {'reminder_id': created.id},
        });
      } catch (queueErr) {
        AppLogger.warning(
          'Failed to schedule notification queue entry: $queueErr',
        );
      }

      return created;
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.createReminder failed', e, stack);
      throw AppStorageException('Failed to create reminder: $e');
    }
  }

  @override
  Future<Reminder> updateReminder(Reminder reminder) async {
    try {
      final map = reminder.toJson();
      map.remove('created_at');
      map['updated_at'] = DateTime.now().toIso8601String();

      final data = await _safeClient
          .from('reminders')
          .update(map)
          .eq('id', reminder.id)
          .select('*, customers(full_name, primary_phone)')
          .single();

      return Reminder.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.updateReminder failed', e, stack);
      throw AppStorageException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> snoozeReminder(String id, DateTime snoozeUntil) async {
    try {
      // Try calling stored procedure snooze_reminder
      try {
        await _safeClient.rpc(
          'snooze_reminder',
          params: {
            'p_reminder_id': id,
            'p_snooze_until': snoozeUntil.toIso8601String(),
          },
        );
        return;
      } catch (_) {
        // Fallback to direct table updates if RPC is pending
        await _safeClient
            .from('reminders')
            .update({
              'status': 'snoozed',
              'snoozed_until': snoozeUntil.toIso8601String(),
              'due_at': snoozeUntil.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);

        // Cancel previous queue and insert new queue entry
        await _safeClient
            .from('notification_queue')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('reminder_id', id)
            .eq('status', 'queued');

        final rem = await getReminderById(id);
        if (rem != null) {
          await _safeClient.from('notification_queue').insert({
            'business_id': rem.businessId,
            'user_id': _safeClient.auth.currentUser?.id,
            'reminder_id': id,
            'idempotency_key':
                'rem_${id}_snooze_${snoozeUntil.millisecondsSinceEpoch}',
            'notification_type': rem.reminderType,
            'title': rem.title,
            'body': rem.description ?? 'Snoozed reminder due now',
            'scheduled_for': snoozeUntil.toIso8601String(),
            'payload': {'reminder_id': id, 'is_snoozed': true},
          });
        }
      }
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.snoozeReminder failed', e, stack);
      throw AppStorageException('Failed to snooze reminder: $e');
    }
  }

  @override
  Future<void> completeReminder(String id, {String? notes}) async {
    try {
      try {
        await _safeClient.rpc(
          'complete_reminder',
          params: {'p_reminder_id': id, 'p_notes': notes},
        );
        return;
      } catch (_) {
        await _safeClient
            .from('reminders')
            .update({
              'status': 'completed',
              'completed_at': DateTime.now().toIso8601String(),
              'completed_notes': notes,
              'completed_by_user_id': _safeClient.auth.currentUser?.id,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);

        await _safeClient
            .from('notification_queue')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('reminder_id', id)
            .eq('status', 'queued');
      }
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.completeReminder failed', e, stack);
      throw AppStorageException('Failed to complete reminder: $e');
    }
  }

  @override
  Future<void> markCompleted(String id) => completeReminder(id);

  @override
  Future<void> cancelReminder(String id) async {
    try {
      await _safeClient
          .from('reminders')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      await _safeClient
          .from('notification_queue')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('reminder_id', id)
          .eq('status', 'queued');
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.cancelReminder failed', e, stack);
      throw AppStorageException('Failed to cancel reminder: $e');
    }
  }

  @override
  Future<ReminderOverviewStats> getOverviewStats() async {
    try {
      final all = await getReminders(includeCompleted: true);
      int dueToday = 0;
      int overdue = 0;
      int upcoming = 0;
      int completed = 0;

      for (final r in all) {
        if (r.isCompleted) {
          completed++;
        } else if (r.isOverdue) {
          overdue++;
        } else if (r.isDueToday) {
          dueToday++;
        } else if (r.isUpcoming) {
          upcoming++;
        }
      }

      return ReminderOverviewStats(
        dueToday: dueToday,
        overdue: overdue,
        upcoming: upcoming,
        completed: completed,
      );
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.getOverviewStats failed', e, stack);
      return const ReminderOverviewStats();
    }
  }
}
