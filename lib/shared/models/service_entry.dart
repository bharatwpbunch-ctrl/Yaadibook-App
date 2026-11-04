/// Represents a service log, repair or installation activity.
class ServiceEntry {
  final String id;
  final String businessId;
  final String customerId;
  final String? customerAddressId;
  final String? equipmentId;
  final String serviceType;
  final String title;
  final String? description;
  final DateTime serviceDate;
  final String status;
  final double? serviceAmount;
  final String? paymentStatus;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceEntry({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.customerAddressId,
    this.equipmentId,
    required this.serviceType,
    required this.title,
    this.description,
    required this.serviceDate,
    this.status = 'pending',
    this.serviceAmount,
    this.paymentStatus,
    this.notes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceEntry.fromJson(Map<String, dynamic> json) {
    return ServiceEntry(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      customerAddressId: json['customer_address_id'] as String?,
      equipmentId: json['equipment_id'] as String?,
      serviceType: json['service_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      serviceDate: DateTime.parse(json['service_date'] as String),
      status: (json['status'] as String?) ?? 'pending',
      serviceAmount: json['service_amount'] != null
          ? (json['service_amount'] as num).toDouble()
          : null,
      paymentStatus: json['payment_status'] as String?,
      notes: json['notes'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'customer_address_id': customerAddressId,
      'equipment_id': equipmentId,
      'service_type': serviceType,
      'title': title,
      'description': description,
      'service_date': serviceDate.toIso8601String().split('T').first,
      'status': status,
      'service_amount': serviceAmount,
      'payment_status': paymentStatus,
      'notes': notes,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
