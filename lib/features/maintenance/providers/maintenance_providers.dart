import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/models/maintenance_occurrence.dart';
import '../../../shared/models/maintenance_plan.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/maintenance_repository.dart';
import '../../reminders/providers/reminder_providers.dart';

/// Maps recurrence interval settings to the Postgres-constrained `frequency_type` enum.
String resolveMaintenanceFrequencyType({
  required bool isOneTime,
  required int intervalValue,
  required String intervalUnit,
}) {
  if (isOneTime) return 'one_time';
  final unit = intervalUnit.toLowerCase();
  if (unit == 'months' && intervalValue == 1) return 'monthly';
  if (unit == 'months' && intervalValue == 3) return 'quarterly';
  if (unit == 'months' && intervalValue == 6) return 'half_yearly';
  if (unit == 'years' && intervalValue == 1) return 'yearly';
  return 'custom';
}

/// Filter tab for maintenance occurrences overview.
enum MaintenanceOccurrenceFilter { all, dueToday, overdue, upcoming, completed }

/// Filter tab for maintenance plans list.
enum MaintenancePlanFilter { all, active, paused, completed, cancelled }

/// Provider for occurrence filter selection.
final occurrenceFilterProvider =
    StateProvider.autoDispose<MaintenanceOccurrenceFilter>(
      (ref) => MaintenanceOccurrenceFilter.all,
    );

/// Provider for plan filter selection.
final planFilterProvider = StateProvider.autoDispose<MaintenancePlanFilter>(
  (ref) => MaintenancePlanFilter.all,
);

/// Provider for search query on plans or occurrences.
final maintenanceSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Provider for maintenance metrics count summary.
final maintenanceOverviewCountsProvider =
    FutureProvider.autoDispose<MaintenanceOverviewCounts>((ref) async {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) return const MaintenanceOverviewCounts();

      final repo = ref.watch(maintenanceRepositoryProvider);
      return repo.getMaintenanceOverviewCounts(business.id);
    });

/// Provider supplying list of occurrences based on the current filter.
final maintenanceOccurrencesListProvider =
    FutureProvider.autoDispose<List<MaintenanceOccurrence>>((ref) async {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) return const [];

      final filter = ref.watch(occurrenceFilterProvider);
      final repo = ref.watch(maintenanceRepositoryProvider);

      String filterStr;
      switch (filter) {
        case MaintenanceOccurrenceFilter.dueToday:
          filterStr = 'today';
          break;
        case MaintenanceOccurrenceFilter.overdue:
          filterStr = 'overdue';
          break;
        case MaintenanceOccurrenceFilter.upcoming:
          filterStr = 'upcoming';
          break;
        case MaintenanceOccurrenceFilter.completed:
          filterStr = 'completed';
          break;
        case MaintenanceOccurrenceFilter.all:
          filterStr = 'all';
          break;
      }

      return repo.getMaintenanceOccurrences(
        businessId: business.id,
        filter: filterStr,
      );
    });

/// Provider supplying list of maintenance plans.
final maintenancePlansListProvider =
    FutureProvider.autoDispose<List<MaintenancePlan>>((ref) async {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) return const [];

      final filter = ref.watch(planFilterProvider);
      final query = ref.watch(maintenanceSearchQueryProvider);
      final repo = ref.watch(maintenanceRepositoryProvider);

      String? statusStr;
      switch (filter) {
        case MaintenancePlanFilter.active:
          statusStr = 'active';
          break;
        case MaintenancePlanFilter.paused:
          statusStr = 'paused';
          break;
        case MaintenancePlanFilter.completed:
          statusStr = 'completed';
          break;
        case MaintenancePlanFilter.cancelled:
          statusStr = 'cancelled';
          break;
        case MaintenancePlanFilter.all:
          statusStr = 'all';
          break;
      }

      return repo.getMaintenancePlans(
        businessId: business.id,
        status: statusStr,
        searchQuery: query.isNotEmpty ? query : null,
      );
    });

/// Provider for single maintenance occurrence detail.
final maintenanceOccurrenceDetailProvider = FutureProvider.autoDispose
    .family<MaintenanceOccurrence?, String>((ref, id) async {
      final repo = ref.watch(maintenanceRepositoryProvider);
      return repo.getMaintenanceOccurrenceById(id);
    });

/// Provider for single maintenance plan detail.
final maintenancePlanDetailProvider = FutureProvider.autoDispose
    .family<MaintenancePlan?, String>((ref, id) async {
      final repo = ref.watch(maintenanceRepositoryProvider);
      return repo.getMaintenancePlanById(id);
    });

