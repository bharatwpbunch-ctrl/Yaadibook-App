import 'customer.dart';
import 'customer_address.dart';
import 'equipment.dart';
import 'service_activity.dart';
import 'service_attachment.dart';

/// Represents a service log, repair, inspection, or installation activity.
class ServiceEntry {
  final String id;
  final String businessId;
  final String customerId;
  final String? customerAddressId;
  final String? equipmentId;
  final String serviceNumber;
  final String
  serviceType; // 'installation', 'repair', 'maintenance', 'inspection', 'general', 'other'
  final String title;
  final String? description;
  final String? workPerformed;
  final DateTime serviceDate;
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final double? serviceAmount;
  final double additionalCharges;
  final double discountAmount;
  final double? totalAmount;
  final String? paymentStatus; // 'unpaid', 'partially_paid', 'paid', 'waived'
  final String? notes;
  final DateTime? completedAt;
  final Customer? customer;
  final CustomerAddress? customerAddress;
  final Equipment? equipment;
  final List<ServiceAttachment> attachments;
  final List<ServiceActivity> activities;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceEntry({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.customerAddressId,
    this.equipmentId,
    this.serviceNumber = '',
    required this.serviceType,
    required this.title,
    this.description,
    this.workPerformed,
    required this.serviceDate,
    this.status = 'pending',
    this.serviceAmount,
    this.additionalCharges = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount,
    this.paymentStatus,
    this.notes,
    this.completedAt,
    this.customer,
    this.customerAddress,
    this.equipment,
    this.attachments = const [],
    this.activities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get serviceTypeDisplay {
    switch (serviceType.toLowerCase()) {
      case 'installation':
        return 'Installation';
      case 'repair':
        return 'Repair';
      case 'maintenance':
        return 'Maintenance';
      case 'inspection':
        return 'Inspection';
      case 'general':
        return 'General Service';
      case 'other':
      default:
        return 'Other';
    }
  }

  /// Accurately computes the total amount: (Base Service Charge + Additional Charges - Discount)
  double get computedTotal {
    if (totalAmount != null) return totalAmount!;
    final base = serviceAmount ?? 0.0;
    final total = base + additionalCharges - discountAmount;
    return total < 0 ? 0.0 : total;
  }

  ServiceEntry copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerAddressId,
    String? equipmentId,
    String? serviceNumber,
    String? serviceType,
    String? title,
    String? description,
    String? workPerformed,
    DateTime? serviceDate,
    String? status,
    double? serviceAmount,
    double? additionalCharges,
    double? discountAmount,
    double? totalAmount,
    String? paymentStatus,
    String? notes,
    DateTime? completedAt,
    Customer? customer,
    CustomerAddress? customerAddress,
    Equipment? equipment,
    List<ServiceAttachment>? attachments,
    List<ServiceActivity>? activities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceEntry(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerAddressId: customerAddressId ?? this.customerAddressId,
      equipmentId: equipmentId ?? this.equipmentId,
      serviceNumber: serviceNumber ?? this.serviceNumber,
      serviceType: serviceType ?? this.serviceType,
      title: title ?? this.title,
      description: description ?? this.description,
      workPerformed: workPerformed ?? this.workPerformed,
      serviceDate: serviceDate ?? this.serviceDate,
      status: status ?? this.status,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      customer: customer ?? this.customer,
      customerAddress: customerAddress ?? this.customerAddress,
      equipment: equipment ?? this.equipment,
      attachments: attachments ?? this.attachments,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ServiceEntry.fromJson(Map<String, dynamic> json) {
    Customer? parsedCustomer;
    if (json['customers'] != null) {
      parsedCustomer = Customer.fromJson(
        json['customers'] as Map<String, dynamic>,
      );
    }

    CustomerAddress? parsedAddress;
    if (json['customer_addresses'] != null) {
      parsedAddress = CustomerAddress.fromJson(
        json['customer_addresses'] as Map<String, dynamic>,
      );
    }

    Equipment? parsedEquipment;
    if (json['equipment'] != null) {
      parsedEquipment = Equipment.fromJson(
        json['equipment'] as Map<String, dynamic>,
      );
    }

    List<ServiceAttachment> parsedAttachments = const [];
    if (json['service_attachments'] is List) {
      parsedAttachments = (json['service_attachments'] as List)
          .map((a) => ServiceAttachment.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<ServiceActivity> parsedActivities = const [];
    if (json['service_activities'] is List) {
      parsedActivities = (json['service_activities'] as List)
          .map((a) => ServiceActivity.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return ServiceEntry(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      customerAddressId: json['customer_address_id'] as String?,
      equipmentId: json['equipment_id'] as String?,
      serviceNumber: (json['service_number'] as String?) ?? '',
      serviceType: json['service_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      workPerformed: json['work_performed'] as String?,
      serviceDate: DateTime.parse(json['service_date'] as String),
      status: (json['status'] as String?) ?? 'pending',
      serviceAmount: json['service_amount'] != null
          ? (json['service_amount'] as num).toDouble()
          : null,
      additionalCharges: json['additional_charges'] != null
          ? (json['additional_charges'] as num).toDouble()
          : 0.0,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : 0.0,
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      paymentStatus: json['payment_status'] as String?,
      notes: json['notes'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      customer: parsedCustomer,
      customerAddress: parsedAddress,
      equipment: parsedEquipment,
      attachments: parsedAttachments,
      activities: parsedActivities,
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
      if (serviceNumber.isNotEmpty) 'service_number': serviceNumber,
      'service_type': serviceType,
      'title': title,
      'description': description,
      'work_performed': workPerformed,
      'service_date': serviceDate.toIso8601String().split('T').first,
      'status': status,
      'service_amount': serviceAmount,
      'additional_charges': additionalCharges,
      'discount_amount': discountAmount,
      'total_amount': totalAmount ?? computedTotal,
      'payment_status': paymentStatus,
      'notes': notes,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
