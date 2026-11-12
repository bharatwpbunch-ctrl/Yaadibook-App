import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/models/service_activity.dart';
import '../../../shared/models/service_entry.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/service_repository.dart';

/// Provider for service filter selection.
final serviceFilterProvider = StateProvider.autoDispose<ServiceFilter>(
  (ref) => ServiceFilter.all,
);

/// Provider for service sort selection.
final serviceSortProvider = StateProvider.autoDispose<ServiceSort>(
  (ref) => ServiceSort.recentlyCreated,
);

/// Provider for service search query.
final serviceSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Provider supplying the list of service entries based on active filters, search, and sort.
final servicesListProvider = FutureProvider.autoDispose<List<ServiceEntry>>((
  ref,
) async {
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return const [];

  final filter = ref.watch(serviceFilterProvider);
  final sort = ref.watch(serviceSortProvider);
  final query = ref.watch(serviceSearchQueryProvider);

  final repo = ref.watch(serviceRepositoryProvider);
  return repo.getServiceEntries(
    businessId: business.id,
    filter: filter,
    sort: sort,
    searchQuery: query,
  );
});

/// Provider supplying business-wide service statistics.
final servicesSummaryProvider =
    FutureProvider.autoDispose<ServiceSummaryCounts>((ref) async {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) return const ServiceSummaryCounts();

      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getServiceSummaryCounts(business.id);
    });

/// Provider supplying recent services (e.g. for overview screen or dashboard).
final recentServicesProvider = FutureProvider.autoDispose<List<ServiceEntry>>((
  ref,
) async {
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return const [];

  final repo = ref.watch(serviceRepositoryProvider);
  return repo.getServiceEntries(
    businessId: business.id,
    filter: ServiceFilter.all,
    sort: ServiceSort.recentlyCreated,
    limit: 5,
  );
});

/// Provider supplying pending services for overview / focus.
final pendingServicesListProvider =
    FutureProvider.autoDispose<List<ServiceEntry>>((ref) async {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) return const [];

      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getServiceEntries(
        businessId: business.id,
        filter: ServiceFilter.pending,
        sort: ServiceSort.newestDate,
        limit: 5,
      );
    });

/// Provider supplying single service entry by ID.
final serviceDetailProvider = FutureProvider.autoDispose
    .family<ServiceEntry?, String>((ref, id) async {
      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getServiceEntryById(id);
    });

/// Provider supplying service history for a specific customer.
final customerServiceHistoryProvider = FutureProvider.autoDispose
    .family<List<ServiceEntry>, String>((ref, customerId) async {
      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getCustomerServiceHistory(customerId);
    });

/// Provider supplying service count summary for a customer.
final customerServiceCountsProvider = FutureProvider.autoDispose
    .family<ServiceSummaryCounts, String>((ref, customerId) async {
      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getCustomerServiceCounts(customerId);
    });

/// Provider supplying optional equipment registered for a customer.
final customerEquipmentListProvider = FutureProvider.autoDispose
    .family<List<Equipment>, String>((ref, customerId) async {
      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getCustomerEquipment(customerId);
    });

/// Provider supplying activity timeline for a service.
final serviceActivitiesProvider = FutureProvider.autoDispose
    .family<List<ServiceActivity>, String>((ref, serviceId) async {
      final repo = ref.watch(serviceRepositoryProvider);
      return repo.getServiceActivities(serviceId);
    });

/// Model representing a locally picked attachment prior to upload.
class PendingAttachment {
  final String fileName;
  final List<int> bytes;
  final String? mimeType;
  final String? localPath;

  const PendingAttachment({
    required this.fileName,
    required this.bytes,
    this.mimeType,
    this.localPath,
  });
}

/// State for the Add / Edit Service Form.
class ServiceFormState {
  final Customer? selectedCustomer;
  final String? customerAddressId;
  final String? equipmentId;
  final String serviceType;
  final String title;
  final String description;
  final String workPerformed;
  final DateTime serviceDate;
  final String status;
  final double? serviceAmount;
  final double additionalCharges;
  final double discountAmount;
  final String notes;
  final List<PendingAttachment> pendingAttachments;
  final bool isLoading;
  final String? errorMessage;

