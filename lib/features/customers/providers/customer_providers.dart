import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/contacts_service.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/repositories/customer_repository.dart';
import '../models/customer_activity_item.dart';

/// Provider for Contacts Service.
final contactsServiceProvider = Provider<IContactsService>((ref) {
  return DeviceContactsService();
});

/// Active search query in Customers screen.
final customerSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Active filter in Customers screen (Active, Archived, All).
final customerFilterProvider = StateProvider.autoDispose<CustomerFilter>(
  (ref) => CustomerFilter.active,
);

/// Active sort order in Customers screen (Recently added, Name A-Z, Name Z-A).
final customerSortProvider = StateProvider.autoDispose<CustomerSort>(
  (ref) => CustomerSort.recentlyAdded,
);

/// Provider supplying the list of customers based on business, search query, filter, and sort.
final customersListProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) async {
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return const [];

  final searchQuery = ref.watch(customerSearchQueryProvider);
  final filter = ref.watch(customerFilterProvider);
  final sort = ref.watch(customerSortProvider);

  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers(
    searchQuery: searchQuery,
    filter: filter,
    sort: sort,
  );
});

/// Provider supplying a single customer's full details by ID.
final customerDetailProvider = FutureProvider.autoDispose
    .family<Customer?, String>((ref, id) async {
      final repo = ref.watch(customerRepositoryProvider);
      return repo.getCustomerById(id);
    });

/// Provider supplying the customer's chronological activity timeline.
final customerActivityProvider = FutureProvider.autoDispose
    .family<List<CustomerActivityItem>, Customer>((ref, customer) async {
      final repo = ref.watch(customerRepositoryProvider);
      return repo.getCustomerActivity(customer);
    });

/// State model for the Add / Edit Customer form.
class CustomerFormState {
  final String fullName;
  final String primaryPhone;
  final String alternatePhone;
  final String email;
  final String customerType; // 'individual' or 'business'
  final String addressLine1;
  final String addressLine2;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String notes;
  final bool isLoading;
  final String? errorMessage;
  final Customer? duplicateWarningCustomer;

  const CustomerFormState({
    this.fullName = '',
    this.primaryPhone = '',
    this.alternatePhone = '',
    this.email = '',
    this.customerType = 'individual',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.area = '',
    this.city = 'Ahmedabad',
    this.state = 'Gujarat',
    this.postalCode = '',
    this.notes = '',
    this.isLoading = false,
    this.errorMessage,
    this.duplicateWarningCustomer,
  });

  CustomerFormState copyWith({
    String? fullName,
    String? primaryPhone,
    String? alternatePhone,
    String? email,
    String? customerType,
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? state,
    String? postalCode,
    String? notes,
    bool? isLoading,
    String? errorMessage,
    Customer? duplicateWarningCustomer,
    bool clearDuplicate = false,
  }) {
    return CustomerFormState(
      fullName: fullName ?? this.fullName,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      customerType: customerType ?? this.customerType,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      duplicateWarningCustomer: clearDuplicate
          ? null
          : (duplicateWarningCustomer ?? this.duplicateWarningCustomer),
    );
  }
}

/// Controller managing customer form state and persistence.
class CustomerFormController extends StateNotifier<CustomerFormState> {
  final ICustomerRepository _customerRepo;

  CustomerFormController(this._customerRepo, [Customer? initialCustomer])
    : super(
        initialCustomer != null
            ? CustomerFormState(
                fullName: initialCustomer.fullName,
                primaryPhone: initialCustomer.primaryPhone,
                alternatePhone: initialCustomer.alternatePhone ?? '',
                email: initialCustomer.email ?? '',
                customerType: initialCustomer.customerType,
                addressLine1:
                    initialCustomer.primaryAddress?.addressLine1 ?? '',
                addressLine2:
                    initialCustomer.primaryAddress?.addressLine2 ?? '',
                area: initialCustomer.primaryAddress?.area ?? '',
                city: initialCustomer.primaryAddress?.city ?? 'Ahmedabad',
                state: initialCustomer.primaryAddress?.state ?? 'Gujarat',
                postalCode: initialCustomer.primaryAddress?.postalCode ?? '',
                notes: initialCustomer.notes ?? '',
              )
            : const CustomerFormState(),
      );

  void updateFullName(String val) =>
      state = state.copyWith(fullName: val, errorMessage: null);

  void updatePrimaryPhone(String val) =>
      state = state.copyWith(primaryPhone: val, errorMessage: null);

  void updateAlternatePhone(String val) =>
      state = state.copyWith(alternatePhone: val);

  void updateEmail(String val) => state = state.copyWith(email: val);

  void updateCustomerType(String val) =>
      state = state.copyWith(customerType: val);

  void updateAddressLine1(String val) =>
      state = state.copyWith(addressLine1: val);

  void updateAddressLine2(String val) =>
      state = state.copyWith(addressLine2: val);

  void updateArea(String val) => state = state.copyWith(area: val);

  void updateCity(String val) => state = state.copyWith(city: val);

  void updateState(String val) => state = state.copyWith(state: val);

  void updatePostalCode(String val) => state = state.copyWith(postalCode: val);

  void updateNotes(String val) => state = state.copyWith(notes: val);

  void clearDuplicateWarning() => state = state.copyWith(clearDuplicate: true);

