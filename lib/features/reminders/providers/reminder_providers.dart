import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/reminder.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/reminder_repository.dart';

/// Filter status for Reminders Overview screen: 'all', 'today', 'upcoming', 'overdue', 'completed'
final reminderStatusFilterProvider = StateProvider<String>((ref) => 'today');

/// Source filter for Reminders Overview screen: 'all', 'maintenance', 'amc', 'follow_up', 'general'
final reminderSourceFilterProvider = StateProvider<String>((ref) => 'all');

/// Provider for 4 summary card metric counters (Due Today, Overdue, Upcoming, Completed)
final remindersOverviewStatsProvider = FutureProvider<ReminderOverviewStats>((
  ref,
) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getOverviewStats();
});

/// Provider for list of reminders based on active status & source filters
final filteredRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  final status = ref.watch(reminderStatusFilterProvider);
  final source = ref.watch(reminderSourceFilterProvider);

  return repo.getReminders(
    status: status,
    type: source == 'all' ? null : source,
    includeCompleted: status == 'completed' || status == 'all',
  );
});

/// Provider for single reminder detail by ID
final reminderDetailProvider = FutureProvider.family<Reminder?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getReminderById(id);
});

/// Provider for customer-specific reminders and follow-ups
final customerRemindersProvider = FutureProvider.family<List<Reminder>, String>(
  (ref, customerId) async {
    final repo = ref.watch(reminderRepositoryProvider);
    return repo.getReminders(customerId: customerId, includeCompleted: true);
  },
);

/// Controller for creating, editing, snoozing, and completing reminders
class ReminderFormState {
  final bool isLoading;
  final String? errorMessage;
  final Reminder? reminder;

  const ReminderFormState({
    this.isLoading = false,
    this.errorMessage,
    this.reminder,
  });

  ReminderFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    Reminder? reminder,
  }) {
    return ReminderFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      reminder: reminder ?? this.reminder,
    );
  }
}

class ReminderFormController extends StateNotifier<ReminderFormState> {
  final IReminderRepository _repository;
  final Ref _ref;

  ReminderFormController(this._repository, this._ref)
    : super(const ReminderFormState());

  Future<Reminder?> createReminder({
    required String businessId,
    String? customerId,
    String? maintenanceOccurrenceId,
    String? amcContractId,
    String? serviceId,
    required String title,
    String? description,
    String reminderType = 'general',
    String category = 'general_task',
    String priority = 'normal',
    required DateTime dueAt,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newReminder = Reminder(
        id: '',
        businessId: businessId,
        customerId: customerId,
        maintenanceOccurrenceId: maintenanceOccurrenceId,
        amcContractId: amcContractId,
        serviceId: serviceId,
        title: title,
        description: description,
        reminderType: reminderType,
        category: category,
        priority: priority,
        dueAt: dueAt,
        status: 'scheduled',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _repository.createReminder(newReminder);
      state = state.copyWith(isLoading: false, reminder: created);
      _invalidateProviders();
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<Reminder?> updateReminder(Reminder reminder) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateReminder(reminder);
      state = state.copyWith(isLoading: false, reminder: updated);
      _invalidateProviders();
      _ref.invalidate(reminderDetailProvider(reminder.id));
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> snoozeReminder(String id, DateTime snoozeUntil) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.snoozeReminder(id, snoozeUntil);
      state = state.copyWith(isLoading: false);
      _invalidateProviders();
      _ref.invalidate(reminderDetailProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> completeReminder(String id, {String? notes}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.completeReminder(id, notes: notes);
      state = state.copyWith(isLoading: false);
      _invalidateProviders();
      _ref.invalidate(reminderDetailProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cancelReminder(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.cancelReminder(id);
      state = state.copyWith(isLoading: false);
      _invalidateProviders();
      _ref.invalidate(reminderDetailProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(remindersOverviewStatsProvider);
    _ref.invalidate(filteredRemindersProvider);
  }
}

final reminderFormControllerProvider =
    StateNotifierProvider<ReminderFormController, ReminderFormState>((ref) {
      final repo = ref.watch(reminderRepositoryProvider);
      return ReminderFormController(repo, ref);
    });
