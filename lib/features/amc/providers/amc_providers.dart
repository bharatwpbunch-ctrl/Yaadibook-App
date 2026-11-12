import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/amc_contract.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/amc_repository.dart';
import '../../reminders/providers/reminder_providers.dart';

/// Filter selection for AMC contracts.
enum AmcFilter { all, active, expiring, expired, renewed, cancelled }

/// Provider for AMC filter selection.
final amcFilterProvider = StateProvider.autoDispose<AmcFilter>(
  (ref) => AmcFilter.all,
);

/// Provider for AMC search query.
final amcSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider for AMC overview metrics summary.
final amcOverviewCountsProvider = FutureProvider.autoDispose<AmcOverviewCounts>(
  (ref) async {
    final business = await ref.watch(currentBusinessProvider.future);
    if (business == null) return const AmcOverviewCounts();

    final repo = ref.watch(amcRepositoryProvider);
    return repo.getAmcOverviewCounts(business.id);
  },
);

/// Provider for AMC contracts list based on active filter and search.
final amcContractsListProvider = FutureProvider.autoDispose<List<AmcContract>>((
  ref,
) async {
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return const [];

  final filter = ref.watch(amcFilterProvider);
  final query = ref.watch(amcSearchQueryProvider);
  final repo = ref.watch(amcRepositoryProvider);

  String? statusStr;
  switch (filter) {
    case AmcFilter.active:
      statusStr = 'active';
      break;
    case AmcFilter.expiring:
      statusStr = 'expiring';
      break;
    case AmcFilter.expired:
      statusStr = 'expired';
      break;
    case AmcFilter.renewed:
      statusStr = 'renewed';
      break;
    case AmcFilter.cancelled:
      statusStr = 'cancelled';
      break;
    case AmcFilter.all:
      statusStr = 'all';
      break;
  }

  return repo.getAmcContracts(
    businessId: business.id,
    status: statusStr,
    searchQuery: query.isNotEmpty ? query : null,
  );
});

/// Provider for single AMC contract detail.
final amcContractDetailProvider = FutureProvider.autoDispose
    .family<AmcContract?, String>((ref, id) async {
      final repo = ref.watch(amcRepositoryProvider);
      return repo.getAmcContractById(id);
    });

/// Provider for customer AMC contracts.
final customerAmcListProvider = FutureProvider.autoDispose
    .family<List<AmcContract>, String>((ref, customerId) async {
      final repo = ref.watch(amcRepositoryProvider);
      return repo.getCustomerAmcContracts(customerId);
    });

/// Form state for creating, editing, or renewing AMC contracts.
class AmcFormState {
  final Customer? customer;
  final Equipment? equipment;
  final String contractTitle;
  final DateTime startDate;
  final DateTime endDate;
  final double contractAmount;
  final int? numberOfVisits;
  final int reminderDaysBefore;
  final String includedServices;
  final String excludedServices;
  final String specialTerms;
  final String renewalTerms;
  final String notes;
  final bool isLoading;
  final String? errorMessage;

  const AmcFormState({
    this.customer,
    this.equipment,
    this.contractTitle = '',
    required this.startDate,
    required this.endDate,
    this.contractAmount = 0.0,
    this.numberOfVisits,
    this.reminderDaysBefore = 15,
    this.includedServices = '',
    this.excludedServices = '',
    this.specialTerms = '',
    this.renewalTerms = '',
    this.notes = '',
    this.isLoading = false,
    this.errorMessage,
  });

