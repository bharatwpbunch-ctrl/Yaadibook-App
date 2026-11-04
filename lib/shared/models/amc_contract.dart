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
  final String status;
  final String? coverageDetails;
  final String? documentPath;
  final String? notes;
  final String? renewedFromContractId;
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
    this.status = 'draft',
    this.coverageDetails,
    this.documentPath,
    this.notes,
    this.renewedFromContractId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AmcContract.fromJson(Map<String, dynamic> json) {
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
      status: (json['status'] as String?) ?? 'draft',
      coverageDetails: json['coverage_details'] as String?,
      documentPath: json['document_path'] as String?,
      notes: json['notes'] as String?,
      renewedFromContractId: json['renewed_from_contract_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'document_path': documentPath,
      'notes': notes,
      'renewed_from_contract_id': renewedFromContractId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
