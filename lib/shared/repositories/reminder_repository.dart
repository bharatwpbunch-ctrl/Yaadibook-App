import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/reminder.dart';

abstract class IReminderRepository {
  Future<List<Reminder>> getReminders({
    String? status,
    bool includeCompleted = false,
  });
  Future<Reminder?> getReminderById(String id);
  Future<Reminder> createReminder(Reminder reminder);
  Future<void> markCompleted(String id);
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
    bool includeCompleted = false,
  }) async {
    try {
      var query = _safeClient.from('reminders').select();

      if (!includeCompleted) {
        query = query.neq('status', 'completed');
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query.order('due_at', ascending: true);
      return (data as List<dynamic>)
          .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
          .toList();
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
          .select()
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
      final data = await _safeClient
          .from('reminders')
          .insert(reminder.toJson())
          .select()
          .single();
      return Reminder.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.createReminder failed', e, stack);
      throw AppStorageException('Failed to create reminder: $e');
    }
  }

  @override
  Future<void> markCompleted(String id) async {
    try {
      await _safeClient
          .from('reminders')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e, stack) {
      AppLogger.error('ReminderRepository.markCompleted failed', e, stack);
      throw AppStorageException('Failed to mark reminder completed: $e');
    }
  }
}