  AmcFormState copyWith({
    Customer? customer,
    Equipment? equipment,
    bool clearEquipment = false,
    String? contractTitle,
    DateTime? startDate,
    DateTime? endDate,
    double? contractAmount,
    int? numberOfVisits,
    bool clearNumberOfVisits = false,
    int? reminderDaysBefore,
    String? includedServices,
    String? excludedServices,
    String? specialTerms,
    String? renewalTerms,
    String? notes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AmcFormState(
      customer: customer ?? this.customer,
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      contractTitle: contractTitle ?? this.contractTitle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contractAmount: contractAmount ?? this.contractAmount,
      numberOfVisits: clearNumberOfVisits
          ? null
          : (numberOfVisits ?? this.numberOfVisits),
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      includedServices: includedServices ?? this.includedServices,
      excludedServices: excludedServices ?? this.excludedServices,
      specialTerms: specialTerms ?? this.specialTerms,
      renewalTerms: renewalTerms ?? this.renewalTerms,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller for creating, updating, or renewing AMC contracts.
class AmcFormNotifier extends StateNotifier<AmcFormState> {
  final Ref _ref;

  AmcFormNotifier(this._ref, [AmcContract? initialContract])
    : super(
        AmcFormState(
          customer: initialContract?.customer,
          equipment: initialContract?.equipment,
          contractTitle: initialContract?.contractTitle ?? '',
          startDate: initialContract?.startDate ?? DateTime.now(),
          endDate:
              initialContract?.endDate ??
              DateTime(
                DateTime.now().year + 1,
                DateTime.now().month,
                DateTime.now().day,
              ),
          contractAmount: initialContract?.contractAmount ?? 0.0,
          numberOfVisits: initialContract?.numberOfVisits,
          includedServices: initialContract?.includedServices ?? '',
          excludedServices: initialContract?.excludedServices ?? '',
          specialTerms: initialContract?.specialTerms ?? '',
          renewalTerms: initialContract?.renewalTerms ?? '',
          notes: initialContract?.notes ?? '',
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

  void setContractTitle(String title) {
    state = state.copyWith(contractTitle: title);
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void setEndDate(DateTime date) {
    state = state.copyWith(endDate: date);
  }

  void setContractAmount(double amount) {
    state = state.copyWith(contractAmount: amount);
  }

  void setNumberOfVisits(int? visits) {
    if (visits == null) {
      state = state.copyWith(clearNumberOfVisits: true);
    } else {
      state = state.copyWith(numberOfVisits: visits);
    }
  }

  void setIncludedServices(String value) {
    state = state.copyWith(includedServices: value);
  }

  void setExcludedServices(String value) {
    state = state.copyWith(excludedServices: value);
  }

  void setSpecialTerms(String value) {
    state = state.copyWith(specialTerms: value);
  }

  void setRenewalTerms(String value) {
    state = state.copyWith(renewalTerms: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void setReminderDaysBefore(int days) {
    state = state.copyWith(reminderDaysBefore: days < 0 ? 0 : days);
  }

  Future<AmcContract?> submit({AmcContract? existingContract}) async {
    if (state.customer == null) {
      state = state.copyWith(errorMessage: 'Please select a customer.');
      return null;
    }

    if (state.contractTitle.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a contract title.');
      return null;
    }

    if (state.endDate.isBefore(state.startDate)) {
      state = state.copyWith(
        errorMessage: 'End date must be after or on start date.',
      );
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

      final repo = _ref.read(amcRepositoryProvider);

      if (existingContract != null) {
        final updated = existingContract.copyWith(
          customerId: state.customer!.id,
          equipmentId: state.equipment?.id,
          contractTitle: state.contractTitle.trim(),
          startDate: state.startDate,
          endDate: state.endDate,
          contractAmount: state.contractAmount,
          numberOfVisits: state.numberOfVisits,
          includedServices: state.includedServices.isNotEmpty
              ? state.includedServices
              : null,
          excludedServices: state.excludedServices.isNotEmpty
              ? state.excludedServices
              : null,
          specialTerms: state.specialTerms.isNotEmpty
              ? state.specialTerms
              : null,
          renewalTerms: state.renewalTerms.isNotEmpty
              ? state.renewalTerms
              : null,
          notes: state.notes.isNotEmpty ? state.notes : null,
        );

        final res = await repo.updateAmcContract(updated);
        _ref.invalidate(amcContractsListProvider);
        _ref.invalidate(amcOverviewCountsProvider);
        _ref.invalidate(amcContractDetailProvider(existingContract.id));
        state = state.copyWith(isLoading: false);
        return res;
      } else {
        final newContract = AmcContract(
          id: '',
          businessId: business.id,
          customerId: state.customer!.id,
          equipmentId: state.equipment?.id,
          contractNumber: '',
          contractTitle: state.contractTitle.trim(),
          startDate: state.startDate,
          endDate: state.endDate,
          contractAmount: state.contractAmount,
          numberOfVisits: state.numberOfVisits,
          includedServices: state.includedServices.isNotEmpty
              ? state.includedServices
              : null,
          excludedServices: state.excludedServices.isNotEmpty
              ? state.excludedServices
              : null,
          specialTerms: state.specialTerms.isNotEmpty
              ? state.specialTerms
              : null,
          renewalTerms: state.renewalTerms.isNotEmpty
              ? state.renewalTerms
              : null,
          notes: state.notes.isNotEmpty ? state.notes : null,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final res = await repo.createAmcContract(
          newContract,
          reminderDaysBefore: state.reminderDaysBefore,
        );
        _ref.invalidate(amcContractsListProvider);
        _ref.invalidate(amcOverviewCountsProvider);
        _ref.invalidate(filteredRemindersProvider);
        _ref.invalidate(remindersOverviewStatsProvider);
        state = state.copyWith(isLoading: false);
        return res;
      }
    } catch (e, stack) {
      Logger.error('Failed to save AMC contract: $e', stack);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<String?> submitRenewal({required String previousContractId}) async {
    if (state.endDate.isBefore(state.startDate)) {
      state = state.copyWith(
        errorMessage: 'Renewal end date must be after start date.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = _ref.read(amcRepositoryProvider);
      final newContractId = await repo.renewAmcContract(
        previousContractId: previousContractId,
        newStartDate: state.startDate,
        newEndDate: state.endDate,
        contractAmount: state.contractAmount,
        contractTitle: state.contractTitle.trim(),
        numberOfVisits: state.numberOfVisits,
        includedServices: state.includedServices.isNotEmpty
            ? state.includedServices
            : null,
        excludedServices: state.excludedServices.isNotEmpty
            ? state.excludedServices
            : null,
        specialTerms: state.specialTerms.isNotEmpty ? state.specialTerms : null,
        notes: state.notes.isNotEmpty ? state.notes : null,
      );

      _ref.invalidate(amcContractsListProvider);
      _ref.invalidate(amcOverviewCountsProvider);
      _ref.invalidate(amcContractDetailProvider(previousContractId));
      _ref.invalidate(filteredRemindersProvider);
      _ref.invalidate(remindersOverviewStatsProvider);
      state = state.copyWith(isLoading: false);
      return newContractId;
    } catch (e, stack) {
      Logger.error('Failed to renew AMC contract: $e', stack);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

/// Provider for AMC contract form controller.
final amcFormControllerProvider = StateNotifierProvider.autoDispose
    .family<AmcFormNotifier, AmcFormState, AmcContract?>((
      ref,
      initialContract,
    ) {
      return AmcFormNotifier(ref, initialContract);
    });
