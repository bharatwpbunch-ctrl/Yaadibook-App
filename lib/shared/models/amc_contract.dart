import 'customer.dart';
import 'equipment.dart';

/// Represents an Annual Maintenance Contract (AMC).
class AmcContract {
  final String id;
  final String businessId;
  final String customerId;
  final String? equipmentId;
  final String contractTitle;
  final String? contractNumber;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final double contractAmount;
  final String? paymentStatus;
  final String
  status; // 'draft', 'active', 'expiring', 'expired', 'renewed', 'cancelled'
  final String? coverageDetails;
  final int? numberOfVisits;
  final String? includedServices;
  final String? excludedServices;
  final String? specialTerms;
  final String? renewalTerms;
  final DateTime? renewalDate;
  final String? documentPath;
  final String? notes;
  final String? renewedFromContractId;
  final Customer? customer;
  final Equipment? equipment;
  final AmcContract? previousContract;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AmcContract({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.equipmentId,
    required this.contractTitle,
    this.contractNumber,
    this.description,
    required this.startDate,
    required this.endDate,
    this.contractAmount = 0.0,
    this.paymentStatus,
    this.status = 'active',
    this.coverageDetails,
    this.numberOfVisits = 4,
    this.includedServices,
    this.excludedServices,
    this.specialTerms,
    this.renewalTerms,
    this.renewalDate,
    this.documentPath,
    this.notes,
    this.renewedFromContractId,
    this.customer,
    this.equipment,
    this.previousContract,
    required this.createdAt,
    required this.updatedAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(today).inDays;
  }

  bool get isActive => status.toLowerCase() == 'active' && !isExpired;
  bool get isRenewed => status.toLowerCase() == 'renewed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isDraft => status.toLowerCase() == 'draft';

  bool get isExpired {
    if (isRenewed || isCancelled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.isBefore(today);
  }

  bool get isExpiringSoon {
    if (isRenewed || isCancelled || isExpired) return false;
    final d = daysRemaining;
    return d >= 0 && d <= 30;
  }

  /// Computed operational status based on contract lifecycle and end date.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'renewed' || s == 'cancelled' || s == 'draft') return s;
    if (isExpired) return 'expired';
    if (isExpiringSoon) return 'expiring';
    return 'active';
  }

  String get expiryText {
    if (isRenewed) return 'Renewed';
    if (isCancelled) return 'Cancelled';
    final d = daysRemaining;
    if (d < 0) {
      final passed = d.abs();
      return passed == 1 ? 'Expired yesterday' : 'Expired $passed days ago';
    } else if (d == 0) {
      return 'Expires today';
    } else if (d == 1) {
      return 'Expires tomorrow';
    } else if (d <= 30) {
      return 'Expires in $d days';
    } else {
      return 'Valid until ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';
    }
  }

  AmcContract copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? equipmentId,
    String? contractTitle,
    String? contractNumber,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? contractAmount,
    String? paymentStatus,
    String? status,
    String? coverageDetails,
    int? numberOfVisits,
    String? includedServices,
    String? excludedServices,
    String? specialTerms,
    String? renewalTerms,
    DateTime? renewalDate,
    String? documentPath,
    String? notes,
    String? renewedFromContractId,
    Customer? customer,
    Equipment? equipment,
    AmcContract? previousContract,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AmcContract(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      equipmentId: equipmentId ?? this.equipmentId,
      contractTitle: contractTitle ?? this.contractTitle,
      contractNumber: contractNumber ?? this.contractNumber,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contractAmount: contractAmount ?? this.contractAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      coverageDetails: coverageDetails ?? this.coverageDetails,
      numberOfVisits: numberOfVisits ?? this.numberOfVisits,
      includedServices: includedServices ?? this.includedServices,
      excludedServices: excludedServices ?? this.excludedServices,
      specialTerms: specialTerms ?? this.specialTerms,
      renewalTerms: renewalTerms ?? this.renewalTerms,
      renewalDate: renewalDate ?? this.renewalDate,
      documentPath: documentPath ?? this.documentPath,
      notes: notes ?? this.notes,
      renewedFromContractId:
          renewedFromContractId ?? this.renewedFromContractId,
      customer: customer ?? this.customer,
      equipment: equipment ?? this.equipment,
      previousContract: previousContract ?? this.previousContract,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AmcContract.fromJson(Map<String, dynamic> json) {
    Customer? customerObj;
    if (json['customers'] != null &&
        json['customers'] is Map<String, dynamic>) {
      customerObj = Customer.fromJson(
        json['customers'] as Map<String, dynamic>,
      );
    }

    Equipment? eqObj;
    if (json['equipment'] != null &&
        json['equipment'] is Map<String, dynamic>) {
      eqObj = Equipment.fromJson(json['equipment'] as Map<String, dynamic>);
    }

    AmcContract? prevObj;
    if (json['previous_contract'] != null &&
        json['previous_contract'] is Map<String, dynamic>) {
      prevObj = AmcContract.fromJson(
        json['previous_contract'] as Map<String, dynamic>,
      );
    }

    return AmcContract(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      equipmentId: json['equipment_id'] as String?,
      contractTitle: json['contract_title'] as String,
      contractNumber: json['contract_number'] as String?,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      contractAmount: (json['contract_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String?,
      status: (json['status'] as String?) ?? 'active',
      coverageDetails: json['coverage_details'] as String?,
      numberOfVisits: json['number_of_visits'] as int?,
      includedServices: json['included_services'] as String?,
      excludedServices: json['excluded_services'] as String?,
      specialTerms: json['special_terms'] as String?,
      renewalTerms: json['renewal_terms'] as String?,
      renewalDate: json['renewal_date'] != null
          ? DateTime.parse(json['renewal_date'] as String)
          : null,
      documentPath: json['document_path'] as String?,
      notes: json['notes'] as String?,
      renewedFromContractId: json['renewed_from_contract_id'] as String?,
      customer: customerObj,
      equipment: eqObj,
      previousContract: prevObj,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'equipment_id': equipmentId,
      'contract_title': contractTitle,
      'contract_number': contractNumber,
      'description': description,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'contract_amount': contractAmount,
      'payment_status': paymentStatus,
      'status': status,
      'coverage_details': coverageDetails,
      'number_of_visits': numberOfVisits,
      'included_services': includedServices,
      'excluded_services': excludedServices,
      'special_terms': specialTerms,
      'renewal_terms': renewalTerms,
      'renewal_date': renewalDate?.toIso8601String().split('T').first,
      'document_path': documentPath,
      'notes': notes,
      'renewed_from_contract_id': renewedFromContractId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
