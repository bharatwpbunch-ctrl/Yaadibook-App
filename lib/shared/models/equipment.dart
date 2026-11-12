/// Represents optional customer equipment/hardware (e.g. CCTV, AC, RO).
class Equipment {
  final String id;
  final String businessId;
  final String customerId;
  final String? customerAddressId;
  final String equipmentName;
  final String category;
  final String? brand;
  final String? modelNumber;
  final String? serialNumber;
  final DateTime? installationDate;
  final DateTime? warrantyStartDate;
  final DateTime? warrantyEndDate;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Equipment({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.customerAddressId,
    required this.equipmentName,
    required this.category,
    this.brand,
    this.modelNumber,
    this.serialNumber,
    this.installationDate,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.notes,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  String get name => equipmentName;

  String get displayName {
    final details = <String>[];
    if (brand != null && brand!.isNotEmpty) {
      details.add(brand!);
    }
    if (modelNumber != null && modelNumber!.isNotEmpty) {
      details.add(modelNumber!);
    }
    if (details.isNotEmpty) {
      return '$equipmentName (${details.join(' ')})';
    }
    return equipmentName;
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      customerAddressId: json['customer_address_id'] as String?,
      equipmentName: json['equipment_name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      modelNumber: json['model_number'] as String?,
      serialNumber: json['serial_number'] as String?,
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'] as String)
          : null,
      warrantyStartDate: json['warranty_start_date'] != null
          ? DateTime.parse(json['warranty_start_date'] as String)
          : null,
      warrantyEndDate: json['warranty_end_date'] != null
          ? DateTime.parse(json['warranty_end_date'] as String)
          : null,
      notes: json['notes'] as String?,
      status: (json['status'] as String?) ?? 'active',
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
      'equipment_name': equipmentName,
      'category': category,
      'brand': brand,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'installation_date': installationDate?.toIso8601String().split('T').first,
      'warranty_start_date': warrantyStartDate
          ?.toIso8601String()
          .split('T')
          .first,
      'warranty_end_date': warrantyEndDate?.toIso8601String().split('T').first,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equipment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