  ServiceFormState({
    this.selectedCustomer,
    this.customerAddressId,
    this.equipmentId,
    this.serviceType = 'general',
    this.title = '',
    this.description = '',
    this.workPerformed = '',
    DateTime? serviceDate,
    this.status = 'pending',
    this.serviceAmount,
    this.additionalCharges = 0.0,
    this.discountAmount = 0.0,
    this.notes = '',
    this.pendingAttachments = const [],
    this.isLoading = false,
    this.errorMessage,
  }) : serviceDate = serviceDate ?? DateTime.now();

  double get computedTotal {
    final base = serviceAmount ?? 0.0;
    final total = base + additionalCharges - discountAmount;
    return total < 0 ? 0.0 : total;
  }

  ServiceFormState copyWith({
    Customer? selectedCustomer,
    String? customerAddressId,
    String? equipmentId,
    String? serviceType,
    String? title,
    String? description,
    String? workPerformed,
    DateTime? serviceDate,
    String? status,
    double? serviceAmount,
    double? additionalCharges,
    double? discountAmount,
    String? notes,
    List<PendingAttachment>? pendingAttachments,
    bool? isLoading,
    String? errorMessage,
    bool clearCustomer = false,
    bool clearEquipment = false,
  }) {
    return ServiceFormState(
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      customerAddressId: customerAddressId ?? this.customerAddressId,
      equipmentId: clearEquipment ? null : (equipmentId ?? this.equipmentId),
      serviceType: serviceType ?? this.serviceType,
      title: title ?? this.title,
      description: description ?? this.description,
      workPerformed: workPerformed ?? this.workPerformed,
      serviceDate: serviceDate ?? this.serviceDate,
      status: status ?? this.status,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      pendingAttachments: pendingAttachments ?? this.pendingAttachments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller managing Service Form validation, attachment queue, and submission.
class ServiceFormController extends StateNotifier<ServiceFormState> {
  final IServiceRepository _serviceRepo;

  ServiceFormController(this._serviceRepo, [ServiceEntry? initialEntry])
    : super(
        initialEntry != null
            ? ServiceFormState(
                selectedCustomer: initialEntry.customer,
                customerAddressId: initialEntry.customerAddressId,
                equipmentId: initialEntry.equipmentId,
                serviceType: initialEntry.serviceType,
                title: initialEntry.title,
                description: initialEntry.description ?? '',
                workPerformed: initialEntry.workPerformed ?? '',
                serviceDate: initialEntry.serviceDate,
                status: initialEntry.status,
                serviceAmount: initialEntry.serviceAmount,
                additionalCharges: initialEntry.additionalCharges,
                discountAmount: initialEntry.discountAmount,
                notes: initialEntry.notes ?? '',
              )
            : ServiceFormState(),
      );

  void selectCustomer(Customer customer) {
    state = state.copyWith(
      selectedCustomer: customer,
      customerAddressId: customer.primaryAddress?.id,
      clearEquipment: true,
      errorMessage: null,
    );
  }

  void selectAddress(String? addressId) {
    state = state.copyWith(customerAddressId: addressId);
  }

  void selectEquipment(String? equipmentId) {
    state = state.copyWith(
      equipmentId: equipmentId,
      clearEquipment: equipmentId == null,
    );
  }

  void updateServiceType(String type) {
    state = state.copyWith(serviceType: type);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  void updateDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void updateWorkPerformed(String work) {
    state = state.copyWith(workPerformed: work);
  }

  void updateServiceDate(DateTime date) {
    state = state.copyWith(serviceDate: date);
  }

  void updateStatus(String status) {
    state = state.copyWith(status: status);
  }

  void updateServiceAmount(double? amount) {
    state = state.copyWith(serviceAmount: amount, errorMessage: null);
  }

  void updateAdditionalCharges(double charges) {
    state = state.copyWith(additionalCharges: charges, errorMessage: null);
  }

  void updateDiscountAmount(double discount) {
    state = state.copyWith(discountAmount: discount, errorMessage: null);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void addPendingAttachment(PendingAttachment attachment) {
    final updated = List<PendingAttachment>.from(state.pendingAttachments)
      ..add(attachment);
    state = state.copyWith(pendingAttachments: updated);
  }

  void removePendingAttachment(int index) {
    if (index >= 0 && index < state.pendingAttachments.length) {
      final updated = List<PendingAttachment>.from(state.pendingAttachments)
        ..removeAt(index);
      state = state.copyWith(pendingAttachments: updated);
    }
  }

  /// Validates and submits a new service entry.
  Future<ServiceEntry?> submitCreate(String businessId) async {
    if (state.selectedCustomer == null) {
      state = state.copyWith(errorMessage: 'Please select a customer');
      return null;
    }
    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter service title');
      return null;
    }

    // Amount validations
    final base = state.serviceAmount ?? 0.0;
    if (base < 0 || state.additionalCharges < 0 || state.discountAmount < 0) {
      state = state.copyWith(errorMessage: 'Amounts cannot be negative');
      return null;
    }
    final subtotal = base + state.additionalCharges;
    if (state.discountAmount > subtotal) {
      state = state.copyWith(
        errorMessage: 'Discount cannot exceed subtotal (₹$subtotal)',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newEntry = ServiceEntry(
        id: '', // Database will allocate UUID
        businessId: businessId,
        customerId: state.selectedCustomer!.id,
        customerAddressId: state.customerAddressId,
        equipmentId: state.equipmentId,
        serviceType: state.serviceType,
        title: state.title.trim(),
        description: state.description.trim().isNotEmpty
            ? state.description.trim()
            : null,
        workPerformed: state.workPerformed.trim().isNotEmpty
            ? state.workPerformed.trim()
            : null,
        serviceDate: state.serviceDate,
        status: state.status,
        serviceAmount: state.serviceAmount,
        additionalCharges: state.additionalCharges,
        discountAmount: state.discountAmount,
        totalAmount: state.computedTotal,
        notes: state.notes.trim().isNotEmpty ? state.notes.trim() : null,
        completedAt: state.status == 'completed' ? DateTime.now() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _serviceRepo.createServiceEntry(newEntry);

      // Upload any queued attachments
      if (state.pendingAttachments.isNotEmpty) {
        for (final att in state.pendingAttachments) {
          try {
            await _serviceRepo.addServiceAttachment(
              businessId: businessId,
              serviceId: created.id,
              fileName: att.fileName,
              fileBytes: att.bytes,
              mimeType: att.mimeType,
            );
          } catch (attErr) {
            // Non-blocking attachment error
          }
        }
      }

      state = state.copyWith(isLoading: false);
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create service: $e',
      );
      return null;
    }
  }

  /// Validates and submits edits to an existing service entry.
  Future<ServiceEntry?> submitUpdate(ServiceEntry existing) async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter service title');
      return null;
    }

    // Amount validations
    final base = state.serviceAmount ?? 0.0;
    if (base < 0 || state.additionalCharges < 0 || state.discountAmount < 0) {
      state = state.copyWith(errorMessage: 'Amounts cannot be negative');
      return null;
    }
    final subtotal = base + state.additionalCharges;
    if (state.discountAmount > subtotal) {
      state = state.copyWith(
        errorMessage: 'Discount cannot exceed subtotal (₹$subtotal)',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedEntry = existing.copyWith(
        title: state.title.trim(),
        serviceType: state.serviceType,
        customerAddressId: state.customerAddressId,
        equipmentId: state.equipmentId,
        description: state.description.trim().isNotEmpty
            ? state.description.trim()
            : null,
        workPerformed: state.workPerformed.trim().isNotEmpty
            ? state.workPerformed.trim()
            : null,
        serviceDate: state.serviceDate,
        status: state.status,
        serviceAmount: state.serviceAmount,
        additionalCharges: state.additionalCharges,
        discountAmount: state.discountAmount,
        totalAmount: state.computedTotal,
        notes: state.notes.trim().isNotEmpty ? state.notes.trim() : null,
        completedAt: state.status == 'completed'
            ? (existing.completedAt ?? DateTime.now())
            : null,
        updatedAt: DateTime.now(),
      );

      final result = await _serviceRepo.updateServiceEntry(updatedEntry);

      // Upload any newly added attachments
      if (state.pendingAttachments.isNotEmpty) {
        for (final att in state.pendingAttachments) {
          try {
            await _serviceRepo.addServiceAttachment(
              businessId: existing.businessId,
              serviceId: existing.id,
              fileName: att.fileName,
              fileBytes: att.bytes,
              mimeType: att.mimeType,
            );
          } catch (_) {}
        }
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update service: $e',
      );
      return null;
    }
  }
}

final serviceFormControllerProvider = StateNotifierProvider.autoDispose
    .family<ServiceFormController, ServiceFormState, ServiceEntry?>((
      ref,
      entry,
    ) {
      final repo = ref.watch(serviceRepositoryProvider);
      return ServiceFormController(repo, entry);
    });