  /// Checks whether the primary phone number matches an existing customer in this business.
  Future<Customer?> checkDuplicate(
    String businessId, {
    String? excludeCustomerId,
  }) async {
    if (state.primaryPhone.trim().isEmpty) return null;
    final duplicate = await _customerRepo.checkDuplicatePhone(
      businessId,
      state.primaryPhone.trim(),
      excludeCustomerId: excludeCustomerId,
    );
    if (duplicate != null) {
      state = state.copyWith(duplicateWarningCustomer: duplicate);
    }
    return duplicate;
  }

  /// Validates and saves a new customer. Returns created Customer on success.
  Future<Customer?> submitCreate(String businessId) async {
    if (state.fullName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter customer name');
      return null;
    }
    if (state.primaryPhone.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter mobile number');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final customer = await _customerRepo.createCustomer(
        businessId: businessId,
        fullName: state.fullName.trim(),
        primaryPhone: state.primaryPhone.trim(),
        alternatePhone: state.alternatePhone.trim().isNotEmpty
            ? state.alternatePhone.trim()
            : null,
        email: state.email.trim().isNotEmpty ? state.email.trim() : null,
        customerType: state.customerType,
        notes: state.notes.trim().isNotEmpty ? state.notes.trim() : null,
        addressLine1: state.addressLine1.trim().isNotEmpty
            ? state.addressLine1.trim()
            : null,
        addressLine2: state.addressLine2.trim().isNotEmpty
            ? state.addressLine2.trim()
            : null,
        area: state.area.trim().isNotEmpty ? state.area.trim() : null,
        city: state.city.trim().isNotEmpty ? state.city.trim() : null,
        state: state.state.trim().isNotEmpty ? state.state.trim() : null,
        postalCode: state.postalCode.trim().isNotEmpty
            ? state.postalCode.trim()
            : null,
      );

      state = state.copyWith(isLoading: false);
      return customer;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create customer: $e',
      );
      return null;
    }
  }

  /// Validates and saves edits for an existing customer. Returns updated Customer on success.
  Future<Customer?> submitUpdate(Customer existingCustomer) async {
    if (state.fullName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter customer name');
      return null;
    }
    if (state.primaryPhone.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter mobile number');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updated = existingCustomer.copyWith(
        fullName: state.fullName.trim(),
        primaryPhone: state.primaryPhone.trim(),
        alternatePhone: state.alternatePhone.trim().isNotEmpty
            ? state.alternatePhone.trim()
            : null,
        email: state.email.trim().isNotEmpty ? state.email.trim() : null,
        customerType: state.customerType,
        notes: state.notes.trim().isNotEmpty ? state.notes.trim() : null,
      );

      final result = await _customerRepo.updateCustomer(
        updated,
        addressLine1: state.addressLine1.trim(),
        addressLine2: state.addressLine2.trim(),
        area: state.area.trim(),
        city: state.city.trim(),
        state: state.state.trim(),
        postalCode: state.postalCode.trim(),
      );

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update customer: $e',
      );
      return null;
    }
  }
}

final customerFormControllerProvider = StateNotifierProvider.autoDispose
    .family<CustomerFormController, CustomerFormState, Customer?>((
      ref,
      customer,
    ) {
      final repo = ref.watch(customerRepositoryProvider);
      return CustomerFormController(repo, customer);
    });

/// State for the Contact Import screen.
class ContactImportState {
  final bool isLoading;
  final PermissionStatus permissionStatus;
  final List<DeviceContact> contacts;
  final String searchQuery;
  final Set<String> selectedContactIds;
  final String? errorMessage;

  const ContactImportState({
    this.isLoading = false,
    this.permissionStatus = PermissionStatus.denied,
    this.contacts = const [],
    this.searchQuery = '',
    this.selectedContactIds = const {},
    this.errorMessage,
  });

  ContactImportState copyWith({
    bool? isLoading,
    PermissionStatus? permissionStatus,
    List<DeviceContact>? contacts,
    String? searchQuery,
    Set<String>? selectedContactIds,
    String? errorMessage,
  }) {
    return ContactImportState(
      isLoading: isLoading ?? this.isLoading,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      contacts: contacts ?? this.contacts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      errorMessage: errorMessage,
    );
  }
}

class ContactImportController extends StateNotifier<ContactImportState> {
  final IContactsService _contactsService;

  ContactImportController(this._contactsService)
    : super(const ContactImportState());

  Future<void> checkPermissionAndLoad() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final status = await _contactsService.checkPermission();
    state = state.copyWith(permissionStatus: status);

    if (status.isGranted) {
      await loadContacts();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> requestPermission() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final status = await _contactsService.requestPermission();
    state = state.copyWith(permissionStatus: status);

    if (status.isGranted) {
      await loadContacts();
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> loadContacts([String? query]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final list = await _contactsService.getContacts(searchQuery: query);
    state = state.copyWith(
      isLoading: false,
      contacts: list,
      searchQuery: query ?? '',
    );
  }

  void updateSearch(String query) {
    loadContacts(query);
  }

  void toggleSelectContact(String id) {
    final updated = Set<String>.from(state.selectedContactIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(selectedContactIds: updated);
  }

  void selectAll() {
    final allIds = state.contacts.map((c) => c.id).toSet();
    state = state.copyWith(selectedContactIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedContactIds: const {});
  }
}

final contactImportControllerProvider =
    StateNotifierProvider.autoDispose<
      ContactImportController,
      ContactImportState
    >((ref) {
      final contactsService = ref.watch(contactsServiceProvider);
      return ContactImportController(contactsService);
    });