/// Provider for customer-specific maintenance history (completed visits).
final customerMaintenanceHistoryProvider = FutureProvider.autoDispose
    .family<List<MaintenanceOccurrence>, String>((ref, customerId) async {
      final repo = ref.watch(maintenanceRepositoryProvider);
      return repo.getCustomerMaintenanceHistory(customerId);
    });

/// Provider for customer-specific maintenance plans.
final customerMaintenancePlansProvider = FutureProvider.autoDispose
    .family<List<MaintenancePlan>, String>((ref, customerId) async {
      final repo = ref.watch(maintenanceRepositoryProvider);
      return repo.getMaintenancePlans(customerId: customerId, status: 'all');
    });

/// Form state for creating or editing a Maintenance Plan.
class MaintenancePlanFormState {
  final Customer? customer;
  final Equipment? equipment;
  final String title;
  final String maintenanceType;
  final String
  frequencyType; // 'one_time', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'custom'
  final int intervalValue;
  final String intervalUnit;
  final DateTime startDate;
  final DateTime? endDate;
  final int reminderDaysBefore;
  final String notes;
  final bool isLoading;
  final String? errorMessage;

  const MaintenancePlanFormState({
    this.customer,
    this.equipment,
    this.title = '',
    this.maintenanceType = 'routine',
    this.frequencyType = 'monthly',
    this.intervalValue = 1,
    this.intervalUnit = 'months',
    required this.startDate,
    this.endDate,
    this.reminderDaysBefore = 3,
    this.notes = '',
    this.isLoading = false,
    this.errorMessage,
  });

  MaintenancePlanFormState copyWith({
    Customer? customer,
    Equipment? equipment,
    bool clearEquipment = false,
    String? title,
    String? maintenanceType,
    String? frequencyType,
    int? intervalValue,
    String? intervalUnit,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    int? reminderDaysBefore,
    String? notes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MaintenancePlanFormState(
      customer: customer ?? this.customer,
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      title: title ?? this.title,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      frequencyType: frequencyType ?? this.frequencyType,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller for creating or editing maintenance plans.
class MaintenancePlanFormNotifier
    extends StateNotifier<MaintenancePlanFormState> {
  final Ref _ref;

  MaintenancePlanFormNotifier(this._ref, [MaintenancePlan? initialPlan])
    : super(
        MaintenancePlanFormState(
          customer: initialPlan?.customer,
          equipment: initialPlan?.equipment,
          title: initialPlan?.title ?? '',
          maintenanceType: initialPlan?.maintenanceType ?? 'routine',
          frequencyType: (initialPlan?.frequencyType == 'recurring')
              ? resolveMaintenanceFrequencyType(
                  isOneTime: false,
                  intervalValue: initialPlan?.intervalValue ?? 1,
                  intervalUnit: initialPlan?.intervalUnit ?? 'months',
                )
              : (initialPlan?.frequencyType ?? 'monthly'),
          intervalValue: initialPlan?.intervalValue ?? 1,
          intervalUnit: initialPlan?.intervalUnit ?? 'months',
          startDate:
              initialPlan?.startDate ??
              DateTime.now().add(const Duration(days: 30)),
          endDate: initialPlan?.endDate,
          reminderDaysBefore: initialPlan?.reminderDaysBefore ?? 3,
          notes: initialPlan?.notes ?? '',
        ),
      );

  void setCustomer(Customer customer) {
    state = state.copyWith(customer: customer, clearEquipment: true);
  }

  void setEquipment(Equipment? equipment) {
    if (equipment == null) {
      state = state.copyWith(clearEquipment: true);
    } else {
      state = state.copyWith(equipment: equipment);
    }
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setMaintenanceType(String type) {
    state = state.copyWith(maintenanceType: type);
  }

  void setFrequencyType(String freq) {
    final normalized = (freq == 'one_time')
        ? 'one_time'
        : (freq == 'recurring'
              ? resolveMaintenanceFrequencyType(
                  isOneTime: false,
                  intervalValue: state.intervalValue,
                  intervalUnit: state.intervalUnit,
                )
              : freq);
    state = state.copyWith(frequencyType: normalized);
  }

  void setInterval(int value, String unit) {
    final safeVal = value < 1 ? 1 : value;
    final nextFreq = state.frequencyType == 'one_time'
        ? 'one_time'
        : resolveMaintenanceFrequencyType(
            isOneTime: false,
            intervalValue: safeVal,
            intervalUnit: unit,
          );
    state = state.copyWith(
      frequencyType: nextFreq,
      intervalValue: safeVal,
      intervalUnit: unit,
    );
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void setEndDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearEndDate: true);
    } else {
      state = state.copyWith(endDate: date);
    }
  }

  void setReminderDaysBefore(int days) {
    state = state.copyWith(reminderDaysBefore: days);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<MaintenancePlan?> submit({MaintenancePlan? existingPlan}) async {
    if (state.customer == null) {
      state = state.copyWith(errorMessage: 'Please select a customer.');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final business = await _ref.read(currentBusinessProvider.future);
      if (business == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Active business session not found.',
        );
        return null;
      }

      final repo = _ref.read(maintenanceRepositoryProvider);
      final dbFrequencyType = resolveMaintenanceFrequencyType(
        isOneTime: state.frequencyType == 'one_time',
        intervalValue: state.intervalValue,
        intervalUnit: state.intervalUnit,
      );

      final defaultLabel = switch (state.maintenanceType) {
        'routine' => 'Routine Maintenance',
        'periodic' => 'Periodic Checkup',
        'seasonal' => 'Seasonal Maintenance',
        'inspection' => 'Inspection Visit',
        _ => 'Maintenance Plan',
      };
      final computedTitle = state.title.trim().isNotEmpty
          ? state.title.trim()
          : (state.equipment != null
                ? '${state.equipment!.name} Maintenance'
                : '$defaultLabel — ${state.customer!.fullName}');

      if (existingPlan != null) {
        final updatedPlan = existingPlan.copyWith(
          customerId: state.customer!.id,
          equipmentId: state.equipment?.id,
          title: computedTitle,
          maintenanceType: state.maintenanceType,
          frequencyType: dbFrequencyType,
          intervalValue: dbFrequencyType == 'one_time'
              ? null
              : state.intervalValue,
          intervalUnit: state.intervalUnit,
          startDate: state.startDate,
          endDate: dbFrequencyType == 'one_time' ? null : state.endDate,
          reminderDaysBefore: state.reminderDaysBefore,
          notes: state.notes,
        );
        final res = await repo.updateMaintenancePlan(updatedPlan);
        _ref.invalidate(maintenancePlansListProvider);
        _ref.invalidate(maintenanceOccurrencesListProvider);
        _ref.invalidate(maintenanceOverviewCountsProvider);
        _ref.invalidate(maintenancePlanDetailProvider(existingPlan.id));
        _ref.invalidate(filteredRemindersProvider);
        _ref.invalidate(remindersOverviewStatsProvider);
        state = state.copyWith(isLoading: false);
        return res;
      } else {
        final newPlan = MaintenancePlan(
          id: '',
          businessId: business.id,
          customerId: state.customer!.id,
          equipmentId: state.equipment?.id,
          planNumber: '',
          title: computedTitle,
          maintenanceType: state.maintenanceType,
          frequencyType: dbFrequencyType,
          intervalValue: dbFrequencyType == 'one_time'
              ? null
              : state.intervalValue,
          intervalUnit: state.intervalUnit,
          startDate: state.startDate,
          endDate: dbFrequencyType == 'one_time' ? null : state.endDate,
          nextDueDate: state.startDate,
          reminderDaysBefore: state.reminderDaysBefore,
          anchorDay: state.startDate.day,
          status: 'active',
          notes: state.notes.isNotEmpty ? state.notes : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final res = await repo.createMaintenancePlan(newPlan);
        _ref.invalidate(maintenancePlansListProvider);
        _ref.invalidate(maintenanceOccurrencesListProvider);
        _ref.invalidate(maintenanceOverviewCountsProvider);
        _ref.invalidate(filteredRemindersProvider);
        _ref.invalidate(remindersOverviewStatsProvider);
        state = state.copyWith(isLoading: false);
        return res;
      }
    } catch (e, stack) {
      Logger.error('Failed to save maintenance plan: $e', stack);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

/// Provider for the maintenance plan form controller.
final maintenancePlanFormControllerProvider = StateNotifierProvider.autoDispose
    .family<
      MaintenancePlanFormNotifier,
      MaintenancePlanFormState,
      MaintenancePlan?
    >((ref, initialPlan) {
      return MaintenancePlanFormNotifier(ref, initialPlan);
    });
